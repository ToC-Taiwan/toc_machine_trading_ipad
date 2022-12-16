import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class PickStockPage extends StatefulWidget {
  const PickStockPage({super.key});

  @override
  State<PickStockPage> createState() => _PickStockPageState();
}

class _PickStockPageState extends State<PickStockPage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)!.pick_stock,
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
