import 'package:flutter/material.dart';
import 'slot_game.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  @override
  Widget build(BuildContext context) {
    return const SlotGamePage();
  }
} 