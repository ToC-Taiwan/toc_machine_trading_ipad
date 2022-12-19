import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';

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

void showErrorDialog(BuildContext context, ErrMessage message) {
  if (message.errCode! != 0) {
    final p = AudioPlayer();
    p.setSource(AssetSource('sound/error.mp3')).then((_) => p.resume());
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
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(
          msgFromErrCode(context, message.errCode!),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: const TextStyle(color: Colors.black),
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
