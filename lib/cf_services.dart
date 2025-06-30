import 'dart:math';
import 'codeforces_api.dart';
import 'db.dart';
import 'modelrunner.dart';
import 'local_data_service.dart';

double _easyProbMin = 0.8;
double _easyProbMax = 0.9;
double _mediumProbMin = 0.55;
double _mediumProbMax = 0.8 - 1e-15;
double _hardProbMin = 0.25;
double _hardProbMax = 0.55 - 1e-15;

Map<String, int> tagMaxRatingFromSubmissions(
    List<Map<String, dynamic>> submissions) {
  final Map<String, int> tagMaxRatings = {};

  final acContestants = submissions
      .where((submission) =>
          submission['verdict'] == 'OK' &&
          submission['author']['participantType'] == 'CONTESTANT')
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
  List<Map<String, dynamic>> allProblems = [];

  try {
    if (DateTime.now()
            .difference(StatusDb.getLastFetchedProblemSetDate())
            .inDays >=
        1) {
      allProblems = await cfApi.fetchAllProblems();
      await StatusDb.saveProblemSet(allProblems);
    } else {
      allProblems = StatusDb.getProblemSet();
    }
  } catch (e) {
    throw Exception(
        'Failed to fetch problem set. Please try again later when codeforces server is ok.');
  }

  final solvedProblems = StatusDb.getSolvedProblems();

  int handleRating = StatusDb.getCurrentRating();
  if (handleRating < 800) {
    handleRating = 800;
  }

  // print('All problems count: ${allProblems.length}');

  return allProblems
      .where((problem) =>
          !solvedProblems
              .contains("${problem['contestId']}:${problem['index']}") &&
          problem.containsKey('rating') &&
          problem['rating'] != null &&
          problem['rating'] >= handleRating - 500 &&
          problem['rating'] <= handleRating + 500)
      .toList();
}

Future<void> loadRecommendations(String difficulty) async {
  if (StatusDb.hasProblems(difficulty)) {
    return;
  }

  await refreshRecommendations(difficulty);
}

Future<void> refreshRecommendations(String difficulty) async {
  double minProb;
  double maxProb;

  if (difficulty == 'set') {
    await _refreshRecommendationSet();
    return;
  }

  if (difficulty == 'easy') {
    minProb = _easyProbMin;
    maxProb = _easyProbMax;
  } else if (difficulty == 'medium') {
    minProb = _mediumProbMin;
    maxProb = _mediumProbMax;
  } else {
    minProb = _hardProbMin;
    maxProb = _hardProbMax;
  }

  List<Map<String, dynamic>> problems;

  try {
    problems = await getUnsolvedProblems();
  } catch (e) {
    rethrow;
  }

  final selectedProblems =
      await selectRandomProblems(minProb, maxProb, problems, 5);

  await StatusDb.saveDisplayedProblems(selectedProblems, difficulty);
}

Future<void> _refreshRecommendationSet() async {
  List<Map<String, dynamic>> unsolved;

  try {
    unsolved = await getUnsolvedProblems();
  } catch (e) {
    rethrow;
  }

  final problems = await selectProblemSet(unsolved);

  await StatusDb.saveDisplayedProblems(problems, 'set');
}

Future<List<Map<String, dynamic>>> selectRandomProblems(double minProb,
    double maxProb, List<Map<String, dynamic>> problems, int count) async {
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  final selectedProblems = <Map<String, dynamic>>[];

  problems.shuffle(random);
  Map<String, double> inputMap = _getBaseFeatureMap();

  for (var problem in problems) {
    double predictionResult;

    try {
      predictionResult = await _predictProblem(problem, inputMap);
    } catch (e) {
      continue;
    }

    // print('Problem: ${problem}');
    // print('Prediction result: $predictionResult');

    if (predictionResult < minProb || predictionResult > maxProb) {
      continue;
    }

    selectedProblems.add(problem);

    if (selectedProblems.length >= count) {
      break;
    }
  }

  return selectedProblems;
}

Future<List<Map<String, dynamic>>> selectProblemSet(
    List<Map<String, dynamic>> problems) async {
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  final selectedProblems = <Map<String, dynamic>>[];
  problems.shuffle(random);

  Map<String, double> inputMap = _getBaseFeatureMap();
  int easyCount = 0;
  int mediumCount = 0;
  int hardCount = 0;

  for (var problem in problems) {
    double result;
    try {
      result = await _predictProblem(problem, inputMap);
    } catch (e) {
      continue;
    }

    if (result < 0.3 || result > 0.9) {
      continue;
    }

    if (result >= _easyProbMin && result <= _easyProbMax && easyCount < 2) {
      selectedProblems.add(problem);
      easyCount++;
    } else if (result >= _mediumProbMin &&
        result <= _mediumProbMax &&
        mediumCount < 2) {
      selectedProblems.add(problem);
      mediumCount++;
    } else if (result >= _hardProbMin &&
        result <= _hardProbMax &&
        hardCount < 1) {
      selectedProblems.add(problem);
      hardCount++;
    }

    if (easyCount + mediumCount + hardCount == 5) {
      break;
    }
  }

  selectedProblems.sort((a, b) {
    return (a['rating'] as int?)?.compareTo(b['rating'] as int? ?? 0) ?? 0;
  });
  return selectedProblems;
}

Map<String, double> _getBaseFeatureMap() {
  int currentRating = StatusDb.getCurrentRating();
  int maxRating = StatusDb.getMaxRating();
  int ratingDeltaAvg = StatusDb.getRatingDeltaAvg();

  Map<String, double> result = {};
  result['current_rating_before_contest'] =
      _minMaxScale(currentRating.toDouble(), 0, 4000);
  result['max_rating_before_contest'] =
      _minMaxScale(maxRating.toDouble(), 0, 4000);
  result['recent_delta_avg'] = ratingDeltaAvg.toDouble();

  LocalDataService.getProblemTags().forEach((tag) {
    result['accepted_max_rating_$tag'] = 0.0;
  });

  StatusDb.getTagMaxRatings().forEach((tag, rating) {
    result['accepted_max_rating_$tag'] =
        _minMaxScale(rating.toDouble(), 800, 3500);
  });

  return result;
}

Future<double> _predictProblem(
    Map<String, dynamic> entity, Map<String, double> baseFeature) async {
  final int contestId = entity['contestId'];

  if (StatusDb.hasContestData('$contestId') == false) {
    try {
      await _calculateContestData(contestId);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, double> contestData = StatusDb.getContestData('$contestId');

  final tagMap = _getTagMap(entity);

  Map<String, double> featureMap = {
    ...baseFeature,
    ...contestData,
    ...tagMap,
  };
  featureMap['problem_rating'] =
      _minMaxScale(entity['rating'].toDouble(), 800, 3500);

  List<double> inputVector = _toFeatureVector(featureMap);

  var model = XGBoostRunner();
  double result = await model.predict(inputVector, inputVector.length);
  return result;
}

Future<void> _calculateContestData(int contestId) async {
  final cfApi = CodeforcesApi();
  final contestData = await cfApi.fetchContestStandings(contestId);

  String contestName = contestData['contest']['name'];

  int contestDivisionTag = _getContestDivisionTag(contestName);

  final Map<String, dynamic> mergedMap = {};

  mergedMap['contest_id'] = contestId.toDouble();
  mergedMap['division_type'] = contestDivisionTag.toDouble();

  await StatusDb.saveContestData('$contestId', mergedMap);
}

int _getContestDivisionTag(String contestName) {
  contestName = contestName.toLowerCase();
  if (contestName.contains('hello') ||
      contestName.contains('good bye') ||
      contestName.contains('goodbye')) {
    return 5;
  } else if (contestName.contains('div. 1 + div. 2') ||
      contestName.contains('global')) {
    return 5;
  } else if (contestName.contains('div. 1')) {
    return 1;
  } else if (contestName.contains('div. 2')) {
    return 2;
  } else if (contestName.contains('div. 3')) {
    return 3;
  } else if (contestName.contains('div. 4')) {
    return 4;
  } else {
    return 5; // usually means all rated contests
  }
}

Map<String, double> _getTagMap(Map<String, dynamic> entity) {
  Map<String, double> tagMap = {};
  final tags = LocalDataService.getProblemTags();

  for (String tag in tags) {
    tagMap['problem_tag_$tag'] = 0;
  }

  final entityTags = entity['tags'];

  if (entityTags == null) {
    return tagMap;
  }

  for (String tag in entityTags) {
    tagMap['problem_tag_$tag'] = 1;
  }

  return tagMap;
}

List<double> _toFeatureVector(Map<String, double> inputMap) {
  final features = LocalDataService.getFeatureNames();

  List<double> inputVector = List<double>.empty(growable: true);

  for (String feature in features) {
    inputVector.add(inputMap[feature] ?? 0.0);
  }

  return inputVector;
}

double _minMaxScale(double value, double min, double max) {
  if (value < min) return 0.0;
  if (value > max) return 1.0;
  return (value - min) / (max - min);
}
