import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

void showOrderResult(BuildContext context, FutureOrder order) {
  final actionStr = order.baseOrder!.action == 1 ? 'buy' : 'sell';
  switch (order.baseOrder!.status) {
    case 1:
      ElegantNotification(
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('pending_submit'),
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
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('pre_submitted'),
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
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('submitted'),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 4:
      ElegantNotification.error(
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('failed'),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 5:
      ElegantNotification(
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('cancelled'),
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
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('filled'),
        description: Text('$actionStr ${order.baseOrder!.price!.toStringAsFixed(0)} x ${order.baseOrder!.quantity}'),
        onDismiss: () {},
      ).show(context);
      return;
    case 7:
      ElegantNotification(
        width: MediaQuery.of(context).size.width,
        notificationPosition: NotificationPosition.topCenter,
        animation: AnimationType.fromTop,
        toastDuration: const Duration(milliseconds: 2000),
        title: const Text('part_filled'),
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
