import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:shaheen_star_app/controller/api_manager/zego_config.dart';

/// Zego Voice Service
/// Manages voice call functionality using Zego Cloud SDK
class ZegoVoiceService {
  static final ZegoVoiceService _instance = ZegoVoiceService._internal();
  factory ZegoVoiceService() => _instance;
  ZegoVoiceService._internal();

  // Zego Express Engine instance
  ZegoExpressEngine? _engine;
  
  // Current room state
  String? _currentRoomID;
  String? _currentUserID;
  String? _currentUserName;
  
  // Stream publishing state
  bool _isPublishing = false;
  
  // Stream playing state (track active streams)
  final Set<String> _activeStreams = {};
  
  // Retry and failure tracking
  int _joinRoomRetries = 0;
  static const int _maxJoinRetries = 3;
  bool _hasJoinFailed = false;
  Timer? _reconnectTimer;

  // Wait for actual Connected callback (don't assume success on loginRoom return)
  Completer<bool>? _pendingJoinCompleter;
  String? _pendingJoinRoomID;
  
  // Callbacks
  Function(String userID, String userName)? onUserJoin;
  Function(String userID)? onUserLeave;
  Function(String streamID, String userID)? onStreamAdd;
  Function(String streamID)? onStreamRemove;
  Function(String? error)? onError;
  
  // ✅ Initialize Zego Express Engine
  Future<bool> initialize() async {
    try {
      debugPrint('🎤 [ZegoVoiceService] ===== INITIALIZING ZEGO ENGINE =====');
      
      // Validate configuration
      final configError = ZegoConfig.validate();
      if (configError != null) {
        debugPrint('❌ [ZegoVoiceService] Configuration error: $configError');
        debugPrint('❌ [ZegoVoiceService] App ID: ${ZegoConfig.appID}');
        debugPrint('❌ [ZegoVoiceService] App Sign configured: ${ZegoConfig.appSign.isNotEmpty}');
        onError?.call(configError);
        return false;
      }
      
      debugPrint('✅ [ZegoVoiceService] Configuration valid');
      debugPrint('🎤 [ZegoVoiceService] Creating Zego Express Engine...');
      debugPrint('🎤 [ZegoVoiceService] App ID: ${ZegoConfig.appID}');
      debugPrint('🎤 [ZegoVoiceService] Scenario: Communication');
      
      // Create Zego Express Engine with correct API
      await ZegoExpressEngine.createEngine(
        ZegoConfig.appID,
        ZegoConfig.appSign,
        false, // isTestEnv
        ZegoScenario.Communication,
      );
      
      debugPrint('✅ [ZegoVoiceService] Engine creation call completed');
      
      // Get the engine instance
      _engine = ZegoExpressEngine.instance;
      
      if (_engine == null) {
        debugPrint('❌ [ZegoVoiceService] Failed to create engine - instance is null');
        onError?.call('Failed to create Zego engine');
        return false;
      }
      
      debugPrint('✅ [ZegoVoiceService] Engine instance obtained');
      
      // Set event handlers (static setters)
      ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
        debugPrint('📢 [ZegoVoiceService] ===== ROOM STATE UPDATE =====');
        debugPrint('📢 [ZegoVoiceService] Room ID: $roomID');
        debugPrint('📢 [ZegoVoiceService] State: $state');
        debugPrint('📢 [ZegoVoiceService] Error Code: $errorCode');
        if (state == ZegoRoomState.Connected) {
          debugPrint('✅ [ZegoVoiceService] Successfully joined room: $roomID');
          _currentRoomID = roomID;
          if (_pendingJoinCompleter != null && _pendingJoinRoomID == roomID) {
            _pendingJoinCompleter!.complete(true);
            _pendingJoinCompleter = null;
            _pendingJoinRoomID = null;
          }
        } else if (state == ZegoRoomState.Disconnected) {
          debugPrint('⚠️ [ZegoVoiceService] Disconnected from room: $roomID');
          if (_currentRoomID == roomID) _currentRoomID = null;
          if (_pendingJoinCompleter != null && _pendingJoinRoomID == roomID) {
            _pendingJoinCompleter!.complete(false);
            _pendingJoinCompleter = null;
            _pendingJoinRoomID = null;
          }
        } else if (state == ZegoRoomState.Connecting) {
          debugPrint('⏳ [ZegoVoiceService] Connecting to room: $roomID');
        } else if (errorCode != 0) {
          debugPrint('❌ [ZegoVoiceService] Room state error: errorCode=$errorCode');
          debugPrint('❌ [ZegoVoiceService] Error details: ${extendedData.toString()}');
          if (_currentRoomID == roomID) _currentRoomID = null;
          if (_pendingJoinCompleter != null && _pendingJoinRoomID == roomID) {
            _pendingJoinCompleter!.complete(false);
            _pendingJoinCompleter = null;
            _pendingJoinRoomID = null;
          }
          _hasJoinFailed = true;
          String errorMsg = _getErrorMessage(errorCode);
          debugPrint('❌ [ZegoVoiceService] $errorMsg');
          onError?.call(errorMsg);
          if (_joinRoomRetries < _maxJoinRetries && roomID.isNotEmpty) {
            _scheduleReconnect(roomID);
          }
        }
      };
      
      ZegoExpressEngine.onRoomUserUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
        debugPrint('👥 [ZegoVoiceService] Room user update: $updateType, users: ${userList.length}');
        for (var user in userList) {
          if (updateType == ZegoUpdateType.Add) {
            onUserJoin?.call(user.userID, user.userName);
          } else if (updateType == ZegoUpdateType.Delete) {
            onUserLeave?.call(user.userID);
          }
        }
      };
      
      ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
        debugPrint('📺 [ZegoVoiceService] ===== STREAM UPDATE =====');
        debugPrint('📺 [ZegoVoiceService] Room ID: $roomID');
        debugPrint('📺 [ZegoVoiceService] Update Type: $updateType');
        debugPrint('📺 [ZegoVoiceService] Streams Count: ${streamList.length}');
        for (var stream in streamList) {
          if (updateType == ZegoUpdateType.Add) {
            debugPrint('✅ [ZegoVoiceService] New stream detected:');
            debugPrint('   - Stream ID: ${stream.streamID}');
            debugPrint('   - User ID: ${stream.user.userID}');
            debugPrint('   - User Name: ${stream.user.userName}');
            onStreamAdd?.call(stream.streamID, stream.user.userID);
            // Auto-play the stream
            debugPrint('🎵 [ZegoVoiceService] Auto-playing stream: ${stream.streamID}');
            _playStream(stream.streamID);
          } else if (updateType == ZegoUpdateType.Delete) {
            debugPrint('❌ [ZegoVoiceService] Stream removed: ${stream.streamID}');
            onStreamRemove?.call(stream.streamID);
            _stopPlayingStream(stream.streamID);
          }
        }
      };
      
      ZegoExpressEngine.onPublisherStateUpdate = (String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
        debugPrint('📤 [ZegoVoiceService] ===== PUBLISHER STATE UPDATE =====');
        debugPrint('📤 [ZegoVoiceService] Stream ID: $streamID');
        debugPrint('📤 [ZegoVoiceService] State: $state');
        debugPrint('📤 [ZegoVoiceService] Error Code: $errorCode');
        if (state == ZegoPublisherState.Publishing) {
          _isPublishing = true;
          debugPrint('✅ [ZegoVoiceService] Publishing is ACTIVE');
          debugPrint('✅ [ZegoVoiceService] Audio stream is now live and broadcasting');
        } else if (state == ZegoPublisherState.NoPublish) {
          _isPublishing = false;
          debugPrint('⚠️ [ZegoVoiceService] Publishing is INACTIVE');
        } else if (state == ZegoPublisherState.PublishRequesting) {
          debugPrint('⏳ [ZegoVoiceService] Publishing is REQUESTING');
        } else if (errorCode != 0) {
          // ✅ Ignore camera permission errors (1003023) for voice-only calls
          if (errorCode == 1003023) {
            debugPrint('ℹ️ [ZegoVoiceService] Camera permission error (ignored for voice-only): $errorCode');
            debugPrint('ℹ️ [ZegoVoiceService] This is normal for voice-only calls - audio should still work');
          } else {
            debugPrint('❌ [ZegoVoiceService] Publisher state error: errorCode=$errorCode');
            onError?.call('Publisher error: $errorCode');
          }
        }
      };
      
      ZegoExpressEngine.onPlayerStateUpdate = (String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData) {
        debugPrint('📥 [ZegoVoiceService] ===== PLAYER STATE UPDATE =====');
        debugPrint('📥 [ZegoVoiceService] Stream ID: $streamID');
        debugPrint('📥 [ZegoVoiceService] State: $state');
        debugPrint('📥 [ZegoVoiceService] Error Code: $errorCode');
        if (state == ZegoPlayerState.Playing) {
          debugPrint('✅ [ZegoVoiceService] Stream is PLAYING - audio should be audible');
        } else if (state == ZegoPlayerState.NoPlay) {
          debugPrint('⚠️ [ZegoVoiceService] Stream is NOT PLAYING');
        } else if (errorCode != 0) {
          debugPrint('❌ [ZegoVoiceService] Player state error: errorCode=$errorCode');
        }
      };
      
      // ✅ Listen for audio frame events to confirm audio is working
      ZegoExpressEngine.onPublisherCapturedAudioFirstFrame = () {
        debugPrint('🎤 [ZegoVoiceService] ✅ Audio capture started - microphone is active');
      };
      
      ZegoExpressEngine.onPublisherSendAudioFirstFrame = (ZegoPublishChannel channel) {
        debugPrint('📡 [ZegoVoiceService] ✅ Audio frame sent - stream is broadcasting (channel: $channel)');
      };
      
      ZegoExpressEngine.onPlayerRecvAudioFirstFrame = (String streamID) {
        debugPrint('🔊 [ZegoVoiceService] ✅ Received audio from stream: $streamID - audio should be audible');
      };
      
      debugPrint('✅ [ZegoVoiceService] Zego Express Engine initialized');
      return true;
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Initialization error: $e');
      onError?.call('Initialization error: $e');
      return false;
    }
  }
  
  // ✅ Get detailed error message
  String _getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 1001005:
        return 'Voice login failed (1001005). Try enabling token auth in Zego Console or check App Sign.';
      case 1002001:
        return 'User already in another room or authentication failed';
      case 1002002:
        return 'Network connection error - check internet connectivity';
      case 1002003:
        return 'Invalid room ID format';
      case 1002004:
        return 'Room authentication failed - invalid credentials';
      case 1003023:
        return 'Camera permission denied (voice-only mode active)';
      default:
        return 'Voice service error: $errorCode (app will work without voice)';
    }
  }
  
  // ✅ Schedule reconnection attempt
  void _scheduleReconnect(String roomID) {
    _reconnectTimer?.cancel();
    
    final delay = Duration(seconds: 2 << _joinRoomRetries); // Exponential backoff
    debugPrint('🔄 [ZegoVoiceService] Scheduling reconnect attempt ${_joinRoomRetries + 1}/$_maxJoinRetries in ${delay.inSeconds}s');
    
    _reconnectTimer = Timer(delay, () {
      debugPrint('🔄 [ZegoVoiceService] Attempting automatic reconnect to room $roomID');
      joinRoom(roomID);
    });
  }
  
  // ✅ Login user
  Future<void> loginUser(String userID, String userName) async {
    _currentUserID = userID;
    _currentUserName = userName;
    debugPrint('✅ [ZegoVoiceService] User logged in: $userID ($userName)');
  }
  
  /// Join room. Use [token] when your Zego project uses token auth (recommended for production).
  Future<bool> joinRoom(String roomID, {String? token}) async {
    try {
      _joinRoomRetries++;
      debugPrint('🎤 [ZegoVoiceService] ===== JOINING ROOM =====');
      debugPrint('🎤 [ZegoVoiceService] Room ID: $roomID');
      debugPrint('🎤 [ZegoVoiceService] Current Room ID: $_currentRoomID');
      debugPrint('🎤 [ZegoVoiceService] Attempt: $_joinRoomRetries/$_maxJoinRetries');
      
      if (_engine == null) {
        debugPrint('❌ [ZegoVoiceService] Engine not initialized');
        onError?.call('Engine not initialized');
        return false;
      }
      
      if (_currentUserID == null) {
        debugPrint('❌ [ZegoVoiceService] User not logged in');
        debugPrint('❌ [ZegoVoiceService] Current User ID: $_currentUserID');
        onError?.call('User not logged in');
        return false;
      }
      
      // ✅ CRITICAL: Leave previous room if joining a different room
      if (_currentRoomID != null && _currentRoomID != roomID) {
        debugPrint('⚠️ [ZegoVoiceService] Already in room $_currentRoomID, leaving before joining $roomID');
        try {
          await _engine!.logoutRoom();
          debugPrint('✅ [ZegoVoiceService] Left previous room: $_currentRoomID');
          _currentRoomID = null;
          // Wait a bit for the logout to complete
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('⚠️ [ZegoVoiceService] Error leaving previous room: $e');
          // Continue anyway - try to join new room
        }
      }
      
      debugPrint('✅ [ZegoVoiceService] Engine ready');
      debugPrint('✅ [ZegoVoiceService] User ID: $_currentUserID');
      debugPrint('✅ [ZegoVoiceService] User Name: $_currentUserName');
      
      // Don't set _currentRoomID here — only set in onRoomStateUpdate when Connected
      _pendingJoinCompleter = Completer<bool>();
      _pendingJoinRoomID = roomID;
      
      ZegoUser user = ZegoUser(_currentUserID!, _currentUserName ?? 'User');
      // Token: pass when using token auth (e.g. from your backend get_zego_token.php)
      ZegoRoomConfig roomConfig = ZegoRoomConfig(0, true, token ?? '');
      
      debugPrint('🎤 [ZegoVoiceService] Calling loginRoom...');
      
      await _engine!.loginRoom(roomID, user, config: roomConfig).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ [ZegoVoiceService] loginRoom API timeout');
          throw TimeoutException('Room login API timed out');
        },
      );
      
      debugPrint('✅ [ZegoVoiceService] loginRoom call completed; waiting for Connected callback...');
      
      // Wait for actual Connected (or Disconnected/error) from SDK (null-safe: completer may be cleared by callback)
      final completer = _pendingJoinCompleter;
      final bool connected = completer != null
          ? await completer.future.timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('⏱️ [ZegoVoiceService] No Connected callback within 15s');
                _pendingJoinCompleter = null;
                _pendingJoinRoomID = null;
                return false;
              },
            )
          : false;
      
      _pendingJoinCompleter = null;
      _pendingJoinRoomID = null;
      
      if (connected) {
        _joinRoomRetries = 0;
        _hasJoinFailed = false;
      }
      return connected;
    } catch (e, stackTrace) {
      if (_pendingJoinCompleter != null && !_pendingJoinCompleter!.isCompleted) {
        _pendingJoinCompleter!.complete(false);
        _pendingJoinCompleter = null;
        _pendingJoinRoomID = null;
      }
      debugPrint('❌ [ZegoVoiceService] Join room error: $e');
      debugPrint('❌ [ZegoVoiceService] Error type: ${e.runtimeType}');
      
      if (e is TimeoutException) {
        debugPrint('❌ [ZegoVoiceService] Room join timed out - network may be slow');
        onError?.call('Voice connection timeout. Continuing without voice...');
      } else {
        debugPrint('❌ [ZegoVoiceService] Stack trace: $stackTrace');
        onError?.call('Voice connection failed. App will work without voice features.');
      }
      
      _hasJoinFailed = true;
      
      // Retry if under limit
      if (_joinRoomRetries < _maxJoinRetries) {
        _scheduleReconnect(roomID);
      } else {
        debugPrint('❌ [ZegoVoiceService] Max retries reached. Voice features disabled.');
        onError?.call('Voice unavailable after 3 attempts. App will work without voice.');
      }
      
      return false;
    }
  }
  
  // ✅ Leave room
  Future<void> leaveRoom() async {
    try {
      if (_engine == null) return;
      
      // Stop publishing
      if (_isPublishing) {
        await stopPublishing();
      }
      
      // Stop all playing streams
      for (var streamID in _activeStreams.toList()) {
        await _stopPlayingStream(streamID);
      }
      
      // Leave room
      if (_currentRoomID != null) {
        await _engine!.logoutRoom();
        debugPrint('✅ [ZegoVoiceService] Left room: $_currentRoomID');
        _currentRoomID = null;
      }
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Leave room error: $e');
    }
  }
  
  // ✅ Start publishing audio stream (when user takes a seat)
  Future<bool> startPublishing() async {
    try {
      debugPrint('🎤 [ZegoVoiceService] ===== STARTING PUBLISHING =====');
      
      if (_engine == null) {
        debugPrint('❌ [ZegoVoiceService] Cannot publish: engine is null');
        onError?.call('Engine not initialized');
        return false;
      }
      
      if (_currentRoomID == null) {
        debugPrint('❌ [ZegoVoiceService] Cannot publish: room ID is null');
        onError?.call('Not in a room');
        return false;
      }
      
      if (_currentUserID == null) {
        debugPrint('❌ [ZegoVoiceService] Cannot publish: user ID is null');
        onError?.call('User not logged in');
        return false;
      }
      
      debugPrint('✅ [ZegoVoiceService] Pre-checks passed');
      debugPrint('🎤 [ZegoVoiceService] Room ID: $_currentRoomID');
      debugPrint('🎤 [ZegoVoiceService] User ID: $_currentUserID');
      debugPrint('🎤 [ZegoVoiceService] Currently publishing: $_isPublishing');
      
      if (_isPublishing) {
        debugPrint('⚠️ [ZegoVoiceService] Already publishing - returning success');
        return true;
      }
      
      // Generate stream ID
      String streamID = '${_currentRoomID}_${_currentUserID}_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('🎤 [ZegoVoiceService] Generated stream ID: $streamID');
      
      // Start publishing
      debugPrint('🎤 [ZegoVoiceService] Calling startPublishingStream...');
      await _engine!.startPublishingStream(streamID);
      
      debugPrint('✅ [ZegoVoiceService] startPublishingStream call completed');
      debugPrint('✅ [ZegoVoiceService] Started publishing stream: $streamID');
      debugPrint('✅ [ZegoVoiceService] Waiting for publisher state update...');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [ZegoVoiceService] Start publishing error: $e');
      debugPrint('❌ [ZegoVoiceService] Stack trace: $stackTrace');
      onError?.call('Start publishing error: $e');
      return false;
    }
  }
  
  // ✅ Stop publishing audio stream (when user leaves seat)
  Future<bool> stopPublishing() async {
    try {
      if (_engine == null) return false;
      
      if (!_isPublishing) {
        debugPrint('⚠️ [ZegoVoiceService] Not publishing');
        return true;
      }
      
      await _engine!.stopPublishingStream();
      
      _isPublishing = false;
      
      debugPrint('✅ [ZegoVoiceService] Stopped publishing');
      return true;
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Stop publishing error: $e');
      return false;
    }
  }
  
  // ✅ Play stream (automatically called when new stream is detected)
  Future<void> _playStream(String streamID) async {
    try {
      if (_engine == null) return;
      
      if (_activeStreams.contains(streamID)) {
        debugPrint('⚠️ [ZegoVoiceService] Stream already playing: $streamID');
        return;
      }
      
      // Start playing stream
      await _engine!.startPlayingStream(streamID);
      
      _activeStreams.add(streamID);
      debugPrint('✅ [ZegoVoiceService] Started playing stream: $streamID');
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Play stream error: $e');
    }
  }
  
  // ✅ Stop playing stream
  Future<void> _stopPlayingStream(String streamID) async {
    try {
      if (!_activeStreams.contains(streamID)) return;
      
      await _engine!.stopPlayingStream(streamID);
      
      _activeStreams.remove(streamID);
      debugPrint('✅ [ZegoVoiceService] Stopped playing stream: $streamID');
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Stop playing stream error: $e');
    }
  }
  
  // ✅ Enable/Disable microphone
  Future<void> enableMicrophone(bool enable) async {
    try {
      if (_engine == null) return;
      await _engine!.muteMicrophone(!enable);
      debugPrint('✅ [ZegoVoiceService] Microphone ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Enable microphone error: $e');
    }
  }
  
  // ✅ Enable/Disable speaker
  Future<void> enableSpeaker(bool enable) async {
    try {
      if (_engine == null) return;
      await _engine!.muteSpeaker(!enable);
      debugPrint('✅ [ZegoVoiceService] Speaker ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Enable speaker error: $e');
    }
  }
  
  // ✅ Get current publishing state
  bool get isPublishing => _isPublishing;
  
  // ✅ Get current room ID
  String? get currentRoomID => _currentRoomID;
  
  // ✅ Get current user ID
  String? get currentUserID => _currentUserID;
  
  // ✅ Get active players count
  int get activePlayersCount => _activeStreams.length;
  
  // ✅ Check if join has failed (for graceful degradation)
  bool get hasJoinFailed => _hasJoinFailed;
  
  // ✅ Dispose and cleanup
  Future<void> dispose() async {
    try {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      
      await leaveRoom();
      
      if (_engine != null) {
        await ZegoExpressEngine.destroyEngine();
        _engine = null;
      }
      
      debugPrint('✅ [ZegoVoiceService] Disposed');
    } catch (e) {
      debugPrint('❌ [ZegoVoiceService] Dispose error: $e');
    }
  }
}
