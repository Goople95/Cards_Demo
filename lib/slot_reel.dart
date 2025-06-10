import 'package:flutter/material.dart';
import 'dart:math';

class SlotReel extends StatefulWidget {
  final List<String> cardPool;
  final String targetCard;
  final Map<String, String> imagePath;
  final Duration delay;
  final VoidCallback onStopped;

  const SlotReel({
    super.key,
    required this.cardPool,
    required this.targetCard,
    required this.imagePath,
    required this.delay,
    required this.onStopped,
  });

  @override
  State<SlotReel> createState() => _SlotReelState();
}

class _SlotReelState extends State<SlotReel> {
  late final FixedExtentScrollController _ctrl;
  late final Random _rng = Random();
  bool _isScrolling = false; // 添加滚动状态标记

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController();
  }

  @override
  void didUpdateWidget(covariant SlotReel old) {
    super.didUpdateWidget(old);
    if (old.targetCard != widget.targetCard && !_isScrolling) {
      _scrollTo(widget.targetCard);
    }
  }

  void _scrollTo(String card) async {
    if (_isScrolling) return; // 防止重复滚动
    
    _isScrolling = true;
    final target = widget.cardPool.indexOf(card);
    
    try {
      // 先滚到随机位置
      final randomStart = _rng.nextInt(widget.cardPool.length * 3) + widget.cardPool.length;
      await _ctrl.animateToItem(
        randomStart,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
      
      // 再滚到目标
      final targetItem = target + widget.cardPool.length * 5;
      await _ctrl.animateToItem(
        targetItem,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
      
      _isScrolling = false;
      widget.onStopped();
    } catch (e) {
      _isScrolling = false;
      // 如果动画被中断，仍然调用回调
      widget.onStopped();
    }
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
          perspective: .002,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: extended.length,
            builder: (_, i) {
              final card = extended[i];
              final img = widget.imagePath[card] ?? 'default.png';
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/cards/$img',
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported, size: 35)),
                  const SizedBox(height: 2),
                  Text(card, 
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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