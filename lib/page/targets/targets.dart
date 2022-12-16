import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key});

  @override
  State<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)!.targets,
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
