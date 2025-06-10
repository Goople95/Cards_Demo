import 'package:flutter/material.dart';
import 'slot_game.dart'; // 引入 slot_game.dart 页面

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ODT Slot Demo',
      theme: ThemeData.dark(),
      home: const SlotGamePage(), // 启动即进入 slot 页面
    );
  }
}
