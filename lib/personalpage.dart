import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cardelement.dart';
import 'codeforces_service.dart';

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
  final _prefsKey = 'cf_handle';

  @override
  void initState() {
    super.initState();
    _loadHandle();
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
            Row(
              children: [
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getRatingColor(_rating))
                  ),
              ]
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Max Rating: ${_maxRating != null && _maxRating! > 0 ? _maxRating : '-'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  'Rating Delta Avg: ${_ratingDeltaAvg != null ? _ratingDeltaAvg : '0'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  CardElement(icon: Icons.cake, title: 'Easy', description: '쉬운 문제(정답률 70%~80%)', onTap: onTapEasy),
                  CardElement(icon: Icons.bolt, title: 'Medium', description: '보통 문제(정답률 40%~60%)', onTap: onTapMedium),
                  CardElement(icon: Icons.fireplace_outlined, title: 'Challenging', description: '도전 문제(정답률 25%~40%)', onTap: onTapHard),
                  CardElement(icon: Icons.rocket_launch, title: 'Set', description: '종합 세트', onTap: onTapSet),
                ],
            ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHandle() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHandle = prefs.getString(_prefsKey);

    String? fetchedHandle = savedHandle;
    int? fetchedRating;

    if (savedHandle != null) {
      await _fetchUserStat(savedHandle);
    }

    setState(() {
      _handle = fetchedHandle;
      _rating = fetchedRating;
    });
  }

  Future<void> _saveHandle(String handle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, handle);

    setState(() {
      _handle = handle;
    });

    await _fetchUserStat(handle);
  }

  Future<void> _fetchRatingFromServer() async {
    if (_handle == null || _handle!.isEmpty) return;

    try {
      final userInfo = await _cfApi.fetchUserInfo(_handle!);

      if (userInfo == null) {
        _showErrorDialog('Failed to fetch user info. Please check your handle.');
        return;
      }

      final rating = userInfo['rating'];
      final maxRating = userInfo['maxRating'];
      setState(() {
        _rating = rating;
        _maxRating = maxRating;
      });
    } catch (error) {
      _showErrorDialog('Failed to fetch user info. Please try again later.');
      debugPrint('Error fetching user info: $error');
    }
  }

  Future<void> _fetchUserStat(String handle) async {
    try {
      await _fetchRatingFromServer();
      int deltaAvg = await _cfApi.fetchUserRatingDeltaAvg(handle);

      setState(() {
        _ratingDeltaAvg = deltaAvg;
      });

    } catch (error) {
      _showErrorDialog('Failed to fetch user statistics. Please try again later.');
      debugPrint('Error fetching user statistics: $error');
    }
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
      )
    );

    if (result != null && result.isNotEmpty) {
      await _saveHandle(result);
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

  void onTapEasy() {
    debugPrint('쉬운 문제 카드 선택됨');
  }

  void onTapMedium() {
    debugPrint('보통 문제 카드 선택됨');
  }

  void onTapHard() {
    debugPrint('도전 문제 카드 선택됨');
  }

  void onTapSet() {
    debugPrint('종합 세트 카드 선택됨');
  }
}