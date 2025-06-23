import 'dart:math';
import 'codeforces_api.dart';
import 'db.dart';
import 'modelrunner.dart';

Map<String, int> tagMaxRatingFromSubmissions(
    List<Map<String, dynamic>> submissions) {
  final Map<String, int> tagMaxRatings = {};

  final acContestants = submissions
      .where((submission) =>
          submission['verdict'] == 'OK' &&
          submission['participantType'] == 'CONTESTANT')
      .toList();

  for (final submission in acContestants) {
    final tags = submission['problem']['tags'] as List<dynamic>;
    final maxRating = submission['problem']['rating'] as int? ?? 0;

    for (final tag in tags) {
      if (tag is String) {
        if (!tagMaxRatings.containsKey(tag)) {
          tagMaxRatings[tag] = maxRating;
        } else {
          tagMaxRatings[tag] = max(tagMaxRatings[tag]!, maxRating);
        }
      }
    }
  }

  return tagMaxRatings;
}

Future<Map<String, int>> getMaxRatingByTag(String handle) async {
  final cfApi = CodeforcesApi();
  final submissions = await cfApi.fetchUserSubmissionHistory(handle);
  return tagMaxRatingFromSubmissions(submissions);
}

Future<void> _saveSolvedProblems(List<Map<String, dynamic>> submissions) async {
  final solvedProblems = submissions
      .where((submission) =>
          submission['verdict'] == 'OK' &&
          submission['participantType'] == 'CONTESTANT')
      .map((submission) => "${submission['contestId']}:${submission['index']}")
      .toSet();

  await StatusDb.saveSolvedProblems(solvedProblems);
}

Future<void> fetchAndProcessSubmissions(String handle) async {
  final cfApi = CodeforcesApi();
  final submissions = await cfApi.fetchUserSubmissionHistory(handle);

  await _saveSolvedProblems(submissions);
  final tagMaxRatings = tagMaxRatingFromSubmissions(submissions);
  await StatusDb.saveTagMaxRating(tagMaxRatings);
}

Future<List<Map<String, dynamic>>> getUnsolvedProblems() async {
  final cfApi = CodeforcesApi();
  final allProblems = await cfApi.fetchAllProblems();
  final solvedProblems = StatusDb.getSolvedProblems();

  return allProblems
      .where((problem) => !solvedProblems
          .contains("${problem['contestId']}:${problem['index']}"))
      .toList();
}
