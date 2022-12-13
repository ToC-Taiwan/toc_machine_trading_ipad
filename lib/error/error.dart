import 'package:flutter/material.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

String msgFromErrCode(num code) {
  switch (code) {
    case -1:
      return 'err_not_trade_time';
    case -2:
      return 'err_not_filled';
    case -3:
      return 'err_assist_not_support';
    case -4:
      return 'err_unmarshal';
    case -5:
      return 'err_get_snapshot';
    case -6:
      return 'err_get_position';
    case -7:
      return 'err_place_order';
    case -8:
      return 'err_cancel_order_failed';
    case -9:
      return 'err_assiting_is_full';
  }
  return 'unknown error';
}

void showErrorDialog(BuildContext context, ErrMessage message) {
  if (message.errCode! != 0) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        iconColor: Colors.red,
        icon: const Icon(
          Icons.error,
          size: 40,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text('Error'),
        content: Text(
          msgFromErrCode(message.errCode!),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              child: const Text(
                'ok',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
