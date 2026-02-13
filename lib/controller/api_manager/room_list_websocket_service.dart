// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';

class RoomListWebSocketService with ChangeNotifier {
  static RoomListWebSocketService? _instance;
  static RoomListWebSocketService get instance {
    _instance ??= RoomListWebSocketService._();
    return _instance!;
  }

  RoomListWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;

  final Map<String, List<Function(Map<String, dynamic>)>> _eventCallbacks = {};
  final Set<String> _joinedRooms = {}; // ✅ Track which rooms we've joined

  bool get isConnected => _isConnected;
  String get wsUrl => ApiConstants.webSocketUrl;

  Future<bool> connect() async {
    try {
      if (_isConnected && _channel != null) {
        return true;
      }

      final baseUrl = wsUrl.trim();
      if (!baseUrl.startsWith('ws://') && !baseUrl.startsWith('wss://')) {
        throw Exception('Invalid WebSocket URL format.');
      }

      final uri = Uri.parse(baseUrl);
      _channel = WebSocketChannel.connect(uri);

      _messageSubscription = _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void on(String eventName, Function(Map<String, dynamic>) callback) {
    _eventCallbacks.putIfAbsent(eventName, () => []).add(callback);
  }

  void offAll(String eventName) {
    _eventCallbacks.remove(eventName);
  }

  /// ✅ Join a room to receive its broadcasts (user:joined, user:left, etc.)
  /// Call this when you want to monitor a specific room's participant count
  void joinRoom(String roomId) {
    if (!_isConnected || _channel == null) {
      print("⚠️ [RoomListWebSocketService] Cannot join room - not connected");
      return;
    }

    if (_joinedRooms.contains(roomId)) {
      return; // Already joined
    }

    _joinedRooms.add(roomId);
    _channel!.sink.add(jsonEncode({'action': 'join_room', 'room_id': roomId}));
    print("✅ [RoomListWebSocketService] Joined room: $roomId");
  }

  /// ✅ Leave a room (stop receiving its broadcasts)
  void leaveRoom(String roomId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    _joinedRooms.remove(roomId);
    _channel!.sink.add(jsonEncode({'action': 'leave_room', 'room_id': roomId}));
    print("✅ [RoomListWebSocketService] Left room: $roomId");
  }

  /// ✅ Request the current participant count for a room
  void requestRoomCount(String roomId) {
    if (!_isConnected || _channel == null) {
      print(
        "⚠️ [RoomListWebSocketService] Cannot request count - not connected",
      );
      return;
    }

    _channel!.sink.add(
      jsonEncode({'action': 'get_room_count', 'room_id': roomId}),
    );
    print("📊 [RoomListWebSocketService] Requested count for room: $roomId");
  }

  Future<void> disconnect() async {
    try {
      await _messageSubscription?.cancel();
      await _channel?.sink.close();
    } catch (e) {
      // Ignore disconnect errors.
    } finally {
      _messageSubscription = null;
      _channel = null;
      _isConnected = false;
      _joinedRooms.clear();
      _eventCallbacks.clear();
      notifyListeners();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data;
      if (message is String) {
        data = json.decode(message) as Map<String, dynamic>;
      } else if (message is Map) {
        data = Map<String, dynamic>.from(message);
      } else {
        return;
      }

      final String? action = data['action']?.toString();
      final String? event = data['event']?.toString();
      final String? eventName = action ?? event;

      // ✅ Only log important events (not every message to reduce noise)
      if (eventName == 'room:count' ||
          eventName == 'user:joined' ||
          eventName == 'user:left') {
        print("📨 [RoomListWebSocketService] Event: $eventName - Data: $data");
      }

      if (eventName == null) {
        return;
      }

      Map<String, dynamic> eventData;
      if (data.containsKey('data') && data['data'] is Map) {
        eventData = Map<String, dynamic>.from(data['data'] as Map);
      } else {
        eventData = Map<String, dynamic>.from(data);
        eventData.remove('action');
        eventData.remove('event');
      }

      _triggerEvent(eventName, eventData);
    } catch (e) {
      print("⚠️ [RoomListWebSocketService] Error handling message: $e");
    }
  }

  void _triggerEvent(String eventName, Map<String, dynamic> data) {
    final callbacks = _eventCallbacks[eventName];
    if (callbacks == null || callbacks.isEmpty) return;
    for (final cb in List<Function(Map<String, dynamic>)>.from(callbacks)) {
      try {
        cb(data);
      } catch (_) {
        // Ignore callback errors.
      }
    }
  }
}
