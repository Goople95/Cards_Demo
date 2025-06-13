import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'models/theme_model.dart';
import 'house_page.dart';
import 'social_page.dart';

class SlotGamePage extends StatefulWidget {
  const SlotGamePage({super.key});

  @override
  State<SlotGamePage> createState() => _SlotGamePageState();
}

class _SlotGamePageState extends State<SlotGamePage> with TickerProviderStateMixin {
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

  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  final GlobalKey _slotMachineKey = GlobalKey(debugLabel: 'slotMachine');
  final GlobalKey _fragmentCounterKey = GlobalKey(debugLabel: 'fragmentCounter');
  final GlobalKey _spinProgressKey = GlobalKey(debugLabel: 'spinProgress');
  Offset? _fragmentGainOffset;

  bool _crystalDiceEffectVisible = false;
  late AnimationController _hintAnimController;

  // 自动浮层提示相关
  bool _showHintOverlay = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _currentTheme = themes['uk']!;
    _initializeGame();
    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _startHintTimer();
  }

  void _initializeGame() {
    // 清理旧的动画控制器
    _animationControllers.values.forEach((controller) => controller.dispose());
    _animationControllers.clear();
    _animations.clear();
    
    // 重新初始化集合和转轮（只包含卡牌，不包含道具）
    _collection = _currentTheme.cards.where((c) => !c.isProp).map((e) => e.clone()).toList();
    
    // 创建新的GlobalKey列表，确保每个key都是唯一的
    _reelKeys = List.generate(3, (index) => GlobalKey<SlotReelState>(debugLabel: 'reel_$index'));
    
    // 老虎机使用所有物品（包括道具）
    _reels = List.generate(3, (index) => SlotReel(
      key: _reelKeys[index],
      cardPool: _currentTheme.cards.map((item) => item.clone()).toList(),
      themeAssetPath: _currentTheme.assetPath,
    ));
    
    // 为新的卡牌设置动画
    _collection.forEach(_setupAnimations);
    
    // 加载状态
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

  Future<void> _loadState() async {
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

  void _startHintTimer() {
    _hintTimer?.cancel();
    setState(() => _showHintOverlay = false);
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showHintOverlay = true);
        _hintAnimController.repeat(reverse: true);
      }
    });
  }

  void _onUserInteraction() {
    if (_showHintOverlay) setState(() => _showHintOverlay = false);
    _hintAnimController.stop();
    _startHintTimer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _animationControllers.values.forEach((controller) => controller.dispose());
    _hintTimer?.cancel();
    _hintAnimController.dispose();
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
      final futures = _reelKeys.map((key) => key.currentState!.spin());
      final List<CollectionCard> finalResults = await Future.wait(futures);

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

  void _resetProgress() async {
    setState(() {
      _spinCount = 0;
      _fragmentCount = 0;
      _remainingSpins = 100;
      for (var card in _collection) {
        card.progress = 0;
      }
    });
    // 清除房产等级和碎片
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('house_level_${_currentTheme.name}', 1);
    await prefs.setInt('fragmentCount', 0);
    _saveState();
    // 弹窗提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已重置所有进度，房产等级和碎片也已清零！')),
    );
  }

  void _checkResult(List<CollectionCard> results) {
    final resultNames = results.map((r) => r.name).toList();
    final counts = <String, int>{};
    for (var name in resultNames) {
      counts[name] = (counts[name] ?? 0) + 1;
    }

    if (counts.containsValue(3)) {
      final matchedItemName = counts.keys.firstWhere((k) => counts[k] == 3);
      _handleMatch(matchedItemName, 3);
    } else if (counts.containsValue(2)) {
      final matchedItemName = counts.keys.firstWhere((k) => counts[k] == 2);
      _handleMatch(matchedItemName, 2);
    } else {
      // 三个不同的情况，奖励+3
      _triggerFragmentAnimationOverlay('三个不同', 3, onComplete: () {
        setState(() => _fragmentCount += 3);
        _saveState();
      }, showGainText: true);
      _playFragmentSound();
    }
  }

  void _handleMatch(String itemName, int matchCount) {
    // 检查是否为水晶骰子道具
    if (itemName == '水晶骰子') {
      final spinsToAdd = matchCount == 3 ? 100 : (matchCount == 2 ? 25 : 0);
      if (spinsToAdd > 0) {
        _triggerCrystalDiceEffect();
        setState(() => _remainingSpins += spinsToAdd);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('水晶骰子发威！获得 $spinsToAdd 次转动机会！')),
        );
        _playMatch3Sound(); // 播放特殊音效
        _triggerConfetti();
      }
      _saveState();
      return;
    }
    // 新增：社交道具逻辑
    if (itemName == '社交道具') {
      _showFriendHouse();
      return;
    }

    // 原有卡牌逻辑
    CollectionCard? card;
    try {
      card = _collection.firstWhere((c) => c.name == itemName);
    } catch (e) {
      return; // 如果找不到对应卡牌，直接返回
    }

    bool wasAlreadyCollected = card!.isCollected;

    if (wasAlreadyCollected) {
      // 已收集齐的重复碎片奖励：2连=10，3连=50
      final fragmentGain = matchCount == 3 ? 50 : 10;
      _triggerFragmentAnimationOverlay(card!.name, fragmentGain, onComplete: () {
        setState(() => _fragmentCount += fragmentGain);
        _saveState();
      }, showGainText: true);
      _playFragmentSound();
    } else {
      setState(() {
        if (matchCount >= 2) {
          card!.progress = min(4, card!.progress + (matchCount == 3 ? 4 : 1));
        }
      });

      bool isNowCollected = card!.isCollected;

      if (isNowCollected && !wasAlreadyCollected) {
        _animationControllers[card!.name]?.forward().then((_) => _animationControllers[card!.name]?.reverse());
        _playCollectionCompleteSound();
      } else if (!isNowCollected) {
        _animationControllers[card!.name]?.forward().then((_) => _animationControllers[card!.name]?.reverse());
        _playMatch2Sound();
      }

      if (matchCount == 3) {
        _playMatch3Sound();
        _triggerConfetti();
      }
    }
    _saveState();
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
    _confettiController.play();
  }

  void _triggerFragmentAnimationOverlay(String sourceCardName, int count, {VoidCallback? onComplete, bool showGainText = true}) {
    final startKey = _slotMachineKey;
    final endKey = _fragmentCounterKey;
    debugPrint('触发碎片特效: sourceCardName=$sourceCardName, count=$count');
    debugPrint('startKey.currentContext: [33m[1m${startKey.currentContext}[0m');
    debugPrint('endKey.currentContext: [33m[1m${endKey.currentContext}[0m');
    if (startKey.currentContext == null || endKey.currentContext == null) {
      debugPrint('碎片特效未触发：startKey或endKey的context为null');
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

    debugPrint('startGlobalCenter: $startGlobalCenter, endGlobalCenter: $endGlobalCenter');

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
    debugPrint('计数器全局位置: $globalPosition');

    // 获取Stack的RenderBox
    final RenderBox? stackBox = context.findAncestorRenderObjectOfType<RenderBox>();
    if (stackBox == null) {
      if (onComplete != null) onComplete();
      return;
    }

    // 将全局坐标转换为Stack中的局部坐标
    final localPosition = stackBox.globalToLocal(globalPosition);
    debugPrint('Stack局部坐标: $localPosition');

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
      // 先清除当前状态
      setState(() {
        _currentTheme = themes[themeKey]!;
      });
      
      // 异步重新初始化游戏，确保UI更新后再进行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeGame();
      });
    }
  }

  void _cheatMatch(int matchCount) async {
    if (_reelKeys.any((key) => key.currentState?.isSpinning ?? true)) return;
    if (_collection.isEmpty) return; // 确保集合已初始化
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
      futures.add(_reelKeys[2].currentState!.spin()); // 第三个轮子随机
    } else {
      // 3连：所有轮子都显示相同的卡牌
      futures = _reelKeys.map((key) => key.currentState!.spinTo(targetCard.name)).toList();
    }
    
    try {
      final finalResults = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _spinCount++;
          _remainingSpins--; // 作弊也消耗转动次数
        });
        _checkResult(finalResults);
        _saveState();
      }
    } catch (e) {
      // No error logging
    }
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          debugPrint('GridView滑动开始 - 位置: ${notification.metrics.pixels}');
          _onUserInteraction();
        } else if (notification is ScrollUpdateNotification) {
          debugPrint('GridView滑动中 - 位置: ${notification.metrics.pixels}, 增量: ${notification.scrollDelta}');
        } else if (notification is ScrollEndNotification) {
          debugPrint('GridView滑动结束 - 位置: ${notification.metrics.pixels}');
          // 如果是向上滑动
          if (notification.metrics.pixels > notification.metrics.minScrollExtent) {
            debugPrint('向上滑动结束，显示老虎机');
            if (mounted) {
              setState(() {
                // 这里可以添加任何需要的状态更新
              });
            }
          }
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              // 主要内容
              Column(
                children: [
                  Expanded(
                    child: _buildSlotMachine(),
                  ),
                ],
              ),
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
              ),
              // 自动浮层提示
              if (_showHintOverlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: AnimatedBuilder(
                          animation: _hintAnimController,
                          builder: (context, child) {
                            final t = _hintAnimController.value;
                            final scale = 1.0 + 0.2 * sin(t * pi);
                            final opacity = 0.3 + 0.7 * sin(t * pi);
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white.withOpacity(opacity),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    '上滑查看我的房子',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _buildSlotMachine() {
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
                  _buildWideButton('重置', _buildResetButton(), color: Colors.red.shade800),
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
      ],
    );
  }

  Widget _buildTopBar() {
    return AppBar(
      title: Text(
        themeChineseNames[_currentTheme.name] ?? _currentTheme.name,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
      actions: [
        _buildThemeSwitcher(), // 只保留主题切换按钮
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
        _showStyledDialog(
          context: context,
          title: '重置进度?',
          content: const Text(
            '将清除当前主题的所有卡牌和碎片进度，并重置转动次数到100次，确定吗?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _resetProgress();
                Navigator.of(context).pop();
              },
              child: const Text('重置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
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
    debugPrint('构建收藏网格 - 卡片数量: ${_collection.length}');
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _collection.length,
      itemBuilder: (context, index) {
        debugPrint('构建卡片 $index');
        final card = _collection[index];
        return _buildCard(card);
      },
    );
  }

  Widget _buildCard(CollectionCard card) {
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

  // 新增作弊道具方法
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
            children: List.generate(3, (i) => _reels[i]),
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

  // endregion
}

// region SlotReel Widget
class SlotReel extends StatefulWidget {
  final List<CollectionCard> cardPool;
  final String themeAssetPath;
  final int spinDuration;

  const SlotReel({
    Key? key,
    required this.cardPool,
    required this.themeAssetPath,
    this.spinDuration = 400,
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
      duration: Duration(milliseconds: widget.spinDuration + random.nextInt(400)),
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
  late List<_ParticleData> _particles;
  Offset? _targetCenter;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(() {
        if (widget.onCompleted != null) widget.onCompleted!();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.targetKey?.currentContext != null) {
        final box = widget.targetKey!.currentContext!.findRenderObject() as RenderBox;
        final center = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
        setState(() => _targetCenter = center);
      }
    });
    // 初始化粒子，数量由count参数决定
    final size = WidgetsBinding.instance.window.physicalSize / WidgetsBinding.instance.window.devicePixelRatio;
    _particles = List.generate(widget.count, (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 200.0 + _random.nextDouble() * 100;
      final randomOffset = Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      );
      final start = Offset(size.width / 2, size.height / 2) + randomOffset;
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
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 动态获取目标点
    Offset? dynamicTargetCenter;
    if (widget.targetKey?.currentContext != null) {
      final box = widget.targetKey!.currentContext!.findRenderObject() as RenderBox;
      dynamicTargetCenter = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _animation.value;
          final target = dynamicTargetCenter ?? _targetCenter ?? Offset(size.width - 40, 40);
          return Stack(
            children: _particles.map((particle) {
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