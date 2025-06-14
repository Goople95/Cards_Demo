import 'package:flutter/material.dart';

class FragmentModel extends ChangeNotifier {
  int fragmentCount = 0;

  void set(int n) {
    fragmentCount = n;
    notifyListeners();
  }

  void add(int n) {
    fragmentCount += n;
    notifyListeners();
  }

  void subtract(int n) {
    fragmentCount = (fragmentCount - n).clamp(0, 999999);
    notifyListeners();
  }
} 