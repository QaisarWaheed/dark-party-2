import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/gift_model.dart';

/// Model for an active gift being displayed
class ActiveGift {
  final String id;
  final GiftModel gift;
  final String senderName;
  final String? senderAvatar;
  final String receiverName;
  final String? receiverAvatar;
  final int quantity;
  final DateTime timestamp;
  Timer? _timer;

  ActiveGift({
    required this.id,
    required this.gift,
    required this.senderName,
    this.senderAvatar,
    required this.receiverName,
    this.receiverAvatar,
    required this.quantity,
    required this.timestamp,
  });

  void setTimer(Timer timer) {
    _timer?.cancel();
    _timer = timer;
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Provider to manage active gift displays on screen
class GiftDisplayProvider with ChangeNotifier {
  final List<ActiveGift> _activeGifts = [];
  static const Duration _displayDuration = Duration(seconds: 150); // 2.5 minutes

  List<ActiveGift> get activeGifts => List.unmodifiable(_activeGifts);

  /// Add a gift to display
  void addGift({
    required GiftModel gift,
    required String senderName,
    String? senderAvatar,
    required String receiverName,
    String? receiverAvatar,
    required int quantity,
  }) {
    final giftId = '${DateTime.now().millisecondsSinceEpoch}_${gift.id}';
    
    final activeGift = ActiveGift(
      id: giftId,
      gift: gift,
      senderName: senderName,
      senderAvatar: senderAvatar,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      quantity: quantity,
      timestamp: DateTime.now(),
    );

    // Set timer to remove gift after duration
    final timer = Timer(_displayDuration, () {
      removeGift(giftId);
    });
    activeGift.setTimer(timer);

    _activeGifts.add(activeGift);
    notifyListeners();

    print('🎁 Gift added to display: ${gift.name} (x$quantity)');
    print('   - Will be displayed for ${_displayDuration.inSeconds} seconds');
  }

  /// Remove a gift from display
  void removeGift(String giftId) {
    final index = _activeGifts.indexWhere((gift) => gift.id == giftId);
    if (index != -1) {
      _activeGifts[index].dispose();
      _activeGifts.removeAt(index);
      notifyListeners();
      print('🎁 Gift removed from display: $giftId');
    }
  }

  /// Clear all active gifts
  void clearAll() {
    for (var gift in _activeGifts) {
      gift.dispose();
    }
    _activeGifts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

