import 'package:flutter/material.dart';

class VipProvider with ChangeNotifier {
  int _selectedVipLevel = 1;
  
  int get selectedVipLevel => _selectedVipLevel;
  
  void selectVipLevel(int level) {
    _selectedVipLevel = level;
    notifyListeners();
  }
}