import 'package:audioplayers/audioplayers.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

void showOrderResult(BuildContext context, FutureOrder order) {
  final actionStr = order.baseOrder!.action == 1 ? AppLocalizations.of(context)!.buy : AppLocalizations.of(context)!.sell;
  final p = AudioPlayer();
  p.setSource(AssetSource('sound/notification.mp3')).then((_) => p.resume());
  switch (order.baseOrder!.status) {
    case 1:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.pending_submit),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.book,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        displayCloseButton: false,
      ).show(context);
      return;
    case 2:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.pre_submitted),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.book,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        displayCloseButton: false,
      ).show(context);
      return;
    case 3:
      ElegantNotification.info(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.submitted),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        displayCloseButton: false,
      ).show(context);
      return;
    case 4:
      ElegantNotification.error(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.failed),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}'),
        displayCloseButton: false,
      ).show(context);
      return;
    case 5:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.cancelled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}'),
        icon: const Icon(
          Icons.cached_outlined,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        displayCloseButton: false,
      ).show(context);
      return;
    case 6:
      ElegantNotification.success(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.filled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        displayCloseButton: false,
      ).show(context);
      return;
    case 7:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.part_filled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.access_alarm,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        displayCloseButton: false,
      ).show(context);
      return;
    default:
      ElegantNotification.error(
        width: MediaQuery.of(context).size.width * 2 / 7,
        notificationPosition: NotificationPosition.bottomLeft,
        animation: AnimationType.fromLeft,
        animationDuration: const Duration(milliseconds: 200),
        toastDuration: const Duration(milliseconds: 3500),
        title: Text(AppLocalizations.of(context)!.error),
        description: Text(AppLocalizations.of(context)!.unknown_error),
        displayCloseButton: false,
      ).show(context);
      return;
  }
}

void showReconnectingWS(BuildContext context) {
  ElegantNotification(
    width: MediaQuery.of(context).size.width * 2 / 7,
    notificationPosition: NotificationPosition.bottomLeft,
    animation: AnimationType.fromLeft,
    toastDuration: const Duration(milliseconds: 4000),
    title: Text(AppLocalizations.of(context)!.connection_failed),
    description: const Text('Reconnecting...'),
    icon: const Icon(
      Icons.warning_amber_outlined,
      color: Colors.teal,
    ),
    progressIndicatorColor: Colors.teal,
    displayCloseButton: false,
  ).show(context);
}
