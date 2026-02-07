import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/provider/zego_voice_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zego Voice Provider
/// Manages voice call state and integrates with seat management
class ZegoVoiceProvider with ChangeNotifier {
  final ZegoVoiceService _zegoService = ZegoVoiceService();
  
  // State
  bool _isInitialized = false;
  bool _isInRoom = false;
  bool _isPublishing = false;
  String? _currentRoomID;
  String? _currentUserID;
  String? _currentUserName;
  String? _errorMessage;
  
  // Microphone and speaker state
  bool _isMicrophoneEnabled = true;
  bool _isSpeakerEnabled = true;
  
  // Active streams count
  int _activeStreamsCount = 0;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInRoom => _isInRoom;
  bool get isPublishing => _isPublishing;
  String? get currentRoomID => _currentRoomID;
  String? get currentUserID => _currentUserID;
  String? get currentUserName => _currentUserName;
  String? get errorMessage => _errorMessage;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  int get activeStreamsCount => _activeStreamsCount;
  
  ZegoVoiceProvider() {
    _setupEventHandlers();
  }
  
  // Callback for when seats need to be refreshed (set from RoomScreen)
  Function()? onSeatsRefreshNeeded;

  // ✅ Setup event handlers
  void _setupEventHandlers() {
    _zegoService.onUserJoin = (userID, userName) {
      debugPrint('👤 [ZegoVoiceProvider] User joined: $userID ($userName)');
      // ✅ Trigger seat refresh when user joins (they might be on a seat)
      if (onSeatsRefreshNeeded != null) {
        debugPrint('🔄 [ZegoVoiceProvider] Triggering seat refresh due to user join');
        // ✅ More aggressive refresh - try immediately and after delays
        onSeatsRefreshNeeded?.call();
        Future.delayed(const Duration(milliseconds: 1000), () {
          onSeatsRefreshNeeded?.call();
        });
        Future.delayed(const Duration(milliseconds: 3000), () {
          onSeatsRefreshNeeded?.call();
        });
      }
      notifyListeners();
    };
    
    _zegoService.onUserLeave = (userID) {
      debugPrint('👤 [ZegoVoiceProvider] User left: $userID');
      // ✅ Trigger seat refresh when user leaves (they might have left a seat)
      if (onSeatsRefreshNeeded != null) {
        debugPrint('🔄 [ZegoVoiceProvider] Triggering seat refresh due to user leave');
        Future.delayed(const Duration(milliseconds: 500), () {
          onSeatsRefreshNeeded?.call();
        });
      }
      notifyListeners();
    };
    
    _zegoService.onStreamAdd = (streamID, userID) {
      debugPrint('📺 [ZegoVoiceProvider] Stream added: $streamID from $userID');
      _activeStreamsCount = _zegoService.activePlayersCount;
      // ✅ Stream added means user is likely on a seat - refresh seats
      if (onSeatsRefreshNeeded != null) {
        debugPrint('🔄 [ZegoVoiceProvider] Triggering seat refresh due to stream add');
        // ✅ More aggressive refresh - try immediately and after delay
        onSeatsRefreshNeeded?.call();
        Future.delayed(const Duration(milliseconds: 1000), () {
          onSeatsRefreshNeeded?.call();
        });
        Future.delayed(const Duration(milliseconds: 3000), () {
          onSeatsRefreshNeeded?.call();
        });
      }
      notifyListeners();
    };
    
    _zegoService.onStreamRemove = (streamID) {
      debugPrint('📺 [ZegoVoiceProvider] Stream removed: $streamID');
      _activeStreamsCount = _zegoService.activePlayersCount;
      notifyListeners();
    };
    
    _zegoService.onError = (error) {
      debugPrint('❌ [ZegoVoiceProvider] Error: $error');
      _errorMessage = error;
      notifyListeners();
    };
  }
  
  // ✅ Initialize Zego service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        debugPrint('⚠️ [ZegoVoiceProvider] Already initialized');
        return true;
      }
      
      _errorMessage = null;
      notifyListeners();
      
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Handle user_id - can be stored as String or int
      String? userID;
      dynamic userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        if (userIdValue is int) {
          userID = userIdValue.toString();
        } else if (userIdValue is String) {
          userID = userIdValue;
        }
      }
      
      // If user_id not found, try google_id
      if (userID == null) {
        dynamic googleIdValue = prefs.get('google_id');
        if (googleIdValue != null) {
          if (googleIdValue is int) {
            userID = googleIdValue.toString();
          } else if (googleIdValue is String) {
            userID = googleIdValue;
          }
        }
      }
      
      final userName = prefs.getString('username') ?? prefs.getString('name') ?? 'User';
      
      if (userID == null || userID.isEmpty) {
        _errorMessage = 'User ID not found. Please login first.';
        notifyListeners();
        return false;
      }
      
      _currentUserID = userID;
      _currentUserName = userName;
      
      // Login to Zego
      await _zegoService.loginUser(userID, userName);
      
      // Initialize engine
      final success = await _zegoService.initialize();
      
      if (success) {
        _isInitialized = true;
        debugPrint('✅ [ZegoVoiceProvider] Initialized successfully');
      } else {
        _errorMessage = 'Failed to initialize Zego service';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Initialization error: $e';
      debugPrint('❌ [ZegoVoiceProvider] Initialize error: $e');
      notifyListeners();
      return false;
    }
  }
  
  // ✅ Join room. Pass [token] when Zego project uses token auth (fixes 1001005).
  Future<bool> joinRoom(String roomID, {String? token}) async {
    try {
      if (!_isInitialized) {
        final initSuccess = await initialize();
        if (!initSuccess) {
          return false;
        }
      }
      
      _errorMessage = null;
      notifyListeners();
      
      // Ensure microphone permission before joining a voice-enabled room
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          _errorMessage = 'Microphone permission required for voice chat';
          notifyListeners();
          return false;
        }
      }

      final success = await _zegoService.joinRoom(roomID, token: token);
      
      if (success) {
        _isInRoom = true;
        _currentRoomID = roomID;
        debugPrint('✅ [ZegoVoiceProvider] Joined room: $roomID');
      } else {
        _errorMessage = 'Failed to join room';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Join room error: $e';
      debugPrint('❌ [ZegoVoiceProvider] Join room error: $e');
      notifyListeners();
      return false;
    }
  }
  
  // ✅ Leave room
  Future<void> leaveRoom() async {
    try {
      await _zegoService.leaveRoom();
      _isInRoom = false;
      _isPublishing = false;
      _currentRoomID = null;
      _activeStreamsCount = 0;
      debugPrint('✅ [ZegoVoiceProvider] Left room');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Leave room error: $e';
      debugPrint('❌ [ZegoVoiceProvider] Leave room error: $e');
      notifyListeners();
    }
  }
  
  // ✅ Start publishing (when user takes a seat)
  Future<bool> startPublishing() async {
    try {
      if (!_isInRoom) {
        _errorMessage = 'Not in room. Please join room first.';
        notifyListeners();
        return false;
      }
      
      _errorMessage = null;
      notifyListeners();
      
      // Request microphone permission if not already granted before publishing
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          _errorMessage = 'Microphone permission required to start publishing';
          notifyListeners();
          return false;
        }
      }

      final success = await _zegoService.startPublishing();
      
      if (success) {
        _isPublishing = true;
        debugPrint('✅ [ZegoVoiceProvider] Started publishing');
      } else {
        _errorMessage = 'Failed to start publishing';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Start publishing error: $e';
      debugPrint('❌ [ZegoVoiceProvider] Start publishing error: $e');
      notifyListeners();
      return false;
    }
  }
  
  // ✅ Stop publishing (when user leaves seat)
  Future<bool> stopPublishing() async {
    try {
      final success = await _zegoService.stopPublishing();
      
      if (success) {
        _isPublishing = false;
        debugPrint('✅ [ZegoVoiceProvider] Stopped publishing');
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Stop publishing error: $e';
      debugPrint('❌ [ZegoVoiceProvider] Stop publishing error: $e');
      notifyListeners();
      return false;
    }
  }
  
  // ✅ Toggle microphone
  Future<void> toggleMicrophone() async {
    try {
      _isMicrophoneEnabled = !_isMicrophoneEnabled;
      await _zegoService.enableMicrophone(_isMicrophoneEnabled);
      debugPrint('✅ [ZegoVoiceProvider] Microphone ${_isMicrophoneEnabled ? "enabled" : "disabled"}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ZegoVoiceProvider] Toggle microphone error: $e');
    }
  }
  
  // ✅ Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      await _zegoService.enableSpeaker(_isSpeakerEnabled);
      debugPrint('✅ [ZegoVoiceProvider] Speaker ${_isSpeakerEnabled ? "enabled" : "disabled"}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ZegoVoiceProvider] Toggle speaker error: $e');
    }
  }
  
  // ✅ Update publishing state (called from seat provider)
  void updatePublishingState(bool isPublishing) {
    if (_isPublishing != isPublishing) {
      _isPublishing = isPublishing;
      notifyListeners();
    }
  }
  
  // ✅ Dispose
  @override
  void dispose() {
    _zegoService.dispose();
    super.dispose();
  }
}

