import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

Widget buildVolumeRatioCircle(double percent, double rate) => Padding(
      padding: const EdgeInsets.only(right: 15),
      child: CircularPercentIndicator(
        animateFromLastPercent: true,
        animation: true,
        radius: 30,
        lineWidth: 8,
        percent: percent / 100,
        center: Text('${percent.toStringAsFixed(0)}%'),
        progressColor: percent >= 55
            ? Colors.red
            : percent <= 45
                ? Colors.green
                : Colors.yellow,
      ),
    );

Widget buildIndexRow(String name, num priceChg, num breakCount) => Row(
      children: [
        Expanded(
          child: Text(
            '$name:',
            style: GoogleFonts.getFont(
              'Source Code Pro',
              fontStyle: FontStyle.normal,
              fontSize: 15,
              color: Colors.blueGrey,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                priceChg.toStringAsFixed(2),
                style: GoogleFonts.getFont(
                  'Source Code Pro',
                  fontStyle: FontStyle.normal,
                  fontSize: 15,
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
              fontSize: 15,
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
