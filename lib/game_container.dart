import 'package:flutter/material.dart';
import 'slot_game.dart';
import 'house_page.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        children: [
          const SlotGamePage(),
          const HousePage(),
        ],
      ),
      // 添加页面指示器
      floatingActionButton: _currentPage == 0 
        ? FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white.withOpacity(0.8),
            onPressed: () {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.black54,
              size: 30,
            ),
          )
        : FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white.withOpacity(0.8),
            onPressed: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black54,
              size: 30,
            ),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 