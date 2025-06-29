import 'package:flutter/material.dart';
import 'pages/personalpage.dart';
import 'pages/teampage.dart';
import 'pages/cardelement.dart';
import 'db.dart';
import 'modelrunner.dart';
import 'local_data_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart' as l10n;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDataService.init();
  await XGBoostRunner().init();
  await StatusDb.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = Locale(StatusDb.getLocale());

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final savedLang = StatusDb.getLocale();
    setState(() {
      _currentLocale = Locale(savedLang);
    });
  }

  Future<void> _changeLocale(Locale newLocale) async {
    await StatusDb.saveLocale(newLocale.languageCode);
    setState(() {
      _currentLocale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CF Drills by nicotina04',
      localizationsDelegates: [
        l10n.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
        Locale('ru'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            DropdownButton<Locale>(
              value: _currentLocale,
              items: [
                DropdownMenuItem(child: Text('한국어'), value: const Locale('ko')),
                DropdownMenuItem(
                    child: Text('English'), value: const Locale('en')),
                DropdownMenuItem(child: Text('日本語'), value: const Locale('ja')),
                DropdownMenuItem(child: Text('中文'), value: const Locale('zh')),
                DropdownMenuItem(
                    child: Text('Русский'), value: const Locale('ru')),
              ],
              onChanged: (Locale? newLocale) async {
                if (newLocale != null) {
                  await _changeLocale(newLocale);
                }
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyApp(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: Builder(builder: (context) {
          final appLocalizations = l10n.AppLocalizations.of(context)!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CardElement(
                  icon: Icons.person,
                  title: appLocalizations.translate('personalModeTitle') ??
                      "개인 모드",
                  description:
                      appLocalizations.translate('personalModeDescription') ??
                          "나만의 맞춤 문제 세트 생성",
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PersonalPage())),
                ),
                CardElement(
                  icon: Icons.group,
                  title: appLocalizations.translate('teamModeTitle') ?? "팀 모드",
                  description:
                      appLocalizations.translate('teamModeDescription') ??
                          "팀 연습을 위한 문제 세트 생성",
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TeamPage())),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
