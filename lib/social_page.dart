import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

// 社交挑战页面，支持10道题随机答题，答对500答错200
class SocialPage extends StatefulWidget {
  final String? friendName;
  final bool isRevenge;

  const SocialPage({
    super.key,
    this.friendName,
    this.isRevenge = false,
  });

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with TickerProviderStateMixin {
  late String _friendName;
  bool _answered = false;
  bool _isCorrect = false;
  int _fragmentsStolen = 0;
  late Map<String, dynamic> _currentQuiz;
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;
  final Random _random = Random();

  final List<String> _funnyNames = [
    '王铁蛋', '李狗剩', '赵美丽', '钱多多', '孙悟饭',
    '周星星', '刘能能', '吴小胖', '郑大力', '冯开心'
  ];

  final List<Map<String, dynamic>> _quizList = [
    {'q': '英国的首都是伦敦吗？', 'a': true},
    {'q': '大本钟位于巴黎吗？', 'a': false},
    {'q': '英镑是英国的货币吗？', 'a': true},
    {'q': '牛津大学在美国吗？', 'a': false},
    {'q': '红色双层巴士是伦敦的标志吗？', 'a': true},
    {'q': '英国国旗叫Union Jack吗？', 'a': true},
    {'q': '英国有女王吗？', 'a': true},
    {'q': '泰晤士河流经伦敦吗？', 'a': true},
    {'q': '伦敦眼是摩天轮吗？', 'a': true},
    {'q': '英国和中国接壤吗？', 'a': false},
  ];

  void _showQuizDialog() async {
    setState(() {
      _showingCustomDialog = true;
    });
  }

  bool _showingCustomDialog = false;

  @override
  void initState() {
    super.initState();
    _friendName = widget.friendName ?? _generateRandomName();
    _currentQuiz = (_quizList..shuffle()).first;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showQuizDialog();
    });
  }

  String _generateRandomName() {
    final names = ['小明', '小红', '小刚', '小李', '小张', '小王', '小赵', '小钱', '小孙', '小周'];
    return names[_random.nextInt(names.length)];
  }

  void _handleQuizAnswer(bool answer) {
    bool correct = (answer == _currentQuiz['a']);
    setState(() {
      _answered = true;
      _isCorrect = correct;
      _fragmentsStolen = correct ? 500 : 200;
      _showingCustomDialog = false;
    });
    if (correct) {
      _confettiController.play();
      _audioPlayer.play(AssetSource('audio/match3__06304.wav'));
    }
  }

  void _returnToSlot(bool liked) {
    if (liked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('你为好友点赞了！')),
      );
    }
    Navigator.of(context).pop(_fragmentsStolen);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/social/Social_House.png',
              fit: BoxFit.cover,
            ),
          ),
          // 主要内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text('$_friendName的小屋', 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(widget.isRevenge ? '（复仇之战）' : '（好友昵称随机生成）', 
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_answered)
                  Column(
                    children: [
                      Text(
                        _isCorrect
                            ? '答对啦！你抢到了$_fragmentsStolen个碎片！'
                            : '答错了，只抢到$_fragmentsStolen个碎片。',
                        style: TextStyle(
                          color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.thumb_up),
                            label: Text('点赞离开'),
                            onPressed: () => _returnToSlot(true),
                          ),
                          const SizedBox(width: 24),
                          OutlinedButton(
                            child: Text('返回老虎机', style: TextStyle(color: Colors.white70)),
                            onPressed: () => _returnToSlot(false),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 自定义弹窗
          if (_showingCustomDialog)
            Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '好友挑战题',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _currentQuiz['q'],
                        style: const TextStyle(fontSize: 20, color: Colors.white, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleQuizAnswer(true),
                            child: const Text('YES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleQuizAnswer(false),
                            child: const Text('NO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 全屏彩带特效，仅答对时显示
          if (_answered && _isCorrect)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.08,
              numberOfParticles: 60,
              gravity: 0.25,
              maxBlastForce: 30,
              minBlastForce: 12,
            ),
        ],
      ),
    );
  }
} 