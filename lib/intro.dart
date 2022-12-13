import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toc_machine_trading_ipad/home.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 2)).then((value) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.teal[300],
        child: Center(
          child: Text(
            'ToC Machine Trading',
            style: GoogleFonts.getFont(
              'Source Code Pro',
              fontStyle: FontStyle.normal,
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
}
