import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:cf_drills/cf_services.dart' as cf_services;
import 'package:cf_drills/db.dart';

class ProblemListPage extends StatefulWidget {
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
  State<ProblemListPage> createState() => _ProblemListPageState();
}

class _ProblemListPageState extends State<ProblemListPage> {
  bool _isRefreshing = false;
  bool _refreshCompleted = false;
  CancelableOperation? _refreshOp;

  @override
  void dispose() {
    _refreshOp?.cancel();
    _refreshOp = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Row(
                children: [
                  ElevatedButton(
                      onPressed: _isRefreshing
                          ? null
                          : () async => await onPressedRefreshProblems(context),
                      child: const Text('Refresh Problem List')),
                  const SizedBox(width: 16),
                  if (_isRefreshing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  if (_refreshCompleted && !_isRefreshing)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var problem in widget.problems)
                        ProblemCard(problem: problem)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> onPressedRefreshProblems(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
      _refreshCompleted = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
            'Recommendations will refresh automatically once processing is complete.'),
        duration: Duration(seconds: 1),
      ),
    );

    await _refreshOp?.cancel();
    _refreshOp = null;

    try {
      _refreshOp = CancelableOperation.fromFuture(
        _executeRefresh(),
        onCancel: () => _cleanUpAfterCancel(),
      );

      await _refreshOp!.valueOrCancellation();
    } catch (e) {
      _handleRefreshError(context, e);
    }
  }

  Future<void> _executeRefresh() async {
    await cf_services.refreshRecommendations(widget.difficulty);

    if (!mounted) return;
    final refreshedProblems = StatusDb.getDisplayedProblems(widget.difficulty);

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _refreshCompleted = true;
      });
    }

    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _refreshCompleted = false;
          });
        }
      });
    }

    if (mounted) {
      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProblemListPage(
            difficulty: widget.difficulty,
            title: widget.title,
            problems: refreshedProblems,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommendations refreshed')),
        );
      }
    }
  }

  void _handleRefreshError(BuildContext context, Object e) {
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _cleanUpAfterCancel() {
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
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
