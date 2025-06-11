import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // 为滤镜效果导入
import 'slot_reel.dart';
import 'collection_model.dart';
import 'package:audioplayers/audioplayers.dart'; // 引入音效库
import 'dart:convert'; // 新增：用于Base64解码
import 'dart:typed_data'; // 新增：用于处理音频数据

// --- 新增：Base64编码的音效 (简化版) ---
const String _successSoundBase64 = 'UklGRk9vT18AV0FWRWZtdCAQAAAAAgABAIABAAgAAAABAAgAZGF0YQAAAAA=';

class SlotGamePage extends StatefulWidget {
  const SlotGamePage({super.key});

  @override
  State<SlotGamePage> createState() => _SlotGamePageState();
}

class _SlotGamePageState extends State<SlotGamePage> {
  final _rng = Random();
  final _collection = CardCollection();
  final List<String> pool = [
    '红衣哨兵', '下午茶三层盘', '伦敦眼门票',
    '查令十字街书店卡', '皇家乐手', '英超球票',
    '风笛手', '地铁报童', '双层巴士'
  ];
  final Map<String, String> pics = {
    '红衣哨兵': 'red_guard.png',
    '下午茶三层盘': 'afternoon_tea.png',
    '伦敦眼门票': 'london_eye.png',
    '查令十字街书店卡': 'bookstore.png',
    '皇家乐手': 'royal_musician.png',
    '英超球票': 'epl_ticket.png',
    '风笛手': 'bagpiper.png',
    '地铁报童': 'newsboy.png',
    '双层巴士': 'double_decker.png',
  };

  // 新增：卡片描述文案
  final _cardDescriptions = {
    '双层巴士': '伦敦街头的红色流动风景线 🚌。坐上上层的第一排，整个城市的脉搏仿佛都在你的脚下。下一站，是未知的惊喜还是熟悉的街角？ #LondonVibes',
    '皇家乐手': '高高的熊皮帽，庄严的红色制服 💂‍♂️。他们不只是仪仗队的守护者，更是日不落帝国历史的回响。嘘...仔细听，空气中仿佛还回荡着他们的鼓点与号角。 #RoyalGuard',
    '风笛手': '苏格兰高地的灵魂之声 🎶。那悠远苍凉的乐声，是山川的低语，是民族的骄傲。闭上眼，仿佛能看到穿着格子裙的乐手，在风中独自矗立。 #ScottishPride',
    '红衣哨兵': '他们是白金汉宫最忠诚的卫士，以纹丝不动和冷峻表情闻名于世。但别被外表骗了，这身鲜红的制服下，是一颗为女王跳动的心 ❤️。 #BuckinghamPalace',
    '伦敦眼门票': '一张通往天际的门票 🎡。在泰晤士河畔缓缓升起，将整个伦敦的壮丽景色尽收眼底。从国会大厦到圣保罗大教堂，每一个地标都变成了你眼中的星辰。 #LondonEye',
    '下午茶三层盘': '这不只是一顿点心，这是英伦生活的仪式感 🍰☕。司康、三明治、小蛋糕，从咸到甜，一层层品味时光的优雅。别忘了，小指要翘起来哦！ #AfternoonTea',
    '英超球票': '周末的呐喊，绿茵场的狂热 ⚽🔥！这张票是通往梦想剧场的凭证，是与成千上万球迷共享激情与心跳的约定。进球的瞬间，整个世界都为你沸腾！ #FootballIsLife',
    '查令十字街书店卡': '致敬所有爱书人的圣地 📖。在这里，时光放慢了脚步，每一本书都承载着一个世界。或许，你也能在这里找到那封寄往84号的信。 #CharingCrossRoad',
    '地铁报童': '“Mind the gap!” 🚇 在繁忙的伦敦地下铁，他们是流动的资讯站。一份报纸，连接着地上与地下的世界，也见证着无数行色匆匆的伦敦故事。 #TubeLife'
  };
  
  late List<String> _draw;
  bool _isRolling = false;
  int _spinCount = 0;
  int _stoppedReels = 0;
  
  String? lastResult; // 上次抽卡结果信息

  // --- 新增：特效与音效相关 ---
  final _audioPlayer = AudioPlayer();
  final Map<String, GlobalKey> _cardKeys = {}; // 用于追踪收藏区卡片的位置

  @override
  void initState() {
    super.initState();
    // 为每张卡片初始化一个GlobalKey
    for (var card in pool) {
      _cardKeys[card] = GlobalKey();
    }
    _draw = List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
    print('SlotGamePage initState: draw=${_draw.join(", ")}');
  }

  void spin() {
    if (_isRolling) {
      print('SlotGamePage spin: already rolling, skipping');
      return;
    }
    
    print('SlotGamePage spin: starting spin #$_spinCount');
    
    _stoppedReels = 0;
    
    try {
      final newDraw = List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
      print('SlotGamePage spin: new draw=${newDraw.join(", ")}');
      
      setState(() {
        _isRolling = true;
        _spinCount++;
        _draw = newDraw;
      });
    } catch (e) {
      print('SlotGamePage spin: error generating cards: $e');
      setState(() {
        _isRolling = false;
      });
    }
  }

  void _onReelStopped() {
    if (!mounted) return;
    
    _stoppedReels++;
    print('SlotGamePage _onReelStopped: A reel has stopped. Total stopped: $_stoppedReels');

    if (_stoppedReels >= 3) {
      print('SlotGamePage: All reels stopped. Updating collection and UI state.');
      
      _collection.updateProgress(_draw);

      final cardCounts = <String, int>{};
      for (final card in _draw) {
        cardCounts[card] = (cardCounts[card] ?? 0) + 1;
      }

      String? feedbackMessage;
      String? celebratedCard;
      for (final entry in cardCounts.entries) {
        if (entry.value >= 2) {
          celebratedCard = entry.key;
          if (entry.value == 3) {
            feedbackMessage = "恭喜！ '${entry.key}' 卡片收集完成！";
            break; 
          }
          if (entry.value == 2) {
            feedbackMessage = "太棒了！ '${entry.key}' 收集进度 +1";
          }
        }
      }

      if (feedbackMessage != null && mounted) {
        // --- 触发特效和音效 ---
        _playSuccessSound();
        _runCelebrationFX(celebratedCard!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedbackMessage),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }

      setState(() {
        _isRolling = false;
      });
    }
  }
  
  Future<void> _playSuccessSound() async {
    try {
      // 使用 Base64 字符串作为音源
      final bytes = base64Decode(_successSoundBase64);
      await _audioPlayer.play(BytesSource(bytes));
      print("Success sound played from Base64.");
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void _generateResultMessage() {
    final cardCounts = <String, int>{};
    for (final card in _draw) {
      cardCounts[card] = (cardCounts[card] ?? 0) + 1;
    }
    
    // 检查是否有收集进展
    final results = <String>[];
    for (final entry in cardCounts.entries) {
      final cardName = entry.key;
      final count = entry.value;
      
      if (count == 3) {
        results.add('🎉 ${cardName} 完成收集！');
      } else if (count == 2) {
        final progress = _collection.getProgress(cardName);
        results.add('✨ ${cardName} 获得进度 (${progress}/4)');
      }
    }
    
    if (results.isEmpty) {
      lastResult = '继续努力，寻找相同卡片！';
    } else {
      lastResult = results.join('\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('SlotGamePage build: rolling=$_isRolling, stoppedReels=$_stoppedReels');
    final stats = _collection.getStats(pool);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('伦敦印象抽卡机'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatsCard(stats),
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: SlotReel(
                      key: ValueKey('reel_$i'),
                      cardPool: pool,
                      targetCard: _draw[i],
                      imagePath: pics,
                      onStopped: _onReelStopped,
                      isSpinning: _isRolling,
                      delay: Duration.zero,
                    ),
                  )),
                ),
                
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isRolling ? null : spin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isRolling ? '🎰 滚动中...' : '🎲 点击抽卡'),
                ),
                const SizedBox(height: 20),
                _buildAllCardsProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(CollectionStats stats) {
    // We need to calculate inProgress and notStarted manually
    int notStarted = 0;
    for (var card in pool) {
      if (_collection.getProgress(card) == 0) {
        notStarted++;
      }
    }
    final int inProgress = stats.total - stats.completed - notStarted;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收集进度', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('已完成', stats.completed.toString()),
                _buildStatItem('进行中', inProgress.toString()),
                _buildStatItem('未开始', notStarted.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  
  Widget _buildAllCardsProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            '我的收藏册',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: pool.length,
          itemBuilder: (context, index) {
            final cardName = pool[index];
            final progress = _collection.getProgress(cardName);
            final imageFile = pics[cardName] ?? '';
            final description = _cardDescriptions[cardName] ?? '暂无描述';

            return GestureDetector(
              onTap: () => _showCardDetails(context, cardName, imageFile, description, progress),
              child: Opacity(
                opacity: progress > 0 ? 1.0 : 0.4,
                child: Card(
                  key: _cardKeys[cardName],
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey[200],
                          child: imageFile.isNotEmpty
                              ? Image.asset('assets/$imageFile', fit: BoxFit.cover)
                              : const Center(child: Text('?')),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          cardName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (progress < 4)
                        LinearProgressIndicator(
                          value: progress / 4,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        )
                      else
                        Container(
                          color: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: const Text('已集齐', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCardDetails(BuildContext context, String cardName, String imageFile, String description, int progress) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(cardName, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageFile.isNotEmpty)
                    Image.asset('assets/$imageFile', height: 150),
                  const SizedBox(height: 15),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '收集进度: $progress/4',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _runCelebrationFX(String cardName) {
    final targetKey = _cardKeys[cardName];
    if (targetKey == null || targetKey.currentContext == null) return;
  
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final target = targetKey.currentContext!.findRenderObject() as RenderBox?;

    if (overlay == null || target == null) return;

    final targetPosition = target.localToGlobal(Offset.zero, ancestor: overlay);
    final targetSize = target.size;

    final entry = OverlayEntry(builder: (context) {
      return Stack(
        children: List.generate(30, (index) {
          return _Particle(
            key: UniqueKey(),
            startTime: Duration(milliseconds: Random().nextInt(400)),
            startPosition: targetPosition + Offset(targetSize.width / 2, targetSize.height / 2),
            targetSize: targetSize,
          );
        }),
      );
    });

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }
}

class _Particle extends StatefulWidget {
  final Duration startTime;
  final Offset startPosition;
  final Size targetSize;
  
  const _Particle({super.key, required this.startTime, required this.startPosition, required this.targetSize});
  
  @override
  _ParticleState createState() => _ParticleState();
}

class _ParticleState extends State<_Particle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _endPosition;
  late Color _color;
  late double _size;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * 80 + 40;
    
    _endPosition = Offset(
      widget.startPosition.dx + cos(angle) * distance,
      widget.startPosition.dy + sin(angle) * distance,
    );
    _color = [Colors.yellow, Colors.orange, Colors.white, Colors.lightBlueAccent][random.nextInt(4)];
    _size = random.nextDouble() * 8 + 4;
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    
    Future.delayed(widget.startTime, () {
      if(mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final position = Offset.lerp(widget.startPosition, _endPosition, value)!;
        final opacity = 1.0 - value;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Opacity(
            opacity: opacity,
            child: Icon(Icons.star, color: _color, size: _size),
          ),
        );
      },
    );
  }
} 