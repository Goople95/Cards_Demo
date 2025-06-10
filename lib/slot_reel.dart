import 'package:flutter/material.dart';
import 'dart:math';

class SlotReel extends StatefulWidget {
  final List<String> cardPool;
  final String targetCard;
  final Map<String, String> imagePath;
  final Duration delay;
  final VoidCallback onStopped;
  final bool shouldSpin; // 新增：是否应该开始滚动

  const SlotReel({
    super.key,
    required this.cardPool,
    required this.targetCard,
    required this.imagePath,
    required this.delay,
    required this.onStopped,
    required this.shouldSpin,
  });

  @override
  State<SlotReel> createState() => _SlotReelState();
}

class _SlotReelState extends State<SlotReel> {
  late final FixedExtentScrollController _ctrl;
  late final Random _rng = Random();
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    // 初始位置设置为一个中间位置，避免边界问题
    final initialPos = widget.cardPool.length * 2;
    _ctrl = FixedExtentScrollController(initialItem: initialPos);
  }

  @override
  void didUpdateWidget(covariant SlotReel old) {
    super.didUpdateWidget(old);
    
    // 当 shouldSpin 从 false 变为 true 时开始滚动
    if (!old.shouldSpin && widget.shouldSpin && !_isSpinning) {
      _scrollTo(widget.targetCard);
    }
  }

  void _scrollTo(String card) async {
    if (_isSpinning) return;
    
    setState(() {
      _isSpinning = true;
    });

    final targetIndex = widget.cardPool.indexOf(card);
    if (targetIndex == -1) {
      setState(() {
        _isSpinning = false;
      });
      widget.onStopped();
      return;
    }
    
    // 计算在扩展列表中的多个可能位置，选择一个靠后的位置
    final possibleTargets = <int>[];
    for (int cycle = 0; cycle < 30 ~/ widget.cardPool.length; cycle++) {
      possibleTargets.add(targetIndex + cycle * widget.cardPool.length);
    }
    
    // 选择一个靠后但不是最后的位置作为目标
    final finalTarget = possibleTargets[possibleTargets.length - 2];
    
    try {
      // 先快速滚动一段距离创造效果
      final currentPos = _ctrl.selectedItem;
      final spinDistance = _rng.nextInt(20) + 15; // 15-35的随机距离
      final tempTarget = currentPos + spinDistance;
      
      await _ctrl.animateToItem(
        tempTarget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // 然后滚到真正的目标位置
      await _ctrl.animateToItem(
        finalTarget,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      print('Animation error: $e');
    }
    
    setState(() {
      _isSpinning = false;
    });
    
    widget.onStopped();
  }

  @override
  Widget build(BuildContext context) {
    final extended = List.generate(
        30, (i) => widget.cardPool[i % widget.cardPool.length]);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 100,
        height: 140,
        child: ListWheelScrollView.useDelegate(
          controller: _ctrl,
          itemExtent: 100,
          physics: const NeverScrollableScrollPhysics(),
          perspective: 0.002,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: extended.length,
            builder: (_, i) {
              final card = extended[i];
              final img = widget.imagePath[card] ?? 'default.png';
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/cards/$img',
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 35),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}