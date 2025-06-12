import 'package:flutter/material.dart';
import 'dart:math';

class SlotReel extends StatefulWidget {
  final List<String> cardPool;
  final String targetCard;
  final Map<String, String> imagePath;
  final String assetPath;
  final Duration delay;
  final VoidCallback onStopped;
  final bool isSpinning;

  const SlotReel({
    Key? key,
    required this.cardPool,
    required this.targetCard,
    required this.imagePath,
    required this.assetPath,
    required this.delay,
    required this.onStopped,
    required this.isSpinning,
  }) : super(key: key);

  @override
  State<SlotReel> createState() => _SlotReelState();
}

class _SlotReelState extends State<SlotReel> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController();
    print('SlotReel initState for ${widget.targetCard}');

    // 在第一帧渲染后，立即跳转到初始卡片位置，无动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialIndex = widget.cardPool.indexOf(widget.targetCard);
        if (initialIndex != -1) {
          _ctrl.jumpToItem(initialIndex);
        }
      }
    });
  }

  @override
  void didUpdateWidget(SlotReel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 核心改动：只要父组件启动了 spin (isSpinning 变为 true)，就无条件触发滚动
    if (widget.isSpinning && !oldWidget.isSpinning) {
      print('SlotReel received spin command for card: ${widget.targetCard}, starting to spin.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(widget.targetCard);
      });
    }
  }

  void _scrollTo(String card) {
    if (!mounted) return;

    final targetIndex = widget.cardPool.indexOf(card);
    if (targetIndex == -1) {
      print('Error: Card "$card" not found in pool.');
      widget.onStopped();
      return;
    }

    // 为了制造旋转效果，计算一个较远的目标索引
    // 例如：旋转5圈，然后停在目标卡片上
    final loops = 5;
    final itemsLength = widget.cardPool.length;
    final currentIndex = _ctrl.selectedItem;
    // 计算从当前位置需要旋转多少个item
    final itemsToSpin = (loops * itemsLength) + targetIndex - (currentIndex % itemsLength);
    final targetItem = currentIndex + itemsToSpin;

    _ctrl.animateToItem(
      targetItem,
      duration: const Duration(milliseconds: 300), // 动画时长：从800ms -> 300ms (光速！)
      curve: Curves.easeOut, // 使用更快的缓动曲线
    ).then((_) {
      if (mounted) {
        print('SlotReel animation finished for $card.');
        widget.onStopped();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 100,
      child: ListWheelScrollView.useDelegate(
        controller: _ctrl,
        itemExtent: 90,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.005,
        useMagnifier: true,
        magnification: 1.1,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: widget.cardPool.map((card) {
            final imageName = widget.imagePath[card] ?? 'default.png';
            final imagePath = 'assets/${widget.assetPath}/$imageName';
            
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.brown.shade800.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  )
                ],
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}