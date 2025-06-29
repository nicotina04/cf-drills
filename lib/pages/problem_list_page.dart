import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:cf_drills/cf_services.dart' as cf_services;
import 'package:cf_drills/db.dart';

class ProblemListPage extends StatelessWidget {
  final String title;
  final String difficulty;
  final List<Map<String, dynamic>> problems;

  const ProblemListPage({
    super.key,
    required this.difficulty,
    required this.title,
    required this.problems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Row(
                children: [
                  ElevatedButton(
                      onPressed: () async =>
                          await onPressedRefreshRecommendations(context),
                      child: const Text('Refresh Recommendations'))
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var problem in problems)
                        ProblemCard(problem: problem)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> onPressedRefreshRecommendations(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    await cf_services.fetchAndProcessSubmissions(StatusDb.getHandle());
    await cf_services.refreshRecommendations(difficulty);

    if (context.mounted) {
      Navigator.of(context).pop();

      final refreshedProblems = StatusDb.getDisplayedProblems(difficulty);

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProblemListPage(
                  difficulty: difficulty,
                  title: title,
                  problems: refreshedProblems)));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recommendations refreshed')),
      );
    }
  }
}

class ProblemCard extends StatelessWidget {
  final Map<String, dynamic> problem;

  const ProblemCard({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                problem['name'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Rating: ${problem['rating']}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final int contestId = problem['contestId'];
                  final String index = problem['index'];
                  final url =
                      'https://codeforces.com/problemset/problem/$contestId/$index';

                  url_launcher
                      .launchUrl(Uri.parse(url),
                          mode: url_launcher.LaunchMode.externalApplication)
                      .then((success) {
                    if (success) {
                      return;
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open problem link')),
                      );
                    }
                  });
                },
                child: const Text('Solve Problem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
