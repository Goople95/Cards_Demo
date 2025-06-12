import 'dart:convert';

// 收集进度模型
class CardCollection {
  final Map<String, int> _progress = {}; // 卡片名称 -> 进度(0-4)
  int fragments = 0; // 新增：幸运碎片数量
  
  // -- JSON序列化和反序列化 --
  CardCollection.fromJson(Map<String, dynamic> json) {
    _progress.clear();
    final progressMap = json['_progress'] as Map<String, dynamic>?;
    if (progressMap != null) {
      progressMap.forEach((key, value) {
        if (value is int) {
          _progress[key] = value;
        }
      });
    }
    fragments = json['fragments'] as int? ?? 0;
  }

  Map<String, dynamic> toJson() => {
    '_progress': _progress,
    'fragments': fragments,
  };

  CardCollection(); // 添加一个默认的构造函数
  
  // 获取卡片收集进度 (0: 未收集, 1-3: 部分收集, 4: 完成收集)
  int getProgress(String cardName) => _progress[cardName] ?? 0;
  
  // 检查卡片是否完成收集
  bool isCompleted(String cardName) => getProgress(cardName) >= 4;
  
  // 获取收集进度百分比 (0.0 - 1.0)
  double getProgressPercent(String cardName) => getProgress(cardName) / 4.0;
  
  // 更新收集进度, 返回 (获得进度的卡牌名, 获得的碎片来源卡牌名, 获得的碎片数)
  (String?, String?, int) updateProgress(List<String> drawnCards) {
    int fragmentsGained = 0;
    String? celebratedCard;
    String? fragmentSourceCard;

    // 统计每张卡片出现次数
    final cardCounts = <String, int>{};
    for (final card in drawnCards) {
      cardCounts[card] = (cardCounts[card] ?? 0) + 1;
    }
    
    // 根据规则更新进度
    for (final entry in cardCounts.entries) {
      final cardName = entry.key;
      final count = entry.value;
      
      if (isCompleted(cardName)) {
        // 如果卡片已集齐，转化为碎片
        if (count == 2) fragmentsGained += 1;
        if (count == 3) fragmentsGained += 3;
        if(count > 1) fragmentSourceCard = cardName; // 记录碎片的来源
      } else {
        // 如果卡片未集齐，正常更新进度
        if (count == 2) {
          final currentProgress = _progress[cardName] ?? 0;
          _progress[cardName] = (currentProgress + 1).clamp(0, 4);
          celebratedCard = cardName;
        } else if (count == 3) {
          _progress[cardName] = 4;
          celebratedCard = cardName;
        }
      }
    }
    fragments += fragmentsGained;
    return (celebratedCard, fragmentSourceCard, fragmentsGained);
  }
  
  // 获取总收集进度
  CollectionStats getStats(List<String> allCards) {
    int completed = 0;
    int totalProgress = 0;
    
    for (final card in allCards) {
      final progress = getProgress(card);
      if (progress >= 4) completed++;
      totalProgress += progress;
    }
    
    return CollectionStats(
      completed: completed,
      total: allCards.length,
      totalProgress: totalProgress,
      maxProgress: allCards.length * 4,
    );
  }
  
  // 重置所有收集进度
  void reset() {
    _progress.clear();
  }
}

// 收集统计数据
class CollectionStats {
  final int completed;     // 完成收集的卡片数
  final int total;         // 总卡片数
  final int totalProgress; // 总进度点数
  final int maxProgress;   // 最大进度点数
  
  CollectionStats({
    required this.completed,
    required this.total,
    required this.totalProgress,
    required this.maxProgress,
  });
  
  // 完成度百分比
  double get completionRate => completed / total;
  
  // 总进度百分比
  double get overallProgress => totalProgress / maxProgress;
}