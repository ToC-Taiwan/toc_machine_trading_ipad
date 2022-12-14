import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:toc_machine_trading_ipad/page/page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;
  List<Widget> pages = [
    const TargetsPage(),
    const StrategyPage(),
    const FutureTradePage(),
    const PickStockPage(),
    const BalancePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: pages[_page],
        drawer: Drawer(
          backgroundColor: Colors.amber[50],
          child: Column(
            children: [
              Expanded(
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.yellow,
                        Colors.red,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.menu,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(AppLocalizations.of(context)!.targets),
                      onTap: () {
                        setState(() {
                          _page = 0;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.call_to_action_rounded),
                      title: Text(AppLocalizations.of(context)!.strategy),
                      onTap: () {
                        setState(() {
                          _page = 1;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(AppLocalizations.of(context)!.future_trade),
                      onTap: () {
                        setState(() {
                          _page = 2;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard_customize),
                      title: Text(AppLocalizations.of(context)!.pick_stock),
                      onTap: () {
                        setState(() {
                          _page = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.money),
                      title: Text(AppLocalizations.of(context)!.balance),
                      onTap: () {
                        setState(() {
                          _page = 4;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
