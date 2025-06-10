import 'package:flutter/material.dart';
import 'dart:math';
import 'slot_reel.dart';

class SlotGamePage extends StatefulWidget {
  const SlotGamePage({super.key});

  @override
  State<SlotGamePage> createState() => _SlotGamePageState();
}

class _SlotGamePageState extends State<SlotGamePage> {
  final _rng = Random();                          // 持久随机器
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
      stoppedReels = 0; // 重置计数器
      draw = List.generate(3, (_) => pool[_rng.nextInt(pool.length)]);
    });
  }

  void _reelStopped() {
    stoppedReels++;
    if (stoppedReels >= 3) { // 只有当所有3个转轮都停止时才设置rolling为false
      setState(() {
        rolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🎰 Slot 抽卡 · 英国卡包')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('抽到的卡牌', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => SlotReel(
                    key: ValueKey('reel_${spinCount}_$i'),
                    cardPool: pool,
                    targetCard: draw[i],
                    imagePath: pics,
                    delay: Duration.zero,
                    onStopped: _reelStopped,
                  )),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: rolling ? null : spin, // 滚动时禁用按钮
              child: Text(rolling ? '🎰 滚动中...' : '🎲 点击抽卡'),
            ),
          ],
        ),
      );
}