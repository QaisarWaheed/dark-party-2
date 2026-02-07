import 'package:flutter/material.dart';

class BottomSheetBackgroundProvider extends ChangeNotifier {
  String? _svgaUrl;

  String? get svgaUrl => _svgaUrl;

  bool get hasSvga => _svgaUrl != null && _svgaUrl!.isNotEmpty;

  void updateSvga(String? url) {
    if (_svgaUrl == url) return;
    _svgaUrl = url;
    notifyListeners();
  }

  void clear() {
    _svgaUrl = null;
    notifyListeners();
  }
}
