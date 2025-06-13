import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'social_page.dart';

// 挑战记录数据模型
class ChallengeRecord {
  final String challengerName;
  final int fragmentsLost;
  final DateTime timestamp;

  ChallengeRecord({
    required this.challengerName,
    required this.fragmentsLost,
    required this.timestamp,
  });
}

class HousePage extends StatefulWidget {
  const HousePage({super.key});

  @override
  State<HousePage> createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> with TickerProviderStateMixin {
  int _fragments = 0;
  int _houseLevel = 1;
  int _likes = 0; // 新增：点赞数
  final int _maxLevel = 6;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  late AudioPlayer _audioPlayer;

  // 新增：水平滑动相关
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _arrowBreathController; // 新增：箭头呼吸动画
  bool _isPanelVisible = true;
  double _panelOffset = 0.0;

  // 新增：挑战记录列表
  final List<ChallengeRecord> _challengeRecords = [
    ChallengeRecord(
      challengerName: '小明',
      fragmentsLost: 5,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChallengeRecord(
      challengerName: '小红',
      fragmentsLost: 3,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ChallengeRecord(
      challengerName: '小刚',
      fragmentsLost: 4,
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];

  bool _showHintOverlay = false;
  bool _hintHasShownOnce = false;
  Timer? _hintTimer;
  Timer? _hintDisplayTimer;
  late AnimationController _hintAnimController;

  @override
  void initState() {
    super.initState();
    _loadState();
    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ),
    );
    _arrowBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);
    _startHintMonitor();
    _audioPlayer = AudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fragments = prefs.getInt('fragmentCount') ?? 0;
      _houseLevel = prefs.getInt('houseLevel_uk') ?? 1;
      _likes = prefs.getInt('houseLikes_uk') ?? 0;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fragmentCount', _fragments);
    await prefs.setInt('houseLevel_uk', _houseLevel);
    await prefs.setInt('houseLikes_uk', _likes); // 新增：保存点赞数
  }

  Future<void> _upgradeHouse() async {
    int cost = 500 * _houseLevel;
    if (_houseLevel < _maxLevel && _fragments >= cost) {
      setState(() {
        _houseLevel++;
        _fragments -= cost;
      });
      await _saveState();
      _confettiController.play();
      _playUpgradeSound();
    }
  }

  Future<void> _playUpgradeSound() async {
    await _audioPlayer.play(AssetSource('house_upgrade.mp3'));
  }

  void _startHintMonitor() {
    _hintTimer?.cancel();
    _hintDisplayTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showHintOverlay = true);
        _hintAnimController.repeat(reverse: true);
        _hintDisplayTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showHintOverlay = false;
              _hintHasShownOnce = true;
            });
            _hintAnimController.stop();
            _startHintMonitor(); // 继续监测，循环
          }
        });
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _showHintOverlay = false);
    _hintAnimController.stop();
    _startHintMonitor();
  }

  // 新增：处理挑战记录点击
  void _handleChallengeTap(ChallengeRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SocialPage(
          friendName: record.challengerName,
          isRevenge: true,
        ),
      ),
    );
  }

  // 新增：格式化时间
  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 新增：处理水平滑动（滑动距离为屏幕宽度）
  void _handleHorizontalDrag(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _panelOffset += details.delta.dx;
      _panelOffset = _panelOffset.clamp(0.0, screenWidth);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldHide = velocity > 500 || _panelOffset > screenWidth / 2;
    if (shouldHide) {
      _slideController.forward();
      setState(() {
        _isPanelVisible = false;
        _panelOffset = screenWidth;
      });
    } else {
      _slideController.reverse();
      setState(() {
        _isPanelVisible = true;
        _panelOffset = 0.0;
      });
    }
  }

  void _togglePanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isPanelVisible) {
      _slideController.forward();
      setState(() {
        _isPanelVisible = false;
        _panelOffset = screenWidth;
      });
    } else {
      _slideController.reverse();
      setState(() {
        _isPanelVisible = true;
        _panelOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int cost = 500 * _houseLevel;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        // 背景图
        Image.asset(
          'assets/house/house_level_$_houseLevel.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        // 渐变遮罩
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.transparent,
                Colors.black.withOpacity(0.65),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // 操作面板
        GestureDetector(
          onHorizontalDragUpdate: _isPanelVisible ? _handleHorizontalDrag : null,
          onHorizontalDragEnd: _isPanelVisible ? _handleHorizontalDragEnd : null,
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              double offset = _isPanelVisible
                  ? _panelOffset
                  : screenWidth * _slideAnimation.value;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // 碎片和点赞数显示
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 28),
                          const SizedBox(width: 8),
                          Text('碎片：$_fragments', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1,1))])),
                          const SizedBox(width: 24),
                          Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
                          const SizedBox(width: 8),
                          Text('$_likes', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1,1))])),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('我的小屋', style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(blurRadius: 12, color: Colors.black, offset: Offset(2,2))])),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text('当前等级：$_houseLevel / $_maxLevel', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
                            const SizedBox(height: 18),
                            _houseLevel < _maxLevel
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.18),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      onPressed: _fragments >= cost ? _upgradeHouse : null,
                                      child: Column(
                                        children: [
                                          Text('升级', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 20),
                                              const SizedBox(width: 4),
                                              Text('消耗 $cost 碎片', style: TextStyle(fontSize: 14, color: Colors.white70)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      onPressed: null,
                                      child: Text('已满级', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800, letterSpacing: 1)),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 新增：挑战记录列表
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '最近挑战记录',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._challengeRecords.map((record) => InkWell(
                              onTap: () => _handleChallengeTap(record),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.blue.shade700,
                                      child: Text(
                                        record.challengerName[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.challengerName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _formatTimeAgo(record.timestamp),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '-${record.fragmentsLost}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 居中右侧呼吸箭头（面板可见时）
        if (_isPanelVisible)
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height / 2 - 32,
            child: GestureDetector(
              onTap: _togglePanel,
              child: AnimatedBuilder(
                animation: _arrowBreathController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _arrowBreathController.value,
                    child: Opacity(
                      opacity: 0.6 + 0.4 * (_arrowBreathController.value - 0.85) / 0.3,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        // 恢复：顶部"下滑返回老虎机"提示浮层（面板可见时才显示）
        if (_showHintOverlay && _isPanelVisible)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _onUserInteraction,
              onPanDown: (_) => _onUserInteraction(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_hintHasShownOnce)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        '下滑返回老虎机',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (!_hintHasShownOnce) const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _hintAnimController,
                    builder: (context, child) {
                      final double offsetY = 8 * (1 - _hintAnimController.value);
                      final double opacity = 0.5 + 0.5 * _hintAnimController.value;
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, offsetY),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_downward, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        // 居中左侧呼吸箭头（面板隐藏时）
        if (!_isPanelVisible)
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height / 2 - 32,
            child: GestureDetector(
              onTap: _togglePanel,
              child: AnimatedBuilder(
                animation: _arrowBreathController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _arrowBreathController.value,
                    child: Opacity(
                      opacity: 0.6 + 0.4 * (_arrowBreathController.value - 0.85) / 0.3,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    _hintTimer?.cancel();
    _hintDisplayTimer?.cancel();
    _hintAnimController.dispose();
    _slideController.dispose();
    _arrowBreathController.dispose(); // 新增
    super.dispose();
  }
} 