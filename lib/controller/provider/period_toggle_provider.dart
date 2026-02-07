import 'package:flutter/foundation.dart';

enum PeriodType {
  daily,
  weekly,
  monthly,
}

class PeriodToggleProvider with ChangeNotifier {
  PeriodType _selectedPeriod = PeriodType.daily;

  PeriodType get selectedPeriod => _selectedPeriod;

  void setPeriod(PeriodType period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  void setDaily() {
    setPeriod(PeriodType.daily);
  }

  void setWeekly() {
    setPeriod(PeriodType.weekly);
  }

  void setMonthly() {
    setPeriod(PeriodType.monthly);
  }
}
