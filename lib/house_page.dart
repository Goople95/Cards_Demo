import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/theme_model.dart';

class HousePage extends StatefulWidget {
  const HousePage({super.key});

  @override
  State<HousePage> createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> with TickerProviderStateMixin {
  String _currentTheme = 'uk';
  int _houseLevel = 1;
  int _totalFragments = 0;
  
  // 房屋升级所需碎片数
  final Map<int, int> _levelCosts = {
    2: 50,
    3: 150,
    4: 300,
    5: 500,
  };
  
  // 房屋等级描述
  final Map<int, String> _levelDescriptions = {
    1: '简陋小屋',
    2: '舒适农舍',
    3: '精美别墅',
    4: '豪华庄园',
    5: '皇家宫殿',
  };

  @override
  void initState() {
    super.initState();
    _loadHouseState();
  }

  Future<void> _loadHouseState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _houseLevel = prefs.getInt('house_level_$_currentTheme') ?? 1;
      // 获取所有主题的碎片总数
      _totalFragments = _calculateTotalFragments(prefs);
    });
  }

  int _calculateTotalFragments(SharedPreferences prefs) {
    int total = 0;
    for (String themeKey in themes.keys) {
      final themeName = themes[themeKey]!.name;
      total += prefs.getInt('fragmentCount_$themeName') ?? 0;
    }
    return total;
  }

  Future<void> _saveHouseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('house_level_$_currentTheme', _houseLevel);
  }

  void _upgradeHouse() {
    if (_houseLevel >= 5) return;
    
    final cost = _levelCosts[_houseLevel + 1] ?? 0;
    if (_totalFragments >= cost) {
      setState(() {
        _houseLevel++;
        _totalFragments -= cost;
      });
      _saveHouseState();
      _deductFragmentsFromThemes(cost);
      
      _showUpgradeSuccessDialog();
    } else {
      _showInsufficientFragmentsDialog(cost);
    }
  }

  Future<void> _deductFragmentsFromThemes(int totalCost) async {
    final prefs = await SharedPreferences.getInstance();
    int remaining = totalCost;
    
    // 按主题顺序扣除碎片
    for (String themeKey in themes.keys) {
      if (remaining <= 0) break;
      
      final themeName = themes[themeKey]!.name;
      final fragments = prefs.getInt('fragmentCount_$themeName') ?? 0;
      final deduct = fragments >= remaining ? remaining : fragments;
      
      await prefs.setInt('fragmentCount_$themeName', fragments - deduct);
      remaining -= deduct;
    }
  }

  void _showUpgradeSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('升级成功！', style: TextStyle(color: Colors.green)),
        content: Text('恭喜！你的房屋已升级到 ${_levelDescriptions[_houseLevel]}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('太棒了！'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFragmentsDialog(int cost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('碎片不足', style: TextStyle(color: Colors.orange)),
        content: Text('升级需要 $cost 个碎片，你目前有 $_totalFragments 个碎片'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续收集'),
          ),
        ],
      ),
    );
  }

  String _getHouseImagePath() {
    final themePrefix = _currentTheme.toUpperCase();
    return 'assets/house/${themePrefix}_House.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景房屋图片铺满整个屏幕
          Image.asset(
            _getHouseImagePath(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF87CEEB), // 天空蓝
                      const Color(0xFF98FB98), // 浅绿色
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.house, size: 100, color: Colors.brown),
                      SizedBox(height: 16),
                      Text(
                        '房屋图片加载中...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // 半透明遮罩层，确保文字可读性
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // UI控件层
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildHouseLevelBadge(),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                themeChineseNames[themes[_currentTheme]!.name] ?? '我的家园',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              Text(
                _levelDescriptions[_houseLevel] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  shadows: [
                    Shadow(
                      blurRadius: 1,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_totalFragments',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseLevelBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Lv.$_houseLevel',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final canUpgrade = _houseLevel < 5;
    final nextLevelCost = _levelCosts[_houseLevel + 1] ?? 0;
    final hasEnoughFragments = _totalFragments >= nextLevelCost;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canUpgrade) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    '升级到 ${_levelDescriptions[_houseLevel + 1]}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$nextLevelCost 碎片',
                        style: TextStyle(
                          fontSize: 16,
                          color: hasEnoughFragments ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnoughFragments ? Colors.green : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: hasEnoughFragments ? 8 : 2,
                ),
                onPressed: hasEnoughFragments ? _upgradeHouse : null,
                child: Text(
                  hasEnoughFragments ? '升级房屋' : '碎片不足',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber.shade700, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.emoji_events, size: 40, color: Colors.orange),
                  SizedBox(height: 8),
                  Text(
                    '恭喜！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '你的房屋已达到最高等级！',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 