import 'dart:math';

import 'package:dio/dio.dart';

class CodeforcesApi {
  final Dio dio;

  CodeforcesApi({Dio? dio})
      : dio = dio ?? Dio(BaseOptions(baseUrl: 'https://codeforces.com/api/'));

  Future<Map<String, dynamic>?> fetchUserInfo(String handle) async {
    try {
      final response =
          await dio.get('user.info', queryParameters: {'handles': handle});
      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        return response.data['result'][0];
      } else {
        throw Exception('Failed to fetch user info: ${response.data}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  Future<int> fetchUserRatingDeltaAvg(String handle) async {
    int avgCount = 3;

    try {
      final res =
          await dio.get('user.rating', queryParameters: {'handle': handle});

      if ((res.statusCode == 200 && res.data['status'] == 'OK') == false) {
        throw Exception('Failed to fetch user rating delta: ${res.data}');
      }

      final ratings = res.data['result'] as List;
      if (ratings.isEmpty) return 0;

      int totalDelta = 0;
      int cnt = 0;

      for (var i = ratings.length - 1;
          i >= max(0, ratings.length - avgCount);
          i--) {
        final rating = ratings[i] as Map<String, dynamic>;
        final int newRating = rating['newRating'] as int;
        final int oldRating = rating['oldRating'] as int;
        totalDelta += newRating - oldRating;
        ++cnt;
      }

      return (totalDelta / max(1, cnt)).floor();
    } catch (e) {
      print('Error fetching user rating delta: $e');
      throw Exception('Failed to fetch user rating delta');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserSubmissionHistory(
      String handle) async {
    try {
      final response =
          await dio.get('user.status', queryParameters: {'handle': handle});
      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        return response.data['result'];
      } else {
        throw Exception(
            'Failed to fetch user submission history: ${response.data}');
      }
    } catch (e) {
      print('Error fetching user submission history: $e');
      throw Exception('Failed to fetch user submission history');
    }
  }
}
