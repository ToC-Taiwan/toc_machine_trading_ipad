import 'package:toc_machine_trading_ipad/pb/app.pb.dart' as pb;

class RealTimeFutureTick {
  RealTimeFutureTick(
    this.code,
    this.tickTime,
    this.open,
    this.underlyingPrice,
    this.bidSideTotalVol,
    this.askSideTotalVol,
    this.avgPrice,
    this.close,
    this.high,
    this.low,
    this.amount,
    this.totalAmount,
    this.volume,
    this.totalVolume,
    this.tickType,
    this.chgType,
    this.priceChg,
    this.pctChg,
    this.simtrade,
  );

  RealTimeFutureTick.fromProto(pb.WSFutureTick tick) {
    code = tick.code;
    tickTime = DateTime.parse(tick.tickTime);
    open = tick.open;
    underlyingPrice = tick.underlyingPrice;
    bidSideTotalVol = tick.bidSideTotalVol.toInt();
    askSideTotalVol = tick.askSideTotalVol.toInt();
    avgPrice = tick.avgPrice;
    close = tick.close;
    high = tick.high;
    low = tick.low;
    amount = tick.amount;
    totalAmount = tick.totalAmount;
    volume = tick.volume.toInt();
    totalVolume = tick.totalVolume.toInt();
    tickType = tick.tickType.toInt();
    chgType = tick.chgType.toInt();
    priceChg = tick.priceChg;
    pctChg = tick.pctChg;
    if (tick.priceChg > 0) {
      changeType = '↗️';
    } else if (tick.priceChg < 0) {
      changeType = '↘️';
    } else {
      changeType = '';
    }
  }

  String? code;
  DateTime? tickTime;
  num? open;
  num? underlyingPrice;
  num? bidSideTotalVol;
  num? askSideTotalVol;
  num? avgPrice;
  num? close;
  num? high;
  num? low;
  num? amount;
  num? totalAmount;
  num? volume;
  num? totalVolume;
  num? tickType;
  num? chgType;
  num? priceChg;
  num? pctChg;
  num? simtrade;
  bool? combo = false;
  String? changeType;
}

class RealTimeFutureTickArr {
  OutInVolume getOutInVolume() {
    var outVolume = 0;
    var inVolume = 0;
    for (var i = 0; i < arr.length; i++) {
      switch (arr[i].tickType) {
        case 1:
          outVolume += arr[i].volume!.toInt();
          continue;
        case 2:
          inVolume += arr[i].volume!.toInt();
          continue;
      }
    }
    return OutInVolume(outVolume, inVolume);
  }

  List<RealTimeFutureTick> arr = [];
}

class AssistStatus {
  AssistStatus.fromProto(pb.WSAssitStatus status) {
    running = status.running;
  }

  bool? running;
}

class ErrMessage {
  ErrMessage(this.errCode, this.response);

  ErrMessage.fromProto(pb.WSErrMessage err) {
    errCode = err.errCode.toInt();
    response = err.response;
  }

  num? errCode;
  String? response;
}

class OutInVolume {
  OutInVolume(this.outVolume, this.inVolume);

  double getOutInRatio() {
    if (outVolume == 0 && inVolume == 0) {
      return 0;
    }
    return 100 * (outVolume! / (outVolume! + inVolume!));
  }

  double getRate(double timeUnit) => (outVolume! + inVolume!) / timeUnit;

  num? outVolume;
  num? inVolume;
}

class TradeRate {
  TradeRate(
    this.outInRatio,
    this.rate,
  );

  double outInRatio;
  double rate;
}

class TradeIndex {
  TradeIndex.fromProto(pb.WSTradeIndex index) {
    tse = IndexStatus.fromProto(index.tse);
    otc = IndexStatus.fromProto(index.otc);
    nasdaq = IndexStatus.fromProto(index.nasdaq);
    nf = IndexStatus.fromProto(index.nf);
  }

  IndexStatus? tse;
  IndexStatus? otc;
  IndexStatus? nasdaq;
  IndexStatus? nf;
}

class IndexStatus {
  IndexStatus.fromProto(pb.WSIndexStatus ws) {
    breakCount = ws.breakCount.toInt();
    priceChg = ws.priceChg;
  }

  num? breakCount;
  num? priceChg;
}

class FuturePosition {
  FuturePosition();

  FuturePosition.fromProto(pb.WSFuturePosition ws, String code) {
    for (final element in ws.position) {
      if (element.code == code) {
        code = element.code;
        direction = element.direction;
        quantity = element.quantity.toInt();
        price = element.price;
        lastPrice = element.lastPrice;
        pnl = element.pnl;
        break;
      }
    }
  }

  String? code;
  String? direction;
  num? quantity;
  num? price;
  num? lastPrice;
  num? pnl;
}

class FutureOrder {
  FutureOrder(
    this.code,
    this.baseOrder,
  );

  FutureOrder.fromProto(pb.WSFutureOrder ws) {
    code = ws.code;
    baseOrder = BaseOrder.fromProto(ws.baseOrder);
  }

  String? code;
  BaseOrder? baseOrder;
}

class BaseOrder {
  BaseOrder(
    this.orderID,
    this.status,
    this.orderTime,
    this.action,
    this.price,
    this.quantity,
  );

  BaseOrder.fromProto(pb.WSOrder ws) {
    orderID = ws.orderId;
    status = ws.status.toInt();
    orderTime = ws.orderTime;
    action = ws.action.toInt();
    price = ws.price;
    quantity = ws.quantity.toInt();
  }

  String? orderID;
  num? status;
  String? orderTime;
  num? action;
  num? price;
  num? quantity;
}

class KbarData {
  KbarData({
    this.kbarTime,
    this.close,
    this.open,
    this.high,
    this.low,
    this.volume,
  });

  DateTime? kbarTime;
  num? close;
  num? open;
  num? high;
  num? low;
  int? volume;
}

class KbarArr {
  KbarArr.fromProto(pb.WSHistoryKbarMessage ws) {
    arr = [];
    maxVolume = 0;

    for (final element in ws.arr) {
      arr!.add(
        KbarData(
          kbarTime: DateTime.parse(element.kbarTime),
          high: element.high,
          low: element.low,
          open: element.open,
          close: element.close,
          volume: element.volume.toInt(),
        ),
      );

      if (maxVolume == 0) {
        maxVolume = element.volume.toInt();
      } else {
        if (element.volume > maxVolume!) {
          maxVolume = element.volume.toInt();
        }
      }
    }
  }

  List<KbarData>? arr;
  num? maxVolume;
}
