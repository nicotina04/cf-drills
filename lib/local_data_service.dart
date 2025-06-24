import 'package:flutter/services.dart' show rootBundle;

class LocalDataService {
  static List<String>? _featureNames;
  static List<String>? _problemTags;

  static Future<void> init() async {
    final featuresRaw = await rootBundle.loadString('assets/feature_names.txt');
    final tagsRaw = await rootBundle.loadString('assets/problem_tags.txt');

    _featureNames = featuresRaw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    _problemTags = tagsRaw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static List<String> getFeatureNames() {
    if (_featureNames == null) {
      throw Exception("DataService not initialized. Call init() first.");
    }

    return _featureNames!;
  }

  static List<String> getProblemTags() {
    if (_problemTags == null) {
      throw Exception("DataService not initialized. Call init() first.");
    }

    return _problemTags!;
  }
}