import 'package:flutter/material.dart';

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key});

  @override
  State<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage> {
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Targets'),
      );
}
