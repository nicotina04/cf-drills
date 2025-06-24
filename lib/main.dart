import 'package:flutter/material.dart';
import 'pages/personalpage.dart';
import 'pages/teampage.dart';
import 'pages/cardelement.dart';
import 'db.dart';
import 'modelrunner.dart';
import 'local_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
                title: "개인 모드",
                description: "나만의 맞춤 문제 세트 생성",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PersonalPage())),
              ),
              CardElement(
                icon: Icons.group,
                title: "팀 모드 (최대 3명)",
                description: "팀 연습을 위한 문제 세트 구성",
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
