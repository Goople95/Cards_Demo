import 'package:flutter/material.dart';
import 'game_container.dart';
// import 'theme_model.dart'; // 不再需要在这里引入

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cards Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameContainer(),
      debugShowCheckedModeBanner: false,
    );
  }
}
