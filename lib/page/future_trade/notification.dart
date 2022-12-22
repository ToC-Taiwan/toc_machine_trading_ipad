import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

class TradeNotification {
  TradeNotification.reconnectingWS(BuildContext context) {
    errorSound();
    title = AppLocalizations.of(context)!.connection_failed;
    content = 'Reconnecting...';
    color = Colors.red;
    time = DateTime.now().toString();
  }

  TradeNotification.connected(BuildContext context) {
    orderSound();
    title = AppLocalizations.of(context)!.connected;
    content = 'Success';
    color = Colors.green;
    time = DateTime.now().toString();
  }

  TradeNotification.fromError(BuildContext context, num code) {
    errorSound();
    title = AppLocalizations.of(context)!.error;
    content = msgFromErrCode(context, code);
    color = Colors.red;
    time = DateTime.now().toString();
  }

  TradeNotification.fromOrder(BuildContext context, FutureOrder order) {
    orderSound();
    final actionStr = order.baseOrder!.action == 1 ? AppLocalizations.of(context)!.buy : AppLocalizations.of(context)!.sell;
    switch (order.baseOrder!.status) {
      case 1:
        title = AppLocalizations.of(context)!.pending_submit;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}';
        color = Colors.blue;
        time = DateTime.now().toString();
        return;

      case 2:
        title = AppLocalizations.of(context)!.pre_submitted;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}';
        time = DateTime.now().toString();
        color = Colors.blue;
        return;

      case 3:
        title = AppLocalizations.of(context)!.submitted;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}';
        time = DateTime.now().toString();
        color = Colors.blue;
        return;

      case 4:
        title = AppLocalizations.of(context)!.failed;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}';
        time = DateTime.now().toString();
        color = Colors.red;
        return;

      case 5:
        title = AppLocalizations.of(context)!.cancelled;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}';
        time = DateTime.now().toString();
        color = Colors.yellow;
        return;

      case 6:
        title = AppLocalizations.of(context)!.filled;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}';
        time = DateTime.now().toString();
        color = Colors.greenAccent;
        return;

      case 7:
        title = AppLocalizations.of(context)!.part_filled;
        content = '$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}';
        time = DateTime.now().toString();
        color = Colors.orange;
        return;

      default:
        title = AppLocalizations.of(context)!.error;
        content = AppLocalizations.of(context)!.unknown_error;
        time = DateTime.now().toString();
        color = Colors.red;
        return;
    }
  }

  void orderSound() {
    final p = AudioPlayer();
    p.setSource(AssetSource('sound/notification.mp3')).then((_) => p.resume());
  }

  void errorSound() {
    final p = AudioPlayer();
    p.setSource(AssetSource('sound/error.mp3')).then((_) => p.resume());
  }

  String? title;
  String? content;
  String? time;
  Color? color;
}

String msgFromErrCode(BuildContext context, num code) {
  switch (code) {
    case -1:
      return AppLocalizations.of(context)!.err_not_trade_time;
    case -2:
      return AppLocalizations.of(context)!.err_not_filled;
    case -3:
      return AppLocalizations.of(context)!.err_assist_not_support;
    case -4:
      return AppLocalizations.of(context)!.err_unmarshal;
    case -5:
      return AppLocalizations.of(context)!.err_get_snapshot;
    case -6:
      return AppLocalizations.of(context)!.err_get_position;
    case -7:
      return AppLocalizations.of(context)!.err_place_order;
    case -8:
      return AppLocalizations.of(context)!.err_cancel_order_failed;
    case -9:
      return AppLocalizations.of(context)!.err_assiting_is_not_finished;
    case -10:
      return AppLocalizations.of(context)!.at_least_one_assist_option_shold_selected;
  }
  return AppLocalizations.of(context)!.unknown_error;
}
