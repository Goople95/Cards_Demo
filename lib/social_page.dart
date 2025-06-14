import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';

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

  // 新增：好友房屋等级、点赞数、碎片数、背景图、国家、头像
  late int _houseLevel;
  late int _likeCount;
  late int _fragmentCount;
  late String _bgImage;
  late String _country;
  late String _avatarImg;

  final List<String> _countryList = [
    '中国', '日本', '英国', '法国', '德国', '意大利', '西班牙', '希腊', '美国', '澳大利亚'
  ];

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

  OverlayEntry? _fragmentOverlayEntry;
  bool _showResult = false;
  bool _showButtons = false;
  int _friendFragmentCount = 0;

  final GlobalKey _friendNameKey = GlobalKey();

  Offset? _resultCenter;

  @override
  void initState() {
    super.initState();
    _friendName = widget.friendName ?? _generateRandomName();
    _currentQuiz = (_quizList..shuffle()).first;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _audioPlayer = AudioPlayer();
    _houseLevel = 1 + _random.nextInt(6); // 1-6
    _likeCount = 10 + _random.nextInt(9991); // 10-10000
    _fragmentCount = 1000 + _random.nextInt(99000); // 1000-99999
    _friendFragmentCount = _fragmentCount;
    _bgImage = 'assets/social/Social_House_${1 + _random.nextInt(10)}.png';
    _country = _countryList[_random.nextInt(_countryList.length)];
    _avatarImg = 'assets/social/Avatar_${1 + _random.nextInt(10)}.png';
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
      // 延迟一帧再播放彩带，确保UI已经更新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Confetti triggered! (before play)'); // 调试信息
        _confettiController.play();
        print('Confetti triggered! (after play)'); // 调试信息
      });
      _audioPlayer.play(AssetSource('audio/match3__06304.wav'));
    }
    // 先碎片飞行动画
    _playFragmentFlyEffect();
  }

  void _playFragmentFlyEffect() async {
    final RenderBox? startBox = _friendNameKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? stackBox = context.findRenderObject() as RenderBox?;
    if (startBox == null || stackBox == null) {
      _showResultAndButtons();
      return;
    }
    // 播放碎片动画音效
    _audioPlayer.play(AssetSource('audio/get_card_shards_10302.wav'));
    final startGlobal = startBox.localToGlobal(Offset(startBox.size.width / 2, startBox.size.height / 2));
    final startLocal = stackBox.globalToLocal(startGlobal);
    final center = Offset(stackBox.size.width / 2, stackBox.size.height / 2);
    _fragmentOverlayEntry = OverlayEntry(
      builder: (context) => _FragmentParticle(
        key: UniqueKey(),
        startPosition: startLocal,
        endPosition: center,
        count: _fragmentsStolen > 200 ? 200 : _fragmentsStolen,
        onCompleted: (_) {
          _fragmentOverlayEntry?.remove();
          _fragmentOverlayEntry = null;
          setState(() {
            _friendFragmentCount -= _fragmentsStolen;
            _showResult = true;
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _showButtons = true);
          });
        },
        duration: const Duration(milliseconds: 1000),
      ),
    );
    Overlay.of(context).insert(_fragmentOverlayEntry!);
    // 记录目标center用于文案定位
    _resultCenter = center;
  }

  void _showResultAndButtons() {
    setState(() {
      _friendFragmentCount -= _fragmentsStolen;
      _showResult = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showButtons = true);
    });
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
    _fragmentOverlayEntry?.remove();
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
              _bgImage,
              fit: BoxFit.cover,
            ),
          ),
          // 主要内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // 新增：好友信息栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade300,
                        backgroundImage: AssetImage(_avatarImg),
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('$_friendName', key: _friendNameKey, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow, size: 18),
                              const SizedBox(width: 2),
                              Text('$_friendFragmentCount', style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                            ],
                          ),
                          Text('房屋等级：$_houseLevel', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 2),
                              Text('$_likeCount', style: const TextStyle(color: Colors.amber, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 原有内容
                const SizedBox(height: 16),
                Text('在$_country的小屋', 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(widget.isRevenge ? '（复仇之战）' : '', 
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_showResult)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _resultCenter?.dy ?? 0,
                    child: Transform.translate(
                      offset: const Offset(0, 150),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 32),
                                const SizedBox(width: 8),
                                Text(
                                  _isCorrect
                                    ? '答对啦，你赢了好友$_fragmentsStolen碎片！'
                                    : '答错啦，你赢了好友$_fragmentsStolen碎片！',
                                  style: TextStyle(
                                    color: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showButtons) ...[
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
                        ],
                      ),
                    ),
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
          // 彩带特效，始终渲染在最顶层，位置与slot页面一致
          Positioned(
            left: 0,
            right: 0,
            bottom: 120, // 起点上移，和slot页面一致
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: (_answered && _isCorrect) ? 1.0 : 0.0,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: -pi / 2, // 向上喷射
                    emissionFrequency: 0.08,
                    numberOfParticles: 30,
                    maxBlastForce: 40,
                    minBlastForce: 20,
                    gravity: 0.15,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.yellow,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// region FragmentParticle Widget
class _FragmentParticle extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final int count;
  final void Function(Key) onCompleted;
  final Duration duration;

  const _FragmentParticle({
    required Key key,
    required this.startPosition,
    required this.endPosition,
    required this.count,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<_FragmentParticle> createState() => _FragmentParticleState();
}

class _FragmentParticleState extends State<_FragmentParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _positions = [];
  final List<double> _sizes = [];
  final List<double> _opacities = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted(widget.key!);
      }
    });

    // 初始化粒子
    for (int i = 0; i < widget.count; i++) {
      _positions.add(widget.startPosition);
      _sizes.add(8 + _random.nextDouble() * 8);
      _opacities.add(0.6 + _random.nextDouble() * 0.4);
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FragmentPainter(
            positions: _positions,
            sizes: _sizes,
            opacities: _opacities,
            progress: _controller.value,
            startPosition: widget.startPosition,
            endPosition: widget.endPosition,
            random: _random,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FragmentPainter extends CustomPainter {
  final List<Offset> positions;
  final List<double> sizes;
  final List<double> opacities;
  final double progress;
  final Offset startPosition;
  final Offset endPosition;
  final Random random;

  _FragmentPainter({
    required this.positions,
    required this.sizes,
    required this.opacities,
    required this.progress,
    required this.startPosition,
    required this.endPosition,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < positions.length; i++) {
      // 计算每个粒子的当前位置
      final t = progress;
      
      // 为每个粒子生成独立的随机控制点
      final controlPoint1 = Offset(
        startPosition.dx + (random.nextDouble() - 0.5) * 200,
        startPosition.dy - 100 - random.nextDouble() * 100,
      );
      
      final controlPoint2 = Offset(
        endPosition.dx + (random.nextDouble() - 0.5) * 100,
        endPosition.dy - 50 - random.nextDouble() * 50,
      );

      // 三阶贝塞尔曲线
      final x = _cubicBezier(
        startPosition.dx,
        controlPoint1.dx,
        controlPoint2.dx,
        endPosition.dx,
        t,
      );
      
      final y = _cubicBezier(
        startPosition.dy,
        controlPoint1.dy,
        controlPoint2.dy,
        endPosition.dy,
        t,
      );

      // 添加一些随机偏移
      final randomOffset = Offset(
        (random.nextDouble() - 0.5) * 30 * (1 - t),
        (random.nextDouble() - 0.5) * 30 * (1 - t),
      );

      final currentPosition = Offset(x, y) + randomOffset;
      
      // 绘制粒子
      paint.color = Colors.yellow.withOpacity(opacities[i] * (1 - t * 0.5));
      canvas.drawCircle(
        currentPosition,
        sizes[i] * (1 - t * 0.3),
        paint,
      );
    }
  }

  double _cubicBezier(double p0, double p1, double p2, double p3, double t) {
    final oneMinusT = 1 - t;
    return p0 * oneMinusT * oneMinusT * oneMinusT +
           3 * p1 * t * oneMinusT * oneMinusT +
           3 * p2 * t * t * oneMinusT +
           p3 * t * t * t;
  }

  @override
  bool shouldRepaint(covariant _FragmentPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
// endregion 