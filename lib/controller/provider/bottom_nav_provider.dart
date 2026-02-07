


import 'package:flutter/foundation.dart';

class BottomNavProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // ✅ Optional: Reset to home tab
  void resetToHome() {
    _currentIndex = 0;
    notifyListeners();
  }
}