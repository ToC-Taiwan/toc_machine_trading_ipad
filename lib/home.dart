import 'package:flutter/material.dart';
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
    const RebornPage(),
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
              const Expanded(
                child: DrawerHeader(
                  decoration: BoxDecoration(
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
                      'Menu',
                      style: TextStyle(
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
                      title: const Text('Targets'),
                      onTap: () {
                        setState(() {
                          _page = 0;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.call_to_action_rounded),
                      title: const Text('Reborn'),
                      onTap: () {
                        setState(() {
                          _page = 1;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: const Text('Future Trade'),
                      onTap: () {
                        setState(() {
                          _page = 2;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard_customize),
                      title: const Text('Pick Stock'),
                      onTap: () {
                        setState(() {
                          _page = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.money),
                      title: const Text('Balance'),
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
