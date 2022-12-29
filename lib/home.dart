import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toc_machine_trading_ipad/page/page.dart';
import 'package:yaml/yaml.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 2;
  List<Widget> pages = [
    const TargetsPage(),
    const StrategyPage(),
    const FutureTradePage(),
    const PickStockPage(),
    const BalancePage(),
  ];

  String version = '-';

  @override
  void initState() {
    getVersion().then((value) {
      final splitVersion = value.split('+');
      var buildNumber = int.parse(splitVersion[1]);
      buildNumber++;
      version = '${splitVersion[0]}+${buildNumber.toString()}';
    });
    super.initState();
  }

  Future<String> getVersion() async {
    final data = await rootBundle.loadString('pubspec.yaml');
    final mapData = loadYaml(data) as YamlMap;
    return mapData['version'] as String;
  }

  Widget _buildMenuTitle(String title) => Text(
        title,
        style: GoogleFonts.getFont(
          'Source Code Pro',
          fontStyle: FontStyle.normal,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: pages[_page],
        drawer: Drawer(
          backgroundColor: Colors.amber[50],
          child: SizedBox(
            child: Column(
              children: [
                Expanded(
                  child: DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.orange,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.menu,
                        style: GoogleFonts.getFont(
                          'Source Code Pro',
                          fontStyle: FontStyle.normal,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 10,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.assignment_outlined),
                              title: _buildMenuTitle(AppLocalizations.of(context)!.targets),
                              onTap: () {
                                setState(() {
                                  _page = 0;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.call_to_action_rounded),
                              title: _buildMenuTitle(AppLocalizations.of(context)!.strategy),
                              onTap: () {
                                setState(() {
                                  _page = 1;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.account_balance_outlined),
                              title: _buildMenuTitle(AppLocalizations.of(context)!.future_trade),
                              onTap: () {
                                setState(() {
                                  _page = 2;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.dashboard_customize),
                              title: _buildMenuTitle(AppLocalizations.of(context)!.pick_stock),
                              onTap: () {
                                setState(() {
                                  _page = 3;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.money),
                              title: _buildMenuTitle(AppLocalizations.of(context)!.balance),
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
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Version: $version',
                                style: GoogleFonts.getFont(
                                  'Source Code Pro',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 20,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
