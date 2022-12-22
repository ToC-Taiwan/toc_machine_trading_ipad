import 'package:date_format/date_format.dart' as df;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:toc_machine_trading_ipad/entity/entity.dart';
import 'package:toc_machine_trading_ipad/page/future_trade/notification.dart';

Widget buildVolumeRatioCircle(double percent, double rate) => CircularPercentIndicator(
      animateFromLastPercent: true,
      animation: true,
      radius: 40,
      lineWidth: 15,
      percent: percent / 100,
      center: Text(
        '${percent.toStringAsFixed(0)}%',
        style: GoogleFonts.getFont(
          'Source Code Pro',
          fontStyle: FontStyle.normal,
          fontSize: 18,
        ),
      ),
      progressColor: rate < 5
          ? Colors.grey
          : percent >= 55
              ? Colors.red
              : percent <= 45
                  ? Colors.green
                  : Colors.yellow,
    );

Widget buildIndexRow(BuildContext context, String name, num priceChg, num breakCount) => Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$name:',
            style: GoogleFonts.getFont(
              'Source Code Pro',
              fontStyle: FontStyle.normal,
              fontSize: 20,
              color: Colors.blueGrey,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                priceChg != 0 ? priceChg.toStringAsFixed(2) : AppLocalizations.of(context)!.loading,
                style: GoogleFonts.getFont(
                  'Source Code Pro',
                  fontStyle: FontStyle.normal,
                  fontSize: 20,
                  color: priceChg == 0
                      ? Colors.blueGrey
                      : priceChg > 0
                          ? Colors.red
                          : Colors.green,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '!${breakCount.abs()}',
            style: GoogleFonts.getFont(
              'Source Code Pro',
              fontStyle: FontStyle.normal,
              fontSize: 20,
              color: breakCount == 0
                  ? Colors.blueGrey
                  : breakCount > 0
                      ? Colors.red
                      : Colors.green,
            ),
          ),
        ),
      ],
    );

Widget buildTickDetail(RealTimeFutureTick tick) => Container(
      margin: const EdgeInsets.only(bottom: 2, right: 20, top: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: tick.tickType == 1 ? Colors.red : Colors.green,
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Text(
          '${tick.volume!}',
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: tick.combo! ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: tick.tickType == 1 ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          tick.close!.toStringAsFixed(0),
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: tick.combo! ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: tick.tickType == 1 ? Colors.red : Colors.green,
          ),
        ),
        trailing: Text(
          df.formatDate(tick.tickTime!, [df.HH, ':', df.nn, ':', df.ss]),
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: 18,
          ),
        ),
      ),
    );

Widget buildNotification(TradeNotification notification) => Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 2, right: 20, top: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ListTile(
        leading: Icon(
          Icons.notifications_active,
          color: notification.color,
          size: 35,
        ),
        title: Text(
          notification.title!,
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: 18,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.content!,
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        isThreeLine: true,
        trailing: Text(
          df.formatDate(DateTime.parse(notification.time!), [df.HH, ':', df.nn, ':', df.ss]),
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
