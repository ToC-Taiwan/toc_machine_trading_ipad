import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)!.balance,
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
