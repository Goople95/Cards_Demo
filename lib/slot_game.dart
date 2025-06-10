import 'package:flutter/material.dart';
import 'dart:math';
import 'slot_reel.dart';
import 'collection_model.dart';
import 'collection_album.dart';

class SlotGamePage extends StatefulWidget {
  const SlotGamePage({super.key});

  @override
  State<SlotGamePage> createState() => _SlotGamePageState();
}

class _SlotGamePageState extends State<SlotGamePage> {
  final _rng = Random();
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

  late List<String> draw;
  bool rolling = false;
  int spinCount = 0;
  int stoppedReels = 0; // 记录已停止的转轮数量
  
  // 收集系统
  final CardCollection collection = CardCollection();
  String? lastResult; // 上次抽卡结果信息

  @override
  void initState() {
    super.initState();
    draw = List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
  }

  void spin() {
    if (rolling) return;
    setState(() {
      rolling = true;
      spinCount++;
      stoppedReels = 0; // 重置停止计数
      draw = List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
      
      // 调试信息：打印本次抽到的卡牌
      print('第${spinCount}次抽卡: ${draw.join(', ')}');
    });
  }

  void _reelStopped() {
    stoppedReels++;
    if (stoppedReels >= 3) { // 所有3个转轮都停止了
      // 更新收集进度
      collection.updateProgress(draw);
      
      // 生成结果信息
      _generateResultMessage();
      
      setState(() {
        rolling = false;
      });
    }
  }
  
  void _generateResultMessage() {
    final cardCounts = <String, int>{};
    for (final card in draw) {
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
        final progress = collection.getProgress(cardName);
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
    final stats = collection.getStats(pool);
    
    return Scaffold(
        appBar: AppBar(
          title: const Text('🎰 Slot 抽卡 · 英国卡包'),
          actions: [
            // 收集图册按钮
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CollectionAlbum(
                      collection: collection,
                      cardPool: pool,
                      cardImages: pics,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.collections_bookmark),
              tooltip: '收集图册',
            ),
            // 重置收集按钮
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('重置收集'),
                    content: const Text('确定要重置所有收集进度吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          collection.reset();
                          setState(() {
                            lastResult = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              tooltip: '重置收集',
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 收集统计信息
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('完成收集', '${stats.completed}/${stats.total}', Colors.green),
                  _buildStatColumn('总进度', '${stats.totalProgress}/${stats.maxProgress}', Colors.blue),
                  _buildStatColumn('完成度', '${(stats.completionRate * 100).toInt()}%', Colors.orange),
                ],
              ),
            ),
            
            const Text('抽到的卡牌', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => SlotReel(
                    key: ValueKey('reel_$i'),
                    cardPool: pool,
                    targetCard: draw[i],
                    imagePath: pics,
                    delay: Duration.zero,
                    onStopped: _reelStopped,
                    shouldSpin: rolling,
                  )),
            ),
            const SizedBox(height: 20),
            
            // 结果信息显示
            if (lastResult != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  lastResult!,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: rolling ? null : spin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(rolling ? '🎰 滚动中...' : '🎲 点击抽卡'),
            ),
          ],
        ),
      );
  }
  
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}