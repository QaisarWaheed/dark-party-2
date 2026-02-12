import 'dart:convert';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AgencyWebSocketService {
  WebSocketChannel? _channel;
  Function(dynamic)? onMessage;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // WebSocket URL
  static final String baseUrl = ApiConstants.agencyWebSocketUrl;

  // Connect to WebSocket
  void connect({
    required int userId,
    required String username,
    required String name,
    String? profileUrl,
  }) {
    try {
      print('🔌 [AgencyWebSocket] Connecting to Agency WebSocket...');
      print(
        '📍 [AgencyWebSocket] UserID: $userId, Username: $username, Name: $name',
      );

      // Build URL with parameters
      final uri = Uri.parse(
        '$baseUrl?user_id=$userId&username=${Uri.encodeComponent(username)}&name=${Uri.encodeComponent(name)}${profileUrl != null ? '&profile_url=${Uri.encodeComponent(profileUrl)}' : ''}',
      );

      print('🌐 [AgencyWebSocket] Connecting to: $uri');

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      print('✅ [AgencyWebSocket] WebSocket connected successfully!');

      // Setup listener for incoming messages
      _channel!.stream.listen(
        (message) {
          print('📨 [AgencyWebSocket] Received raw message: $message');

          // Parse the message to check structure
          try {
            final parsed = json.decode(message);
            print('📊 [AgencyWebSocket] Parsed message: $parsed');
          } catch (e) {
            print('⚠️ [AgencyWebSocket] Could not parse as JSON: $message');
          }

          // Forward message to provider
          if (onMessage != null) {
            onMessage!(message);
          }
        },
        onError: (error) {
          print('❌ [AgencyWebSocket] WebSocket stream error: $error');
          _isConnected = false;
          if (onError != null) {
            onError!(error);
          }
          if (onDisconnected != null) {
            onDisconnected!();
          }
        },
        onDone: () {
          print('🔌 [AgencyWebSocket] WebSocket connection closed');
          _isConnected = false;
          if (onDisconnected != null) {
            onDisconnected!();
          }
        },
        cancelOnError: true,
      );

      // Call onConnected callback
      if (onConnected != null) {
        Future.delayed(Duration(milliseconds: 100), () {
          onConnected!();
        });
      }
    } catch (e) {
      print('❌ [AgencyWebSocket] Connection failed: $e');
      print(
        '❌ [AgencyWebSocket] Port 8043 might not be running or server is down',
      );
      print(
        '❌ [AgencyWebSocket] Check if WebSocket server is running on $baseUrl',
      );
      _isConnected = false;
      if (onError != null) {
        onError!(e);
      }
    }
  }

  // Send message
  bool send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      final jsonData = json.encode(data);
      print('📤 [AgencyWebSocket] Sending: $jsonData');
      _channel!.sink.add(jsonData);
      return true;
    } else {
      print('❌ [AgencyWebSocket] Cannot send - WebSocket not connected');
      if (onError != null) {
        onError!('WebSocket not connected');
      }
      return false;
    }
  }

  // Disconnect
  void disconnect() {
    print('🔌 [AgencyWebSocket] Disconnecting WebSocket...');
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  // ========== AGENCY MANAGEMENT METHODS ==========

  /// Create a new agency
  bool createAgency(int userId, String agencyName) {
    print(
      '🏢 [AgencyWebSocket] createAgency called: userId=$userId, agencyName=$agencyName',
    );
    return send({
      'action': 'create_agency',
      'user_id': userId,
      'agency_name': agencyName,
    });
  }

  /// Update an existing agency
  bool updateAgency(int userId, int agencyId, String agencyName) {
    print(
      '🏢 [AgencyWebSocket] updateAgency called: userId=$userId, agencyId=$agencyId, agencyName=$agencyName',
    );
    return send({
      'action': 'update_agency',
      'user_id': userId,
      'agency_id': agencyId,
      'agency_name': agencyName,
    });
  }

  /// Delete an agency
  bool deleteAgency(int userId, int agencyId) {
    print(
      '🏢 [AgencyWebSocket] deleteAgency called: userId=$userId, agencyId=$agencyId',
    );
    return send({
      'action': 'delete_agency',
      'user_id': userId,
      'agency_id': agencyId,
    });
  }

  /// Get a specific agency
  bool getAgency(int agencyId) {
    print('🏢 [AgencyWebSocket] getAgency called: agencyId=$agencyId');
    return send({'action': 'get_agency', 'agency_id': agencyId});
  }

  /// Get all agencies
  bool getAllAgencies({int limit = 50, int offset = 0}) {
    print(
      '🏢 [AgencyWebSocket] getAllAgencies called: limit=$limit, offset=$offset',
    );
    return send({
      'action': 'get_all_agencies',
      'limit': limit,
      'offset': offset,
    });
  }

  /// Add a member to an agency
  bool addMember(int userId, int agencyId, int memberUserId) {
    print(
      '👤 [AgencyWebSocket] addMember called: userId=$userId, agencyId=$agencyId, memberUserId=$memberUserId',
    );
    return send({
      'action': 'add_member',
      'user_id': userId,
      'agency_id': agencyId,
      'member_user_id': memberUserId,
    });
  }

  /// Remove a member from an agency
  bool removeMember(int userId, int agencyId, int memberUserId) {
    print(
      '👤 [AgencyWebSocket] removeMember called: userId=$userId, agencyId=$agencyId, memberUserId=$memberUserId',
    );
    return send({
      'action': 'remove_member',
      'user_id': userId,
      'agency_id': agencyId,
      'member_user_id': memberUserId,
    });
  }

  /// Get members of an agency
  bool getMembers(int agencyId) {
    print('👥 [AgencyWebSocket] getMembers called: agencyId=$agencyId');
    return send({'action': 'get_members', 'agency_id': agencyId});
  }

  /// Get all users (for member selection)
  bool getAllUsers({int limit = 100, int offset = 0}) {
    print(
      '👥 [AgencyWebSocket] getAllUsers called: limit=$limit, offset=$offset',
    );
    return send({'action': 'get_all_users', 'limit': limit, 'offset': offset});
  }

  /// Get a specific user
  bool getUser(int userId) {
    print('👤 [AgencyWebSocket] getUser called: userId=$userId');
    return send({'action': 'get_user', 'user_id': userId});
  }

  /// Get agency statistics
  bool getStats() {
    print('📊 [AgencyWebSocket] getStats called');
    return send({'action': 'get_stats'});
  }

  /// Join an agency
  bool joinAgency(int userId, int agencyId) {
    print(
      '🚪 [AgencyWebSocket] joinAgency called: userId=$userId, agencyId=$agencyId',
    );
    return send({
      'action': 'join_agency',
      'user_id': userId,
      'agency_id': agencyId,
    });
  }

  /// Leave an agency
  bool leaveAgency(int userId, int agencyId) {
    print(
      '🚪 [AgencyWebSocket] leaveAgency called: userId=$userId, agencyId=$agencyId',
    );
    return send({
      'action': 'leave_agency',
      'user_id': userId,
      'agency_id': agencyId,
    });
  }

  /// Search agencies
  bool searchAgencies(String searchTerm, {int limit = 20, int offset = 0}) {
    print(
      '🔍 [AgencyWebSocket] searchAgencies called: searchTerm=$searchTerm, limit=$limit, offset=$offset',
    );
    return send({
      'action': 'search_agencies',
      'search_term': searchTerm,
      'limit': limit,
      'offset': offset,
    });
  }
}
