// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

enum CpPeriodType {
  CpWall,
  Ranking,
}

class CpPeriodToggleProvider with ChangeNotifier {
  CpPeriodType _selectedPeriod = CpPeriodType.Ranking;

  CpPeriodType get selectedPeriod => _selectedPeriod;

  void setPeriod(CpPeriodType period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  void setWall() {
    setPeriod(CpPeriodType.CpWall);
  }

  void setRanking() {
    setPeriod(CpPeriodType.Ranking);
  }
}
