import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class HousePage extends StatefulWidget {
  const HousePage({super.key});

  @override
  State<HousePage> createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> {
  int _fragments = 0;
  int _houseLevel = 1;
  final int _maxLevel = 6;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadState();
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
    });
    print('HousePage _loadState: _fragments = $_fragments, _houseLevel = $_houseLevel');
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fragmentCount', _fragments);
    await prefs.setInt('houseLevel_uk', _houseLevel);
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

  @override
  Widget build(BuildContext context) {
    print('HousePage build! _fragments = $_fragments, _houseLevel = $_houseLevel');
    int cost = 500 * _houseLevel;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
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
            // 内容区毛玻璃卡片
            Center(
              child: SingleChildScrollView(
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
                      Text('DEBUG-HOUSEPAGE', style: TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.yellow.shade700, size: 28),
                          const SizedBox(width: 8),
                          Text('碎片：$_fragments', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1,1))])),
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
                                      gradient: LinearGradient(colors: [Color(0xFFffb347), Color(0xFFffcc33)]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.25),
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
                                      child: Text('升级（消耗 $cost 碎片）', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade900, letterSpacing: 1)),
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
                      const SizedBox(height: 32),
                      Text('下滑屏幕返回老虎机', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1)),
                    ],
                  ),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
} 