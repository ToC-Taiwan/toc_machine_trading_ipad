import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart' as df;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';
import 'package:toc_machine_trading_ipad/error/error.dart';
import 'package:toc_machine_trading_ipad/global/global.dart';
import 'package:toc_machine_trading_ipad/page/future_trade/widget.dart';
import 'package:toc_machine_trading_ipad/pb/app.pb.dart' as pb;
import 'package:toc_machine_trading_ipad/service/service.dart';
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

  bool isAssiting = false;
  bool automaticMode = false;
  bool automationByTimer = false;
  bool automationByBalance = false;

  int qty = 1;
  int automationType = 0;
  num? automationByBalanceHigh = 1;
  num? automationByBalanceLow = -1;
  num? automationByTimePeriod = 5;
  num placeOrderTime = DateTime.now().millisecondsSinceEpoch;

  double lastRate = 0;
  TradeRate tradeRate = TradeRate(0, 0, 0, 0, 0);

  List<RealTimeFutureTick> totalTickArr = [];
  List<RealTimeFutureTick> tickArr = [];
  RealTimeFutureTick? lastTick;
  RealTimeFutureTick? beforeLastTick;

  Future<RealTimeFutureTick?> realTimeFutureTick = Future.value();
  Future<FuturePosition?> futurePosition = Future.value();
  Future<TradeIndex?> tradeIndex = Future.value();
  Future<List<RealTimeFutureTick>> realTimeFutureTickArr = Future.value([]);
  Future<List<KbarData>> kbarArr = Future.value([]);

  @override
  void initState() {
    super.initState();
    initialWS();
    Wakelock.enable();
  }

  @override
  void dispose() {
    _channel!.sink.close();
    Wakelock.disable();
    super.dispose();
  }

  void initialWS() {
    _channel = IOWebSocketChannel.connect(Uri.parse(tradeAgentFutureWSURLPrefix));
    _channel!.stream.listen(
      (message) {
        if (message == 'pong') {
          return;
        }

        final msg = pb.WSMessage.fromBuffer(message as List<int>);
        switch (msg.type) {
          case pb.WSType.TYPE_FUTURE_TICK:
            if (mounted) {
              updateTradeRate(msg.futureTick, totalTickArr);
              setState(() {
                lastTick = RealTimeFutureTick.fromProto(msg.futureTick);
                realTimeFutureTick = getData(msg.futureTick);
                realTimeFutureTickArr = fillArr(msg.futureTick, tickArr);
              });
            }
            return;

          case pb.WSType.TYPE_FUTURE_ORDER:
            if (mounted) {
              showOrderResult(context, FutureOrder.fromProto(msg.futureOrder));
            }
            return;

          case pb.WSType.TYPE_TRADE_INDEX:
            if (mounted) {
              setState(() {
                tradeIndex = updateTradeIndex(msg.tradeIndex);
              });
            }
            return;

          case pb.WSType.TYPE_FUTURE_POSITION:
            if (code.isNotEmpty) {
              futurePosition = updateFuturePosition(msg.futurePosition, code);
            }
            return;

          case pb.WSType.TYPE_ASSIST_STATUS:
            if (mounted) {
              setState(() {
                isAssiting = AssistStatus.fromProto(msg.assitStatus).running!;
              });
            }
            return;

          case pb.WSType.TYPE_KBAR_ARR:
            setState(() {
              kbarArr = getKbarArr(msg.historyKbar);
            });
            return;

          case pb.WSType.TYPE_ERR_MESSAGE:
            if (mounted) {
              showErrorDialog(context, ErrMessage.fromProto(msg.errMessage));
            }
            return;

          case pb.WSType.TYPE_FUTURE_DETAIL:
            code = msg.futureDetail.code;
            setState(() {
              delieveryDate = msg.futureDetail.deliveryDate;
            });
            return;
        }
      },
      onDone: () {
        if (mounted) {
          initialWS();
        }
      },
    );
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        try {
          _channel!.sink.add('ping');
        } on Exception catch (_) {
          timer.cancel();
        }
      }
    });
  }

  void updateTradeRate(pb.WSFutureTick ws, List<RealTimeFutureTick> totalArr) {
    totalTickArr.add(RealTimeFutureTick.fromProto(ws));

    const baseDuration = Duration(seconds: 10);
    final firstPeriod = RealTimeFutureTickArr();
    final secondPeriod = RealTimeFutureTickArr();
    final thirdPeriod = RealTimeFutureTickArr();
    final fourthPeriod = RealTimeFutureTickArr();

    for (var i = 0; i < totalTickArr.length; i++) {
      if (totalTickArr[i].tickTime!.isBefore(DateTime.now().subtract(baseDuration * 4))) {
        totalTickArr.removeAt(i);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(DateTime.now().subtract(baseDuration * 3))) {
        fourthPeriod.arr.add(totalTickArr[i]);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(DateTime.now().subtract(baseDuration * 2))) {
        thirdPeriod.arr.add(totalTickArr[i]);
        fourthPeriod.arr.add(totalTickArr[i]);
        continue;
      }

      if (totalTickArr[i].tickTime!.isBefore(DateTime.now().subtract(baseDuration * 1))) {
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

    if (!isAssiting && automaticMode && (automationByBalance || automationByTimer) && DateTime.now().millisecondsSinceEpoch - placeOrderTime > 30000) {
      if (tradeRate.rate > 25 && lastRate < 10) {
        if (tradeRate.percent1 > 85) {
          _buyFuture(code, lastTick!.close!);
          placeOrderTime = DateTime.now().millisecondsSinceEpoch;
        } else if (tradeRate.percent1 < 15) {
          _sellFuture(code, lastTick!.close!);
          placeOrderTime = DateTime.now().millisecondsSinceEpoch;
        }
      }
    }
    lastRate = tradeRate.rate;

    setState(() {
      if (mounted) {
        tradeRate = TradeRate(
          firstPeriod.getOutInVolume().getOutInRatio(),
          secondPeriod.getOutInVolume().getOutInRatio(),
          thirdPeriod.getOutInVolume().getOutInRatio(),
          fourthPeriod.getOutInVolume().getOutInRatio(),
          firstPeriod.getOutInVolume().getRate(),
        );
      }
    });
  }

  Future<RealTimeFutureTick> getData(pb.WSFutureTick ws) async => RealTimeFutureTick.fromProto(ws);
  Future<TradeIndex> updateTradeIndex(pb.WSTradeIndex ws) async => TradeIndex.fromProto(ws);
  Future<FuturePosition> updateFuturePosition(pb.WSFuturePosition ws, String code) async => FuturePosition.fromProto(ws, code);
  Future<List<KbarData>> getKbarArr(pb.WSHistoryKbarMessage ws) async {
    final tmp = <KbarData>[];
    for (final element in ws.arr) {
      tmp.add(
        KbarData(
          kbarTime: DateTime.parse(element.kbarTime),
          high: element.high,
          low: element.low,
          open: element.open,
          close: element.close,
          volume: element.volume.toInt(),
        ),
      );
    }
    return tmp;
  }

  Future<List<RealTimeFutureTick>> fillArr(pb.WSFutureTick wsTick, List<RealTimeFutureTick> originalArr) async {
    final tmp = RealTimeFutureTick.fromProto(wsTick);
    if (originalArr.isNotEmpty && originalArr.last.close == tmp.close && originalArr.last.tickType == tmp.tickType) {
      originalArr.last.volume = originalArr.last.volume! + tmp.volume!;
      originalArr.last.tickTime = tmp.tickTime;
      originalArr.last.combo = true;
    } else {
      originalArr.add(tmp);
      if (originalArr.length > 14) {
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
        title: Text(AppLocalizations.of(context)!.settings),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            height: 300,
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
                  value: automationByBalanceHigh!.toInt(),
                  minValue: 1,
                  maxValue: 50,
                  itemWidth: 75,
                  axis: Axis.horizontal,
                  haptics: true,
                  onChanged: (value) {
                    setState(() {
                      automationByBalanceHigh = value;
                    });
                  },
                ),
                Text(AppLocalizations.of(context)!.loss),
                NumberPicker(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.teal, fontSize: 40),
                  value: automationByBalanceLow!.toInt(),
                  minValue: -50,
                  maxValue: -1,
                  itemWidth: 75,
                  axis: Axis.horizontal,
                  haptics: true,
                  onChanged: (value) {
                    setState(() {
                      automationByBalanceLow = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: const TextStyle(color: Colors.black),
              ),
              onPressed: () {
                setState(() {
                  automationByBalance = true;
                });
                Navigator.pop(context);
              },
            ),
          ),
        ],
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
        title: Text(AppLocalizations.of(context)!.settings),
        content: StatefulBuilder(
          builder: (context, setState) => NumberPicker(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal),
              borderRadius: BorderRadius.circular(10),
            ),
            selectedTextStyle: const TextStyle(color: Colors.teal, fontSize: 40),
            value: automationByTimePeriod!.toInt(),
            minValue: 5,
            maxValue: 500,
            step: 5,
            itemWidth: 75,
            axis: Axis.horizontal,
            haptics: true,
            onChanged: (value) {
              setState(() {
                automationByTimePeriod = value;
              });
            },
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: const TextStyle(color: Colors.black),
              ),
              onPressed: () {
                setState(() {
                  automationByTimer = true;
                });
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
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
                    Expanded(
                      child: FutureBuilder<List<RealTimeFutureTick>>(
                        future: realTimeFutureTickArr,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final value = snapshot.data!;
                            return ListView.builder(
                              itemCount: value.length,
                              itemBuilder: (context, index) => Container(
                                margin: const EdgeInsets.only(bottom: 2, right: 20, top: 4.25),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: value[index].tickType == 1 ? Colors.red : Colors.green,
                                    width: 1.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Text(
                                    '${value[index].volume!}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: value[index].combo! ? 20 : 14,
                                      color: value[index].tickType == 1 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    value[index].close!.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: value[index].combo! ? 20 : 14,
                                      color: value[index].tickType == 1 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  trailing: Text(df.formatDate(value[index].tickTime!, [df.HH, ':', df.nn, ':', df.ss])),
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
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
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: FutureBuilder<FuturePosition?>(
                                    future: futurePosition,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        if (snapshot.data!.direction == 'Buy') {
                                          return Text(
                                            '$code\n${AppLocalizations.of(context)!.buy}: ${snapshot.data!.quantity}\n${AppLocalizations.of(context)!.avg}: ${snapshot.data!.price}',
                                            style: GoogleFonts.getFont('Source Code Pro', fontStyle: FontStyle.normal, fontSize: 35, color: Colors.grey),
                                          );
                                        }
                                        if (snapshot.data!.direction == 'Sell') {
                                          return Text(
                                            '$code\n${AppLocalizations.of(context)!.sell}: ${snapshot.data!.quantity}\n${AppLocalizations.of(context)!.avg}: ${snapshot.data!.price}',
                                            style: GoogleFonts.getFont('Source Code Pro', fontStyle: FontStyle.normal, fontSize: 35, color: Colors.grey),
                                          );
                                        }
                                      }
                                      return Text(
                                        '$code\n$delieveryDate',
                                        style: GoogleFonts.getFont(
                                          'Source Code Pro',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 40,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.bold,
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
                                          buildIndexRow('^IXIC', snapshot.data!.nasdaq!.priceChg!, snapshot.data!.nasdaq!.breakCount!),
                                          buildIndexRow('NQ=F', snapshot.data!.nf!.priceChg!, snapshot.data!.nf!.breakCount!),
                                          buildIndexRow('^TWII', snapshot.data!.tse!.priceChg!, snapshot.data!.tse!.breakCount!),
                                          buildIndexRow('TWO', snapshot.data!.otc!.priceChg!, snapshot.data!.otc!.breakCount!),
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
                          FutureBuilder<RealTimeFutureTick?>(
                            future: realTimeFutureTick,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final type = (snapshot.data!.priceChg! == 0)
                                    ? ''
                                    : (snapshot.data!.priceChg! > 0)
                                        ? '↗️'
                                        : '↘️';
                                return SizedBox(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            snapshot.data!.close!.toStringAsFixed(0),
                                            style: GoogleFonts.getFont(
                                              'Source Code Pro',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 50,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$type ${snapshot.data!.priceChg!.toStringAsFixed(0)}',
                                            style: GoogleFonts.getFont(
                                              'Source Code Pro',
                                              fontStyle: FontStyle.normal,
                                              fontSize: 50,
                                              color: snapshot.data!.priceChg! == 0
                                                  ? Colors.blueGrey
                                                  : snapshot.data!.priceChg! > 0
                                                      ? Colors.red
                                                      : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${tradeRate.rate.toStringAsFixed(2)}/s',
                                        style: GoogleFonts.getFont(
                                          'Source Code Pro',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 35,
                                          color: tradeRate.rate < 10
                                              ? Colors.grey
                                              : tradeRate.percent1 > 50
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                      buildVolumeRatioCircle(tradeRate.percent1, tradeRate.rate),
                                      buildVolumeRatioCircle(tradeRate.percent2, tradeRate.rate),
                                      buildVolumeRatioCircle(tradeRate.percent3, tradeRate.rate),
                                      buildVolumeRatioCircle(tradeRate.percent4, tradeRate.rate),
                                    ],
                                  ),
                                );
                              } else {
                                return Text(AppLocalizations.of(context)!.loading);
                              }
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onLongPress: _showByBalanceSetting,
                                onTap: () {
                                  setState(() {
                                    automationByBalance = !automationByBalance;
                                  });
                                },
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
                                onLongPress: _showByTimePeriodSetting,
                                onTap: () {
                                  setState(() {
                                    automationByTimer = !automationByTimer;
                                  });
                                },
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
                                  backgroundColor: Colors.yellow[50],
                                ),
                                child: const Text(
                                  '-',
                                  style: TextStyle(color: Colors.black, fontSize: 22),
                                ),
                                onPressed: () {
                                  setState(() {
                                    qty--;
                                    if (qty == 0) {
                                      qty = 1;
                                    }
                                  });
                                },
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
                                  backgroundColor: Colors.yellow[50],
                                ),
                                child: const Text(
                                  '+',
                                  style: TextStyle(color: Colors.black, fontSize: 22),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    qty++;
                                    if (qty == 10) {
                                      qty = 9;
                                    }
                                  });
                                },
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
                                onPressed: () {
                                  setState(() {
                                    automaticMode = !automaticMode;
                                  });
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
                    Expanded(
                      child: FutureBuilder<List<KbarData>>(
                        future: kbarArr,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return SfCartesianChart(
                              plotAreaBorderWidth: 0,
                              primaryYAxis: NumericAxis(
                                isVisible: false,
                              ),
                              primaryXAxis: DateTimeAxis(
                                isVisible: false,
                              ),
                              series: <ChartSeries>[
                                CandleSeries(
                                  showIndicationForSameValues: true,
                                  enableSolidCandles: true,
                                  bearColor: Colors.green,
                                  bullColor: Colors.red,
                                  dataSource: snapshot.data!,
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
                                )
                              ],
                            );
                          }
                          return Text(
                            AppLocalizations.of(context)!.kbar_is_loading,
                            style: GoogleFonts.getFont('Source Code Pro', fontStyle: FontStyle.normal, fontSize: 15, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
}
