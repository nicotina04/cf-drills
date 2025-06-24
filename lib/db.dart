import 'package:hive_flutter/hive_flutter.dart';

class StatusDb {
  static const String _boxName = 'handle_data';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> saveHandle(String handle) async {
    final box = Hive.box(_boxName);
    await box.put('cf_handle', handle);
  }

  static String getHandle() {
    final box = Hive.box(_boxName);
    return box.get('cf_handle', defaultValue: '');
  }

  static bool hasHandle() {
    final box = Hive.box(_boxName);
    return box.containsKey('cf_handle');
  }

  static Future<void> clearHandle() async {
    final box = Hive.box(_boxName);
    await box.delete('cf_handle');
  }

  static int getRatingDeltaAvg() {
    final box = Hive.box(_boxName);
    return box.get('rating_delta_avg', defaultValue: 0) as int;
  }

  static Future<void> saveRatingDeltaAvg(int delta) async {
    final box = Hive.box(_boxName);
    await box.put('rating_delta_avg', delta);
  }

  static Future<void> saveMaxRating(int rating) async {
    final box = Hive.box(_boxName);
    await box.put('max_rating', rating);
  }

  static int getMaxRating() {
    final box = Hive.box(_boxName);
    return box.get('max_rating', defaultValue: 0) as int;
  }

  static int getCurrentRating() {
    final box = Hive.box(_boxName);
    return box.get('current_rating', defaultValue: 0) as int;
  }

  static Future<void> saveCurrentRating(int rating) async {
    final box = Hive.box(_boxName);
    await box.put('current_rating', rating);
  }

  static Future<void> saveTagMaxRating(Map<String, int> ratingMap) async {
    final box = Hive.box(_boxName);
    await box.put('max_rating_tags', ratingMap);
  }

  static Map<String, int> getTagMaxRatings() {
    final box = Hive.box(_boxName);
    return box.get('max_rating_tags', defaultValue: <String, int>{})
        as Map<String, int>;
  }

  static Set<String> getSolvedProblems() {
    final box = Hive.box(_boxName);
    return box.get('solved_problems', defaultValue: <String>{}) as Set<String>;
  }

  static Future<void> saveSolvedProblems(Set<String> problems) async {
    final box = Hive.box(_boxName);
    await box.put('solved_problems', problems);
  }

  static Future<void> saveDisplayedProblems(
      List<Map<String, dynamic>> problems, String difficulty) async {
    final box = Hive.box(_boxName);
    await box.put('displayed_$difficulty', problems);
  }

  static List<Map<String, dynamic>> getDisplayedProblems(String difficulty) {
    final box = Hive.box(_boxName);
    return box.get('displayed_$difficulty',
        defaultValue: <Map<String, dynamic>>[]) as List<Map<String, dynamic>>;
  }

  static bool hasContestData(String contestId) {
    final box = Hive.box(_boxName);
    return box.containsKey('contest_data_$contestId');
  }

  static Future<void> saveContestData(
      String contestId, Map<String, dynamic> data) async {
    final box = Hive.box(_boxName);
    await box.put('contest_data_$contestId', data);
  }

  static Map<String, dynamic> getContestData(String contestId) {
    final box = Hive.box(_boxName);
    return box.get('contest_data_$contestId',
        defaultValue: <String, dynamic>{}) as Map<String, dynamic>;
  }

  static Future<void> clear() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
