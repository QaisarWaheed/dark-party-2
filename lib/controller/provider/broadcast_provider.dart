import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/gift_web_socket_service.dart';

/// Shows the lucky gift broadcast overlay across the app.
/// Triggered when user sends a Lucky gift.
/// Uses the top banner with user data.
class BroadcastProvider with ChangeNotifier {
  final GiftWebSocketService _wsService = GiftWebSocketService.instance;
  bool _showBroadcast = false;
  Timer? _hideTimer;

  String _senderName = '';
  String _senderProfileUrl = '';
  String _receiverName = '';
  String _giftName = '';
  String _giftImage = '';
  int _giftCount = 1;
  double _giftAmount = 0;

  bool get isBroadcastVisible => _showBroadcast;
  String get senderName => _senderName;
  String get senderProfileUrl => _senderProfileUrl;
  String get receiverName => _receiverName;
  String get giftName => _giftName;
  String get giftImage => _giftImage;
  int get giftCount => _giftCount;
  double get giftAmount => _giftAmount;

  BroadcastProvider() {
    _initWebSocketListener();
  }

  void _initWebSocketListener() {
    void handleGiftEvent(dynamic data) {
      // Robust payload normalization
      Map<String, dynamic> payload = data is Map<String, dynamic> ? data : {};
      if (data != null && data['data'] != null && data['data'] is Map) {
        payload = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data is Map) {
        payload = Map<String, dynamic>.from(data);
      }

      print("🔔 [BroadcastProvider] Gift Event Received: $payload");

      // Robust helpers
      String? safeString(dynamic value) {
        if (value == null) return null;
        final s = value.toString().trim();
        if (s.isEmpty || s.toLowerCase() == 'null') return null;
        return s;
      }

      int safeInt(dynamic value) {
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      double safeDouble(dynamic value) {
        return double.tryParse(value?.toString() ?? '') ?? 0.0;
      }

      bool safeBool(dynamic value) {
        if (value == true || value == 1) return true;
        if (value is String) {
          return value == '1' || value.toLowerCase() == 'true';
        }
        return false;
      }

      String? nestedString(Map<String, dynamic> map, List<String> path) {
        dynamic current = map;
        for (final key in path) {
          if (current is Map && current.containsKey(key)) {
            current = current[key];
          } else {
            return null;
          }
        }
        return safeString(current);
      }

      final isLucky =
          safeBool(payload['is_lucky']) ||
          (safeString(
                payload['gift_category'],
              )?.toLowerCase().contains('lucky') ??
              false) ||
          (safeString(payload['category'])?.toLowerCase().contains('lucky') ??
              false) ||
          (safeString(payload['gift_name'])?.toLowerCase().contains('lucky') ??
              false) ||
          (safeString(payload['gift'])?.toLowerCase().contains('lucky') ??
              false);
      final basePrice = safeDouble(
        payload['gift_value'] ??
            payload['gift_price'] ??
            payload['gift_amount'] ??
            payload['price'],
      );

      // Only show for lucky gifts
      if (isLucky) {
        print("🔔 [BroadcastProvider] Lucky gift detected! Processing...");

        // Massive search for Sender Name
        var senderName =
            safeString(payload['sender_name']) ??
            safeString(payload['sender_username']) ??
            safeString(payload['sender']) ??
            safeString(payload['from_name']) ??
            nestedString(payload, ['sender', 'name']) ??
            nestedString(payload, ['sender', 'username']) ??
            'User';

        // Massive search for Receiver Name
        var receiverName =
            safeString(payload['receiver_name']) ??
            safeString(payload['receiver_username']) ??
            safeString(payload['receiver']) ??
            safeString(payload['to_name']) ??
            safeString(payload['to_username']) ??
            nestedString(payload, ['receiver', 'name']) ??
            nestedString(payload, ['receiver', 'username']) ??
            nestedString(payload, ['to_user', 'name']) ??
            nestedString(payload, ['to_user', 'username']) ??
            'User';

        // Massive search for Sender Avatar
        var senderAvatar =
            safeString(payload['sender_avatar']) ??
            safeString(payload['sender_image']) ??
            safeString(payload['sender_profile']) ??
            safeString(payload['sender_profile_url']) ??
            nestedString(payload, ['sender', 'profile_url']) ??
            nestedString(payload, ['sender', 'avatar']) ??
            nestedString(payload, ['sender', 'image']);

        // Massive search for Gift Image
        var giftImageRaw =
            safeString(payload['gift_image']) ??
            safeString(payload['gift_icon']) ??
            safeString(payload['gift_img']) ??
            safeString(payload['image']) ??
            safeString(payload['gift_file']) ??
            nestedString(payload, ['gift', 'image']) ??
            nestedString(payload, ['gift', 'icon']) ??
            nestedString(payload, ['gift', 'url']);

        // Massive search for Gift Name
        var giftName =
            safeString(payload['gift_name']) ??
            safeString(payload['gift']) ??
            safeString(payload['gift_title']) ??
            nestedString(payload, ['gift', 'gift_name']) ??
            nestedString(payload, ['gift', 'name']) ??
            'Gift';

        final quantity = safeInt(payload['quantity']) > 0
            ? safeInt(payload['quantity'])
            : 1;
        final baseTotal = basePrice > 0 && quantity > 1
            ? basePrice * quantity
            : basePrice;
        final rewardAmount = safeDouble(
          payload['reward_amount'] ??
              payload['reward'] ??
              payload['amount'] ??
              payload['reward_value'] ??
              payload['win_amount'] ??
              payload['win_coins'] ??
              payload['coins'] ??
              payload['lucky_amount'] ??
              payload['lucky_reward'],
        );
        final multiplier = safeDouble(
          payload['multiplier'] ??
              payload['reward_multiplier'] ??
              payload['lucky_multiplier'] ??
              payload['combo_multiplier'] ??
              payload['x'] ??
              payload['times'],
        );
        final totalCoins = rewardAmount > 0
            ? rewardAmount
            : (multiplier > 0 && baseTotal > 0)
            ? baseTotal * multiplier
            : baseTotal;
        if (rewardAmount <= 0 && multiplier <= 0) {
          print(
            "⏳ [BroadcastProvider] Lucky gift received without multiplier/result; skipping base-only banner",
          );
          return;
        }

        print("🔇 [BroadcastProvider] Lucky gift detected but BROADCAST IS DISABLED per request (Only Room Banner should show).");
        return; // EXIT HERE so no broadcast is shown

        /*
        final normalizedSenderAvatar = _normalizeMediaUrl(senderAvatar);

        print("🔔 [BroadcastProvider] Showing Broadcast:");
        print("   Sender: $senderName, Recv: $receiverName");
        print("   Gift Img: $giftImageRaw, Qty: $quantity");
        print("   Coins: $totalCoins (base: $baseTotal, x: $multiplier)");

        showBroadcastOverlay(
          senderName: senderName,
          senderProfileUrl: normalizedSenderAvatar,
          receiverName: receiverName,
          giftName: giftName,
          giftImage: _normalizeMediaUrl(giftImageRaw),
          giftCount: quantity,
          giftAmount: totalCoins,
          source: 'InternalListener',
        );
        */
      } else {
        print(
          "🔔 [BroadcastProvider] Gift ignored (Lucky: $isLucky, Price: $basePrice)",
        );
      }
    }

    // Generic Result Handler
    void handleLuckyGiftResult(dynamic data) {
      print("🔔 [BroadcastProvider] lucky_gift:result (or var) received: $data");
      
      Map<String, dynamic> payload = data is Map<String, dynamic> ? data : {};
      if (data != null && data['data'] != null && data['data'] is Map) {
        payload = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data is Map) {
         payload = Map<String, dynamic>.from(data);
      }

      // Extract multiplier data
      final multiplier = _parseDouble(
        payload['multiplier'] ??
            payload['reward_multiplier'] ??
            payload['lucky_multiplier'] ??
            payload['x'] ??
            payload['times'],
      );
      
      final winCoins = _parseDouble(
        payload['win_coins'] ??
        payload['amount'] ??
        payload['reward_amount'] ??
        payload['win_amount'] ??
        payload['coins']
      );

      final giftPrice = _parseDouble(
        payload['gift_price'] ?? payload['gift_value'] ?? payload['price']
      );

      // Determine final coins
      final calculatedWin = (giftPrice > 0 && multiplier > 0) ? giftPrice * multiplier : 0.0;
      final finalCoins = calculatedWin > 0 ? calculatedWin : (winCoins > 0 ? winCoins : giftPrice);

      print("🔔 [BroadcastProvider] Result -> Mult: $multiplier, Win: $winCoins, Price: $giftPrice -> FINAL: $finalCoins");

      if (finalCoins > 0) {
        print("🔇 [BroadcastProvider] Lucky Result detected but BROADCAST IS DISABLED per request.");
        /*
        String senderName = _safeString(payload['sender_name']) ?? _safeString(payload['sender_username']) ?? _senderName;
        if (senderName.isEmpty) senderName = 'User';
        
        String giftName = _safeString(payload['gift_name']) ?? _giftName;
        if (giftName.isEmpty || giftName == 'Gift') giftName = 'Lucky';
        
        showBroadcastOverlay(
           senderName: senderName,
           senderProfileUrl: _senderProfileUrl,
           receiverName: _receiverName,
           giftName: giftName,
           giftImage: _giftImage,
           giftCount: _giftCount,
           giftAmount: finalCoins,
           source: 'LuckyResultHandler',
        );
        */
      }
    }

    _wsService.on('gift:sent', handleGiftEvent);
    _wsService.on('gift_sent', handleGiftEvent);
    
    // Listen for result variations
    _wsService.on('lucky_gift:result', handleLuckyGiftResult);
    _wsService.on('lucky_gift_result', handleLuckyGiftResult);
    
    // Listen for success (might contain result)
    _wsService.on('success', (data) {
       // Only process if it looks like a lucky gift result
       if (data.containsKey('win_coins') || data.containsKey('multiplier') || 
           (data['data'] != null && (data['data']['win_coins'] != null || data['data']['multiplier'] != null))) {
           handleLuckyGiftResult(data);
       }
    });
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> data) {
    if (data['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
    }
    return data;
  }

  bool _parseBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  String? _safeString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  double _parseDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _parseInt(dynamic value, {int fallback = 0}) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final val = data[key];
      if (val != null) {
        final s = val.toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
      }
    }
    return '';
  }

  String _normalizeMediaUrl(String? raw) {
    if (raw == null) return '';
    var url = raw.trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) url = url.substring(1);
    return 'https://shaheenstar.online/$url';
  }

  /// Show the broadcast overlay in the same position as Lucky banner, with user data.
  void showBroadcastOverlay({
    String senderName = '',
    String senderProfileUrl = '',
    String receiverName = '',
    String giftName = '',
    String giftImage = '',
    int giftCount = 1,
    double giftAmount = 0,
    Duration duration = const Duration(seconds: 4),
    String source = 'Unknown',
  }) {
    print("🔔 [BroadcastProvider] showBroadcastOverlay called from [$source]");
    print("   -> Sender: '$senderName'");
    print("   -> Receiver: '$receiverName'");

    // Final defensive fallback to prevent 'Blank' names
    final finalSender = (senderName.trim().isEmpty || senderName == 'null')
        ? 'User'
        : senderName;
    final finalReceiver =
        (receiverName.trim().isEmpty || receiverName == 'null')
        ? 'User'
        : receiverName;

    print(
      "   -> Final Resolved: Sender='$finalSender', Receiver='$finalReceiver'",
    );

    _hideTimer?.cancel();
    _senderName = finalSender;
    _senderProfileUrl = senderProfileUrl;
    _receiverName = finalReceiver;
    _giftName = giftName.trim().isEmpty ? 'Gift' : giftName;
    _giftImage = giftImage;
    _giftCount = giftCount;
    _giftAmount = giftAmount;
    _showBroadcast = true;
    notifyListeners();

    _hideTimer = Timer(duration, () {
      _showBroadcast = false;
      _senderName = '';
      _senderProfileUrl = '';
      _receiverName = '';
      _giftName = '';
      _giftImage = '';
      _giftCount = 1;
      _giftAmount = 0;
      _hideTimer = null;
      notifyListeners();
    });
  }

  void hideBroadcast() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showBroadcast = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
