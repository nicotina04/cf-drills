import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../codeforces_api.dart';
import '../db.dart';
import '../cf_services.dart';
import 'problem_list_page.dart';
import 'cardelement.dart';
import 'package:cf_drills/l10n/app_localizations.dart' as l10n;

class PersonalPage extends StatefulWidget {
  const PersonalPage({Key? key}) : super(key: key);

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final CodeforcesApi _cfApi = CodeforcesApi();
  String? _handle;
  int? _rating;
  int? _maxRating;
  int? _ratingDeltaAvg;

  @override
  void initState() {
    super.initState();

    if (StatusDb.hasHandle()) {
      _loadUserStat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tab'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(_handle ?? 'Enter your Codeforces handle'),
                onPressed: _showHandleInputDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                  'Current Rating: ${_rating != null && _rating! > 0 ? _rating : '-'}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(_rating))),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                onPressed: () async => await _refreshUserStat(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
              )
            ]),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Max Rating: ${_maxRating != null && _maxRating! > 0 ? _maxRating : '-'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  'Rating Delta Avg: ${_ratingDeltaAvg ?? 0}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CardElement(
                        icon: Icons.cake,
                        title: 'Easy',
                        description: l10n.AppLocalizations.of(context)!
                                .translate('easyProblem') ??
                            '쉬운 문제',
                        onTap: () async => await onTapCard(context, 'easy')),
                    CardElement(
                        icon: Icons.bolt,
                        title: 'Medium',
                        description: l10n.AppLocalizations.of(context)!
                                .translate('mediumProblem') ??
                            '중간 문제',
                        onTap: () async => await onTapCard(context, 'medium')),
                    CardElement(
                        icon: Icons.fireplace_outlined,
                        title: 'Challenging',
                        description: l10n.AppLocalizations.of(context)!
                                .translate('hardProblem') ??
                            '도전적인 문제',
                        onTap: () async => await onTapCard(context, 'hard')),
                    CardElement(
                        icon: Icons.rocket_launch,
                        title: 'Set',
                        description: l10n.AppLocalizations.of(context)!
                                .translate('problemSet') ??
                            '문제 세트',
                        onTap: () async => await onTapCard(context, 'set')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHandle(String handle) async {
    await StatusDb.saveHandle(handle);
    await _fetchUserStat(handle);
    _loadUserStat();
  }

  Future<void> _fetchRatingFromServer() async {
    String handle = StatusDb.getHandle();

    try {
      final userInfo = await _cfApi.fetchUserInfo(handle);
      final rating = userInfo['rating'];
      final maxRating = userInfo['maxRating'];

      await StatusDb.saveMaxRating(maxRating as int);
      await StatusDb.saveCurrentRating(rating as int);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      _showErrorDialog(
          'Failed to fetch user info (code: $code). Please try again later.');
      debugPrint('DioException fetching user info: $e');
    } catch (error) {
      _showErrorDialog('Failed to fetch user info. Please try again later.');
      debugPrint('Error fetching user info: $error');
    }
  }

  Future<void> _fetchUserStat(String handle) async {
    try {
      await _fetchRatingFromServer();
      await fetchAndProcessSubmissions(handle);
      int deltaAvg = await _cfApi.fetchUserRatingDeltaAvg(handle);
      await StatusDb.saveRatingDeltaAvg(deltaAvg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      _showErrorDialog(
          'Failed to fetch user statistics (code: $code). Please try again later.');
      debugPrint('DioException fetching user statistics: $e');
      await _clearHandle();
    } catch (error) {
      _showErrorDialog(
          'Failed to fetch user statistics. Please try again later. $error');
      debugPrint('Error fetching user statistics: $error');
      await _clearHandle();
    }
  }

  void _loadUserStat() {
    String handle = StatusDb.getHandle();
    int rating = StatusDb.getCurrentRating();
    int maxRating = StatusDb.getMaxRating();
    int ratingDeltaAvg = StatusDb.getRatingDeltaAvg();

    setState(() {
      _handle = handle;
      _rating = rating;
      _maxRating = maxRating;
      _ratingDeltaAvg = ratingDeltaAvg;
    });
  }

  void _showHandleInputDialog() async {
    String input = _handle ?? '';
    final controller = TextEditingController(text: input);
    final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Codeforces Handle'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Enter your Codeforces handle',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(controller.text.trim());
                  },
                  child: const Text('Save'),
                ),
              ],
            ));

    if (result != null && result.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _saveHandle(result);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refreshUserStat(BuildContext context) async {
    if (StatusDb.hasHandle() == false) {
      await _showErrorDialog('Please enter your Codeforces handle first.');
      return;
    }

    try {
      String handle = StatusDb.getHandle();
      await _fetchUserStat(handle);
      await fetchAndProcessSubmissions(handle);

      _loadUserStat();
    } catch (error) {
      debugPrint('Error refreshing user statistics: $error');
      await _showErrorDialog(
          'Failed to refresh user statistics. Please try again later.');
      return;
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> onTapCard(BuildContext context, String difficulty) async {
    if (!StatusDb.hasHandle()) {
      await _showErrorDialog('Please enter your Codeforces handle first.');
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      List<Map<String, dynamic>> problems;
      await loadRecommendations(difficulty);
      problems = StatusDb.getDisplayedProblems(difficulty);

      if (context.mounted) {
        Navigator.of(context).pop();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProblemListPage(
                    difficulty: difficulty,
                    title: 'Recommended Problems ($difficulty)',
                    problems: problems)));
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load problems: $e')),
      );

      rethrow;
    }
  }

  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating < 1200) return Colors.grey;
    if (rating < 1400) return const Color.fromARGB(255, 0, 128, 0);
    if (rating < 1600) return const Color.fromARGB(255, 3, 168, 158);
    if (rating < 1900) return const Color.fromARGB(255, 0, 0, 255);
    if (rating < 2100) return const Color.fromARGB(255, 170, 0, 170);
    if (rating < 2400) return const Color.fromARGB(255, 255, 140, 0);
    if (rating < 4000) return Colors.red;
    return Colors.black;
  }

  Future<void> _clearHandle() async {
    await StatusDb.clearHandle();
    setState(() {
      _handle = null;
      _rating = null;
      _maxRating = null;
      _ratingDeltaAvg = null;
    });
  }
}
