import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Tab'),
      ),
      body: const Center(
        child: Text('Team Tab Content'),
      ),
    );
  }
}
