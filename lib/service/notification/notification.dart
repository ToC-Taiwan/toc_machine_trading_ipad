import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

void showOrderResult(BuildContext context, FutureOrder order) {
  final actionStr = order.baseOrder!.action == 1 ? AppLocalizations.of(context)!.buy : AppLocalizations.of(context)!.sell;
  switch (order.baseOrder!.status) {
    case 1:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.pending_submit),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.book,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        onDismiss: () {},
      ).show(context);
      return;
    case 2:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.pre_submitted),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.book,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        onDismiss: () {},
      ).show(context);
      return;
    case 3:
      ElegantNotification.info(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.submitted),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 4:
      ElegantNotification.error(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.failed),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 5:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.cancelled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}'),
        icon: const Icon(
          Icons.cached_outlined,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        onDismiss: () {},
      ).show(context);
      return;
    case 6:
      ElegantNotification.success(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.filled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 7:
      ElegantNotification(
        width: MediaQuery.of(context).size.width * 2 / 3,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: Text(AppLocalizations.of(context)!.part_filled),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        icon: const Icon(
          Icons.access_alarm,
          color: Colors.orange,
        ),
        progressIndicatorColor: Colors.orange,
        onDismiss: () {},
      ).show(context);
      return;
  }
}
