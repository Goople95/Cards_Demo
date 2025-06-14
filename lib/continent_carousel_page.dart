import 'package:flutter/material.dart';
import 'models/theme_model.dart';

class ContinentCarouselPage extends StatefulWidget {
  const ContinentCarouselPage({Key? key}) : super(key: key);

  @override
  State<ContinentCarouselPage> createState() => _ContinentCarouselPageState();
}

class _ContinentCarouselPageState extends State<ContinentCarouselPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> continents = [
    {
      'name': '欧洲',
      'background': 'assets/backgrounds/europe_bg.png',
      'countries': [
        {'id': 'uk', 'name': '英国', 'flag': 'assets/backgrounds/uk_bg.png'},
      ]
    },
    {
      'name': '亚洲',
      'background': 'assets/backgrounds/asia_bg.png',
      'countries': [
        {'id': 'japan', 'name': '日本', 'flag': 'assets/backgrounds/japan_bg.png'},
      ]
    },
    {
      'name': '美洲',
      'background': 'assets/backgrounds/america_bg.png',
      'countries': []
    },
    {
      'name': '非洲',
      'background': 'assets/backgrounds/africa_bg.png',
      'countries': []
    },
    {
      'name': '大洋洲',
      'background': 'assets/backgrounds/oceania_bg.png',
      'countries': []
    },
  ];

  // 假数据：最近游玩国家
  final List<Map<String, String>> recentCountries = [
    {
      'id': 'uk',
      'name': '英国',
      'mainImage': 'assets/backgrounds/uk_bg.png',
      'flag': 'assets/flags/flag_uk.png',
    },
    {
      'id': 'japan',
      'name': '日本',
      'mainImage': 'assets/backgrounds/japan_bg.png',
      'flag': 'assets/flags/flag_japan.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择国家关卡'),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 最近游玩国家横滑区
          if (recentCountries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 8),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentCountries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, idx) {
                    final country = recentCountries[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, country['id']);
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              country['mainImage']!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: CircleAvatar(
                              backgroundImage: AssetImage(country['flag']!),
                              radius: 16,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                              ),
                              child: Text(
                                country['name']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pageController,
              itemCount: continents.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final continent = continents[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 洲背景图
                    Image.asset(
                      continent['background'],
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                    Center(
                      child: Text(
                        continent['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 指示器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(continents.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentPage ? Colors.blueAccent : Colors.grey,
              ),
            )),
          ),
          const SizedBox(height: 16),
          // 国家卡片区
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: continents[_currentPage]['countries'].length,
              itemBuilder: (context, idx) {
                final country = continents[_currentPage]['countries'][idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, country['id']);
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          country['flag'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: CircleAvatar(
                          backgroundImage: AssetImage(country['flag']),
                          radius: 16,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                          ),
                          child: Text(
                            country['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 