import 'package:flutter/material.dart';
import 'collection_model.dart';
import 'theme_model.dart';

class CollectionAlbum extends StatelessWidget {
  final CardCollection collection;
  final GameTheme theme;

  const CollectionAlbum({
    super.key,
    required this.collection,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final stats = collection.getStats(theme.cardPool);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 ${theme.name} 图册'),
        backgroundColor: Colors.deepPurple.shade800,
      ),
      body: Column(
        children: [
          // 总体进度统计
          _buildStatsHeader(stats),
          
          // 卡片收集网格
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: theme.cardPool.length,
                itemBuilder: (context, index) {
                  final cardName = theme.cardPool[index];
                  return _buildCardItem(cardName);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(CollectionStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '收集进度',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                '完成收集',
                '${stats.completed}/${stats.total}',
                stats.completionRate,
                Colors.green,
              ),
              _buildStatItem(
                '总体进度',
                '${stats.totalProgress}/${stats.maxProgress}',
                stats.overallProgress,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, double progress, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(String cardName) {
    final progress = collection.getProgress(cardName);
    final isCompleted = collection.isCompleted(cardName);
    final imagePath = theme.cardPics[cardName] ?? 'default.png';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCompleted
              ? LinearGradient(
                  colors: [Colors.amber.shade100, Colors.amber.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          children: [
            // 卡片头部状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(progress),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                _getStatusText(progress),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            // 卡片图片
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: progress == 0 ? Colors.grey.shade300 : null,
                        ),
                        child: progress == 0
                            ? Icon(
                                Icons.help_outline,
                                size: 40,
                                color: Colors.grey.shade600,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/${theme.assetPath}/$imagePath',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 卡片名称
                    Text(
                      cardName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: progress == 0 ? Colors.grey : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 进度条
                    const SizedBox(height: 6),
                    _buildProgressBar(progress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index < progress;
        return Container(
          width: 12,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getStatusColor(int progress) {
    if (progress >= 4) return Colors.green;
    if (progress >= 3) return Colors.orange;
    if (progress >= 1) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusText(int progress) {
    if (progress >= 4) return '✅ 已完成';
    if (progress >= 3) return '🔥 即将完成';
    if (progress >= 1) return '📈 收集中';
    return '❓ 未发现';
  }
}