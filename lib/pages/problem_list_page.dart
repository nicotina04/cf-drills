import 'package:flutter/material.dart';

class ProblemListPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> problems;

  const ProblemListPage({
    super.key,
    required this.title,
    required this.problems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: problems.map((p) => ProblemCard(problem: p)).toList(),
          ),
        ));
  }
}

class ProblemCard extends StatelessWidget {
  final Map<String, dynamic> problem;

  const ProblemCard({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              problem['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Rating: ${problem['rating']}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Handle problem selection
              },
              child: const Text('Solve Problem'),
            ),
          ],
        ),
      ),
    );
  }
}
