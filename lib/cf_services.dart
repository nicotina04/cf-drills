import 'dart:math';
import 'codeforces_api.dart';
import 'db.dart';
import 'modelrunner.dart';
import 'local_data_service.dart';

Map<String, int> tagMaxRatingFromSubmissions(
    List<Map<String, dynamic>> submissions) {
  final Map<String, int> tagMaxRatings = {};

  final acContestants = submissions
      .where((submission) =>
          submission['verdict'] == 'OK' &&
          submission['author']['participantType'] == 'CONTESTANT')
      .toList();

  print(acContestants.length);

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

Future<void> _saveSolvedProblemsAll(
    List<Map<String, dynamic>> submissions) async {
  final solvedProblems = submissions
      .where((submission) => submission['verdict'] == 'OK')
      .map((submission) => "${submission['contestId']}:${submission['index']}")
      .toSet();

  List<String> solvedProblemsList = solvedProblems.toList(growable: false);
  await StatusDb.saveSolvedProblems(solvedProblemsList);
}

Future<void> _saveSolvedProblemsContestant(
    List<Map<String, dynamic>> submissions) async {
  final solvedProblems = submissions
      .where((submission) =>
          submission['verdict'] == 'OK' &&
          submission['participantType'] == 'CONTESTANT')
      .map((submission) => "${submission['contestId']}:${submission['index']}")
      .toSet();

  await StatusDb.saveSolvedProblemsRated(List<String>.from(solvedProblems));
}

Future<void> fetchAndProcessSubmissions(String handle) async {
  final cfApi = CodeforcesApi();
  final submissions = await cfApi.fetchUserSubmissionHistory(handle);

  await _saveSolvedProblemsAll(submissions);
  await _saveSolvedProblemsContestant(submissions);
  final tagMaxRatings = tagMaxRatingFromSubmissions(submissions);
  await StatusDb.saveTagMaxRating(tagMaxRatings);
}

Future<List<Map<String, dynamic>>> getUnsolvedProblems() async {
  final cfApi = CodeforcesApi();
  final allProblems = await cfApi.fetchAllProblems();
  final solvedProblems = StatusDb.getSolvedProblems();

  return allProblems
      .where((problem) =>
          !solvedProblems
              .contains("${problem['contestId']}:${problem['index']}") &&
          problem.containsKey('rating') &&
          problem['rating'] != null)
      .toList();
}

Future<List<Map<String, dynamic>>> selectRandomProblems(double minProb,
    double maxProb, List<Map<String, dynamic>> problems, int count) async {
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  final selectedProblems = <Map<String, dynamic>>[];

  problems.shuffle(random);
  var model = XGBoostRunner();

  final features = LocalDataService.getFeatureNames();
  int featureSize = features.length;

  for (var problem in problems) {
    Map<String, double> inputMap = {};
    inputMap['current_rating_before_contest'] =
        StatusDb.getCurrentRating().toDouble();
    inputMap['max_rating_before_contest'] = StatusDb.getMaxRating().toDouble();
    inputMap['rating_delta_avg'] = StatusDb.getRatingDeltaAvg().toDouble();
    // calculate contest data

    // final contestId = problem
    StatusDb.getTagMaxRatings().forEach((tag, rating) {
      inputMap['accepted_max_rating_$tag'] = rating.toDouble();
    });

    // make vector
    List<double> inputVector = List<double>.empty(growable: true);
    for (String feature in features) {
      inputVector.add(inputMap[feature] ?? 0.0);
    }

    print('Input map: $inputMap');
    print('Input vector: $inputVector');

    final result = await model.predict(inputVector, featureSize);

    if (result < minProb || result > maxProb) {
      continue;
    }

    print('Problem: ${problem} added');
    selectedProblems.add(problem);

    if (selectedProblems.length >= count) {
      break;
    }
  }

  return selectedProblems;
}
