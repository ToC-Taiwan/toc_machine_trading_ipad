import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)!.strategy,
          style: GoogleFonts.getFont(
            'Source Code Pro',
            fontStyle: FontStyle.normal,
            fontSize: 40,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
