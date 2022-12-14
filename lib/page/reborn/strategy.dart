import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.strategy),
      );
}
