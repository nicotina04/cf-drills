import 'package:flutter/material.dart';

class PersonalPage extends StatelessWidget {
  const PersonalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _handleController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tab'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 코드포스 핸들 입력 폼
            TextField(
              controller: _handleController,
              decoration: InputDecoration(
                labelText: 'Codeforces Handle',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // 여기에 검색 또는 등록 로직 넣으면 됨
                    final handle = _handleController.text.trim();
                    debugPrint('Searching for handle: $handle');
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. 카드 그리드
            const Row(
              children: [
                PracticeCard(
                  title: '쉬움',
                  subtitle: '정답률 0.7 ~ 0.8',
                  color: Colors.greenAccent,
                ),
                PracticeCard(
                  title: '보통',
                  subtitle: '정답률 0.4 ~ 0.6',
                  color: Colors.amberAccent,
                ),
                PracticeCard(
                  title: '어려움',
                  subtitle: '정답률 0.25 ~ 0.3',
                  color: Colors.redAccent,
                ),
                PracticeCard(
                  title: '종합 연습 세트',
                  subtitle: '믹스된 문제 제공',
                  color: Colors.blueAccent,
                ),
              ],
            ),

            // Expanded(
            //   child: GridView.count(
            //     crossAxisCount: 2,
            //     crossAxisSpacing: 12,
            //     mainAxisSpacing: 12,
            //     childAspectRatio: 3 / 2,
            //     children: const [
            //       PracticeCard(
            //         title: '쉬움',
            //         subtitle: '정답률 0.7 ~ 0.8',
            //         color: Colors.greenAccent,
            //       ),
            //       PracticeCard(
            //         title: '보통',
            //         subtitle: '정답률 0.4 ~ 0.6',
            //         color: Colors.amberAccent,
            //       ),
            //       PracticeCard(
            //         title: '어려움',
            //         subtitle: '정답률 0.25 ~ 0.3',
            //         color: Colors.redAccent,
            //       ),
            //       PracticeCard(
            //         title: '종합 연습 세트',
            //         subtitle: '믹스된 문제 제공',
            //         color: Colors.blueAccent,
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class PracticeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const PracticeCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // 여기에 카드 눌렀을 때 동작 정의
          debugPrint('$title 카드 선택됨');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
