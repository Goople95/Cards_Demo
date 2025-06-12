import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'models/collection_model.dart';
import 'models/theme_model.dart';

class SlotGamePage extends StatefulWidget {
  const SlotGamePage({super.key});

  @override
  State<SlotGamePage> createState() => _SlotGamePageState();
}

class _SlotGamePageState extends State<SlotGamePage> with TickerProviderStateMixin {
  // region State & Business Logic
  late List<SlotReel> _reels;
  late List<CollectionCard> _collection;
  late ThemeModel _currentTheme;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  int _spinCount = 0;
  int _fragmentCount = 0;

  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  bool _isButtonPressed = false;

  final GlobalKey _fragmentCounterKey = GlobalKey();
  final GlobalKey _slotMachineKey = GlobalKey();
  final List<Widget> _fragmentParticles = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _currentTheme = themes['uk']!;
    _initializeGame();
  }

  void _initializeGame() {
    _collection = _currentTheme.cards.map((e) => e.clone()).toList();
    _reels = List.generate(3, (index) => SlotReel(
      cardPool: _collection,
      themeAssetPath: _currentTheme.assetPath,
    ));
    _loadState();
    _collection.forEach(_setupAnimations);
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
      _fragmentCount = prefs.getInt('fragmentCount_${_currentTheme.name}') ?? 0;
      
      for (var card in _collection) {
        card.progress = prefs.getInt('card_progress_${_currentTheme.name}_${card.name}') ?? 0;
      }
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spinCount_${_currentTheme.name}', _spinCount);
    await prefs.setInt('fragmentCount_${_currentTheme.name}', _fragmentCount);
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _animationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onSpin() async {
    if (_reels.any((reel) => reel.isSpinning)) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _isButtonPressed = false));

    final futures = _reels.map((reel) => reel.spin());
    final List<CollectionCard> finalResults = await Future.wait(futures);

    setState(() => _spinCount++);
    _checkResult(finalResults);
    _saveState();
  }

  void _cheat(String cardName) {
    if (_reels.any((reel) => reel.isSpinning)) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _isButtonPressed = false));

    final futures = _reels.map((reel) => reel.spinTo(cardName));
    Future.wait(futures).then((finalResults) {
      setState(() => _spinCount++);
      _checkResult(finalResults);
      _saveState();
    });
  }

  void _resetProgress() {
    setState(() {
      _spinCount = 0;
      _fragmentCount = 0;
      for (var card in _collection) {
        card.progress = 0;
      }
    });
    _saveState();
  }

  void _checkResult(List<CollectionCard> results) {
    final resultNames = results.map((r) => r.name).toList();
    final counts = <String, int>{};
    for (var name in resultNames) {
      counts[name] = (counts[name] ?? 0) + 1;
    }

    if (counts.containsValue(3)) {
      final matchedCardName = counts.keys.firstWhere((k) => counts[k] == 3);
      _handleMatch(matchedCardName, 3);
    } else if (counts.containsValue(2)) {
      final matchedCardName = counts.keys.firstWhere((k) => counts[k] == 2);
      _handleMatch(matchedCardName, 2);
    }
  }

  void _handleMatch(String cardName, int matchCount) {
    final card = _collection.firstWhere((c) => c.name == cardName);
    bool wasAlreadyCollected = card.isCollected;

    if (wasAlreadyCollected) {
      final fragmentGain = matchCount == 3 ? 3 : 1;
      setState(() => _fragmentCount += fragmentGain);
      _triggerFragmentAnimation(card.name, fragmentGain);
      _playFragmentSound();
    } else {
      setState(() {
        if (matchCount >= 2) { // Both 2 and 3 matches give progress
            card.progress = min(4, card.progress + (matchCount == 3 ? 4 : 1) );
        }
      });

      bool isNowCollected = card.isCollected;

      if (isNowCollected && !wasAlreadyCollected) {
        // Just completed a card
        _animationControllers[card.name]?.forward().then((_) => _animationControllers[card.name]?.reverse());
        _playCollectionCompleteSound(); // New, distinct sound
      } else if (!isNowCollected) {
        // Made progress, but not completed yet (2-match)
        _animationControllers[card.name]?.forward().then((_) => _animationControllers[card.name]?.reverse());
        _playMatch2Sound();
      }

      // Confetti and 3-match sound ONLY for a true 3-of-a-kind roll.
      if (matchCount == 3) {
        _playMatch3Sound();
        _triggerConfetti();
      }
    }
    _saveState(); // Save state after any change
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  void _triggerFragmentAnimation(String sourceCardName, int count) {
    final startKey = _slotMachineKey;
    final endKey = _fragmentCounterKey;
    if (startKey.currentContext == null || endKey.currentContext == null) return;

    final startRenderBox = startKey.currentContext!.findRenderObject() as RenderBox;
    final endRenderBox = endKey.currentContext!.findRenderObject() as RenderBox;

    // 从老虎机中央位置开始，飞到右上角碎片计数器
    final startPosition = startRenderBox.localToGlobal(startRenderBox.size.center(Offset.zero));
    final endPosition = endRenderBox.localToGlobal(endRenderBox.size.center(Offset.zero));

    for (int i = 0; i < count + 2; i++) {
      final particle = _FragmentParticle(
        key: UniqueKey(),
        startPosition: startPosition,
        endPosition: endPosition,
        onCompleted: (key) => setState(() => _fragmentParticles.removeWhere((p) => p.key == key)),
      );
      setState(() => _fragmentParticles.add(particle));
    }
  }

  void _changeTheme(String themeKey) {
    if (themes.containsKey(themeKey) && themes[themeKey]!.name != _currentTheme.name) {
      setState(() {
        _currentTheme = themes[themeKey]!;
        _initializeGame();
      });
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFF1a2b3c),
      appBar: _buildAppBar(),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _buildSlotMachineContainer(),
                    const SizedBox(height: 20),
                    _buildSpinWidgets(),
                    const SizedBox(height: 24),
                    _buildCollectionGrid(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            maxBlastForce: 25,
            minBlastForce: 10,
          ),
          ..._fragmentParticles,
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        '英国印象',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
      actions: [
        _buildFragmentCounter(),
        _buildThemeSwitcher(),
      ],
    );
  }

  Widget _buildFragmentCounter() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        child: Container(
          key: _fragmentCounterKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade700),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                '$_fragmentCount 碎片',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
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

  Widget _buildSpinWidgets() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                _buildCounterColumn('Spin次数', '$_spinCount'),
                const SizedBox(height: 8),
                _buildResetButton(),
              ],
            ),
            _buildSpinButton(),
            Column(
              children: [
                _buildCheatButton('随机2连', () => _cheatMatch(2)),
                const SizedBox(height: 8),
                _buildCheatButton('随机3连', () => _cheatMatch(3)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ],
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
        scale: _reels.any((r) => r.isSpinning) ? 1.0 : (_isButtonPressed ? 0.9 : 1.0),
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: _reels.any((r) => r.isSpinning) ? 0.6 : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF003688),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF003688), Color(0xFF005EB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Container(
                height: 35,
                width: 90,
                color: const Color(0xFFD42A2F),
              ),
              const Text(
                '开始',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ],
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
            '将清除当前主题的所有卡牌和碎片进度，确定吗?',
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

  Widget _buildCheatButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(60, 30),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _cheatMatch(int matchCount) async {
    if (_reels.any((r) => r.isSpinning)) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    _playSpinStartSound();
    setState(() => _isButtonPressed = true);
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _isButtonPressed = false));

    // 随机选择一张卡牌
    final random = Random();
    final targetCard = _collection[random.nextInt(_collection.length)];
    
    List<Future<CollectionCard>> futures = [];
    
    if (matchCount == 2) {
      // 2连：前两个轮子显示相同卡牌，第三个轮子随机
      futures.add(_reels[0].spinTo(targetCard.name));
      futures.add(_reels[1].spinTo(targetCard.name));
      futures.add(_reels[2].spin()); // 第三个轮子随机
    } else {
      // 3连：所有轮子都显示相同的卡牌
      futures = _reels.map((reel) => reel.spinTo(targetCard.name)).toList();
    }
    
    final finalResults = await Future.wait(futures);
    
    setState(() => _spinCount++);
    _checkResult(finalResults);
    _saveState();
  }

  Widget _buildCollectionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85, // 增加高度比例，让卡牌更紧凑
      ),
      itemCount: _collection.length,
      itemBuilder: (context, index) {
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


// endregion
}

// region SlotReel Widget
class SlotReel extends StatefulWidget {
  final List<CollectionCard> cardPool;
  late final List<CollectionCard> shuffledPool;
  final String themeAssetPath;
  final int spinDuration;

  SlotReel({
    Key? key,
    required this.cardPool,
    required this.themeAssetPath,
    this.spinDuration = 400,
  }) : super(key: key) {
    shuffledPool = (List.from(cardPool)..shuffle()).cast<CollectionCard>();
  }

  late final _SlotReelState state = _SlotReelState();

  Future<CollectionCard> spin() => state.spin();
  Future<CollectionCard> spinTo(String cardName) => state.spinTo(cardName);
  CollectionCard get activeCard => state.activeCard;
  bool get isSpinning => state.isSpinning;

  @override
  _SlotReelState createState() => state;
}

class _SlotReelState extends State<SlotReel> with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  int _activeIndex = 0;
  bool isSpinning = false;
  
  CollectionCard get activeCard => widget.shuffledPool[_activeIndex];

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
  }
  
  Future<CollectionCard> spin() async {
    if (isSpinning) return activeCard;
    if (mounted) setState(() => isSpinning = true);
    
    final random = Random();
    final int targetPoolIndex = random.nextInt(widget.shuffledPool.length);

    final int currentLap = (_scrollController.selectedItem / widget.shuffledPool.length).floor();
    final int laps = 3 + random.nextInt(2);
    final int targetControllerIndex = (currentLap + laps) * widget.shuffledPool.length + targetPoolIndex;
    
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
    return widget.shuffledPool[targetPoolIndex];
  }

  Future<CollectionCard> spinTo(String cardName) async {
    if (isSpinning) return activeCard;
    if (mounted) setState(() => isSpinning = true);

    final int targetPoolIndex = widget.shuffledPool.indexWhere((c) => c.name == cardName);
    if (targetPoolIndex == -1) {
      return spin();
    }

    final int currentLap = (_scrollController.selectedItem / widget.shuffledPool.length).floor();
    final int laps = 2;
    final int targetControllerIndex = (currentLap + laps) * widget.shuffledPool.length + targetPoolIndex;

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
    return widget.shuffledPool[targetPoolIndex];
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
                if (!isSpinning) {
                  setState(() => _activeIndex = index % widget.shuffledPool.length);
                }
              },
              childDelegate: ListWheelChildLoopingListDelegate(
                children: List.generate(widget.shuffledPool.length, (i) {
                  final card = widget.shuffledPool[i];
                  return SizedBox(
                    height: itemHeight,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/cards/${widget.themeAssetPath}/${card.imagePath}',
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
  final void Function(Key) onCompleted;

  const _FragmentParticle({
    required Key key,
    required this.startPosition,
    required this.endPosition,
    required this.onCompleted,
  }) : super(key: key);

  @override
  _FragmentParticleState createState() => _FragmentParticleState();
}

class _FragmentParticleState extends State<_FragmentParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _controlPoint;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800 + Random().nextInt(400)),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted(widget.key!);
      }
    });

    final random = Random();
    final controlX = lerpDouble(widget.startPosition.dx, widget.endPosition.dx, 0.5)! + (random.nextDouble() - 0.5) * 200;
    final controlY = lerpDouble(widget.startPosition.dy, widget.endPosition.dy, 0.2)! - random.nextDouble() * 150;
    _controlPoint = Offset(controlX, controlY);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    
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
        if (_controller.isAnimating) {
          final t = _animation.value;
          final p0 = widget.startPosition;
          final p1 = _controlPoint;
          final p2 = widget.endPosition;
          final x = pow(1 - t, 2) * p0.dx + 2 * (1 - t) * t * p1.dx + pow(t, 2) * p2.dx;
          final y = pow(1 - t, 2) * p0.dy + 2 * (1 - t) * t * p1.dy + pow(t, 2) * p2.dy;

          return Positioned(
            left: x,
            top: y,
            child: Icon(CupertinoIcons.staroflife_fill, color: Colors.yellow.shade700, size: 20),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
// endregion 
// endregion 