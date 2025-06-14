import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'models/theme_model.dart';
import 'house_page.dart';
import 'social_page.dart';

class SlotGame extends StatefulWidget {
  const SlotGame({super.key});

  @override
  State<SlotGame> createState() => _SlotGameState();
}

class _SlotGameState extends State<SlotGame> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // region State Variables
  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;
  late ThemeModel _currentTheme;
  late List<CollectionCard> _collection;
  late List<SlotReel> _reels;
  late List<GlobalKey<SlotReelState>> _reelKeys;
  
  int _spinCount = 0;
  int _fragmentCount = 0;
  int _remainingSpins = 100; // 新增：剩余转动次数
  String _fragmentGainText = ''; // 碎片增加显示文字
  bool _showingFragmentGain = false; // 是否正在显示碎片增加动画
  bool _isButtonPressed = false;
  List<bool> _matchedReels = List.filled(3, false); // 新增：跟踪匹配的转轮
  Timer? _matchEffectTimer; // 新增：匹配特效计时器

  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  final GlobalKey _slotMachineKey = GlobalKey(debugLabel: 'slotMachine');
  final GlobalKey _fragmentCounterKey = GlobalKey(debugLabel: 'fragmentCounter');
  final GlobalKey _spinProgressKey = GlobalKey(debugLabel: 'spinProgress');
  Offset? _fragmentGainOffset;

  bool _crystalDiceEffectVisible = false;
  bool _showHintOverlay = false;
  bool _hintHasShownOnce = false;
  Timer? _hintTimer;
  Timer? _hintDisplayTimer;
  late AnimationController _hintAnimController;

  final PageController _pageController = PageController();
  bool _isSlotMachineVisible = true;

  late List<List<CollectionCard>> _reelCardPools;
  late List<int> _reelIndices;

  // 标记是否已发放全部集齐奖励
  bool _hasGivenAllCollectedReward = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _currentTheme = themes['uk']!;
    _reelKeys = List.generate(3, (index) => GlobalKey<SlotReelState>());
    _reelCardPools = List.generate(3, (_) {
      final pool = _currentTheme.cards.map((item) => item.clone()).toList();
      pool.shuffle();
      return pool;
    });
    _reelIndices = List.filled(3, 0);
    _reels = List.generate(3, (index) => SlotReel(
      key: _reelKeys[index],
      cardPool: _reelCardPools[index],
      selectedIndex: _reelIndices[index],
      themeAssetPath: _currentTheme.assetPath,
      isMatched: _matchedReels[index],
    ));
    _initializeGame();
    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _startHintMonitor();
    _pageController.addListener(() {});
  }

  void _initializeGame() {
    _animationControllers.values.forEach((controller) => controller.dispose());
    _animationControllers.clear();
    _animations.clear();
    _collection = _currentTheme.cards.where((c) => !c.isProp).map((e) => e.clone()).toList();
    _collection.forEach(_setupAnimations);
    _loadState();
  }

  void _setupAnimations(CollectionCard card) {
    _animationControllers[card.name] = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animations[card.name] = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationControllers[card.name]!,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _updateReels() {
    setState(() {
      _reels = List.generate(3, (index) => SlotReel(
        key: _reelKeys[index],
        cardPool: _reelCardPools[index],
        selectedIndex: _reelIndices[index],
        themeAssetPath: _currentTheme.assetPath,
        isMatched: _matchedReels[index],
      ));
    });
  }

  void _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _spinCount = prefs.getInt('spinCount_${_currentTheme.name}') ?? 0;
      _fragmentCount = prefs.getInt('fragmentCount') ?? 0;
      _remainingSpins = prefs.getInt('remainingSpins_${_currentTheme.name}') ?? 100;
      
      for (var card in _collection) {
        card.progress = prefs.getInt('card_progress_${_currentTheme.name}_${card.name}') ?? 0;
      }
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spinCount_${_currentTheme.name}', _spinCount);
    await prefs.setInt('fragmentCount', _fragmentCount);
    await prefs.setInt('remainingSpins_${_currentTheme.name}', _remainingSpins);
    for (var card in _collection) {
      await prefs.setInt('card_progress_${_currentTheme.name}_${card.name}', card.progress);
    }
  }

  Future<void> _showStyledDialog({
    required BuildContext context,
    required String title,
    Widget? content,
    required List<Widget> actions,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AlertDialog(
            backgroundColor: const Color(0xFF2c3e50).withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(color: Colors.blueGrey.shade700, width: 2),
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: [Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1.0, 1.0))],
              ),
            ),
            content: content,
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            actions: actions,
          ),
        );
      },
    );
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _animationControllers.values.forEach((controller) => controller.dispose());
    _hintTimer?.cancel();
    _hintDisplayTimer?.cancel();
    _hintAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSpin() async {
    if (_reelKeys.any((key) => key.currentState?.isSpinning ?? true)) return;
    if (_remainingSpins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转动次数已用完，请使用刷新按钮重置！')),
      );
      return;
    }
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isButtonPressed = false);
      }
    });

    try {
      // 让每个转轮都执行 spin 动画
      List<Future<CollectionCard>> futures = _reelKeys.map((key) => key.currentState!.spin()).toList();
      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _spinCount++;
          _remainingSpins--;
        });
        _checkResult(results);
        _saveState();
      }
    } catch (e) {
      // No error logging
    }
  }

  void _resetProgress() async {
    setState(() {
      _spinCount = 0;
      _fragmentCount = 0;
      _remainingSpins = 100;
      // 重置所有卡牌的收集状态
      for (var card in _collection) {
        card.progress = 0;
      }
      _reelCardPools = List.generate(3, (_) {
        final pool = _currentTheme.cards.map((item) => item.clone()).toList();
        pool.shuffle();
        return pool;
      });
      _reelIndices = List.filled(3, 0);
      _updateReels();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('houseLevel_uk', 1);
    await prefs.setInt('fragmentCount', 0);
    await prefs.setInt('remainingSpins_${_currentTheme.name}', 100);
    // 清除所有卡牌的收集状态（包括所有主题下的卡牌进度）
    for (var card in _collection) {
      await prefs.setInt('card_${card.name}', 0); // 兼容旧数据
      await prefs.setInt('card_progress_${_currentTheme.name}_${card.name}', 0);
    }
    _initializeGame();
    _hasGivenAllCollectedReward = false;
    _saveState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已重置所有进度，房产等级恢复到1级，碎片和卡牌收集状态也已清零！')),
    );
  }

  void _checkResult(List<CollectionCard> results) {
    final resultNames = results.map((r) => r.name).toList();
    final counts = <String, int>{};
    for (var name in resultNames) {
      counts[name] = (counts[name] ?? 0) + 1;
    }

    // 找出出现次数最多的卡牌
    String? itemName;
    int matchCount = 0;
    counts.forEach((name, count) {
      if (count > matchCount) {
        itemName = name;
        matchCount = count;
      }
    });

    // 处理三个不同的情况
    if (matchCount == 1) {
      _triggerFragmentAnimationOverlay('三个不同', 3, onComplete: () {
        setState(() => _fragmentCount += 3);
        _saveState();
      }, showGainText: true);
      _playFragmentSound();
      return;
    }

    if (itemName == null || matchCount < 2) return;

    // 更新匹配状态
    setState(() {
      _matchedReels = List.generate(3, (index) => results[index].name == itemName);
    });

    // 设置匹配特效计时器
    _matchEffectTimer?.cancel();
    _matchEffectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _matchedReels = List.filled(3, false);
        });
        _updateReels();
      }
    });

    // 更新转轮状态
    _updateReels();

    // 检查是否为水晶骰子道具
    if (counts.containsKey('水晶骰子')) {
      final matchCount = counts['水晶骰子']!;
      final spinsToAdd = matchCount == 3 ? 100 : (matchCount == 2 ? 25 : 0);
      if (spinsToAdd > 0) {
        _triggerCrystalDiceEffect();
        setState(() {
          _remainingSpins += spinsToAdd;
          // 更新匹配状态
          _matchedReels = List.generate(3, (index) => results[index].name == '水晶骰子');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('水晶骰子发威！获得 $spinsToAdd 次转动机会！')),
        );
        _playMatch3Sound();
        _updateReels();
      }
      _saveState();
      // 不再return，继续判断普通奖励
    }

    // 检查是否为社交道具
    if (counts.containsKey('社交道具')) {
      final matchCount = counts['社交道具']!;
      if (matchCount >= 2) {
        setState(() {
          _matchedReels = List.generate(3, (index) => results[index].name == '社交道具');
        });
        _updateReels();
        _showFriendHouse();
      }
      // 不再return，继续判断普通奖励
    }

    // 处理匹配奖励
    final card = _collection.firstWhere((c) => c.name == itemName);
    final wasAlreadyCollected = card.isCollected;

    if (wasAlreadyCollected) {
      final fragmentGain = matchCount == 3 ? 50 : 10;
      _triggerFragmentAnimationOverlay(card.name, fragmentGain, onComplete: () {
        setState(() => _fragmentCount += fragmentGain);
        _saveState();
      }, showGainText: true);
      _playFragmentSound();
      if (matchCount == 3) {
        _playMatch3Sound();
        _triggerConfetti();
      }
    } else {
      setState(() {
        if (matchCount >= 2) {
          card.progress = min(4, card.progress + (matchCount == 3 ? 4 : 1));
        }
      });

      bool isNowCollected = card.isCollected;

      if (isNowCollected && !wasAlreadyCollected) {
        _animationControllers[card.name]?.forward().then((_) => _animationControllers[card.name]?.reverse());
        _playCollectionCompleteSound();
      } else if (!isNowCollected) {
        _animationControllers[card.name]?.forward().then((_) => _animationControllers[card.name]?.reverse());
        _playMatch2Sound();
      }

      if (matchCount == 3) {
        _playMatch3Sound();
        _triggerConfetti();
      }
    }

    _saveState();

    // 检查是否全部卡片收集完成，发放重大奖励
    final allCollected = _collection.every((c) => c.isCollected);
    if (allCollected && !_hasGivenAllCollectedReward) {
      _hasGivenAllCollectedReward = true;
      // 四角彩带
      _playCornerConfetti();
      // 奖励10000碎片，动画只播放100个粒子
      _triggerFragmentAnimationOverlay('全部集齐', 100, onComplete: () {
        setState(() => _fragmentCount += 10000);
        _saveState();
      }, showGainText: true);
      _playFragmentSound();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恭喜你集齐全部卡牌，获得10000碎片重大奖励！')),
      );
    }
  }

  void _showFriendHouse() async {
    final fragments = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SocialPage()),
    );
    if (fragments != null && fragments is int) {
      setState(() {
        _fragmentCount += fragments;
      });
    }
  }

  void _showHousePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => HousePage()),
    );
  }

  void _triggerConfetti() {
    setState(() {}); // 保留强制刷新UI
    _confettiController.play();
  }

  void _triggerFragmentAnimationOverlay(String sourceCardName, int count, {VoidCallback? onComplete, bool showGainText = true}) {
    final startKey = _slotMachineKey;
    final endKey = _fragmentCounterKey;
    if (startKey.currentContext == null || endKey.currentContext == null) {
      if (onComplete != null) onComplete();
      return;
    }

    final startRenderBox = startKey.currentContext!.findRenderObject() as RenderBox;
    final endRenderBox = endKey.currentContext!.findRenderObject() as RenderBox;

    final startGlobalCenter = startRenderBox.localToGlobal(
      Offset(startRenderBox.size.width / 2, startRenderBox.size.height / 2 - 100),
    );
    final endGlobalCenter = endRenderBox.localToGlobal(
      Offset(endRenderBox.size.width / 2, endRenderBox.size.height / 2),
    );

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    bool completed = false;
    entry = OverlayEntry(
      builder: (context) => _FragmentParticle(
        key: UniqueKey(),
        startPosition: startGlobalCenter,
        endPosition: endGlobalCenter,
        count: count,
        onCompleted: (key) {
          if (!completed) {
            completed = true;
            entry.remove();
            if (showGainText) {
              _showFragmentGain(count, onComplete: onComplete);
            } else {
              if (onComplete != null) onComplete();
            }
          }
        },
      ),
    );
    overlay.insert(entry);
  }

  void _showFragmentGain(int count, {VoidCallback? onComplete}) {
    final RenderBox? box = _fragmentCounterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      if (onComplete != null) onComplete();
      return;
    }
    
    // 获取计数器的全局位置，使用与碎片特效相同的偏移
    final globalPosition = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2 - 100)
    );

    // 获取Stack的RenderBox
    final RenderBox? stackBox = context.findAncestorRenderObjectOfType<RenderBox>();
    if (stackBox == null) {
      if (onComplete != null) onComplete();
      return;
    }

    // 将全局坐标转换为Stack中的局部坐标
    final localPosition = stackBox.globalToLocal(globalPosition);

    setState(() {
      _fragmentGainText = '+$count';
      _showingFragmentGain = true;
      _fragmentGainOffset = localPosition;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showingFragmentGain = false;
        });
        if (onComplete != null) onComplete();
      }
    });
  }

  void _changeTheme(String themeKey) {
    if (themes.containsKey(themeKey) && themes[themeKey]!.name != _currentTheme.name) {
      setState(() {
        _currentTheme = themes[themeKey]!;
        _reelCardPools = List.generate(3, (_) {
          final pool = _currentTheme.cards.map((item) => item.clone()).toList();
          pool.shuffle();
          return pool;
        });
        _reelIndices = List.filled(3, 0);
        _updateReels();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeGame();
      });
    }
  }

  void _cheatMatch(int matchCount) async {
    if (_reelKeys.any((key) => key.currentState?.isSpinning ?? true)) return;
    if (_collection.isEmpty) return;
    if (_remainingSpins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转动次数已用完，请使用刷新按钮重置！')),
      );
      return;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isButtonPressed = false);
      }
    });

    // 随机选择一张卡牌
    final random = Random();
    final targetCard = _collection[random.nextInt(_collection.length)];
    
    List<Future<CollectionCard>> futures = [];
    
    if (matchCount == 2) {
      // 2连：前两个轮子显示相同卡牌，第三个轮子随机
      futures.add(_reelKeys[0].currentState!.spinTo(targetCard.name));
      futures.add(_reelKeys[1].currentState!.spinTo(targetCard.name));
      futures.add(_reelKeys[2].currentState!.spin());
    } else {
      // 3连：所有轮子都显示相同的卡牌
      futures = _reelKeys.map((key) => key.currentState!.spinTo(targetCard.name)).toList();
    }
    
    try {
      final finalResults = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _spinCount++;
          _remainingSpins--;
        });
        _checkResult(finalResults);
        _saveState();
      }
    } catch (e) {
      // No error logging
    }
  }

  void _cheatProp(String propName, int matchCount) async {
    if (_reelKeys.any((key) => key.currentState?.isSpinning ?? true)) return;
    if (_remainingSpins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转动次数已用完，请使用刷新按钮重置！')),
      );
      return;
    }
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isButtonPressed = false);
      }
    });

    List<Future<CollectionCard>> futures = [];
    for (int i = 0; i < 3; i++) {
      if (i < matchCount) {
        futures.add(_reelKeys[i].currentState!.spinTo(propName));
      } else {
        futures.add(_reelKeys[i].currentState!.spin());
      }
    }

    try {
      final finalResults = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _spinCount++;
          _remainingSpins--;
        });
        _checkResult(finalResults);
        _saveState();
      }
    } catch (e) {}
  }

  void _triggerCrystalDiceEffect() {
    setState(() => _crystalDiceEffectVisible = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _crystalDiceEffectVisible = false);
    });
  }

  // endregion

  // region Audio
  Future<void> _playAudio(String assetName) => _audioPlayer.play(AssetSource('audio/$assetName'));
  Future<void> _playSpinStartSound() => _playAudio('spin_06531.wav');
  Future<void> _playMatch2Sound() => _playAudio('match2_06698.wav');
  Future<void> _playMatch3Sound() => _playAudio('match3__06304.wav');
  Future<void> _playFragmentSound() => _playAudio('get_card_shards_10302.wav');
  Future<void> _playCollectionCompleteSound() => _playAudio('collection_complete_11550.wav');
  // endregion

  // region UI Building
  @override
  Widget build(BuildContext context) {
    super.build(context); // 保活机制需要
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(),
            body: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              pageSnapping: true,
              dragStartBehavior: DragStartBehavior.down,
              onPageChanged: _onPageChanged,
              children: [
                // 老虎机页面（包含收藏区）
                Stack(
                  children: [
                    // 主要内容
                    Column(
                      children: [
                        Expanded(
                          child: _buildSlotMachineContent(),
                        ),
                      ],
                    ),
                    // 其他子组件
                    if (_isSlotMachineVisible) ...[
                      _buildSlotMachineOverlay(),
                    ],
                  ],
                ),
                // 我的房子页面
                const HousePage(),
              ],
            ),
          ),
          // 滚动提示浮层（底部居中）
          if (_showHintOverlay && _isSlotMachineVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _hintAnimController,
                      builder: (context, child) {
                        final double offsetY = 8 * (1 - _hintAnimController.value); // 上下浮动
                        final double opacity = 0.5 + 0.5 * _hintAnimController.value; // 透明度渐变
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
                                child: Icon(Icons.arrow_upward, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (!_hintHasShownOnce) const SizedBox(height: 8),
                    if (!_hintHasShownOnce)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          '上滑进入我的房子',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // ConfettiWidget始终在最顶层
          Positioned(
            left: 0,
            right: 0,
            bottom: 120, // 起点上移，视觉更靠近老虎机
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
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
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        themeChineseNames[_currentTheme.name] ?? _currentTheme.name,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
      actions: [
        _buildThemeSwitcher(),
      ],
    );
  }

  Widget _buildFragmentDisplay() {
    return Container(
      key: _fragmentCounterKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 18),
          const SizedBox(width: 4),
          Text(
            '$_fragmentCount',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  PopupMenuButton<String> _buildThemeSwitcher() {
    return PopupMenuButton<String>(
      tooltip: '切换主题',
      icon: Icon(Icons.palette_outlined, color: Colors.white),
      onSelected: _changeTheme,
      itemBuilder: (BuildContext context) {
        return themes.keys.map((String key) {
          return PopupMenuItem<String>(
            value: key,
            child: Text(themes[key]!.name),
          );
        }).toList();
      },
    );
  }

  Widget _buildSlotMachineContent() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const SizedBox(height: 8),
              _buildFragmentDisplay(),
              _buildSlotMachineContainer(),
              _buildSpinProgressBar(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: _buildSpinButton(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWideButton('重置', _buildResetButton()),
                  _buildWideButton('2连作弊', _buildMiniCheatButton('2连作弊', () => _cheatMatch(2), color: Colors.purple.shade700)),
                  _buildWideButton('3连作弊', _buildMiniCheatButton('3连作弊', () => _cheatMatch(3), color: Colors.orange.shade700)),
                  _buildWideButton('水晶作弊', _buildMiniCheatButton('水晶作弊', () => _cheatProp('水晶骰子', 2), color: Colors.blue.shade700)),
                  _buildWideButton('社交作弊', _buildMiniCheatButton('社交作弊', () => _cheatProp('社交道具', 2), color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _buildCollectionGrid(),
              ),
            ],
          ),
        ),
        // 添加水晶特效
        if (_crystalDiceEffectVisible)
          CrystalDiceEffect(
            count: 50,
            duration: const Duration(milliseconds: 1200),
            targetKey: _spinProgressKey, // 使用计数条的key作为目标点
            onCompleted: () {
              if (mounted) {
                setState(() => _crystalDiceEffectVisible = false);
              }
            },
          ),
        // 添加匹配特效
        if (_matchedReels.any((matched) => matched))
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.yellow.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlotMachineOverlay() {
    return Stack(
      children: [
        // 碎片获得动画
        if (_showingFragmentGain && _fragmentGainOffset != null)
          Positioned(
            left: _fragmentGainOffset!.dx,
            top: _fragmentGainOffset!.dy,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * value),
                  child: Opacity(
                    opacity: 1 - value,
                    child: Text(
                      _fragmentGainText,
                      style: TextStyle(
                        color: Colors.yellow.shade400,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                setState(() {
                  _fragmentGainOffset = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSpinProgressBar() {
    final progress = _remainingSpins / 100.0;
    return Container(
      key: _spinProgressKey,
      width: 90,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 1),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          Container(
            width: 90 * progress,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: LinearGradient(
                colors: progress > 0.3 ? [Colors.blue.shade600, Colors.blue.shade400] : [Colors.red.shade600, Colors.red.shade400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Center(
            child: Text(
              '$_remainingSpins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) {
        setState(() => _isButtonPressed = false);
        _onSpin();
      },
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedScale(
        scale: _reelKeys.any((key) => key.currentState?.isSpinning ?? false) ? 1.0 : (_isButtonPressed ? 0.9 : 1.0),
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: _reelKeys.any((key) => key.currentState?.isSpinning ?? false) ? 0.6 : 1.0,
          child: Container(
            width: 90,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF003688), Color(0xFF005EB8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '旋转',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(60, 30),
      ),
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF232323),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '确认重置',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '确定要重置所有进度吗？\n房产等级将恢复到1级，碎片和卡牌收集状态将被清零！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetProgress();
                        },
                        child: const Text('确定', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: const Text('重置', style: TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildCheatButtons() {
    return Column(
      children: [
        Row(
          children: [
            _buildMiniCheatButton('2连', () => _cheatMatch(2), color: Colors.purple.shade700),
            const SizedBox(width: 4),
            _buildMiniCheatButton('3连', () => _cheatMatch(3), color: Colors.orange.shade700),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildMiniCheatButton('水晶', () => _cheatProp('水晶骰子', 2), color: Colors.blue.shade700),
            const SizedBox(width: 4),
            _buildMiniCheatButton('社交', () => _cheatProp('社交道具', 2), color: Colors.green.shade700),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCheatButton(String text, VoidCallback onPressed, {Color? color}) {
    return SizedBox(
      width: 40,
      height: 22,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blueGrey.shade700,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.white)),
      ),
    );
  }

  Widget _buildCollectionGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      physics: const NeverScrollableScrollPhysics(),  // 禁用GridView的滚动
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _collection.length,
      itemBuilder: (context, index) {
        return _buildCollectionCard(_collection[index]);
      },
    );
  }

  Widget _buildCollectionCard(CollectionCard card) {
    final animation = _animations[card.name]!;
    final color = card.isCollected ? Colors.transparent : Colors.black.withOpacity(0.6);
    final borderColor = card.isCollected ? Colors.amber.shade600 : Colors.grey.shade700;
    final borderWidth = card.isCollected ? 2.5 : 1.5;

    return GestureDetector(
      onTap: () {
        _showStyledDialog(
          context: context,
          title: card.name,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 25, spreadRadius: 5)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/cards/${_currentTheme.assetPath}/${card.imagePath}',
                      fit: BoxFit.contain,
                      height: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 添加卡牌描述
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    cardDescriptions[card.imagePath] ?? '暂无描述',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 16),
                if (card.isCollected)
                  const Text('已集齐!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16))
                else
                  Column(
                    children: [
                      Text('收集进度: ${card.progress} / 4', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: card.progress / 4,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ],
                  )
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: borderWidth),
                borderRadius: BorderRadius.circular(10),
                boxShadow: card.isCollected
                    ? [
                  BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10, spreadRadius: 1),
                ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/cards/${_currentTheme.assetPath}/${card.imagePath}',
                      fit: BoxFit.cover,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: color,
                    ),
                    if (!card.isCollected)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                           mainAxisSize: MainAxisSize.min,
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              color: Colors.black.withOpacity(0.6),
                              child: Text(
                                card.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                ),
                              ),
                            ),
                            LinearProgressIndicator(
                              value: card.progress / 4,
                              backgroundColor: Colors.grey.shade800.withOpacity(0.8),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              minHeight: 6,
                            ),
                           ],
                        )
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotMachineContainer() {
    final boxDecoration = BoxDecoration(
      color: const Color(0xFF6B4F3A),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      border: Border.all(color: const Color(0xFF4A3525), width: 4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          spreadRadius: 2,
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
    final innerDecoration = BoxDecoration(
      color: const Color(0xFF4A3525),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      border: Border.all(color: const Color(0xFF2d1f14), width: 2),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: boxDecoration,
      child: DecoratedBox(
        decoration: innerDecoration,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            key: _slotMachineKey,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reels,
          ),
        ),
      ),
    );
  }

  Widget _buildWideButton(String label, Widget child, {Color? color}) {
    return SizedBox(
      width: 70,
      height: 36,
      child: child,
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _onPageChanged(int index) {
    setState(() {
      _isSlotMachineVisible = index == 0;
    });
  }

  // 四角彩带特效
  void _playCornerConfetti() {
    final overlay = Overlay.of(context);
    final List<Alignment> corners = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];
    for (final alignment in corners) {
      final controller = ConfettiController(duration: const Duration(seconds: 2));
      final entry = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: alignment,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.12,
                numberOfParticles: 40,
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
                  Colors.red,
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      );
      overlay.insert(entry);
      controller.play();
      Future.delayed(const Duration(seconds: 3), () {
        controller.dispose();
        entry.remove();
      });
    }
  }

  // endregion
}

// region SlotReel Widget
class SlotReel extends StatefulWidget {
  final List<CollectionCard> cardPool;
  final String themeAssetPath;
  final int selectedIndex;
  final bool isMatched;

  const SlotReel({
    Key? key,
    required this.cardPool,
    required this.themeAssetPath,
    required this.selectedIndex,
    required this.isMatched,
  }) : super(key: key);

  @override
  SlotReelState createState() => SlotReelState();
}

class SlotReelState extends State<SlotReel> with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  late List<CollectionCard> _shuffledPool;
  int _activeIndex = 0;
  bool isSpinning = false;
  
  CollectionCard get activeCard => _shuffledPool[_activeIndex];

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _updatePool();
  }
  
  @override
  void didUpdateWidget(SlotReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果卡牌池或主题路径发生变化，重新创建shuffled pool
    if (oldWidget.cardPool != widget.cardPool || 
        oldWidget.themeAssetPath != widget.themeAssetPath) {
      _updatePool();
    }
  }
  
  void _updatePool() {
    _shuffledPool = List.from(widget.cardPool)..shuffle();
    _activeIndex = 0;
  }
  
  Future<CollectionCard> spin() async {
    if (isSpinning) return activeCard;
    if (mounted) setState(() => isSpinning = true);
    
    final random = Random();
    final int targetPoolIndex = random.nextInt(_shuffledPool.length);

    final int currentLap = (_scrollController.selectedItem / _shuffledPool.length).floor();
    final int laps = 3 + random.nextInt(2);
    final int targetControllerIndex = (currentLap + laps) * _shuffledPool.length + targetPoolIndex;
    
    await _scrollController.animateToItem(
      targetControllerIndex,
      duration: Duration(milliseconds: 400 + random.nextInt(400)),
      curve: Curves.decelerate,
    );
    
    if (mounted) {
      setState(() {
        _activeIndex = targetPoolIndex;
        isSpinning = false;
      });
    }
    return _shuffledPool[targetPoolIndex];
  }

  Future<CollectionCard> spinTo(String itemName) async {
    if (isSpinning) return activeCard;
    if (mounted) setState(() => isSpinning = true);

    final int targetPoolIndex = _shuffledPool.indexWhere((item) => item.name == itemName);
    if (targetPoolIndex == -1) {
      return spin();
    }

    final int currentLap = (_scrollController.selectedItem / _shuffledPool.length).floor();
    final int laps = 2;
    final int targetControllerIndex = (currentLap + laps) * _shuffledPool.length + targetPoolIndex;

    await _scrollController.animateToItem(
      targetControllerIndex,
      duration: const Duration(milliseconds: 800),
      curve: Curves.decelerate,
    );

    if (mounted) {
      setState(() {
        _activeIndex = targetPoolIndex;
        isSpinning = false;
      });
    }
    return _shuffledPool[targetPoolIndex];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 120;
    return Container(
      width: 90,
      height: itemHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFDCCFBA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0A582), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: itemHeight,
              physics: const NeverScrollableScrollPhysics(),
              onSelectedItemChanged: (index) {
                if (!isSpinning && mounted) {
                  setState(() => _activeIndex = index % _shuffledPool.length);
                }
              },
              childDelegate: ListWheelChildLoopingListDelegate(
                children: List.generate(_shuffledPool.length, (i) {
                  final card = _shuffledPool[i];
                  return SizedBox(
                    height: itemHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          card.isProp 
                            ? 'assets/slot_item/${card.imagePath}'
                            : 'assets/cards/${widget.themeAssetPath}/${card.imagePath}',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// endregion

// region FragmentParticle Widget
class _FragmentParticle extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final int count;
  final void Function(Key) onCompleted;

  const _FragmentParticle({
    required Key key,
    required this.startPosition,
    required this.endPosition,
    required this.count,
    required this.onCompleted,
  }) : super(key: key);

  @override
  _FragmentParticleState createState() => _FragmentParticleState();
}

class _FragmentParticleState extends State<_FragmentParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<_ParticleData> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted(widget.key!);
      }
    });

    // 初始化粒子，数量由count参数决定
    _particles = List.generate(widget.count, (i) {
      // 随机分布在屏幕四周
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 200.0 + _random.nextDouble() * 100;
      final randomOffset = Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      );
      return _ParticleData(
        startPosition: widget.startPosition + randomOffset,
        controlPoint1: Offset(
          widget.startPosition.dx + (_random.nextDouble() - 0.5) * 300,
          widget.startPosition.dy - _random.nextDouble() * 200,
        ),
        controlPoint2: Offset(
          widget.endPosition.dx + (_random.nextDouble() - 0.5) * 100,
          widget.endPosition.dy + _random.nextDouble() * 100,
        ),
        endPosition: widget.endPosition,
        scale: 0.5 + _random.nextDouble() * 0.5,
        rotation: _random.nextDouble() * 2 * pi,
        opacity: 0.8 + _random.nextDouble() * 0.2,
      );
    });

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
        final t = _animation.value;
        return Stack(
          children: _particles.map((particle) {
            // 使用三次贝塞尔曲线计算位置
            final x = _cubicBezier(
              t,
              particle.startPosition.dx,
              particle.controlPoint1.dx,
              particle.controlPoint2.dx,
              particle.endPosition.dx,
            );
            final y = _cubicBezier(
              t,
              particle.startPosition.dy,
              particle.controlPoint1.dy,
              particle.controlPoint2.dy,
              particle.endPosition.dy,
            );

            // 计算缩放和旋转
            final scale = particle.scale * (1.0 + 0.2 * sin(t * pi));
            final rotation = particle.rotation + t * 2 * pi;
            final opacity = particle.opacity * (1.0 - t * 0.5);

            return Positioned(
              left: x - 10, // 居中偏移
              top: y - 10,  // 居中偏移
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      CupertinoIcons.staroflife_fill,
                      color: Colors.yellow.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 三次贝塞尔曲线计算
  double _cubicBezier(double t, double p0, double p1, double p2, double p3) {
    final oneMinusT = 1 - t;
    return oneMinusT * oneMinusT * oneMinusT * p0 +
           3 * oneMinusT * oneMinusT * t * p1 +
           3 * oneMinusT * t * t * p2 +
           t * t * t * p3;
  }
}

class _ParticleData {
  final Offset startPosition;
  final Offset controlPoint1;
  final Offset controlPoint2;
  final Offset endPosition;
  final double scale;
  final double rotation;
  final double opacity;

  _ParticleData({
    required this.startPosition,
    required this.controlPoint1,
    required this.controlPoint2,
    required this.endPosition,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });
}
// endregion 

// region CrystalDiceEffect Widget
class CrystalDiceEffect extends StatefulWidget {
  final int count;
  final Duration duration;
  final VoidCallback? onCompleted;
  final GlobalKey? targetKey;
  const CrystalDiceEffect({this.count = 50, this.duration = const Duration(milliseconds: 1200), this.onCompleted, this.targetKey, super.key});

  @override
  State<CrystalDiceEffect> createState() => _CrystalDiceEffectState();
}

class _CrystalDiceEffectState extends State<CrystalDiceEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<_ParticleData>? _particles;
  Offset? _targetCenter;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(() {
        if (widget.onCompleted != null) widget.onCompleted!();
      });

    // 延迟一帧以获取正确的目标位置（转换为动画Stack的局部坐标）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.targetKey?.currentContext != null && context.findRenderObject() is RenderBox) {
        final box = widget.targetKey!.currentContext!.findRenderObject() as RenderBox;
        final targetPosition = box.localToGlobal(Offset.zero);
        final targetSize = box.size;
        final globalCenter = Offset(
          targetPosition.dx + targetSize.width / 2,
          targetPosition.dy + targetSize.height / 2,
        );
        final stackBox = context.findRenderObject() as RenderBox;
        final localCenter = stackBox.globalToLocal(globalCenter);
        setState(() {
          _targetCenter = localCenter;
        });
      }
    });
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _initParticlesIfNeeded(Size size) {
    if (_particles != null) return;
    final center = Offset(size.width / 2, size.height / 2);
    _particles = List.generate(widget.count, (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 200.0 + _random.nextDouble() * 100;
      final randomOffset = Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      );
      final start = center + randomOffset;
      return _ParticleData(
        startPosition: start,
        controlPoint1: Offset(
          start.dx + (_random.nextDouble() - 0.5) * 300,
          start.dy - _random.nextDouble() * 200,
        ),
        controlPoint2: Offset(
          (_targetCenter?.dx ?? size.width - 40) + (_random.nextDouble() - 0.5) * 100,
          (_targetCenter?.dy ?? 40) + _random.nextDouble() * 100,
        ),
        endPosition: _targetCenter ?? Offset(size.width - 40, 40),
        scale: 0.7 + _random.nextDouble() * 0.8,
        rotation: _random.nextDouble() * 2 * pi,
        opacity: 0.7 + _random.nextDouble() * 0.3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _initParticlesIfNeeded(size);
    // 动态获取目标点（同样转换为局部坐标）
    Offset? dynamicTargetCenter;
    if (widget.targetKey?.currentContext != null && context.findRenderObject() is RenderBox) {
      final box = widget.targetKey!.currentContext!.findRenderObject() as RenderBox;
      final targetPosition = box.localToGlobal(Offset.zero);
      final targetSize = box.size;
      final globalCenter = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );
      final stackBox = context.findRenderObject() as RenderBox;
      dynamicTargetCenter = stackBox.globalToLocal(globalCenter);
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _animation.value;
          final target = dynamicTargetCenter ?? _targetCenter ?? Offset(size.width - 40, 40);
          return Stack(
            children: (_particles ?? []).map((particle) {
              final x = _cubicBezier(
                t,
                particle.startPosition.dx,
                particle.controlPoint1.dx,
                particle.controlPoint2.dx,
                target.dx,
              );
              final y = _cubicBezier(
                t,
                particle.startPosition.dy,
                particle.controlPoint1.dy,
                particle.controlPoint2.dy,
                target.dy,
              );
              final scale = particle.scale * (0.9 + 0.2 * sin(t * pi));
              final rotation = particle.rotation + t * 2 * pi;
              final opacity = particle.opacity * (1.0 - t * 0.5);
              return Positioned(
                left: x - 24,
                top: y - 24,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/slot_item/Crystal Dice.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  double _cubicBezier(double t, double p0, double p1, double p2, double p3) {
    final oneMinusT = 1 - t;
    return oneMinusT * oneMinusT * oneMinusT * p0 +
        3 * oneMinusT * oneMinusT * t * p1 +
        3 * oneMinusT * t * t * p2 +
        t * t * t * p3;
  }
}
// endregion 

// 添加手势轨迹绘制类
class SwipePathPainter extends CustomPainter {
  final double progress;
  final Color color;

  SwipePathPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final startY = size.height * 0.8;
    final endY = size.height * 0.2;

    // 绘制主轨迹
    path.moveTo(centerX, startY);
    path.quadraticBezierTo(
      centerX,
      startY - (endY - startY) * 0.5,
      centerX,
      endY,
    );

    // 绘制动态光点
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // 修改光点动画逻辑：从下向上滑动后消失
    if (progress < 0.5) { // 只在动画前半段显示光点
      final dotY = startY - (startY - endY) * (progress * 2);
      canvas.drawCircle(Offset(centerX, dotY), 4, dotPaint);
    }

    // 绘制轨迹
    canvas.drawPath(path, paint);

    // 绘制轨迹光晕效果
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(SwipePathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 