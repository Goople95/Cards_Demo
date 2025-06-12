class CollectionCard {
  final String name;
  final String imagePath;
  int progress; // 0 to 4

  bool get isCollected => progress >= 4;

  CollectionCard({
    required this.name,
    required this.imagePath,
    this.progress = 0,
  });

  CollectionCard clone() {
    return CollectionCard(
      name: name,
      imagePath: imagePath,
      progress: progress,
    );
  }
} 