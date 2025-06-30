import 'package:flutter/material.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io';
import 'pages/personalpage.dart';
import 'pages/teampage.dart';
import 'pages/cardelement.dart';
import 'db.dart';
import 'modelrunner.dart';
import 'local_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid && !Platform.isIOS) {
    await DesktopWindow.setMinWindowSize(const Size(900, 600));
  }

  await LocalDataService.init();
  await XGBoostRunner().init();
  await StatusDb.init();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CF Drills by nicotina04',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardElement(
                icon: Icons.person,
                title: "Personal Mode",
                description: "Create a personalized problem set",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PersonalPage())),
              ),
              CardElement(
                icon: Icons.group,
                title: "Team Mode",
                description: "Create a problem set for team practice",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TeamPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
