import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';
import 'package:toc_machine_trading_ipad/global/global.dart';
import 'package:toc_machine_trading_ipad/page/future_trade/notification.dart';
import 'package:toc_machine_trading_ipad/page/future_trade/widget.dart';
import 'package:toc_machine_trading_ipad/pb/app.pb.dart' as pb;
import 'package:wakelock/wakelock.dart';
import 'package:web_socket_channel/io.dart';

class FutureTradePage extends StatefulWidget {
  const FutureTradePage({super.key});

  @override
  State<FutureTradePage> createState() => _FutureTradePageState();
}

class _FutureTradePageState extends State<FutureTradePage> {
  late IOWebSocketChannel? _channel;

  String code = '';
  String delieveryDate = '';

  bool automaticMode = false;
  bool automationByBalance = false;
  bool automationByTimer = false;
  bool isAssiting = false;

  int qty = 1;
  int automationType = 0;

  num automationByBalanceHigh = 4;
  num automationByBalanceLow = -4;
  num automationByTimePeriod = 10;
  num placeOrderTime = DateTime.now().millisecondsSinceEpoch;

  double lastRate = 0;
  double rateDifferenceRatio = 0;

  RealTimeFutureTick? lastTick;
  TradeRate tradeRate = TradeRate(0, 0, 0, 0, 0);

  List<TradeNotification> notificationList = [];
  List<RealTimeFutureTick> totalTickArr = [];
  List<RealTimeFutureTick> tickArr = [];

  List<KbarData> kbarArr = [];
  int kbarMaxVolume = 0;

  Future<FuturePosition?> futurePosition = Future.value();
  Future<TradeIndex?> tradeIndex = Future.value();
  Future<List<RealTimeFutureTick>> realTimeFutureTickArr = Future.value([]);

  @override
  void initState() {
    initialWS();
    Wakelock.enable();
    super.initState();
  }

  @override
  void dispose() {
    _channel!.sink.close();
    Wakelock.disable();
    super.dispose();
  }

  void initialWS() {
    _channel = IOWebSocketChannel.connect(Uri.parse(tradeAgentFutureWSURLPrefix), pingInterval: const Duration(seconds: 1));
    _channel!.stream.listen(
      (message) {
        if (!mounted) {
          return;
        }

        final msg = pb.WSMessage.fromBuffer(message as List<int>);
        switch (msg.type) {
          case pb.WSType.TYPE_FUTURE_TICK:
            updateTradeRate(msg.futureTick, totalTickArr);
            setState(() {
              lastTick = RealTimeFutureTick.fromProto(msg.futureTick);
              if (!automaticMode) {
                realTimeFutureTickArr = fillArr(msg.futureTick, tickArr);
              }
            });
            return;

          case pb.WSType.TYPE_FUTURE_ORDER:
            addNotification(TradeNotification.fromOrder(context, FutureOrder.fromProto(msg.futureOrder)));
            return;

          case pb.WSType.TYPE_TRADE_INDEX:
            setState(() {
              tradeIndex = updateTradeIndex(msg.tradeIndex);
            });
            return;

          case pb.WSType.TYPE_FUTURE_POSITION:
            if (code.isNotEmpty) {
              setState(() {
                futurePosition = updateFuturePosition(msg.futurePosition, code);
              });
            }
            return;

          case pb.WSType.TYPE_ASSIST_STATUS:
            setState(() {
              isAssiting = AssistStatus.fromProto(msg.assitStatus).running!;
            });
            return;

          case pb.WSType.TYPE_KBAR_ARR:
            setState(() {
              final tmp = KbarArr.fromProto(msg.historyKbar);
              kbarArr = tmp.arr!;
              kbarMaxVolume = tmp.maxVolume!.toInt();
            });
            return;

          case pb.WSType.TYPE_ERR_MESSAGE:
            addNotification(TradeNotification.fromError(context, msg.errMessage.errCode.toInt()));
            return;

          case pb.WSType.TYPE_FUTURE_DETAIL:
            setState(() {
              code = msg.futureDetail.code;
              delieveryDate = msg.futureDetail.deliveryDate;
            });
            addNotification(TradeNotification.connected(context));
            return;
        }
      },
      onDone: () {
        if (mounted) {
          addNotification(TradeNotification.reconnectingWS(context));
          Future.delayed(const Duration(milliseconds: 1000)).then((value) {
            _channel!.sink.close();
            tradeRate = TradeRate(0, 0, 0, 0, 0);
            initialWS();
          });
        }
      },
      onError: (error) {},
    );
  }

  void updateTradeRate(pb.WSFutureTick ws, List<RealTimeFutureTick> totalArr) {
    totalTickArr.add(RealTimeFutureTick.fromProto(ws));

    const baseDuration = Duration(seconds: 10);
    final firstPeriod = RealTimeFutureTickArr();
    final secondPeriod = RealTimeFutureTickArr();
    final thirdPeriod = RealTimeFutureTickArr();
    final fourthPeriod = RealTimeFutureTickArr();

    final startTime = totalTickArr[totalTickArr.length - 1].tickTime;
    for (var i = 0; i < totalTickArr.length; i++) {
      if (totalTickArr[i].tickTime!.isBefore(startTime!.subtract(baseDuration * 4))) {
        totalTickArr.removeAt(i);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(startTime.subtract(baseDuration * 3))) {
        fourthPeriod.arr.add(totalTickArr[i]);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(startTime.subtract(baseDuration * 2))) {
        thirdPeriod.arr.add(totalTickArr[i]);
        fourthPeriod.arr.add(totalTickArr[i]);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(startTime.subtract(baseDuration * 1))) {
        secondPeriod.arr.add(totalTickArr[i]);
        thirdPeriod.arr.add(totalTickArr[i]);
        fourthPeriod.arr.add(totalTickArr[i]);
        continue;
      }

      firstPeriod.arr.add(totalTickArr[i]);
      secondPeriod.arr.add(totalTickArr[i]);
      thirdPeriod.arr.add(totalTickArr[i]);
      fourthPeriod.arr.add(totalTickArr[i]);
    }

    setState(() {
      tradeRate = TradeRate(
        firstPeriod.getOutInVolume().getOutInRatio(),
        secondPeriod.getOutInVolume().getOutInRatio(),
        thirdPeriod.getOutInVolume().getOutInRatio(),
        fourthPeriod.getOutInVolume().getOutInRatio(),
        firstPeriod.getOutInVolume().getRate(),
      );
      rateDifferenceRatio = tradeRate.rate / lastRate;
      // log('rate: ${tradeRate.rate.toString()}, diff_ratio: ${rateDifferenceRatio.toStringAsFixed(2)}');
    });

    if (!isAssiting && automaticMode && (automationByBalance || automationByTimer) && DateTime.now().millisecondsSinceEpoch - placeOrderTime > 30000) {
      if (lastRate > 6 && rateDifferenceRatio > 1.6) {
        if (tradeRate.percent1 > 70) {
          _buyFuture(code, lastTick!.close!);
          placeOrderTime = DateTime.now().millisecondsSinceEpoch;
        } else if (tradeRate.percent1 < 30) {
          _sellFuture(code, lastTick!.close!);
          placeOrderTime = DateTime.now().millisecondsSinceEpoch;
        }
      }
    }
    lastRate = tradeRate.rate;
  }

  Future<TradeIndex> updateTradeIndex(pb.WSTradeIndex ws) async => TradeIndex.fromProto(ws);
  Future<FuturePosition> updateFuturePosition(pb.WSFuturePosition ws, String code) async => FuturePosition.fromProto(ws, code);
  Future<List<RealTimeFutureTick>> fillArr(pb.WSFutureTick wsTick, List<RealTimeFutureTick> originalArr) async {
    final tmp = RealTimeFutureTick.fromProto(wsTick);
    if (originalArr.isNotEmpty && originalArr.last.close == tmp.close && originalArr.last.tickType == tmp.tickType) {
      originalArr.last.volume = originalArr.last.volume! + tmp.volume!;
      originalArr.last.tickTime = tmp.tickTime;
      originalArr.last.combo = true;
    } else {
      originalArr.add(tmp);
      if (originalArr.length > 7) {
        originalArr.removeAt(0);
      }
    }
    return originalArr.reversed.toList();
  }

  void _buyFuture(String code, num close) {
    if (close == 0) {
      return;
    }

    num automationType = 0;
    if (automationByBalance && automationByTimer) {
      automationType = 3;
    } else if (automationByBalance) {
      automationType = 1;
    } else if (automationByTimer) {
      automationType = 2;
    }

    _channel!.sink.add(
      jsonEncode(
        {
          'code': code,
          'action': 1,
          'price': close,
          'qty': qty,
          'option': {
            'automation_type': automationType,
            'by_balance_high': automationByBalanceHigh,
            'by_balance_low': automationByBalanceLow,
            'by_time_period': automationByTimePeriod,
          },
        },
      ),
    );
  }

  void _sellFuture(String code, num close) {
    if (close == 0) {
      return;
    }

    num automationType = 0;
    if (automationByBalance && automationByTimer) {
      automationType = 3;
    } else if (automationByBalance) {
      automationType = 1;
    } else if (automationByTimer) {
      automationType = 2;
    }

    _channel!.sink.add(
      jsonEncode(
        {
          'code': code,
          'action': 2,
          'price': close,
          'qty': qty,
          'option': {
            'automation_type': automationType,
            'by_balance_high': automationByBalanceHigh,
            'by_balance_low': automationByBalanceLow,
            'by_time_period': automationByTimePeriod,
          },
        },
      ),
    );
  }

  void _showByBalanceSetting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        iconColor: Colors.teal,
        icon: const Icon(
          Icons.settings,
          size: 40,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(AppLocalizations.of(context)!.balance),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            height: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(AppLocalizations.of(context)!.earn),
                NumberPicker(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.teal, fontSize: 40),
                  value: automationByBalanceHigh.toInt(),
                  minValue: 1,
                  maxValue: 50,
                  itemWidth: 90,
                  axis: Axis.horizontal,
                  haptics: true,
                  onChanged: (value) {
                    setState(() {
                      automationByBalanceHigh = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '-',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByBalanceHigh -= 1;
                          if (automationByBalanceHigh < 1) {
                            automationByBalanceHigh = 1;
                          }
                        });
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '+',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByBalanceHigh += 1;
                          if (automationByBalanceHigh > 50) {
                            automationByBalanceHigh = 50;
                          }
                        });
                      },
                    ),
                  ],
                ),
                Text(AppLocalizations.of(context)!.loss),
                NumberPicker(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.teal, fontSize: 40),
                  value: automationByBalanceLow.toInt(),
                  minValue: -50,
                  maxValue: -1,
                  itemWidth: 90,
                  axis: Axis.horizontal,
                  haptics: true,
                  onChanged: (value) {
                    setState(() {
                      automationByBalanceLow = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '-',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByBalanceLow -= 1;
                          if (automationByBalanceLow < -50) {
                            automationByBalanceLow = -50;
                          }
                        });
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '+',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByBalanceLow += 1;
                          if (automationByBalanceLow > -1) {
                            automationByBalanceLow = -1;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showByTimePeriodSetting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        iconColor: Colors.teal,
        icon: const Icon(
          Icons.settings,
          size: 40,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(AppLocalizations.of(context)!.time_period),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NumberPicker(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.teal, fontSize: 40),
                  value: automationByTimePeriod.toInt(),
                  minValue: 5,
                  maxValue: 500,
                  step: 5,
                  itemWidth: 90,
                  axis: Axis.horizontal,
                  haptics: true,
                  onChanged: (value) {
                    setState(() {
                      automationByTimePeriod = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '-',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByTimePeriod -= 5;
                          if (automationByTimePeriod < 5) {
                            automationByTimePeriod = 5;
                          }
                        });
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.yellow[50],
                      ),
                      child: const Text(
                        '+',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                      onPressed: () {
                        setState(() {
                          automationByTimePeriod += 5;
                          if (automationByTimePeriod > 500) {
                            automationByTimePeriod = 500;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addNotification(TradeNotification notification) {
    setState(() {
      final limit = automaticMode ? 8 : 4;
      if (notificationList.length == limit) {
        notificationList.removeLast();
      }
      notificationList.insert(0, notification);
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(15),
        child: SizedBox(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (automaticMode)
                      Container()
                    else
                      Expanded(
                        child: FutureBuilder<List<RealTimeFutureTick>>(
                          future: realTimeFutureTickArr,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final arr = <Widget>[];
                              for (final i in snapshot.data!) {
                                arr.add(buildTickDetail(i));
                              }
                              return Center(
                                child: Column(
                                  children: arr,
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (notificationList.isNotEmpty) buildNotification(notificationList[0]) else Container(),
                          if (notificationList.length > 1) buildNotification(notificationList[1]) else Container(),
                          if (notificationList.length > 2) buildNotification(notificationList[2]) else Container(),
                          if (notificationList.length > 3) buildNotification(notificationList[3]) else Container(),
                          if (notificationList.length > 4) buildNotification(notificationList[4]) else Container(),
                          if (notificationList.length > 5) buildNotification(notificationList[5]) else Container(),
                          if (notificationList.length > 6) buildNotification(notificationList[6]) else Container(),
                          if (notificationList.length > 7) buildNotification(notificationList[7]) else Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: FutureBuilder<FuturePosition?>(
                                    future: futurePosition,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data!.direction != null) {
                                        String action;
                                        action = snapshot.data!.direction == 'Buy' ? AppLocalizations.of(context)!.buy : AppLocalizations.of(context)!.sell;
                                        return Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                code,
                                                style: GoogleFonts.getFont(
                                                  'Source Code Pro',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: 50,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '$action: ${snapshot.data!.quantity}\n${AppLocalizations.of(context)!.avg}: ${snapshot.data!.price}',
                                                style: GoogleFonts.getFont(
                                                  'Source Code Pro',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: 25,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      if (code.isNotEmpty) {
                                        return Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                code,
                                                style: GoogleFonts.getFont(
                                                  'Source Code Pro',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: 50,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Settlement: $delieveryDate',
                                                style: GoogleFonts.getFont(
                                                  'Source Code Pro',
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: 25,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return Center(
                                        child: Text(
                                          AppLocalizations.of(context)!.loading,
                                          style: GoogleFonts.getFont(
                                            'Source Code Pro',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 40,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: FutureBuilder<TradeIndex?>(
                                  future: tradeIndex,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Column(
                                        children: [
                                          buildIndexRow(context, 'NASDAQ', snapshot.data!.nasdaq!.priceChg!, snapshot.data!.nasdaq!.breakCount!),
                                          buildIndexRow(context, 'NQ=F', snapshot.data!.nf!.priceChg!, snapshot.data!.nf!.breakCount!),
                                          buildIndexRow(context, 'TSE', snapshot.data!.tse!.priceChg!, snapshot.data!.tse!.breakCount!),
                                          buildIndexRow(context, 'OTC', snapshot.data!.otc!.priceChg!, snapshot.data!.otc!.breakCount!),
                                        ],
                                      );
                                    }
                                    return Center(
                                      child: Text(
                                        AppLocalizations.of(context)!.loading,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (lastTick == null)
                            Center(child: Text(AppLocalizations.of(context)!.loading))
                          else
                            SizedBox(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        Text(
                                          lastTick!.close!.toStringAsFixed(0),
                                          style: GoogleFonts.getFont(
                                            'Source Code Pro',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 50,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${lastTick!.changeType} ${lastTick!.priceChg!.abs().toStringAsFixed(0)}',
                                          style: GoogleFonts.getFont(
                                            'Source Code Pro',
                                            fontStyle: FontStyle.normal,
                                            fontSize: 50,
                                            color: lastTick!.priceChg! == 0
                                                ? Colors.blueGrey
                                                : lastTick!.priceChg! > 0
                                                    ? Colors.red
                                                    : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Text(
                                        '${tradeRate.rate.toStringAsFixed(2)}/s',
                                        style: GoogleFonts.getFont(
                                          'Source Code Pro',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 35,
                                          color: tradeRate.rate < 7
                                              ? Colors.grey
                                              : tradeRate.percent1 > 70
                                                  ? Colors.red
                                                  : tradeRate.percent1 < 30
                                                      ? Colors.green
                                                      : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        buildVolumeRatioCircle(tradeRate.percent1, tradeRate.rate),
                                        buildVolumeRatioCircle(tradeRate.percent2, tradeRate.rate),
                                        buildVolumeRatioCircle(tradeRate.percent3, tradeRate.rate),
                                        buildVolumeRatioCircle(tradeRate.percent4, tradeRate.rate),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: !automaticMode
                                    ? () {
                                        if (!automationByBalance) {
                                          _showByBalanceSetting();
                                        }
                                        setState(() {
                                          automationByBalance = !automationByBalance;
                                        });
                                      }
                                    : null,
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.monetization_on,
                                    color: automationByBalance ? Colors.blueAccent : Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: !automaticMode
                                    ? () {
                                        if (!automationByTimer) {
                                          _showByTimePeriodSetting();
                                        }
                                        setState(() {
                                          automationByTimer = !automationByTimer;
                                        });
                                      }
                                    : null,
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.timer,
                                    color: automationByTimer ? Colors.blueAccent : Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: automaticMode ? Colors.grey : Colors.yellow[50],
                                ),
                                onPressed: !automaticMode
                                    ? () {
                                        setState(() {
                                          qty--;
                                          if (qty == 0) {
                                            qty = 1;
                                          }
                                        });
                                      }
                                    : null,
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    color: !automaticMode ? Colors.black : Colors.grey,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              Text(
                                qty.toString(),
                                style: GoogleFonts.getFont(
                                  'Source Code Pro',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 30,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: automaticMode ? Colors.grey : Colors.yellow[50],
                                ),
                                onPressed: !automaticMode
                                    ? () {
                                        setState(() {
                                          qty++;
                                          if (qty == 10) {
                                            qty = 9;
                                          }
                                        });
                                      }
                                    : null,
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    color: !automaticMode ? Colors.black : Colors.grey,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  elevation: MaterialStateProperty.all(10),
                                  backgroundColor: automaticMode ? MaterialStateProperty.all(Colors.red[500]) : MaterialStateProperty.all(Colors.amber[400]),
                                ),
                                onPressed: !automaticMode
                                    ? () {
                                        if (!automationByBalance && !automationByTimer) {
                                          addNotification(TradeNotification.fromError(context, -10));
                                          return;
                                        }
                                        setState(() {
                                          automaticMode = !automaticMode;
                                        });
                                      }
                                    : () {
                                        setState(() {
                                          tradeRate = TradeRate(0, 0, 0, 0, 0);
                                          automaticMode = !automaticMode;
                                          automationByBalance = false;
                                          automationByTimer = false;
                                          if (notificationList.length > 4) {
                                            notificationList.length = 4;
                                          }
                                        });
                                        _channel!.sink.close();
                                      },
                                child: SizedBox(
                                  width: 75,
                                  height: 70,
                                  child: Center(
                                    child: Text(
                                      automaticMode ? AppLocalizations.of(context)!.stop : AppLocalizations.of(context)!.auto,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  elevation: (!automaticMode && !isAssiting) ? MaterialStateProperty.all(10) : MaterialStateProperty.all(0),
                                  backgroundColor: isAssiting
                                      ? MaterialStateProperty.all(Colors.orange[100])
                                      : !automaticMode
                                          ? MaterialStateProperty.all(Colors.red)
                                          : MaterialStateProperty.all(Colors.grey[300]),
                                ),
                                onPressed: (!automaticMode && !isAssiting) ? () => _buyFuture(code, lastTick!.close!) : null,
                                child: SizedBox(
                                  width: 130,
                                  height: 70,
                                  child: Center(
                                    child: Text(
                                      !isAssiting ? AppLocalizations.of(context)!.buy : AppLocalizations.of(context)!.assisting,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  elevation: (!automaticMode && !isAssiting) ? MaterialStateProperty.all(10) : MaterialStateProperty.all(0),
                                  backgroundColor: isAssiting
                                      ? MaterialStateProperty.all(Colors.orange[100])
                                      : !automaticMode
                                          ? MaterialStateProperty.all(Colors.green)
                                          : MaterialStateProperty.all(Colors.grey[300]),
                                ),
                                onPressed: (!automaticMode && !isAssiting) ? () => _sellFuture(code, lastTick!.close!) : null,
                                child: SizedBox(
                                  width: 130,
                                  height: 70,
                                  child: Center(
                                    child: Text(
                                      !isAssiting ? AppLocalizations.of(context)!.sell : AppLocalizations.of(context)!.assisting,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (kbarArr.isNotEmpty)
                      Expanded(
                        child: SfCartesianChart(
                          enableSideBySideSeriesPlacement: false,
                          plotAreaBorderWidth: 0,
                          primaryYAxis: NumericAxis(
                            isVisible: false,
                          ),
                          primaryXAxis: DateTimeAxis(
                            majorGridLines: const MajorGridLines(width: 0),
                          ),
                          axes: [
                            NumericAxis(
                              isVisible: false,
                              name: 'price',
                            ),
                            NumericAxis(
                              maximum: kbarMaxVolume.toDouble() * 3,
                              isVisible: false,
                              opposedPosition: true,
                              name: 'volume',
                            ),
                          ],
                          series: <ChartSeries>[
                            ColumnSeries(
                              yAxisName: 'volume',
                              dataSource: kbarArr,
                              xValueMapper: (datum, index) => (datum as KbarData).kbarTime,
                              yValueMapper: (datum, index) => (datum as KbarData).volume!,
                              pointColorMapper: (datum, index) => (datum as KbarData).close! > datum.open! ? Colors.redAccent : Colors.greenAccent,
                            ),
                            CandleSeries(
                              yAxisName: 'price',
                              showIndicationForSameValues: true,
                              enableSolidCandles: true,
                              bearColor: Colors.green,
                              bullColor: Colors.red,
                              dataSource: kbarArr,
                              xValueMapper: (datum, index) => (datum as KbarData).kbarTime,
                              lowValueMapper: (datum, index) => (datum as KbarData).low,
                              highValueMapper: (datum, index) => (datum as KbarData).high,
                              openValueMapper: (datum, index) => (datum as KbarData).open,
                              closeValueMapper: (datum, index) => (datum as KbarData).close,
                              trendlines: <Trendline>[
                                Trendline(
                                  type: TrendlineType.polynomial,
                                  dashArray: <double>[5, 5],
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.kbar_is_loading,
                            style: GoogleFonts.getFont('Source Code Pro', fontStyle: FontStyle.normal, fontSize: 15, color: Colors.grey),
                          ),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      );
}
