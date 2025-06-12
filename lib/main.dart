import 'package:flutter/material.dart';
import 'slot_game.dart'; // 引入 slot_game.dart 页面
// import 'theme_model.dart'; // 不再需要在这里引入

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SlotGamePage(), // 直接启动 SlotGamePage
    );
  }
}
