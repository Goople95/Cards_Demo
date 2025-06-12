import 'dart:math';

// 模拟游戏中的卡片收集模型
class SimulatedCardCollection {
  final Map<String, int> _progress = {};
  final int totalCards;

  SimulatedCardCollection(this.totalCards);

  void updateProgress(List<String> drawnCards) {
    final cardCounts = <String, int>{};
    for (final card in drawnCards) {
      cardCounts[card] = (cardCounts[card] ?? 0) + 1;
    }

    for (final entry in cardCounts.entries) {
      final cardName = entry.key;
      final count = entry.value;
      final currentProgress = _progress[cardName] ?? 0;

      if (count == 2) {
        _progress[cardName] = (currentProgress + 1).clamp(0, 4);
      } else if (count == 3) {
        _progress[cardName] = 4;
      }
    }
  }

  bool isAllCollected() {
    if (_progress.length < totalCards) return false;
    return _progress.values.every((p) => p >= 4);
  }
}

// 模拟单次游戏直到全部收集完成
int simulateSingleGame() {
  final cardPool = List.generate(9, (i) => 'card_$i');
  final collection = SimulatedCardCollection(cardPool.length);
  final rng = Random();
  int spinCount = 0;

  while (!collection.isAllCollected()) {
    spinCount++;
    // 模拟一次spin
    final drawnCards = List.generate(3, (_) => cardPool[rng.nextInt(cardPool.length)]);
    collection.updateProgress(drawnCards);
  }
  return spinCount;
}

// 主函数：运行多次模拟并输出统计结果
void main() {
  final numberOfSimulations = 10000;
  final results = <int>[];

  print('开始进行 $numberOfSimulations 次模拟...');

  for (int i = 0; i < numberOfSimulations; i++) {
    results.add(simulateSingleGame());
    if ((i + 1) % 1000 == 0) {
      print('已完成 ${(i + 1)} 次模拟...');
    }
  }

  results.sort();

  // 计算统计数据
  final averageSpins = results.reduce((a, b) => a + b) / numberOfSimulations;
  final medianSpins = results[(numberOfSimulations / 2).floor()];
  final p90Spins = results[(numberOfSimulations * 0.9).floor()];
  final minSpins = results.first;
  final maxSpins = results.last;

  print('\n--- 模拟结果分析 ---');
  print('总模拟次数: $numberOfSimulations');
  print('平均spin次数: ${averageSpins.toStringAsFixed(2)}');
  print('中位数spin次数: $medianSpins (意味着50%的玩家在此次数内完成)');
  print('90百分位spin次数: $p90Spins (意味着90%的玩家在此次数内完成)');
  print('最快完成次数 (欧皇): $minSpins');
  print('最慢完成次数 (非酋): $maxSpins');
  print('\n结论:');
  print('综合来看，一个普通玩家大概需要 ${averageSpins.round()} 次spin左右可以集齐全部9张卡片。');
  print('运气极好的玩家可能在 $minSpins 次左右就完成，而运气较差的玩家可能需要接近 $p90Spins 次。');
} 