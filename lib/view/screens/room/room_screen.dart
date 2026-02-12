// ignore_for_file: unused_field, unused_local_variable, unused_element, dead_code

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/category_bottom_sheet.dart';
import 'package:shaheen_star_app/components/gift_animation_overlay.dart';
import 'package:shaheen_star_app/components/profile_with_frame.dart';
import 'package:shaheen_star_app/components/tools_bottom_sheet.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/gift_web_socket_service.dart';
import 'package:shaheen_star_app/controller/provider/backback_provider.dart';
import 'package:shaheen_star_app/controller/provider/broadcast_provider.dart';
import 'package:shaheen_star_app/controller/provider/gift_display_provider.dart';
import 'package:shaheen_star_app/controller/provider/gift_provider.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/join_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/leave_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/room_message_provider.dart';
import 'package:shaheen_star_app/controller/provider/seat_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_message_provider.dart';
import 'package:shaheen_star_app/controller/provider/zego_voice_provider.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:shaheen_star_app/model/seat_model.dart';
import 'package:shaheen_star_app/model/send_message_room_model.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:shaheen_star_app/utils/country_utils.dart';
import 'package:shaheen_star_app/view/screens/room/room_bootom_sheet_content.dart';
import 'package:shaheen_star_app/view/screens/room/room_ranking_screen.dart';
import 'package:shaheen_star_app/view/screens/user_chat/user_chat_list_screen.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';
import 'package:shaheen_star_app/view/widgets/user_id_display.dart';

import '../../../controller/api_manager/number_format.dart';
import '../../../controller/provider/store_provider.dart';
import 'package:shaheen_star_app/view/screens/merchant/wallet_screen.dart';

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String roomId;
  final String roomCreatorId;
  final String topic;
  final File? avatarUrl;
  final String? roomProfileUrl;

  const RoomScreen({
    super.key,
    required this.roomName,
    required this.roomCreatorId,
    required this.roomId,
    required this.topic,
    this.avatarUrl,
    this.roomProfileUrl,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _LuckyGiftSnapshot {
  final String senderName;
  final String senderAvatar;
  final String giftName;
  final double baseTotal;

  const _LuckyGiftSnapshot({
    required this.senderName,
    required this.senderAvatar,
    required this.giftName,
    required this.baseTotal,
  });
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  bool _showAnnouncement = true;

  // Lucky Gift Banner State
  bool _isLuckyBannerVisible = false;
  int _luckyMultiplier = 0;
  double _luckyReward = 0;
  double _luckyGiftPrice = 0;
  String _luckySenderName = 'User';
  Timer? _luckyBannerTimer;
  final Map<String, _LuckyGiftSnapshot> _luckyGiftSnapshots = {};
  AnimationController? _luckyBannerAnimationController;
  Animation<Offset>? _luckyBannerSlideAnimation;

  final TextEditingController _messageController = TextEditingController();
  String? totalCoins = "0.0";
  String? _currentUserId; // Google ID
  String? _databaseUserId; // Database user_id for WebSocket actions
  String? _baishunUserId; // Game user_id (no leading zeros)
  bool _isInitializing = true;
  late String _displayRoomName;
  late String? _displayRoomProfileUrl;
  InAppWebViewController? _gameWebController;
  final EventChannel _bsEventChannel = const EventChannel('baishunChannel');
  StreamSubscription? _bsEventSub;
  bool _isGameLoading = false;
  int _selectedMessageTab = 0; // 0: All, 1: Message, 2: Gift
  Seat? _selectedSeatForGift; // ✅ Track selected seat for gift sending

  // ✅ BAISHUN session-level code (ONE code per game session, NEVER regenerate)
  String? _currentGameSessionCode;
  // ✅ ss_token from backend (code exchange). Some games need this in getConfig to login (e.g. MeshH5).
  String? _currentGameSessionSstoken;
  // ✅ User data from get_user_info (name, avatar, balance) so game can display it in getConfig
  Map<String, dynamic>? _currentGameUserInfo;
  // Track whether the game has already called getConfig in this session.
  bool _hasGameRequestedConfig = false;

  // ✅ Gift animation overlay state
  GiftModel? _currentGiftAnimation;
  int _currentGiftQuantity = 0;
  String? _currentGiftSenderName;
  String? _currentGiftSenderAvatar;
  String? _currentGiftReceiverName;
  String? _currentGiftReceiverAvatar;
  bool _currentGiftIsMultipleReceivers = false;
  bool _clearedChatOnEnter = false;
  bool _skipInitialChatHistory = true;
  final bool _ignoreChatHistory = true;
  bool _giftsFetchRequested = false;

  String? _normalizeRoomProfileUrl(String? url) {
    if (url == null || url.trim().isEmpty || url == 'null') {
      return null;
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return '${ApiConstants.baseUrl}$url';
  }

  String _normalizeBaishunUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '';
    final stripped = userId.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? userId : stripped;
  }

  String _resolveBaishunCountryCode() {
    String? raw = _currentGameUserInfo?['country']?.toString();
    if (raw == null || raw.trim().isEmpty) {
      raw = _currentGameUserInfo?['country_code']?.toString();
    }
    if (raw == null || raw.trim().isEmpty) {
      try {
        final profile = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        raw = profile.country;
      } catch (_) {
        raw = null;
      }
    }
    final cleaned = raw?.trim() ?? '';
    if (cleaned.length == 2) return cleaned.toUpperCase();
    return CountryUtils.getCountryCode(cleaned) ?? 'PK';
  }

  // Game integration constants (provided)
  static const String _appChannel = 'shaheen';
  static const String _appName = 'shaheen_app';
  static const int _appId = 5864440123;
  // NOTE: Do NOT embed BAISHUN AppKey here. Keep secrets off the client and
  // perform signing on a trusted backend when possible.

  Future<String> _generateOneTimeCode() async {
    // Try to get a server-minted one-time code first. Fall back to local generation.
    try {
      final serverCode = await ApiManager.requestGameCode(
        userId: _databaseUserId ?? '',
        roomId: widget.roomId,
      );
      if (serverCode != null && serverCode.isNotEmpty) {
        print('[RoomScreen] Obtained server one-time code');
        return serverCode;
      }
    } catch (e) {
      print('[RoomScreen] requestGameCode failed: $e');
    }

    // Fallback: Generate a cryptographically-random one-time code locally.
    try {
      final rng = Random.secure();
      final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      final code = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return code;
    } catch (e) {
      print('[RoomScreen] _generateOneTimeCode error: $e');
      return 'code_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// BAISHUN doc: "injecting API with the help of JSBridge" - NativeBridge must
  /// exist BEFORE game scripts run.
  /// Injected at AT_DOCUMENT_START. If bridge not ready yet, getConfig is queued
  /// and retried until ready (fixes stuck games).
  static const String _kBaishunNativeBridgeAtDocumentStart = r'''(function(){
try {
  if(window.NativeBridge && window.NativeBridge.getConfig) return;
  function doGetConfig(msg, retryCount) {
    retryCount = retryCount || 0;
    if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('getConfig', msg).then(function(config){
        var msgData = typeof msg === 'string' ? (function(){ try{ return JSON.parse(msg); }catch(e){ return {}; } })() : (msg || {});
        var callbackName = msgData.jsCallback || null;
        if(callbackName && config && typeof config === 'object'){
          try{
            if(window.MeshH5 && typeof window.MeshH5._invokeCallback === 'function')
              window.MeshH5._invokeCallback(callbackName, config);
            else if(typeof window[callbackName] === 'function')
              window[callbackName](config);
            else { window.__gameConfigFromApp = config; window.dispatchEvent(new CustomEvent('nativeConfig',{detail:config})); }
          }catch(e){ console.error('getConfig callback:', e); }
        }
      }).catch(function(err){ console.error('getConfig failed:', err); });
      return;
    }
    if(retryCount < 50) setTimeout(function(){ doGetConfig(msg, retryCount + 1); }, 100);
    else console.error('NativeBridge getConfig: bridge not ready after 5s');
  }
  window.NativeBridge = {
    getConfig: function(msg){
      try{
        doGetConfig(msg);
      }catch(e){ console.error('NativeBridge.getConfig:', e); }
    },
    destroy: function(msg){ try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('destroy', msg); }catch(e){} },
    gameRecharge: function(msg){ try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('gameRecharge', msg); }catch(e){} },
    gameLoaded: function(msg){ try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('gameLoaded', msg); }catch(e){} }
  };
} catch(e) { console.error('NativeBridge init:', e); }
})();''';

  /// BAISHUN doc 2.1: gameMode is string. 2 = Half Screen (Streamer Show), 3 = Full screen (Game Lobby). Cannot be 0.
  String _validGameModeString(dynamic value) {
    if (value == null) return '2';
    final v = value is int ? value : int.tryParse(value.toString());
    if (v == null || v == 0) return '2';
    if (v == 3) return '3';
    return '2'; // 2 = half-screen, 3 = full-screen only per doc
  }

  /// Logs user info and ss_token sent to game (when opening game / getConfig / onLoadStop).
  /// Use [config] when logging from an already-built config map; otherwise uses _currentGameUserInfo and _currentGameSessionSstoken.
  void _logGameConfigSent({Map<String, dynamic>? config}) {
    final Map<String, dynamic> data = config ?? {};
    if (config == null) {
      if (_currentGameSessionSstoken != null &&
          _currentGameSessionSstoken!.isNotEmpty) {
        data['ss_token'] = _currentGameSessionSstoken;
      }
      data['uid'] = _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId);
      if (_currentGameUserInfo != null && _currentGameUserInfo!.isNotEmpty) {
        final ui = _currentGameUserInfo!;
        if (ui['user_name'] != null)
          data['user_name'] = ui['user_name'].toString();
        if (ui['userName'] != null)
          data['userName'] = ui['userName'].toString();
        if (ui['balance'] != null) data['balance'] = ui['balance'];
        if (ui['user_avatar'] != null)
          data['user_avatar'] = ui['user_avatar'].toString().length > 50
              ? '${ui['user_avatar'].toString().substring(0, 50)}...'
              : ui['user_avatar'].toString();
      }
    }
    final token = data['ss_token']?.toString() ?? '';
    final maskedToken = token.isEmpty
        ? '(empty)'
        : (token.length <= 16
              ? token
              : '${token.substring(0, 8)}...${token.length > 12 ? token.substring(token.length - 4) : ""}');
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] ========== User info & ss_token sent to game ==========',
    );
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] user_name: ${data['user_name'] ?? "(not set)"}',
    );
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] userName:   ${data['userName'] ?? "(not set)"}',
    );
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] balance:  ${data['balance'] ?? "(not set)"}',
    );
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] uid:      ${data['uid'] ?? "(not set)"}',
    );
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] user_avatar: ${data['user_avatar'] != null ? (data['user_avatar'].toString().length > 60 ? "yes (${data['user_avatar'].toString().length} chars)" : data['user_avatar']) : "(not set)"}',
    );
    print('[RoomScreen] 🎮 [GAME CONFIG] ss_token: $maskedToken');
    print(
      '[RoomScreen] 🎮 [GAME CONFIG] ============================================================',
    );
  }

  /// Normalizes backend get_user_info response so getConfig always has user_name, userName, balance, user_avatar.
  /// Backend may return nickname/name/username, coins/balance, avatar/profile_pic etc.
  Map<String, dynamic> _normalizeGameUserInfo(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final name =
        raw['user_name'] ??
        raw['userName'] ??
        raw['nickname'] ??
        raw['name'] ??
        raw['username'];
    if (name != null) {
      out['user_name'] = name.toString();
      out['userName'] = name.toString();
    }
    final balance =
        raw['balance'] ??
        raw['coins'] ??
        raw['merchant_coins'] ??
        raw['coin_balance'];
    if (balance != null) {
      out['balance'] = balance is num
          ? balance
          : (double.tryParse(balance.toString()) ?? 0);
    }
    final avatar =
        raw['user_avatar'] ??
        raw['userAvatar'] ??
        raw['avatar'] ??
        raw['profile_pic'] ??
        raw['profile_picture'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      out['user_avatar'] = avatar.toString();
    }
    return out;
  }

  /// Opens any BAISHUN game in a WebView. Same process for ALL games (Fruit Carnival,
  /// LuckyChest, Teen Patti, Dragon Tiger, etc.): requestGameCode → inject code in URL →
  /// getConfig returns same code. No game-specific branching; if some games work and others
  /// don't, the difference is on BAISHUN/game-server side (e.g. which games call get_sstoken).
  Future<void> _openGameWebView(
    BuildContext context,
    String url,
    String name, {
    Map<String, dynamic>? meta,
  }) async {
    // ✅ Step 1: Generate SESSION-LEVEL code ONCE (CRITICAL: Never regenerate!)
    // This code is like an OAuth auth-code, not a nonce.
    // URL.code MUST equal getConfig.code or BAISHUN kills the session.
    try {
      final userId = _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId);
      final roomId = widget.roomId;

      if (userId.isEmpty) {
        print('[RoomScreen] ❌ Cannot request game code: userId is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to launch game: User not logged in')),
        );
        return;
      }

      print('[RoomScreen] 🎮 Generating SESSION code for game...');
      print('[RoomScreen]    userId: $userId, roomId: $roomId');

      _currentGameSessionCode = await ApiManager.requestGameCode(
        userId: userId,
        roomId: roomId,
      );

      // ⚠️ TEMPORARY FIX: If backend endpoint doesn't exist, generate local code
      if (_currentGameSessionCode == null || _currentGameSessionCode!.isEmpty) {
        print(
          '[RoomScreen] ⚠️ Backend endpoint not available - using temporary local code generation',
        );
        print(
          '[RoomScreen] ⚠️ NOTE: This is a temporary workaround. Backend should implement request_game_code.php',
        );
        _currentGameSessionCode = await _generateOneTimeCode();
        print(
          '[RoomScreen] ✅ Generated temporary SESSION code: $_currentGameSessionCode',
        );
      } else {
        print(
          '[RoomScreen] ✅ Received SESSION code from server: $_currentGameSessionCode',
        );
      }
      print(
        '[RoomScreen] 🔒 CRITICAL: This code will be reused in getConfig. NEVER regenerate!',
      );

      // ✅ DO NOT call get_sstoken here. Code is one-time and must be consumed by the game server.
      _currentGameSessionSstoken = null;

      // ✅ Fetch user info (name, avatar, balance) from backend so game can display it
      _currentGameUserInfo = null;
      try {
        final uid = (_baishunUserId ?? _databaseUserId) != null
            ? int.tryParse(
                _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId),
              )
            : null;
        if (uid != null) {
          final userInfo = await ApiManager.getUserInfoById(uid);
          if (userInfo != null && userInfo.isNotEmpty) {
            _currentGameUserInfo = _normalizeGameUserInfo(userInfo);
            print(
              '[RoomScreen] ✅ Got user info for game: name=${_currentGameUserInfo!['user_name'] ?? _currentGameUserInfo!['userName']}, balance=${_currentGameUserInfo!['balance']}, avatar=${_currentGameUserInfo!['user_avatar'] != null ? "yes" : "no"}',
            );
          }
        }
      } catch (e) {
        print('[RoomScreen] ⚠️ getUserInfoById failed: $e');
      }

      // 🎮 Log user info when game opens (to verify we send correct data)
      _logGameConfigSent();
    } catch (e) {
      print('[RoomScreen] ❌ Exception requesting game code: $e');
      print('[RoomScreen] ⚠️ Falling back to local code generation');
      try {
        _currentGameSessionCode = await _generateOneTimeCode();
        print(
          '[RoomScreen] ✅ Generated fallback SESSION code: $_currentGameSessionCode',
        );
      } catch (fallbackError) {
        print('[RoomScreen] ❌ Fallback code generation failed: $fallbackError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to launch game: $fallbackError')),
        );
        return;
      }
    }

    final countryCode = _resolveBaishunCountryCode();

    // Resolve per-game create/close endpoints from meta (fall back to localhost)
    final createGameUrl =
        (meta != null &&
            (meta['create_url'] ??
                    meta['createUrl'] ??
                    meta['createGameUrl']) !=
                null)
        ? (meta['create_url'] ?? meta['createUrl'] ?? meta['createGameUrl'])
              .toString()
        : 'http://127.0.0.1';
    final closeGameUrl =
        (meta != null &&
            (meta['close_url'] ?? meta['closeUrl'] ?? meta['closeGameUrl']) !=
                null)
        ? (meta['close_url'] ?? meta['closeUrl'] ?? meta['closeGameUrl'])
              .toString()
        : 'http://127.0.0.1';

    // Notify game server that a game session is being created (use per-game endpoint when available)
    _notifyGameLifecycle(createGameUrl, 'create', {
      'gameUrl': url,
      'gameId': meta?['gameId'],
      'roomId': widget.roomId,
      'userId': _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId),
    });

    // ✅ Step 2: Inject BAISHUN parameters into game URL
    // CRITICAL: Use the SAME session code that will be returned in getConfig!
    String finalUrl = url;
    try {
      final uri = Uri.parse(url);
      final q = Map<String, String>.from(uri.queryParameters);

      // Required BAISHUN parameters
      q['appChannel'] = _appChannel;
      q['appId'] = _appId.toString();
      q['userId'] = _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId);
      q['code'] =
          _currentGameSessionCode ?? ''; // ⚠️ MUST match getConfig.code!

      // Optional parameters
      q['roomId'] = widget.roomId;
      if (meta != null && meta['gameId'] != null)
        q['game_id'] = meta['gameId'].toString();
      q['language'] = (meta?['language'] ?? '2').toString();
      q['country'] = countryCode;

      finalUrl = uri.replace(queryParameters: q).toString();
      print('[RoomScreen] ✅ Opening game with BAISHUN parameters:');
      print('[RoomScreen]    URL: $finalUrl');
      print('[RoomScreen]    appChannel: ${q['appChannel']}');
      print('[RoomScreen]    appId: ${q['appId']}');
      print('[RoomScreen]    userId: ${q['userId']}');
      print('[RoomScreen]    code: ${q['code']}');
      print('[RoomScreen]    roomId: ${q['roomId']}');
    } catch (e) {
      print('[RoomScreen] ❌ Failed to append query params to game URL: $e');
      print('[RoomScreen]    Using original URL: $url');
      finalUrl = url;
    }

    // ✅ NOTE: We do NOT fetch ss_token here.
    // The game server will use the 'code' parameter to obtain ss_token from the app server.
    // The code is a one-time token that becomes unusable after the game server uses it.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        // Track loading state locally (initialized once per bottom sheet)
        bool isBottomSheetLoading = true;
        final gameServerErrorNotifier = ValueNotifier<bool>(false);

        // Use StatefulBuilder to manage loading state within the bottom sheet
        return StatefulBuilder(
          builder: (builderContext, setBottomSheetState) {
            // Force hide loading after 15 seconds as fallback
            Future.delayed(Duration(seconds: 15), () {
              if (!builderContext.mounted) return;
              try {
                setBottomSheetState(() {
                  isBottomSheetLoading = false;
                });
              } catch (e) {
                print('[RoomScreen] Failed to hide loading after timeout: $e');
              }
            });

            return SizedBox(
              height: MediaQuery.of(builderContext).size.height * 0.95,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF083814),
                    title: Text(name),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reload',
                        onPressed: () async {
                          try {
                            await _gameWebController?.reload();
                            print('[RoomScreen] Manual reload requested');
                          } catch (e) {
                            print('[RoomScreen] Manual reload failed: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open in external browser',
                        onPressed: () async {
                          try {
                            final uri = Uri.parse(finalUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              print(
                                '[RoomScreen] Cannot open external URL: $finalUrl',
                              );
                            }
                          } catch (e) {
                            print('[RoomScreen] Open external failed: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(builderContext).pop(),
                      ),
                    ],
                  ),
                  body: Stack(
                    children: [
                      // Give WebView full size so game canvas can render (fixes blank white screen)
                      Positioned.fill(
                        child: InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(finalUrl),
                            // ✅ Don't set Referer/Origin - let browser handle it naturally
                            // Setting wrong headers causes CORS blocking
                          ),
                          // BAISHUN doc: "injecting API with the help of JSBridge" - must be available before game runs.
                          // AT_DOCUMENT_START ensures NativeBridge exists when game script calls getConfig (fixes blank screen).
                          initialUserScripts:
                              UnmodifiableListView<UserScript>(<UserScript>[
                                UserScript(
                                  source: _kBaishunNativeBridgeAtDocumentStart,
                                  injectionTime:
                                      UserScriptInjectionTime.AT_DOCUMENT_START,
                                ),
                              ]),
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              javaScriptEnabled: true,
                              mediaPlaybackRequiresUserGesture: false,
                              useShouldOverrideUrlLoading: true,
                              clearCache: false,
                              cacheEnabled:
                                  true, // ✅ Enable cache for better performance
                              // Chrome UA so game servers serve full H5 game (many block or break on default WebView UA)
                              userAgent:
                                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                              // ✅ Network and connectivity settings
                              javaScriptCanOpenWindowsAutomatically: true,
                              supportZoom: false,
                              // Transparent so game canvas is visible; white comes from page/game
                              transparentBackground: true,
                              // ✅ Disable web security to allow cross-origin requests
                              disableContextMenu: false,
                            ),
                            android: AndroidInAppWebViewOptions(
                              useHybridComposition: true,
                              // Enable so WebGL/canvas and game content render (false often causes blank white screen)
                              hardwareAcceleration: true,
                              allowFileAccess: true,
                              allowContentAccess:
                                  true, // ✅ Allow content access
                              builtInZoomControls: false,
                              supportMultipleWindows: false,
                              domStorageEnabled: true,
                              databaseEnabled:
                                  true, // ✅ Enable database storage
                              useWideViewPort: true,
                              loadWithOverviewMode: true,
                              // ✅ Use default cache mode for better network connectivity
                              cacheMode: AndroidCacheMode.LOAD_DEFAULT,
                              // Allow mixed content (http resources on https pages) if needed
                              mixedContentMode: AndroidMixedContentMode
                                  .MIXED_CONTENT_ALWAYS_ALLOW,
                              // ✅ Ensure network access
                              blockNetworkImage: false,
                              blockNetworkLoads: false,
                              // ✅ Allow all domain access for game server connections
                              safeBrowsingEnabled: false,
                              thirdPartyCookiesEnabled: true,
                            ),
                            ios: IOSInAppWebViewOptions(
                              allowsInlineMediaPlayback: true,
                              allowsBackForwardNavigationGestures: false,
                            ),
                          ),
                          onWebViewCreated: (controller) {
                            _gameWebController = controller;
                            // Primary getConfig handler used by flutter_inappwebview
                            controller.addJavaScriptHandler(
                              handlerName: 'getConfig',
                              callback: (args) async {
                                _hasGameRequestedConfig = true;
                                print(
                                  '[RoomScreen] ⭐⭐⭐ getConfig handler called by game! Args: $args',
                                );
                                // ✅ CRITICAL: REUSE the session code from _openGameWebView!
                                // NEVER regenerate! URL.code MUST equal getConfig.code!
                                // The code is a session-level login ticket, NOT a per-request OTP.
                                // BAISHUN uses it ONCE to create ss_token, then uses ss_token.
                                // Regenerating causes: URL.code ≠ getConfig.code → session killed.
                                print(
                                  '[RoomScreen] 🔒 Using SESSION code (NEVER regenerate): $_currentGameSessionCode',
                                );
                                // ✅ Provider size: W:750, H:1334, SH (safe_height) per game - must match provider dashboard
                                final designW = 750;
                                final designH = 1334;
                                final safeH = meta?['safe_height'] is int
                                    ? (meta!['safe_height'] as int)
                                    : (int.tryParse(
                                            meta?['safe_height']?.toString() ??
                                                '',
                                          ) ??
                                          770);
                                final userIdStr = _normalizeBaishunUserId(
                                  _baishunUserId ?? _databaseUserId,
                                );
                                final userIdInt = int.tryParse(userIdStr) ?? 0;
                                final roomIdInt =
                                    int.tryParse(widget.roomId.toString()) ?? 0;
                                final gameModeInt =
                                    int.tryParse(
                                      _validGameModeString(meta?['gameMode']),
                                    ) ??
                                    2;
                                final languageInt =
                                    int.tryParse(
                                      (meta?['language'] ?? '2').toString(),
                                    ) ??
                                    2;
                                final token = _currentGameSessionSstoken ?? '';
                                final config = <String, dynamic>{
                                  'appChannel': _appChannel,
                                  'appId': _appId,
                                  'userId': userIdInt,
                                  'uid': userIdInt,
                                  // ⚠️ MUST be the SAME code as in URL query params!
                                  'code': _currentGameSessionCode ?? '',
                                  'roomId': roomIdInt,
                                  // Doc 2.1: gameMode string "2" or "3" only
                                  'gameMode': gameModeInt,
                                  'language': languageInt,
                                  'country': countryCode,
                                  'gameConfig': {
                                    'sceneMode': meta?['sceneMode'] ?? 0,
                                    'designWidth': designW,
                                    'designHeight': designH,
                                    'safeHeight': safeH,
                                  },
                                  'gsp': meta?['gsp'] ?? 101,
                                  'currencyIcon': meta?['currencyIcon'] ?? '',
                                  'token': token,
                                  'ss_token': token,
                                };
                                // ✅ Do not pass ss_token from client; game server must consume code once.

                                // ✅ User data from get_user_info so game can show name, avatar, balance
                                if (_currentGameUserInfo != null &&
                                    _currentGameUserInfo!.isNotEmpty) {
                                  final ui = _currentGameUserInfo!;
                                  if (ui['user_name'] != null)
                                    config['user_name'] = ui['user_name']
                                        .toString();
                                  if (ui['userName'] != null)
                                    config['userName'] = ui['userName']
                                        .toString();
                                  if (ui['balance'] != null)
                                    config['balance'] = ui['balance'] is num
                                        ? (ui['balance'] as num).toDouble()
                                        : double.tryParse(
                                            ui['balance'].toString(),
                                          );
                                  if (ui['user_avatar'] != null &&
                                      ui['user_avatar'].toString().isNotEmpty) {
                                    final av = ui['user_avatar'].toString();
                                    final fullUrl = av.startsWith('http')
                                        ? av
                                        : '${ApiConstants.baseUrl}$av';
                                    config['user_avatar'] = fullUrl;
                                    config['userAvatar'] = fullUrl;
                                  }
                                }

                                if (meta != null &&
                                    meta.containsKey('gameId')) {
                                  config['gameId'] = meta['gameId'];
                                }

                                if (meta != null) {
                                  meta.forEach((k, v) {
                                    if (!config.containsKey(k)) config[k] = v;
                                  });
                                }

                                // 🎮 Log exactly what we send to game via getConfig (user info + ss_token)
                                _logGameConfigSent(config: config);

                                // Some H5 games provide a jsCallback name inside params and expect
                                // the app to call jsCallback(config). The incoming `args` may be
                                // an array containing either an object or a JSON string.
                                String? jsCallback;
                                if (args.isNotEmpty) {
                                  final a = args[0];
                                  try {
                                    if (a is String) {
                                      final parsed = jsonDecode(a);
                                      if (parsed is Map &&
                                          parsed['jsCallback'] != null)
                                        jsCallback = parsed['jsCallback'];
                                    } else if (a is Map) {
                                      if (a['jsCallback'] != null)
                                        jsCallback = a['jsCallback'];
                                    }
                                  } catch (e) {
                                    // ignore parse errors
                                  }
                                }

                                final cfgJson = jsonEncode(config);
                                print(
                                  '[RoomScreen] 📦 Prepared config JSON: ${cfgJson.substring(0, cfgJson.length > 200 ? 200 : cfgJson.length)}...',
                                );
                                if (jsCallback != null &&
                                    jsCallback.isNotEmpty) {
                                  final call = "$jsCallback($cfgJson)";
                                  try {
                                    await controller.evaluateJavascript(
                                      source: call,
                                    );
                                    print(
                                      '[RoomScreen] ✅ Called game jsCallback successfully: $jsCallback',
                                    );
                                  } catch (e) {
                                    print(
                                      '[RoomScreen] ❌ Failed to call jsCallback: $e',
                                    );
                                  }
                                  // CRITICAL: Return config so Promise in game resolves with real config (was returning {} and game got stuck)
                                  return config;
                                }

                                // Fallback: return the config (will resolve the Promise if the game uses callHandler())
                                print(
                                  '[RoomScreen] ✅ Returning config to game (no jsCallback)',
                                );
                                return config;
                              },
                            );

                            // Additional handlers to support H5 calling NativeBridge.getConfig/destroy etc.
                            controller.addJavaScriptHandler(
                              handlerName: 'destroy',
                              callback: (args) {
                                print(
                                  '[RoomScreen] Game requested destroy: $args',
                                );
                                // Notify lifecycle close
                                _notifyGameLifecycle(closeGameUrl, 'close', {
                                  'gameId': meta?['gameId'],
                                  'roomId': widget.roomId,
                                  'userId': _databaseUserId,
                                });

                                // Close the webview modal by popping current route
                                try {
                                  controller.loadUrl(
                                    urlRequest: URLRequest(
                                      url: WebUri('about:blank'),
                                    ),
                                  );
                                } catch (e) {
                                  // ignore
                                }
                                try {
                                  Navigator.of(context).pop();
                                } catch (e) {}
                                return {};
                              },
                            );

                            controller.addJavaScriptHandler(
                              handlerName: 'gameRecharge',
                              callback: (args) {
                                print(
                                  '[RoomScreen] Game requested gameRecharge: $args',
                                );
                                // Open in-app wallet/recharge screen
                                try {
                                  Navigator.of(context).pushNamed('/wallet');
                                } catch (e) {
                                  try {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const WalletScreen(),
                                      ),
                                    );
                                  } catch (e) {
                                    print(
                                      '[RoomScreen] Failed to open wallet route: $e',
                                    );
                                  }
                                }
                                return {};
                              },
                            );

                            controller.addJavaScriptHandler(
                              handlerName: 'gameLoaded',
                              callback: (args) {
                                print(
                                  '[RoomScreen] Game reported loaded: $args',
                                );
                                try {
                                  setBottomSheetState(() {
                                    isBottomSheetLoading = false;
                                  });
                                } catch (e) {
                                  print(
                                    '[RoomScreen] Failed to update loading state: $e',
                                  );
                                }
                                return {};
                              },
                            );

                            // Debug handler to receive JS-side debug dumps from the game page
                            controller.addJavaScriptHandler(
                              handlerName: 'nativeDebug',
                              callback: (args) {
                                try {
                                  print('[RoomScreen][nativeDebug] $args');
                                } catch (e) {
                                  print(
                                    '[RoomScreen][nativeDebug] handler error: $e',
                                  );
                                }
                                return {};
                              },
                            );

                            // Inject a compatibility shim so games that call window.NativeBridge.getConfig
                            // (Android-style JavascriptInterface) will be forwarded to the flutter handler.
                            const nativeBridgeShim = '''(function(){
                    try {
                      console.log('📱 Checking for existing NativeBridge...');
                      if(window.NativeBridge && window.NativeBridge.getConfig) {
                        console.log('✅ Native NativeBridge detected - game will use it');
                        return;
                      }
                      
                      console.log('📱 Creating JavaScript NativeBridge shim for BAISHUN game integration');
                      
                      // Create the NativeBridge object that games expect
                      window.NativeBridge = {
                        getConfig: function(msg){
                          console.log('🎮 [CRITICAL] NativeBridge.getConfig called by game!');
                          console.log('📦 Game sent message:', msg);
                          
                          try{
                            // Parse the message to extract jsCallback
                            var msgData = typeof msg === 'string' ? JSON.parse(msg) : msg;
                            var callbackName = msgData && msgData.jsCallback ? msgData.jsCallback : null;
                            console.log('📞 Callback function name:', callbackName);
                            
                            if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                              console.log('✅ Flutter InAppWebView bridge found - calling getConfig handler');
                              
                              // Call the Flutter handler and wait for config
                              window.flutter_inappwebview.callHandler('getConfig', msg).then(function(config){
                                console.log('✅ [SUCCESS] Flutter returned config:', config);
                                
                                // MeshH5 games manage callbacks internally via their framework
                                // The callback is stored in MeshH5's internal callback registry, not globally
                                // Just returning the config is enough - MeshH5 will handle calling the callback
                                if(callbackName){
                                  console.log('📣 MeshH5 callback registered:', callbackName);
                                  console.log('✅ Config returned - MeshH5 will handle callback internally');
                                  
                                  // Try to call via MeshH5 framework if it exists
                                  try{
                                    if(window.MeshH5 && typeof window.MeshH5._invokeCallback === 'function'){
                                      window.MeshH5._invokeCallback(callbackName, config);
                                      console.log('✅ Called via MeshH5._invokeCallback');
                                    } else if(typeof window[callbackName] === 'function'){
                                      // Only call if it exists globally
                                      window[callbackName](config);
                                      console.log('✅ Called global callback function');
                                    } else {
                                      // Don't try to eval - just log that MeshH5 will handle it
                                      console.log('ℹ️ Callback not globally accessible - MeshH5 framework will handle it');
                                    }
                                  }catch(cbErr){
                                    console.log('ℹ️ Callback invocation skipped:', cbErr.message);
                                    console.log('ℹ️ This is OK - MeshH5 handles callbacks via its internal registry');
                                  }
                                }
                                console.log('🎉 Config successfully delivered to game!');
                              }).catch(function(err){
                                console.error('❌ Flutter getConfig handler failed:', err);
                              });
                            } else {
                              console.error('❌ CRITICAL: flutter_inappwebview.callHandler not available!');
                              console.error('Available:', typeof window.flutter_inappwebview);
                            }
                          }catch(e){
                            console.error('❌ NativeBridge.getConfig crashed:', e);
                            console.error('Stack:', e.stack);
                          }
                        },
                        
                        destroy: function(msg){ 
                          console.log('🎮 NativeBridge.destroy called by game');
                          try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('destroy', msg); }catch(e){console.error('destroy error:', e);} 
                        },
                        
                        gameRecharge: function(msg){ 
                          console.log('🎮 NativeBridge.gameRecharge called by game');
                          try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('gameRecharge', msg); }catch(e){console.error('gameRecharge error:', e);} 
                        },
                        
                        gameLoaded: function(msg){ 
                          console.log('🎮 [IMPORTANT] NativeBridge.gameLoaded called - game reports it has loaded!');
                          try{ if(window.flutter_inappwebview) window.flutter_inappwebview.callHandler('gameLoaded', msg); }catch(e){console.error('gameLoaded error:', e);} 
                        }
                      };
                      
                      console.log('✅ NativeBridge shim created and ready!');
                      console.log('📋 Available methods:', Object.keys(window.NativeBridge));
                      
                    } catch(e) { 
                      console.error('❌ FATAL: NativeBridge shim creation failed:', e);
                      console.error('Stack:', e.stack);
                    }
                  })();''';

                            controller.evaluateJavascript(
                              source: nativeBridgeShim,
                            );
                          },
                          onLoadStart: (controller, uri) {
                            print(
                              '[RoomScreen] ===== WebView onLoadStart =====',
                            );
                            print('[RoomScreen] Loading URL: $uri');
                            // Only update loading state; do NOT run JS here - causes blank screen on many devices
                            try {
                              if (builderContext.mounted) {
                                setBottomSheetState(() {
                                  isBottomSheetLoading = true;
                                });
                              }
                            } catch (e) {
                              print('[RoomScreen] Error showing loading: $e');
                            }
                          },
                          onLoadStop: (controller, uri) async {
                            print(
                              '[RoomScreen] ===== WebView onLoadStop =====',
                            );
                            print('[RoomScreen] Page loaded: $uri');

                            // ✅ Inject config and getConfig caller AFTER page load (avoids blank white screen from running JS in onLoadStart)
                            try {
                              final safeH = meta?['safe_height'] is int
                                  ? (meta!['safe_height'] as int)
                                  : (int.tryParse(
                                          meta?['safe_height']?.toString() ??
                                              '',
                                        ) ??
                                        770);
                              final userIdStr = _normalizeBaishunUserId(
                                _baishunUserId ?? _databaseUserId,
                              );
                              final userIdInt = int.tryParse(userIdStr) ?? 0;
                              final roomIdInt =
                                  int.tryParse(widget.roomId.toString()) ?? 0;
                              final gameModeInt =
                                  int.tryParse(
                                    _validGameModeString(meta?['gameMode']),
                                  ) ??
                                  2;
                              final languageInt =
                                  int.tryParse(
                                    (meta?['language'] ?? '2').toString(),
                                  ) ??
                                  2;
                              final token = _currentGameSessionSstoken ?? '';
                              final configData = <String, dynamic>{
                                'appChannel': _appChannel,
                                'appId': _appId,
                                'userId': userIdInt,
                                'uid': userIdInt,
                                'code': _currentGameSessionCode ?? '',
                                'roomId': roomIdInt,
                                'gameMode': gameModeInt,
                                'language': languageInt,
                                'country': countryCode,
                                'gameConfig': {
                                  'sceneMode': meta?['sceneMode'] ?? 0,
                                  'designWidth': 750,
                                  'designHeight': 1334,
                                  'safeHeight': safeH,
                                },
                                'gsp': meta?['gsp'] ?? 101,
                                'currencyIcon': meta?['currencyIcon'] ?? '',
                                'token': token,
                                'ss_token': token,
                              };
                              if (meta != null && meta.containsKey('gameId')) {
                                configData['gameId'] = meta['gameId'];
                              }
                              if (_currentGameUserInfo != null &&
                                  _currentGameUserInfo!.isNotEmpty) {
                                final ui = _currentGameUserInfo!;
                                if (ui['user_name'] != null)
                                  configData['user_name'] = ui['user_name']
                                      .toString();
                                if (ui['userName'] != null)
                                  configData['userName'] = ui['userName']
                                      .toString();
                                if (ui['balance'] != null)
                                  configData['balance'] = ui['balance'] is num
                                      ? (ui['balance'] as num).toDouble()
                                      : double.tryParse(
                                          ui['balance'].toString(),
                                        );
                                if (ui['user_avatar'] != null &&
                                    ui['user_avatar'].toString().isNotEmpty) {
                                  final av = ui['user_avatar'].toString();
                                  configData['user_avatar'] =
                                      av.startsWith('http')
                                      ? av
                                      : '${ApiConstants.baseUrl}$av';
                                  configData['userAvatar'] =
                                      configData['user_avatar'];
                                }
                              }
                              // 🎮 Log what we inject in onLoadStop (user info + ss_token)
                              _logGameConfigSent(config: configData);
                              final configJson = jsonEncode(configData);
                              final shouldCallGetConfig =
                                  !_hasGameRequestedConfig;
                              final callHandlerSnippet = shouldCallGetConfig
                                  ? """
                                    if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                                      window.flutter_inappwebview.callHandler('getConfig', {jsCallback: '__flutter_game_config_callback'});
                                    }
                                  """
                                  : """
                                    console.log('Skipping getConfig call onLoadStop (already handled).');
                                  """;
                              await controller.evaluateJavascript(
                                source:
                                    '''
                                (function(){
                                  try {
                                    window.__flutter_game_config_callback = function(cfg){
                                      try{
                                        if(typeof window.jsCallback === 'function') window.jsCallback(cfg);
                                        else if(typeof window.onNativeConfig === 'function') window.onNativeConfig(cfg);
                                        else { window.__gameConfigFromApp = cfg; try{ localStorage.setItem('native_game_config', JSON.stringify(cfg)); }catch(e){} }
                                      }catch(e){}
                                    };
                                    var cfg = $configJson;
                                    window.__gameConfigFromApp = cfg;
                                    window.__flutter_config_ready = true;
                                    try { localStorage.setItem('native_game_config', JSON.stringify(cfg)); } catch(e) {}
                                    try { window.config = cfg; window.gameConfig = cfg; } catch(e) {}
                                    $callHandlerSnippet
                                    try{ if(typeof window.jsCallback === 'function') window.jsCallback(cfg); }catch(e){}
                                    try{ if(typeof window.onNativeConfig === 'function') window.onNativeConfig(cfg); }catch(e){}
                                    try{ window.dispatchEvent(new CustomEvent('nativeConfig', {detail: cfg})); }catch(e){}
                                  } catch(e) { console.error('preload config:', e); }
                                })();
                                ''',
                              );
                              print(
                                '[RoomScreen] ✅ Injected game config and getConfig trigger in onLoadStop',
                              );
                            } catch (e) {
                              print(
                                '[RoomScreen] Failed injecting config in onLoadStop: $e',
                              );
                            }

                            // Don't hide loading here - wait for gameLoaded so we don't show blank while game initializes (fixes "stuck" feel)
                            // Loading will be hidden when game calls NativeBridge.gameLoaded() or after timeout in timer below
                            print(
                              '[RoomScreen] Page loaded; waiting for gameLoaded before hiding overlay',
                            );
                            if (builderContext.mounted) {
                              Future.delayed(const Duration(seconds: 12), () {
                                if (!builderContext.mounted) return;
                                try {
                                  setBottomSheetState(() {
                                    if (isBottomSheetLoading) {
                                      isBottomSheetLoading = false;
                                      print(
                                        '[RoomScreen] ✅ Loading overlay hidden (timeout 12s)',
                                      );
                                    }
                                  });
                                } catch (_) {}
                              });
                            }

                            // ✅ Debug: Check if page actually loaded
                            try {
                              final html = await controller.evaluateJavascript(
                                source:
                                    'document.documentElement.outerHTML.length',
                              );
                              print(
                                '[RoomScreen] 📄 Page HTML length: $html characters',
                              );

                              final bodyContent = await controller
                                  .evaluateJavascript(
                                    source:
                                        'document.body ? document.body.innerHTML.length : 0',
                                  );
                              print(
                                '[RoomScreen] 📄 Body content length: $bodyContent characters',
                              );

                              // Check for canvas elements (games usually use canvas)
                              final canvasCount = await controller
                                  .evaluateJavascript(
                                    source:
                                        'document.querySelectorAll("canvas").length',
                                  );
                              print(
                                '[RoomScreen] 🎨 Canvas elements found: $canvasCount',
                              );

                              // 🔍 Check canvas dimensions and visibility
                              if (canvasCount != null && canvasCount > 0) {
                                try {
                                  final canvasDebug = await controller
                                      .evaluateJavascript(
                                        source: '''
                          (function() {
                            const canvas = document.querySelector('canvas');
                            if (!canvas) return {error: 'No canvas found'};
                            const rect = canvas.getBoundingClientRect();
                            const style = window.getComputedStyle(canvas);
                            return {
                              width: canvas.width,
                              height: canvas.height,
                              clientWidth: canvas.clientWidth,
                              clientHeight: canvas.clientHeight,
                              rectWidth: rect.width,
                              rectHeight: rect.height,
                              rectTop: rect.top,
                              rectLeft: rect.left,
                              display: style.display,
                              visibility: style.visibility,
                              opacity: style.opacity,
                              zIndex: style.zIndex,
                              position: style.position
                            };
                          })()
                        ''',
                                      );
                                  print(
                                    '[RoomScreen] 🎨 Canvas dimensions and style: $canvasDebug',
                                  );
                                } catch (e) {
                                  print(
                                    '[RoomScreen] ❌ Failed to check canvas: $e',
                                  );
                                }
                              }
                            } catch (e) {
                              print(
                                '[RoomScreen] ⚠️ Failed to check page content: $e',
                              );
                            }

                            try {
                              final inject = '''(function(){
                      window.__flutter_game_config_callback = function(cfg){
                        try{
                          if(typeof window.jsCallback === 'function'){
                            window.jsCallback(cfg);
                          } else if (typeof window.onNativeConfig === 'function'){
                            window.onNativeConfig(cfg);
                          } else {
                            window.__gameConfigFromApp = cfg;
                          }
                        }catch(e){}
                      };
                      if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                        window.flutter_inappwebview.callHandler('getConfig', {jsCallback: '__flutter_game_config_callback'});
                      }
                    })();''';
                              await controller.evaluateJavascript(
                                source: inject,
                              );
                              print(
                                '[RoomScreen] Injected auto-getConfig caller.',
                              );

                              // Apply ONE Cocos fix after load: disable retina, set design resolution, resize, resume, force first draw
                              try {
                                final cocosConfigInject = '''(function(){
                        try{
                          console.log('🎮 Configuring Cocos Creator engine...');
                          
                          var cocosConfigAttempts = 0;
                          var cocosConfigInterval = setInterval(function(){
                            cocosConfigAttempts++;
                            
                            if(window.cc && window.cc.game && window.cc.view){
                              console.log('✅ Cocos Creator engine found, applying configuration...');
                              
                              try{
                                // 1. Disable retina display
                                if(typeof window.cc.view.enableRetina === 'function'){
                                  window.cc.view.enableRetina(false);
                                  console.log('✅ Disabled Cocos retina display');
                                }
                                
                                // 2. Set design resolution (use provider size: W:750, H:1334, safeHeight from config)
                                if(typeof window.cc.view.setDesignResolutionSize === 'function'){
                                  var cfg = window.__gameConfigFromApp || (function(){ try{ var ls = localStorage.getItem('native_game_config'); return ls ? JSON.parse(ls) : null; }catch(e){ return null; } })();
                                  var w = 750;
                                  var h = (cfg && cfg.gameConfig && (cfg.gameConfig.safeHeight != null)) ? cfg.gameConfig.safeHeight : (window.innerHeight || 1334);
                                  window.cc.view.setDesignResolutionSize(w, h, window.cc.ResolutionPolicy.SHOW_ALL);
                                  console.log('✅ Set Cocos design resolution (provider size): ' + w + 'x' + h);
                                }
                                
                                // 3. Enable browser resize
                                if(typeof window.cc.view.resizeWithBrowserSize === 'function'){
                                  window.cc.view.resizeWithBrowserSize(true);
                                  console.log('✅ Enabled Cocos browser resize');
                                }
                                
                                // 4. Resume the game engine
                                if(typeof window.cc.game.resume === 'function'){
                                  window.cc.game.resume();
                                  console.log('✅ Resumed Cocos game engine');
                                }
                                
                                // 5. Force first frame draw
                                setTimeout(function(){
                                  try{
                                    if(window.cc.director && window.cc.director.getScheduler()){
                                      window.cc.director.getScheduler().update(0.016);
                                      console.log('✅ Forced Cocos first frame draw');
                                    }
                                  }catch(e){
                                    console.error('❌ Failed to draw first frame:', e);
                                  }
                                }, 100);
                                
                                clearInterval(cocosConfigInterval);
                                console.log('🎉 Cocos configuration complete!');
                              }catch(e){
                                console.error('❌ Error configuring Cocos:', e);
                                clearInterval(cocosConfigInterval);
                              }
                            } else if(cocosConfigAttempts >= 60){
                              console.log('⚠️ Cocos Creator engine not found after 12 seconds, skipping configuration');
                              clearInterval(cocosConfigInterval);
                            }
                          }, 200);
                        }catch(e){ 
                          console.error('❌ Cocos config inject failed:', e); 
                        }
                      })();''';
                                await controller.evaluateJavascript(
                                  source: cocosConfigInject,
                                );
                                print(
                                  '[RoomScreen] Injected ONE Cocos configuration fix.',
                                );
                              } catch (e) {
                                print(
                                  '[RoomScreen] Failed injecting Cocos config: $e',
                                );
                              }

                              try {
                                // ✅ CRITICAL: Check if game actually initialized after 3 seconds
                                Future.delayed(Duration(seconds: 3), () async {
                                  try {
                                    final gameCheck = await controller
                                        .evaluateJavascript(
                                          source: '''(function(){
                            var diagnostics = {
                              hasCanvas: document.querySelectorAll('canvas').length > 0,
                              canvasVisible: false,
                              canvasDimensions: '',
                              bodyHasContent: document.body ? document.body.innerHTML.length : 0,
                              hasGameEngine: !!window.cc || !!window.MeshH5 || !!window.Cocos2d,
                              hasConfig: !!window.__gameConfigFromApp,
                              jsErrors: window.__jsErrorCount || 0,
                              localStorage: {},
                              cookies: (function(){ try { return document.cookie || ''; } catch(e) { return ''; } })(),
                              documentReady: document.readyState,
                              scriptsLoaded: document.querySelectorAll('script').length,
                              scriptSrcs: [],
                              windowKeys: Object.keys(window).filter(function(k){ return k.includes('game') || k.includes('Game') || k.includes('MeshH5') || k.includes('cc'); }).slice(0, 20)
                            };
                            try {
                              var canvas = document.querySelector('canvas');
                              if (canvas) {
                                var rect = canvas.getBoundingClientRect();
                                var style = window.getComputedStyle(canvas);
                                diagnostics.canvasVisible = rect.width > 0 && rect.height > 0 && style.display !== 'none';
                                diagnostics.canvasDimensions = canvas.width + 'x' + canvas.height + ' (' + rect.width + 'x' + rect.height + ')';
                                diagnostics.canvasStyle = {
                                  display: style.display,
                                  visibility: style.visibility,
                                  opacity: style.opacity
                                };
                              }
                            } catch(e) { diagnostics.canvasError = String(e); }
                            try {
                              diagnostics.localStorage = {
                                sstoken: localStorage.getItem('sstoken'),
                                token: localStorage.getItem('token'),
                                native_game_config: localStorage.getItem('native_game_config')
                              };
                            } catch(e) { diagnostics.localStorageError = String(e); }
                            try {
                              var scripts = document.querySelectorAll('script[src]');
                              for (var i = 0; i < Math.min(scripts.length, 10); i++) {
                                diagnostics.scriptSrcs.push(scripts[i].src.substring(0, 100));
                              }
                            } catch(e) {}
                            return diagnostics;
                          })()''',
                                        );
                                    print(
                                      '[RoomScreen] 🔍 GAME DIAGNOSTICS (3s): $gameCheck',
                                    );

                                    // If game hasn't initialized, investigate further
                                    if (gameCheck is Map) {
                                      final hasCanvas =
                                          gameCheck['hasCanvas'] as bool? ??
                                          false;
                                      final canvasVisible =
                                          gameCheck['canvasVisible'] as bool? ??
                                          false;
                                      final hasEngine =
                                          gameCheck['hasGameEngine'] as bool? ??
                                          false;

                                      if (!hasCanvas) {
                                        print(
                                          '[RoomScreen] ❌❌❌ CRITICAL: No canvas element found! Game not loading.',
                                        );
                                        print(
                                          '[RoomScreen]    Scripts loaded: ${gameCheck['scriptsLoaded']}',
                                        );
                                        print(
                                          '[RoomScreen]    Script sources: ${gameCheck['scriptSrcs']}',
                                        );
                                      } else if (!canvasVisible) {
                                        print(
                                          '[RoomScreen] ❌❌❌ CRITICAL: Canvas exists but not visible!',
                                        );
                                        print(
                                          '[RoomScreen]    Style: ${gameCheck['canvasStyle']}',
                                        );
                                      } else if (!hasEngine) {
                                        print(
                                          '[RoomScreen] ⚠️ WARNING: Canvas visible but game engine not detected!',
                                        );
                                        print(
                                          '[RoomScreen]    Window game-related keys: ${gameCheck['windowKeys']}',
                                        );
                                      } else {
                                        print(
                                          '[RoomScreen] ✅ Game appears to be initialized correctly.',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print(
                                      '[RoomScreen] ❌ Failed game diagnostics: $e',
                                    );
                                  }
                                });
                              } catch (e) {
                                print(
                                  '[RoomScreen] Failed viewport resize fix: $e',
                                );
                              }
                              try {
                                // Poll for H5 engine or injected config and notify Flutter the game loaded.
                                final pollAndNotify = '''(function(){
                        try{
                          var called = false;
                          function notify(){
                            if(called) return; called = true;
                            try{ if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler) window.flutter_inappwebview.callHandler('gameLoaded', {}); }catch(e){}
                          }
                          function check(){
                            try{
                              if(window.MeshH5 || window.__gameConfigFromApp || window.__flutter_game_config_callback_received){ notify(); return true; }
                            }catch(e){}
                            return false;
                          }
                          // initial check
                          if(check()) return;
                          var interval = setInterval(function(){ if(check()){ clearInterval(interval); } }, 500);
                          // fallback: force notify after 12s to avoid permanent loading
                          setTimeout(function(){ try{ notify(); }catch(e){}; try{ clearInterval(interval); }catch(e){} }, 12000);
                        }catch(e){}
                      })();''';
                                await controller.evaluateJavascript(
                                  source: pollAndNotify,
                                );
                                print(
                                  '[RoomScreen] Injected gameLoaded poller.',
                                );
                                try {
                                  final nativeDebugInject = '''(function(){
                          try{
                            function send(){
                              var ls = null;
                              try{ ls = localStorage.getItem('native_game_config'); }catch(e){}
                              var cfg = window.__gameConfigFromApp || (ls ? JSON.parse(ls) : null);
                              var payload = { cfg: cfg, raw_localStorage: ls, mesh: !!window.MeshH5, jsCallback: (typeof window.jsCallback === 'function'), onNativeConfig: (typeof window.onNativeConfig === 'function') };
                              try{ if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler) window.flutter_inappwebview.callHandler('nativeDebug', payload); }catch(e){}
                              try{ console.log('NATIVE_DEBUG:'+JSON.stringify(payload)); }catch(e){}
                            }
                            // Send debug info once after 2 seconds
                            setTimeout(function(){ try{ send(); }catch(e){} }, 2000);
                          }catch(e){ try{ console.error('native debug inject failed', e); }catch(e){} }
                        })();''';
                                  await controller.evaluateJavascript(
                                    source: nativeDebugInject,
                                  );
                                  print(
                                    '[RoomScreen] Injected native debug reporter.',
                                  );
                                  try {
                                    final netInterceptor = '''(function(){
                              try{
                                function report(kind, obj){
                                  try{ if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler) window.flutter_inappwebview.callHandler('nativeDebug', {net: {kind: kind, info: obj}}); }catch(e){}
                                  try{ console.log('NATIVE_NET:'+kind+JSON.stringify(obj)); }catch(e){}
                                }

                                // fetch wrapper
                                if(window.fetch){
                                  const _fetch = window.fetch.bind(window);
                                  window.fetch = function(input, init){
                                    var url = (input && input.url) || input;
                                    var method = (init && init.method) || 'GET';
                                    return _fetch(input, init).then(function(resp){
                                      try{ resp.clone().text().then(function(body){ report('fetch',{url: url, method: method, status: resp.status, bodyPreview: (body||'').substring(0,400)}); }); }catch(e){}
                                      return resp;
                                    });
                                  };
                                }

                                // XHR wrapper
                                if(window.XMLHttpRequest){
                                  const _open = window.XMLHttpRequest.prototype.open;
                                  const _send = window.XMLHttpRequest.prototype.send;
                                  window.XMLHttpRequest.prototype.open = function(method, url){ this._req_method = method; this._req_url = url; return _open.apply(this, arguments); };
                                  window.XMLHttpRequest.prototype.send = function(body){ this.addEventListener('load', function(){ try{ report('xhr',{url: this._req_url, method: this._req_method, status: this.status, responsePreview: (this.responseText||'').substring(0,400)}); }catch(e){} }); return _send.apply(this, arguments); };
                                }
                              }catch(e){ try{ console.error('net interceptor failed', e); }catch(e){} }
                            })();''';
                                    await controller.evaluateJavascript(
                                      source: netInterceptor,
                                    );
                                    print(
                                      '[RoomScreen] Injected network interceptor.',
                                    );
                                    try {
                                      final wsInterceptor = '''(function(){
                                try{
                                  function report(kind,obj){ try{ if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler) window.flutter_inappwebview.callHandler('nativeDebug', {net:{kind:kind,info:obj}}); }catch(e){}
                                    try{ console.log('NATIVE_NET:'+kind+JSON.stringify(obj)); }catch(e){}
                                  }
                                  if(window.WebSocket){
                                    const _WS = window.WebSocket;
                                    window.WebSocket = function(url, protocols){
                                      report('websocket', {action: 'creating', url: url});
                                      console.log('🔌 WebSocket connecting to: ' + url);
                                      var ws = protocols ? new _WS(url, protocols) : new _WS(url);
                                      ws.addEventListener('open', function(){ report('websocket', {action: 'connected', url: url}); console.log('✅ WebSocket connected: ' + url); });
                                      ws.addEventListener('error', function(e){ report('websocket', {action: 'error', url: url, error: String(e)}); console.error('❌ WebSocket error: ' + url, e); });
                                      ws.addEventListener('close', function(e){ report('websocket', {action: 'closed', url: url, code: e.code, reason: e.reason}); console.log('🔌 WebSocket closed: ' + url); });
                                      try{ report('ws_open',{url:url, protocols:protocols}); }catch(e){}
                                      const _origSend = ws.send;
                                      ws.send = function(data){ try{ report('ws_send',{url:url, payload: (typeof data === 'string' ? data.substring(0,400) : 'binary')}); }catch(e){}; return _origSend.apply(this, arguments); };
                                      ws.addEventListener('message', function(ev){ try{ var d = ev.data; report('ws_msg',{url:url, payload: (typeof d === 'string' ? d.substring(0,400) : 'binary')}); }catch(e){} });
                                      return ws;
                                    };
                                    window.WebSocket.prototype = _WS.prototype;
                                  }

                                  // ✅ CRITICAL: Aggressive game initialization with retry
                                  var initAttempts = 0;
                                  var maxAttempts = 20;
                                  var initInterval = setInterval(function(){
                                    initAttempts++;
                                    try{
                                      var ls = null; try{ ls = localStorage.getItem('native_game_config'); }catch(e){}
                                      var cfg = window.__gameConfigFromApp || (ls ? JSON.parse(ls) : null);
                                      if(!cfg){ console.log('⏳ Init attempt ' + initAttempts + ': No config yet'); return; }
                                      
                                      var initialized = false;
                                      
                                      // Try MeshH5 init
                                      if(window.MeshH5){
                                        console.log('🎮 Found MeshH5 object!');
                                        if(typeof window.MeshH5.init === 'function'){ 
                                          try{
                                            window.MeshH5.init(cfg); 
                                            console.log('✅ Called MeshH5.init with config');
                                            report('init','MeshH5.init called successfully');
                                            initialized = true;
                                          }catch(e){ console.error('❌ MeshH5.init error:', e); }
                                        } else if(typeof window.MeshH5.start === 'function'){
                                          try{
                                            window.MeshH5.start(cfg);
                                            console.log('✅ Called MeshH5.start with config');
                                            report('init','MeshH5.start called successfully');
                                            initialized = true;
                                          }catch(e){ console.error('❌ MeshH5.start error:', e); }
                                        }
                                      }
                                      
                                      // Cocos Creator games self-initialize - just confirm engine exists
                                      if(window.cc && window.cc.game){
                                        console.log('✅ Cocos Creator engine found - game will self-initialize');
                                        // Don't manually call game.resume() or game.run() - causes errors
                                        // Game handles its own initialization
                                        initialized = true;
                                      }
                                      
                                      // Try callback functions
                                      if(typeof window.onNativeConfig === 'function'){ 
                                        try{
                                          window.onNativeConfig(cfg); 
                                          console.log('✅ Called onNativeConfig');
                                          report('init','onNativeConfig called');
                                          initialized = true;
                                        }catch(e){ console.error('❌ onNativeConfig error:', e); }
                                      }
                                      if(typeof window.jsCallback === 'function'){ 
                                        try{
                                          window.jsCallback(cfg); 
                                          console.log('✅ Called jsCallback');
                                          report('init','jsCallback called');
                                          initialized = true;
                                        }catch(e){ console.error('❌ jsCallback error:', e); }
                                      }
                                      
                                      // Dispatch event
                                      try{ 
                                        window.dispatchEvent(new CustomEvent('nativeConfig', {detail: cfg})); 
                                        console.log('✅ Dispatched nativeConfig event');
                                        report('init','event dispatched');
                                      }catch(e){ console.error('❌ Event dispatch error:', e); }
                                      
                                      if(initialized){
                                        console.log('🎉 Game initialized successfully!');
                                        clearInterval(initInterval);
                                      } else if(initAttempts < maxAttempts){
                                        console.log('⏳ Init attempt ' + initAttempts + ': Game objects not ready yet, retrying...');
                                      } else {
                                        console.warn('⚠️ Max init attempts reached, game may not start properly');
                                        clearInterval(initInterval);
                                      }
                                    }catch(e){ 
                                      console.error('❌ Init error:', e); 
                                      if(initAttempts >= maxAttempts) clearInterval(initInterval);
                                    }
                                  }, 300);
                                }catch(e){ try{ console.error('ws interceptor failed', e); }catch(e){} }
                              })();''';
                                      await controller.evaluateJavascript(
                                        source: wsInterceptor,
                                      );
                                      print(
                                        '[RoomScreen] Injected WebSocket interceptor and auto-init caller.',
                                      );

                                      // Also inject token aliases and attempt an automatic login call if the game exposes it
                                      try {
                                        final tokenAliasInject = '''(function(){
                                  try{
                                    var ls = null; try{ ls = localStorage.getItem('native_game_config'); }catch(e){}
                                    var cfg = window.__gameConfigFromApp || (ls ? JSON.parse(ls) : null);
                                    var t = cfg && (cfg.ss_token || cfg.sstoken || cfg.token || cfg.SS_TOKEN || cfg.sstoken);
                                    if(t){
                                      try{ localStorage.setItem('sstoken', t); }catch(e){}
                                      try{ localStorage.setItem('token', t); }catch(e){}
                                      try{ window.sstoken = t; window.token = t; window.SS_TOKEN = t; }catch(e){}
                                      try{ var uid = cfg.uid || cfg.userId || cfg.user_id || cfg.uid; }
                                      catch(e){ var uid = null; }
                                      try{ if(window.MeshH5 && typeof window.MeshH5.login === 'function'){ window.MeshH5.login({ss_token: t, uid: uid}); } }catch(e){}
                                    }
                                  }catch(e){ try{ console.error('token alias inject failed', e); }catch(e){} }
                                })();''';
                                        await controller.evaluateJavascript(
                                          source: tokenAliasInject,
                                        );
                                        print(
                                          '[RoomScreen] Injected token aliases and auto-login attempt.',
                                        );
                                      } catch (e) {
                                        print(
                                          '[RoomScreen] Failed injecting token aliases: $e',
                                        );
                                      }
                                      print(
                                        '[RoomScreen] Injected WebSocket interceptor and auto-init caller.',
                                      );
                                    } catch (e) {
                                      print(
                                        '[RoomScreen] Failed injecting ws interceptor: $e',
                                      );
                                    }
                                  } catch (e) {
                                    print(
                                      '[RoomScreen] Failed injecting network interceptor: $e',
                                    );
                                  }
                                } catch (e) {
                                  print(
                                    '[RoomScreen] Failed injecting native debug reporter: $e',
                                  );
                                }
                              } catch (e) {
                                print(
                                  '[RoomScreen] Failed injecting gameLoaded poller: $e',
                                );
                              }
                            } catch (e) {
                              print(
                                '[RoomScreen] Failed injecting auto-getConfig caller: $e',
                              );
                            }
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            final level = consoleMessage.messageLevel;
                            final msg = consoleMessage.message;

                            // When game reports "Cannot connect to server" = backend (get_sstoken/get_user_info) not configured or failing
                            if (msg.contains('无法连接到服务器')) {
                              gameServerErrorNotifier.value = true;
                            }

                            // ✅ Highlight errors and warnings
                            if (level == ConsoleMessageLevel.ERROR) {
                              print('[RoomScreen] ❌❌❌ GAME ERROR: $msg');
                            } else if (level == ConsoleMessageLevel.WARNING) {
                              print('[RoomScreen] ⚠️ GAME WARNING: $msg');
                            } else if (msg.contains('ERROR') ||
                                msg.contains('Error') ||
                                msg.contains('error')) {
                              print('[RoomScreen] ❌ Game Console: $msg');
                            } else if (msg.startsWith('❌') ||
                                msg.startsWith('NATIVE_NET') ||
                                msg.startsWith('CANVAS_FIX')) {
                              print('[RoomScreen] 🎮 $msg');
                            }
                            // Don't print routine debug messages to reduce noise
                          },
                          onLoadError: (controller, url, code, message) {
                            print('[RoomScreen] ❌ WebView load error:');
                            print('[RoomScreen]    URL: $url');
                            print('[RoomScreen]    Code: $code');
                            print('[RoomScreen]    Message: $message');

                            // Hide loading on error
                            if (builderContext.mounted) {
                              try {
                                setBottomSheetState(() {
                                  isBottomSheetLoading = false;
                                });
                              } catch (e) {
                                print(
                                  '[RoomScreen] Failed to hide loading on error: $e',
                                );
                              }
                            }
                          },
                          onLoadHttpError:
                              (controller, url, statusCode, description) {
                                print('[RoomScreen] ❌ HTTP error:');
                                print('[RoomScreen]    URL: $url');
                                print('[RoomScreen]    Status: $statusCode');
                                print(
                                  '[RoomScreen]    Description: $description',
                                );

                                // Hide loading on HTTP error
                                if (builderContext.mounted) {
                                  try {
                                    setBottomSheetState(() {
                                      isBottomSheetLoading = false;
                                    });
                                  } catch (e) {
                                    print(
                                      '[RoomScreen] Failed to hide loading on HTTP error: $e',
                                    );
                                  }
                                }
                              },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                                final uri = navigationAction.request.url;
                                print(
                                  '[RoomScreen] 🌐 Navigation attempt: ${uri?.toString()}',
                                );
                                // Allow all navigations within game domain
                                return NavigationActionPolicy.ALLOW;
                              },
                          onReceivedHttpAuthRequest: (controller, challenge) async {
                            print(
                              '[RoomScreen] 🔐 HTTP Auth request: ${challenge.protectionSpace.host}:${challenge.protectionSpace.port}',
                            );
                            return null; // Use default handling
                          },
                          onPermissionRequest: (controller, request) async {
                            print(
                              '[RoomScreen] 🔓 Permission request: ${request.resources}',
                            );
                            // Grant all permissions for game functionality
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          shouldInterceptRequest: (controller, request) async {
                            print(
                              '[RoomScreen] 📡 Network request: ${request.url}',
                            );
                            print('[RoomScreen]    Method: ${request.method}');
                            if (request.headers != null) {
                              print(
                                '[RoomScreen]    Headers: ${request.headers}',
                              );
                            }
                            // Don't intercept, just log
                            return null;
                          },
                          onReceivedError: (controller, request, error) async {
                            print(
                              '[RoomScreen] ❌ Network error for ${request.url}',
                            );
                            print('[RoomScreen]    Type: ${error.type}');
                            print(
                              '[RoomScreen]    Description: ${error.description}',
                            );
                          },
                        ),
                      ),

                      // Game loading overlay
                      if (isBottomSheetLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Loading game...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Blank-screen fallback: retry + open in browser
                      if (!isBottomSheetLoading)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SafeArea(
                            child: Material(
                              color: Colors.black54,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ValueListenableBuilder<bool>(
                                      valueListenable: gameServerErrorNotifier,
                                      builder: (_, showError, __) => showError
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Text(
                                                'Server connection failed. Configure get_sstoken & get_user_info in BAISHUN backend.',
                                                style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Text(
                                      'If blank in browser too, this game link may be down.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            if (!builderContext.mounted) return;
                                            try {
                                              setBottomSheetState(() {
                                                isBottomSheetLoading = true;
                                              });
                                              await _gameWebController
                                                  ?.clearCache();
                                              await _gameWebController
                                                  ?.reload();
                                            } catch (e) {
                                              print(
                                                '[RoomScreen] Retry reload failed: $e',
                                              );
                                              if (builderContext.mounted) {
                                                setBottomSheetState(() {
                                                  isBottomSheetLoading = false;
                                                });
                                              }
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.refresh,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Retry',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            try {
                                              final uri = Uri.parse(finalUrl);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } else {
                                                if (builderContext.mounted) {
                                                  ScaffoldMessenger.of(
                                                    builderContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Cannot open URL',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              print(
                                                '[RoomScreen] Open in browser failed: $e',
                                              );
                                              if (builderContext.mounted) {
                                                ScaffoldMessenger.of(
                                                  builderContext,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.open_in_new,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Open in browser',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ], // Row children
                                    ), // Row
                                  ], // Column children
                                ), // Column
                              ), // Padding
                            ), // Material
                          ), // SafeArea
                        ), // Positioned
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to notify a local endpoint about game lifecycle events (create/close)
  Future<void> _notifyGameLifecycle(
    String baseUrl,
    String action,
    Map<String, dynamic>? payload,
  ) async {
    try {
      final uri = Uri.parse(baseUrl);
      // Skip if localhost/invalid - avoids Connection refused and log noise (audit fix)
      if (uri.host == '127.0.0.1' ||
          uri.host == 'localhost' ||
          !uri.host.contains('.'))
        return;
      final client = HttpClient();
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'action': action, 'payload': payload ?? {}}));
      final resp = await req.close();
      print('[RoomScreen] lifecycle notify $action -> ${resp.statusCode}');
      client.close();
    } catch (e) {
      print('[RoomScreen] _notifyGameLifecycle error: $e');
    }
  }

  Future<void> _sendWalletUpdate(
    InAppWebViewController? controller,
    Map<String, dynamic> data,
  ) async {
    if (controller == null) return;
    try {
      final payload = jsonEncode(data);
      final js =
          '''(function(){
          try{
            var cfg = $payload;
            if(typeof window.walletUpdate === 'function'){
              window.walletUpdate(cfg);
            } else if (typeof window.onWalletUpdate === 'function'){
              window.onWalletUpdate(cfg);
            } else {
              try{ window.dispatchEvent(new CustomEvent('walletUpdate', {detail: cfg})); }catch(e){}
              try{ localStorage.setItem('native_wallet_update', JSON.stringify(cfg)); }catch(e){}
            }
          }catch(e){}
        })();''';
      await controller.evaluateJavascript(source: js);
      print('[RoomScreen] Sent walletUpdate to game: $data');
    } catch (e) {
      print('[RoomScreen] Failed to send walletUpdate: $e');
    }
  }

  // Manual JS runner for use when you need to push a raw JS call into the game.
  Future<void> _manualRunJs(String js) async {
    try {
      await _gameWebController?.evaluateJavascript(source: js);
      print('[RoomScreen] manualRunJs executed: $js');
    } catch (e) {
      print('[RoomScreen] manualRunJs error: $e');
    }
  }

  Future<void> _handleBsEvent(dynamic event) async {
    try {
      final obj = json.decode(event);
      final jsFunName = (obj['jsCallback'] ?? '') as String;
      if (jsFunName.contains('getConfig')) {
        final code = _currentGameSessionCode ?? await _generateOneTimeCode();
        final config = <String, dynamic>{
          'appChannel': _appChannel,
          'appName': _appName,
          'appId': _appId,
          'userId': _normalizeBaishunUserId(_baishunUserId ?? _databaseUserId),
          'code': code,
          'roomId': widget.roomId,
          // Doc 2.1: gameMode string "2" or "3" only
          'gameMode': _validGameModeString(obj['gameMode']),
          'language': obj['language'] ?? '2',
          'country': _resolveBaishunCountryCode(),
          'gameConfig': {'sceneMode': obj['sceneMode'] ?? 0},
          'gsp': obj['gsp'] ?? 101,
          'currencyIcon': obj['currencyIcon'] ?? '',
        };
        if (obj['gameId'] != null) config['gameId'] = obj['gameId'];
        final js = "$jsFunName(${jsonEncode(config)})";
        await _gameWebController?.evaluateJavascript(source: js);
        print('[RoomScreen] Responded to getConfig via EventChannel: $js');
        // send wallet update as well
        _sendWalletUpdate(_gameWebController, {'balance': totalCoins ?? '0'});
      } else if (jsFunName.contains('destroy')) {
        print('[RoomScreen] Received destroy via EventChannel');
        try {
          await _gameWebController?.loadUrl(
            urlRequest: URLRequest(url: WebUri('about:blank')),
          );
        } catch (e) {}
        try {
          Navigator.of(context).pop();
        } catch (e) {}
      } else if (jsFunName.contains('gameRecharge')) {
        print('[RoomScreen] Received gameRecharge via EventChannel');
        try {
          Navigator.of(context).pushNamed('/wallet');
        } catch (e) {
          try {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
          } catch (e) {
            print('[RoomScreen] Failed to open wallet via EventChannel: $e');
          }
        }
      } else if (jsFunName.contains('gameLoaded')) {
        print('[RoomScreen] Received gameLoaded via EventChannel');
        _safeSetState(() {
          _isGameLoading = false;
        });
      }
    } catch (e) {
      print('[RoomScreen] _handleBsEvent error: $e');
    }
  }

  // Show half-screen draggable bottom sheet with dark green background
  Future<void> _showGamesBottomSheet(BuildContext context) async {
    print('[RoomScreen] _showGamesBottomSheet() called');
    // Attempt to fetch games from backend; fall back to hardcoded list on failure.
    List<Map<String, dynamic>> games = [];
    try {
      final list = await ApiManager.getGameList();
      if (list.isNotEmpty) {
        games = list
            .map((item) {
              final id = item['game_id'] ?? item['id'] ?? item['gameId'];
              final name =
                  item['name'] ?? item['game_name'] ?? item['title'] ?? 'Game';
              // Prefer fields commonly returned by BAISHUN: download_url or preview_url
              final url =
                  item['download_url'] ??
                  item['downloadUrl'] ??
                  item['url'] ??
                  item['index_url'] ??
                  '';
              final preview =
                  item['preview_url'] ??
                  item['previewUrl'] ??
                  'assets/images/game_icon.png';
              // ✅ Provider requires W:750, H:1334, SH (safe_height) per game - pass in meta
              final meta = <String, dynamic>{'gameId': id};
              if (item['safe_height'] != null)
                meta['safe_height'] = item['safe_height'] is int
                    ? item['safe_height']
                    : int.tryParse(item['safe_height'].toString());
              if (item['game_mode'] != null)
                meta['game_mode'] = item['game_mode'];
              if (item['game_orientation'] != null)
                meta['game_orientation'] = item['game_orientation'];
              return {
                'id': id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
                'name': name.toString(),
                'asset': preview.toString(),
                'url': url.toString(),
                'meta': meta,
              };
            })
            .where((g) => (g['url'] as String).isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('[RoomScreen] getGameList failed: $e');
    }

    // NOTE: Removed hardcoded fallback game list. Games must be provided by backend.
    // If `games` is empty here, the UI will show "No games available".

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF083814), // dark green background
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Games',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: games.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No games available currently.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  0.8, // Width to height ratio to prevent overflow
                            ),
                            itemCount: games.length,
                            itemBuilder: (context, index) {
                              final g = games[index];
                              return _buildGameTile(
                                context,
                                g['name'] as String,
                                g['asset'] as String,
                                g['url'] as String,
                                g['meta'] as Map<String, dynamic>?,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGameTile(
    BuildContext context,
    String name,
    String asset,
    String url,
    Map<String, dynamic>? meta,
  ) {
    // Determine if asset is a network URL or local asset path
    final bool isNetworkImage =
        asset.startsWith('http://') || asset.startsWith('https://');
    final bool isLocalAsset = asset.startsWith('assets/');

    return GestureDetector(
      onTap: () async {
        // If URL is not provided, inform the user
        if (url.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name is not available currently')),
          );
          return;
        }

        // If we have a gameId, prefer fetching authoritative per-game info from backend
        String finalUrl = url;
        String finalAsset = asset;
        if (meta != null && meta!.containsKey('gameId')) {
          try {
            final gameId = meta!['gameId'] is int
                ? meta!['gameId'] as int
                : int.tryParse(meta!['gameId'].toString()) ?? 0;
            if (gameId > 0) {
              print('[RoomScreen] Fetching one_game_info for gameId=$gameId');
              final info = await ApiManager.getOneGameInfo(
                appChannel: ApiConstants.baishunAppChannel,
                appId: ApiConstants.baishunAppId,
                gameId: gameId,
              );
              if (info != null) {
                // Debug response keys to find the correct URL field
                print(
                  '[RoomScreen] getOneGameInfo keys: ${info.keys.toList()}',
                );
                print('[RoomScreen] getOneGameInfo values: $info');

                // Doc 4.1: download_url is "Game package loading address" - use first
                if (info.containsKey('download_url') &&
                    info['download_url'] != null &&
                    info['download_url'].toString().trim().isNotEmpty) {
                  final val = info['download_url'].toString().trim();
                  if (!val.contains('127.0.0.1')) {
                    finalUrl = val;
                    print(
                      '[RoomScreen] Using download_url from one_game_info: $finalUrl',
                    );
                  }
                }
                if (finalUrl == url &&
                    info.containsKey('address') &&
                    info['address'] != null &&
                    info['address'].toString().isNotEmpty) {
                  finalUrl = info['address'].toString();
                  print('[RoomScreen] Using address field: $finalUrl');
                }
                // Other standard fields per doc / legacy, ignore localhost
                if (finalUrl == url && info.containsKey('load_url')) {
                  final val = info['load_url'].toString();
                  if (!val.contains('127.0.0.1')) finalUrl = val;
                }
                if (finalUrl == url && info.containsKey('loadUrl')) {
                  final val = info['loadUrl'].toString();
                  if (!val.contains('127.0.0.1')) finalUrl = val;
                }
                if (finalUrl == url && info.containsKey('url')) {
                  final val = info['url'].toString();
                  if (!val.contains('127.0.0.1')) finalUrl = val;
                }
                if (finalUrl == url && info.containsKey('index_url')) {
                  final val = info['index_url'].toString();
                  if (!val.contains('127.0.0.1')) finalUrl = val;
                }

                if (info.containsKey('preview_url')) {
                  finalAsset = info['preview_url'].toString();
                } else if (info.containsKey('previewUrl'))
                  finalAsset = info['previewUrl'].toString();

                // ✅ Merge provider size (safe_height, game_mode) into meta so getConfig uses it
                final mergedMeta = meta == null
                    ? <String, dynamic>{'gameId': gameId}
                    : Map<String, dynamic>.from(meta!);
                if (info['safe_height'] != null)
                  mergedMeta['safe_height'] = info['safe_height'] is int
                      ? info['safe_height']
                      : int.tryParse(info['safe_height'].toString());
                if (info['game_mode'] != null)
                  mergedMeta['game_mode'] = info['game_mode'];
                if (info['game_orientation'] != null)
                  mergedMeta['game_orientation'] = info['game_orientation'];
                meta = mergedMeta;

                print(
                  '[RoomScreen] getOneGameInfo resolved finalUrl=$finalUrl preview=$finalAsset safe_height=${mergedMeta['safe_height']}',
                );
              }
            }
          } catch (e) {
            print('[RoomScreen] getOneGameInfo failed: $e');
          }
        }

        // Fallback URLs for games when backend doesn't provide valid URL
        try {
          final lowerName = name.toLowerCase();
          final lowerUrl = finalUrl.toLowerCase();
          final metaStr = meta?.toString().toLowerCase() ?? '';
          final urlInvalid =
              finalUrl.isEmpty ||
              lowerUrl.contains('127.0.0.1') ||
              !lowerUrl.startsWith('http');

          if (urlInvalid) {
            // GreedyCat (game_id: 1128)
            if (lowerName.contains('greedy') ||
                lowerName.contains('cat') ||
                lowerUrl.contains('greedy') ||
                lowerUrl.contains('cat') ||
                metaStr.contains('greedy-cat') ||
                metaStr.contains('greedycat')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/greedy-cat/1.0.9/web-mobile/index.html';
              print('[RoomScreen] Using fallback GreedyCat URL -> $finalUrl');
            }
            // Fruit77 (game_id: 1094)
            else if (lowerName.contains('fruit77') ||
                lowerName.contains('fruit 77') ||
                lowerUrl.contains('fruit77') ||
                lowerUrl.contains('fruit 77') ||
                metaStr.contains('fruit77')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/fruit77/1.0.7/web-mobile/index.html';
              print('[RoomScreen] Using fallback Fruit77 URL -> $finalUrl');
            }
            // FruitParty2 (game_id: 1085)
            else if (lowerName.contains('fruitparty2') ||
                lowerName.contains('fruit party 2') ||
                lowerName.contains('fruit party2') ||
                lowerUrl.contains('fruit-party2') ||
                lowerUrl.contains('fruitparty2') ||
                metaStr.contains('fruit-party2') ||
                metaStr.contains('fruitparty2')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/fruit-party2/1.6.8/web-mobile/index.html';
              print('[RoomScreen] Using fallback FruitParty2 URL -> $finalUrl');
            }
            // RoulettePro (game_id: 1081)
            else if (lowerName.contains('roulettepro') ||
                lowerName.contains('roulette pro') ||
                lowerName.contains('roulette') ||
                lowerUrl.contains('roulette') ||
                metaStr.contains('roulette-pro') ||
                metaStr.contains('roulettepro')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/roulette-pro/1.2.8/web-mobile/index.html';
              print('[RoomScreen] Using fallback RoulettePro URL -> $finalUrl');
            }
            // FruitParty (game_id: 1077)
            else if (lowerName.contains('fruitparty') ||
                lowerName.contains('fruit party') ||
                lowerUrl.contains('fruit-party') ||
                lowerUrl.contains('fruitparty') ||
                metaStr.contains('fruit-party') ||
                metaStr.contains('fruitparty')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/fruit-party/1.0.7/web-mobile/index.html';
              print('[RoomScreen] Using fallback FruitParty URL -> $finalUrl');
            }
            // DragonTiger (game_id: 1073)
            else if (lowerName.contains('dragon') ||
                lowerName.contains('tiger') ||
                lowerUrl.contains('dragon') ||
                lowerUrl.contains('tiger') ||
                metaStr.contains('dragon-tiger') ||
                metaStr.contains('dragontiger')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/dragon-tiger/1.1.7/web-mobile/index.html';
              print('[RoomScreen] Using fallback DragonTiger URL -> $finalUrl');
            }
            // GreedyLion (game_id: 1068)
            else if (lowerName.contains('greedy') ||
                lowerName.contains('lion') ||
                lowerUrl.contains('greedy') ||
                lowerUrl.contains('lion') ||
                metaStr.contains('greedy-lion') ||
                metaStr.contains('greedylion')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/greedy-lion/1.3.7/web-mobile/index.html';
              print('[RoomScreen] Using fallback GreedyLion URL -> $finalUrl');
            }
            // BigEater (game_id: 1067)
            else if (lowerName.contains('big') ||
                lowerName.contains('eater') ||
                lowerUrl.contains('big') ||
                lowerUrl.contains('eater') ||
                metaStr.contains('big-eater') ||
                metaStr.contains('bigeater')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/big-eater/1.2.2/web-mobile/index.html';
              print('[RoomScreen] Using fallback BigEater URL -> $finalUrl');
            }
            // TeenPatti (game_id: 1041)
            else if (lowerName.contains('teen') ||
                lowerName.contains('patti') ||
                lowerUrl.contains('teen') ||
                lowerUrl.contains('patti') ||
                metaStr.contains('teenpatti')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/teenpatti/1.4.1/web-mobile/index.html';
              print('[RoomScreen] Using fallback TeenPatti URL -> $finalUrl');
            }
            // Lucky77 (game_id: 1040)
            else if (lowerName.contains('lucky77') ||
                lowerName.contains('lucky 77') ||
                lowerUrl.contains('lucky77') ||
                lowerUrl.contains('lucky 77') ||
                metaStr.contains('lucky77')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/fruitroulette/1.4.2/web-mobile/index.html';
              print('[RoomScreen] Using fallback Lucky77 URL -> $finalUrl');
            }
            // LuckyChest (game_id: 1026)
            else if (lowerName.contains('lucky') ||
                lowerName.contains('chest') ||
                lowerUrl.contains('lucky') ||
                lowerUrl.contains('chest') ||
                metaStr.contains('lucky_chest')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/lucky_chest/1.2.7/web-mobile/index.html';
              print('[RoomScreen] Using fallback LuckyChest URL -> $finalUrl');
            }
            // Fruit Carnival
            else if (lowerName.contains('fruit') ||
                lowerUrl.contains('fruit') ||
                metaStr.contains('fruit_carnival') ||
                metaStr.contains('fruit')) {
              finalUrl =
                  'https://game-center-test.jieyou.shop/game-packages/common-web/fruit_carnival/1.0.8/web-mobile/index.html';
              print(
                '[RoomScreen] Using fallback Fruit Carnival URL -> $finalUrl',
              );
            }
          }
        } catch (e) {
          print('[RoomScreen] Error checking game URL fallback: $e');
        }

        // Open the game in an in-app WebView with JS bridge; pass meta if present
        await _openGameWebView(context, finalUrl, name, meta: meta);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetworkImage
                  ? Image.network(
                      asset,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.videogame_asset,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : isLocalAsset
                  ? AppImage.asset(
                      asset,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.videogame_asset,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.videogame_asset,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          SizedBox(height: 6),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Store provider references for safe access in dispose()
  SeatProvider? _seatProvider;
  RoomMessageProvider? _messageProvider;

  // ✅ Track when user joined the room (for filtering chat history)
  DateTime? _userJoinedAt;

  // ✅ Periodic seat refresh timer (to sync seats even if backend is slow)
  Timer? _seatRefreshTimer;

  // ✅ Track all users in the room (whether on seats or not)
  // Map: userId -> {name, profileUrl, username}
  // ✅ User IDs are normalized (leading zeros removed) to prevent duplicates
  final Map<String, Map<String, String?>> _usersInRoom = {};
  // Cache for chat contact profile URLs fetched on demand
  final Map<String, String?> _chatUserProfiles = {};

  // ✅ Track processed user:joined events to prevent duplicate messages
  // Map: normalizedUserId -> last processed timestamp
  final Map<String, DateTime> _processedUserJoinedEvents = {};

  // ✅ Cache user tags by userId for room display
  final Map<String, List<String>> _userTagsById = {};
  final Set<String> _loadingUserTags = {};

  // ✅ Helper function to normalize user ID (remove leading zeros)
  String _normalizeUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '';
    return userId.replaceFirst(RegExp(r'^0+'), '');
  }

  Future<void> _requestUserTags(String? userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId.isEmpty) return;
    if (_userTagsById.containsKey(normalizedUserId)) return;
    if (_loadingUserTags.contains(normalizedUserId)) return;

    final userIdInt = int.tryParse(normalizedUserId);
    if (userIdInt == null) return;

    _loadingUserTags.add(normalizedUserId);
    try {
      final response = await ApiManager.getUserTags(userIdInt);
      if (response != null && response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>?;
        final tagsList = data?['tags'] as List<dynamic>? ?? [];
        final tags = tagsList.map((tag) => tag.toString()).toList();

        if (mounted) {
          setState(() {
            _userTagsById[normalizedUserId] = tags;
          });
        } else {
          _userTagsById[normalizedUserId] = tags;
        }
      }
    } catch (e) {
      // Silently ignore tag fetch failures in room UI
    } finally {
      _loadingUserTags.remove(normalizedUserId);
    }
  }

  @override
  void initState() {
    _luckyBannerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    // Initialize with left-to-right entrance
    _luckyBannerSlideAnimation =
        Tween<Offset>(begin: Offset(-1.2, 0), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: _luckyBannerAnimationController!,
            curve: Curves.easeOut,
          ),
        );
    super.initState();
    _displayRoomName = widget.roomName;
    _displayRoomProfileUrl = widget.roomProfileUrl;
    _initializeAllData();
    // Listen for native Baishun events (Android Java bridge) and forward responses to the WebView
    if (Platform.isAndroid) {
      try {
        _bsEventSub = _bsEventChannel.receiveBroadcastStream().listen(
          (event) async {
            await _handleBsEvent(event);
          },
          onError: (err) {
            print('[RoomScreen] Baishun EventChannel error: $err');
          },
        );
      } catch (e) {
        print('[RoomScreen] Failed to subscribe to baishunChannel: $e');
      }
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && showInput) {
        Future.delayed(const Duration(milliseconds: 150), () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_focusNode.hasFocus) {
              setState(() => showInput = false);
            }
          });
        });
      }
    });
    // ✅ REMOVED: loadCoins() from here - moved to after room join in _initializeAllData
  }

  Future<void> loadCoins() async {
    final coins = await getTotalCoins();
    if (coins != null && mounted) {
      setState(() {
        totalCoins = coins.toString();
      });
      // Notify game (if open) about wallet update
      _sendWalletUpdate(_gameWebController, {'balance': coins});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Store provider references safely when dependencies are available
    _seatProvider ??= Provider.of<SeatProvider>(context, listen: false);
    _messageProvider ??= Provider.of<RoomMessageProvider>(
      context,
      listen: false,
    );
    if (!_giftsFetchRequested) {
      _giftsFetchRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final giftProvider = Provider.of<GiftProvider>(context, listen: false);
        giftProvider.fetchAllGifts();
      });
    }
    if (!_clearedChatOnEnter && _messageProvider != null) {
      _messageProvider!.clearMessages();
      _clearedChatOnEnter = true;
      print("🧹 Cleared chat on room entry");
    }
  }

  /// Fetch total coins for the current room
  /// Returns the total_sent_value from room_summary or null on error
  Future<dynamic> getTotalCoins() async {
    try {
      print('💰 [RoomScreen] Fetching total coins for room: ${widget.roomId}');

      final response = await ApiManager.fetchTotalCoins(roomId: widget.roomId);

      if (response == null) {
        print('❌ [RoomScreen] Null response from API');
        return null;
      }

      // Validate response structure
      if (response['status'] != "success") {
        final errorMsg = response['message'] ?? 'Unknown error';
        print('❌ [RoomScreen] API failed: $errorMsg');
        return null;
      }

      final data = response['data'];
      if (data == null) {
        print('❌ [RoomScreen] No data field in response');
        return null;
      }

      // Extract total_sent_value from room_summary
      final roomSummary = data['room_summary'];
      if (roomSummary == null) {
        print('❌ [RoomScreen] No room_summary in data');
        return null;
      }

      final totalCoins = roomSummary['total_sent_value'];
      if (totalCoins == null) {
        print('⚠️ [RoomScreen] total_sent_value is null, returning 0');
        return 0;
      }

      print('✅ [RoomScreen] Total coins fetched: $totalCoins');
      return totalCoins;
    } catch (e, stackTrace) {
      print('❌ [RoomScreen] Error fetching total coins: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _runDebugTest() async {
    String roomId = widget.roomId;
    print("🚀 Starting debug test for room: $roomId");
    await ApiManager.debugSeatsFlow(roomId);

    print("\n🧪 Testing with Provider:");
    await Provider.of<SeatProvider>(
      context,
      listen: false,
    ).initializeSeats(roomId);
    await Future.delayed(Duration(seconds: 1));

    bool success = await Provider.of<SeatProvider>(
      context,
      listen: false,
    ).getSeats(roomId);
    print("Provider Success: $success");
    print(
      "Provider Seats Count: ${Provider.of<SeatProvider>(context, listen: false).seats.length}",
    );
  }

  void _showLoginError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Login Required"),
          content: const Text("You need to login to access rooms."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text("Go to Login"),
            ),
          ],
        ),
      );
    });
  }

  void _showServerError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Server Error"),
          content: const Text(
            "The server is currently unavailable (Error 500).\n\n"
            "Please try again in a few moments. If the problem persists, "
            "please contact support.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry by reinitializing
                _initializeAllData();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    });
  }

  // ✅ Added _isDisposing flag to prevent setState after dispose
  bool _isDisposing = false;
  // Track single reload attempt to recover from renderer crashes / blank canvas
  final int _gameReloadAttempts = 0;
  String? _gameReloadTarget;

  // ✅ Safe setState helper: checks mounted and disposing flag
  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposing) return;
    setState(fn);
  }

  Future<void> _initializeAllData() async {
    try {
      print("🎯 STARTING ROOM INITIALIZATION");

      final prefs = await SharedPreferences.getInstance();

      // ✅ DEBUG: Print all SharedPreferences keys to understand what's stored
      print("🔍 All SharedPreferences keys: ${prefs.getKeys()}");
      print("🔍 Checking for google_id...");

      // ✅ Try multiple ways to get google_id (handle both String and int types)
      dynamic userIdValue = prefs.get('google_id');
      print(
        "🔍 Raw google_id value: $userIdValue (Type: ${userIdValue?.runtimeType})",
      );

      if (userIdValue != null) {
        if (userIdValue is int) {
          _currentUserId = userIdValue.toString();
        } else if (userIdValue is String) {
          _currentUserId = userIdValue;
        }
      } else {
        _currentUserId = null;
      }

      print("📱 User ID from SharedPreferences: $_currentUserId");
      print("📱 is_logged_in: ${prefs.getBool('is_logged_in')}");
      print("📱 isLoggedIn: ${prefs.getBool('isLoggedIn')}");
      print("📱 email: ${prefs.getString('email')}");
      print("📱 username: ${prefs.getString('username')}");

      // ✅ If user_id is missing, try to fetch it using google_id
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        print("⚠️ USER ID NULL - Attempting to fetch using google_id...");

        // ✅ Check if we have google_id from SharedPreferences
        // ✅ Try multiple keys: 'google_id' (global) and user-specific ones
        String? googleId = prefs.getString('google_id');

        // ✅ If global google_id not found, check user-specific keys
        if (googleId == null || googleId.isEmpty) {
          // Try to find any google_id in SharedPreferences
          final allKeys = prefs.getKeys();
          for (String key in allKeys) {
            if (key.startsWith('google_id')) {
              googleId = prefs.getString(key);
              if (googleId != null && googleId.isNotEmpty) {
                print("🔍 Found google_id in key: $key");
                break;
              }
            }
          }
        }

        if (googleId != null && googleId.isNotEmpty) {
          print("🔍 Found google_id from SharedPreferences: $googleId");
          print("🔄 Attempting to fetch user_id from API using google_id...");
          print(
            "🔄 API might return 500 (server error), but we'll keep trying...",
          );

          // ✅ Increased retries with exponential backoff for 500 errors
          bool fetchSuccess = false;
          int maxRetries =
              2; // ✅ Increased from 2 to 5 retries for persistent 500 errors

          for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
              print(
                "🔄 Attempt $attempt of $maxRetries (using google_id: $googleId)...",
              );
              final userData = await ApiManager.googleLogin(
                google_id: googleId,
              );

              if (userData != null && userData.id.isNotEmpty) {
                print(
                  "✅ Successfully fetched user_id from API: ${userData.id}",
                );
                // ✅ Format user_id to 8 digits and save to SharedPreferences
                final formattedUserId = UserIdUtils.formatTo8Digits(
                  userData.id,
                );
                if (formattedUserId != null) {
                  await prefs.setString('user_id', formattedUserId);
                  _currentUserId = formattedUserId;
                  print(
                    "✅ User ID formatted to 8 digits: $formattedUserId (original: ${userData.id})",
                  );
                } else {
                  await prefs.setString('user_id', userData.id);
                  _currentUserId = userData.id;
                }

                // ✅ Also save other user data if available
                if (userData.email.isNotEmpty) {
                  await prefs.setString('email', userData.email);
                }
                if (userData.name.isNotEmpty) {
                  await prefs.setString('username', userData.name);
                }

                // ✅ Save google_id with user_id for future use
                await prefs.setString('google_id_${userData.id}', googleId);

                print("✅ User ID saved successfully: $_currentUserId");
                fetchSuccess = true;
                break; // Success, exit retry loop
              } else {
                print(
                  "⚠️ Attempt $attempt: API returned null or empty user_id",
                );
                if (attempt < maxRetries) {
                  // ✅ Exponential backoff: 1s, 2s, 3s, 4s
                  int delaySeconds = attempt;
                  print("⏳ Waiting $delaySeconds second(s) before retry...");
                  await Future.delayed(Duration(seconds: delaySeconds));
                }
              }
            } catch (e) {
              print("❌ Attempt $attempt failed: $e");
              // ✅ Check if it's a 500 error (server error)
              if (e.toString().contains('500') ||
                  e.toString().contains('HTTP Error: 500')) {
                print(
                  "⚠️ Server returned 500 error - This is a server issue, not a client issue",
                );
              }

              if (attempt < maxRetries) {
                // ✅ Exponential backoff: 1s, 2s, 3s, 4s
                int delaySeconds = attempt;
                print("⏳ Waiting $delaySeconds second(s) before retry...");
                await Future.delayed(Duration(seconds: delaySeconds));
              }
            }
          }

          if (!fetchSuccess) {
            print(
              "❌ All $maxRetries attempts failed - API is consistently returning 500 error",
            );
            print(
              "❌ Server is currently unavailable. User cannot access rooms.",
            );
            print(
              "❌ google_id was found in SharedPreferences but API is not responding",
            );
            _showServerError();
            if (mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
            return;
          }
        } else {
          print("❌ USER ID NULL AND NO GOOGLE_ID - Showing login error");
          print(
            "❌ This means the user is not logged in or google_id was not saved properly",
          );
          _showLoginError();
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
          return;
        }
      }

      // User ID found
      print("✅ User ID found");

      await Future.delayed(Duration(milliseconds: 100));

      // ✅ Check if still mounted after async operations
      if (!mounted) return;

      // ✅ Use stored reference or get it if not stored yet
      _seatProvider ??= Provider.of<SeatProvider>(context, listen: false);
      final seatProvider = _seatProvider!;

      // ✅ Get database user_id for WebSocket connection
      final databaseUserId = await _getDatabaseUserId();
      _databaseUserId = databaseUserId; // ✅ Store for later use
      _baishunUserId = _normalizeBaishunUserId(_databaseUserId);
      // ✅ Ensure UserMessageProvider is initialized and chatRooms are loaded
      try {
        final userMsgProv = Provider.of<UserMessageProvider>(
          context,
          listen: false,
        );
        final dbIdInt = int.tryParse(_databaseUserId ?? '') ?? 0;
        if (dbIdInt != 0) {
          userMsgProv.setCurrentUser(dbIdInt);
          await userMsgProv.loadChatRooms();
          print(
            '✅ UserMessageProvider: loaded chatRooms for user $dbIdInt (${userMsgProv.chatRooms.length})',
          );
        } else {
          await userMsgProv.initializeUser();
          print(
            '✅ UserMessageProvider: initialized (chatRooms: ${userMsgProv.chatRooms.length})',
          );
        }
      } catch (e) {
        print('⚠️ Failed to initialize UserMessageProvider: $e');
      }

      // // Fetch backpack for current database user id
      // try {
      //   if (databaseUserId != null && databaseUserId.isNotEmpty) {
      //     final backbackProvider = Provider.of<BackpackProvider>(context, listen: false);
      //     backbackProvider.fetchBackpackByUserId(databaseUserId);
      //     print('🔍 Requested backpack for user: $databaseUserId');
      //   }
      // } catch (e) {
      //   print('⚠️ Failed to fetch backpack: $e');
      // }
      print("🔌 Connecting to WebSocket...");

      print("📡 [RoomScreen] Using ProfileUpdateProvider data:");
      final profileProvider = Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      );
      final currentUsername = profileProvider.username ?? 'User';
      final currentProfileUrl = profileProvider.profile_url;
      print("   - Username: $currentUsername (NO SharedPreferences fallback)");
      print(
        "   - Profile URL: $currentProfileUrl (NO SharedPreferences fallback)",
      );

      final wsConnected = await seatProvider.connect(
        roomId: widget.roomId.toString(),
        userId: databaseUserId ?? '',
        username: currentUsername,
        profileUrl: currentProfileUrl,
      );

      if (wsConnected && databaseUserId != null && databaseUserId.isNotEmpty) {
        print(
          "🎯 Joining room via WebSocket: roomId=${widget.roomId}, userId=$databaseUserId",
        );

        // ✅ Store join timestamp - messages before this will be filtered out
        _userJoinedAt = DateTime.now();
        print("⏰ User join timestamp recorded: $_userJoinedAt");

        // ✅ Add current user to room users tracking - normalize user ID
        // Get current user info from ProfileUpdateProvider
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        final normalizedUserId = _normalizeUserId(databaseUserId);
        if (normalizedUserId.isNotEmpty) {
          _usersInRoom[normalizedUserId] = {
            'name': profileProvider.username ?? 'User',
            'username': profileProvider.username ?? 'User',
            'profileUrl': profileProvider.profile_url,
          };
          print(
            "👤 [RoomScreen] Current user $normalizedUserId (normalized from $databaseUserId) added to room. Total users: ${_usersInRoom.length}",
          );
        }

        await seatProvider.joinRoom(widget.roomId.toString(), databaseUserId);

        // ✅ Verify room context is set
        print("✅ WebSocket Room Context Verification:");
        print("   - Current Room ID: ${seatProvider.currentRoomId}");
        print("   - Expected Room ID: ${widget.roomId}");
        print(
          "   - Match: ${seatProvider.currentRoomId == widget.roomId.toString()}",
        );

        // ✅ Set up WebSocket event listeners for chat messages and gifts
        _setupWebSocketEventListeners(seatProvider);

        // ✅ Set SeatProvider in RoomMessageProvider for WebSocket message sending
        final messageProvider = Provider.of<RoomMessageProvider>(
          context,
          listen: false,
        );
        // ✅ CLEAR MESSAGES FROM PREVIOUS ROOM when entering new room
        messageProvider.clearMessages();
        print(
          "🗑️ Cleared messages from previous room - starting fresh for room ${widget.roomId}",
        );
        messageProvider.setSeatProvider(seatProvider);
        print(
          "✅ RoomMessageProvider configured with SeatProvider for WebSocket",
        );

        print("📡 Requesting seats...");
        await seatProvider.getSeats(widget.roomId.toString());

        // ✅ Request microphone permission before initializing Zego
        print("🎤 Requesting microphone permission...");
        try {
          // Request microphone permission
          final micPermission = await Permission.microphone.request();
          if (micPermission.isGranted) {
            print("✅ Microphone permission granted");
          } else if (micPermission.isPermanentlyDenied) {
            print(
              "⚠️ Microphone permission permanently denied - user needs to enable in settings",
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Microphone permission is required for voice calls. Please enable it in app settings.',
                  ),
                  action: SnackBarAction(
                    label: 'Open Settings',
                    onPressed: () async {
                      await openAppSettings();
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } else {
            print("⚠️ Microphone permission denied - voice calls may not work");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Microphone permission is required for voice calls.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print("⚠️ Error requesting microphone permission: $e");
          // Continue anyway - Zego will handle permission errors
        }

        // ✅ Initialize Zego Voice Service
        print("🎤 ===== INITIALIZING ZEGO VOICE SERVICE =====");
        final zegoProvider = Provider.of<ZegoVoiceProvider>(
          context,
          listen: false,
        );

        // ✅ Set up callback to refresh seats when Zego detects users/streams
        // This ensures seats are updated even if backend doesn't send seat events
        zegoProvider.onSeatsRefreshNeeded = () {
          print(
            "🔄 [RoomScreen] Zego detected user/stream change - refreshing seats",
          );
          seatProvider.getSeats(widget.roomId.toString());
        };

        // ✅ Initialize Zego with error checking (non-blocking)
        print("🎤 [RoomScreen] Step 1: Initializing Zego engine...");
        final initSuccess = await zegoProvider.initialize();
        if (!initSuccess) {
          final errorMsg = zegoProvider.errorMessage ?? 'Unknown error';
          print("⚠️ [RoomScreen] Zego initialization failed: $errorMsg");
          print(
            "ℹ️ [RoomScreen] Continuing without voice features - app will work normally",
          );
          // No SnackBar - user won't see voice-unavailable banner
        } else {
          print("✅ [RoomScreen] Zego engine initialized successfully");
        }

        // ✅ Join room with error checking (non-blocking). Fetch token if backend supports it (fixes 1001005).
        print("🎤 [RoomScreen] Step 2: Joining Zego room ${widget.roomId}...");
        if (initSuccess) {
          String? zegoToken;
          if (_databaseUserId != null && _databaseUserId!.isNotEmpty) {
            try {
              zegoToken = await ApiManager.getZegoToken(
                roomId: widget.roomId.toString(),
                userId: _databaseUserId!,
              );
              if (zegoToken != null) {
                print(
                  "✅ [RoomScreen] Got Zego token from backend – using token auth",
                );
              }
            } catch (e) {
              print(
                "⚠️ [RoomScreen] Zego token fetch failed: $e – joining without token",
              );
            }
          }
          final joinSuccess = await zegoProvider.joinRoom(
            widget.roomId.toString(),
            token: zegoToken,
          );
          if (!joinSuccess) {
            final errorMsg = zegoProvider.errorMessage ?? 'Unknown error';
            print("⚠️ [RoomScreen] Zego join room failed: $errorMsg");
            print(
              "ℹ️ [RoomScreen] Continuing without voice - all other features work normally",
            );
            // SnackBar removed so user doesn't see "Voice unavailable" banner every time
          } else {
            print(
              "✅ [RoomScreen] Successfully joined Zego room: ${widget.roomId}",
            );
            print("✅ [RoomScreen] Zego Voice Service ready for audio calls");
          }
        } else {
          print(
            "ℹ️ [RoomScreen] Skipping room join - Zego not initialized (app continues normally)",
          );
        }

        // ✅ Start periodic seat refresh (every 30 seconds) to keep seats in sync
        // This ensures seats are updated even if backend doesn't send real-time events
        // ✅ Increased interval to prevent clearing seat data when backend is slow
        _seatRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
          timer,
        ) {
          if (mounted) {
            print("🔄 [RoomScreen] Periodic seat refresh triggered");
            seatProvider.getSeats(widget.roomId.toString());
          }
        });
        print("✅ Periodic seat refresh timer started (every 30 seconds)");

        // ✅ Load chat history after seats are loaded
        print("📜 Loading chat history for room ${widget.roomId}...");
        await seatProvider.getChatHistory(
          roomId: widget.roomId.toString(),
          limit: 50,
        );
        print("✅ Chat history request sent");

        int maxWaitTime = 5000;
        int checkInterval = 500;
        int waited = 0;

        while (!seatProvider.hasSeats && waited < maxWaitTime) {
          await Future.delayed(Duration(milliseconds: checkInterval));
          waited += checkInterval;
          if (waited % 1000 == 0) {
            print("⏳ Waiting for seats... (${waited}ms / ${maxWaitTime}ms)");
          }
        }

        if (seatProvider.hasSeats) {
          print("✅ Seats loaded successfully! (waited ${waited}ms)");
        } else {
          print(
            "⚠️ Seats not received after ${maxWaitTime}ms - server may be slow",
          );
          print("⚠️ Seats will appear automatically when server responds");
        }
      } else {
        if (!wsConnected) {
          print("❌ WebSocket connection failed: ${seatProvider.errorMessage}");
        } else {
          print("⚠️ Could not get user ID for WebSocket join");
        }
      }

      if (!mounted) return;

      // ✅ Load coins after room is joined
      print("💰 Loading room coins...");
      try {
        final coins = await getTotalCoins();
        if (coins != null && mounted) {
          setState(() {
            totalCoins = coins.toString();
          });
          // Notify game (if open) about wallet update
          _sendWalletUpdate(_gameWebController, {'balance': coins});
          print("✅ Room coins loaded: $totalCoins");
        }
      } catch (e) {
        print("⚠️ Error loading coins: $e");
      }

      // ✅ REMOVED: Duplicate joinRoom call via JoinRoomProvider
      // ✅ REMOVED: fetchRoomMessages call - messages come via WebSocket only
      // ✅ WebSocket joinRoom (line 509) is sufficient - backend handles everything
      print(
        "✅ Room joined via WebSocket - messages and seats will update via WebSocket events",
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      print("🎉 ALL INITIALIZATION COMPLETED");
    } catch (e) {
      print("❌ INITIALIZATION ERROR: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  // ✅ Set up WebSocket event listeners for real-time chat messages
  // Note: Room filtering is handled at WebSocketService level - events here are already filtered
  // ✅ REMOVED: All local message sending - backend handles all messages via WebSocket
  // ✅ messageProvider is only used for RECEIVING messages from backend, not sending
  void _setupWebSocketEventListeners(SeatProvider seatProvider) {
    final messageProvider = Provider.of<RoomMessageProvider>(
      context,
      listen: false,
    );

    // ✅ User joined room
    // ✅ Backend sends user:joined events with message field - process and display it
    seatProvider.onUserJoined = (data) {
      print("👤 [RoomScreen] ===== USER JOINED EVENT RECEIVED =====");
      print("👤 [RoomScreen] Event data: $data");

      // ✅ Track user in room - handle both int and string user_id
      final userIdRaw = data['user_id'];
      String? userId;
      if (userIdRaw != null) {
        userId = userIdRaw.toString();
        print(
          "👤 [RoomScreen] Extracted user_id: $userId (type: ${userIdRaw.runtimeType})",
        );
      } else {
        print("⚠️ [RoomScreen] user_id is null in user:joined event");
      }

      // ✅ Extract message from user:joined event and display it
      final message =
          data['message'] as String? ?? data['message_text'] as String?;
      final userName =
          data['username'] as String? ?? data['user_name'] as String?;
      final profileUrl = data['profile_url'] as String?;
      final timestamp =
          data['timestamp'] as String? ?? data['created_at'] as String?;

      // ✅ Normalize profile URL if it's a relative path
      String? normalizedProfileUrl = profileUrl;
      if (normalizedProfileUrl != null &&
          normalizedProfileUrl.isNotEmpty &&
          !normalizedProfileUrl.startsWith('http')) {
        normalizedProfileUrl =
            'https://shaheenstar.online/$normalizedProfileUrl';
      }

      // ✅ Store user info in room tracking - normalize user ID to prevent duplicates
      if (userId != null && userId.isNotEmpty) {
        final normalizedUserId = _normalizeUserId(userId);
        if (normalizedUserId.isNotEmpty) {
          // Check if user already exists with different format
          String? existingUser;
          try {
            existingUser = _usersInRoom.keys.firstWhere(
              (key) => _normalizeUserId(key) == normalizedUserId,
            );
          } catch (e) {
            existingUser = null;
          }

          if (existingUser != null && existingUser != normalizedUserId) {
            // User exists with different format - update the existing entry
            print(
              "👤 [RoomScreen] User already exists with different format: $existingUser -> $normalizedUserId",
            );
            final existingInfo = _usersInRoom.remove(existingUser);
            _usersInRoom[normalizedUserId] =
                existingInfo ??
                {
                  'name': userName ?? data['user_name'] as String? ?? 'User',
                  'username':
                      userName ?? data['user_name'] as String? ?? 'User',
                  'profileUrl': normalizedProfileUrl,
                };
          } else {
            // New user or same format - add/update normally
            _usersInRoom[normalizedUserId] = {
              'name': userName ?? data['user_name'] as String? ?? 'User',
              'username': userName ?? data['user_name'] as String? ?? 'User',
              'profileUrl': normalizedProfileUrl,
            };
          }

          if (mounted) {
            setState(() {}); // Update UI to show new user count
          }
          print(
            "👤 [RoomScreen] ✅ User $normalizedUserId (normalized from $userId) added to room. Total users: ${_usersInRoom.length}",
          );
          print("👤 [RoomScreen] User info: ${_usersInRoom[normalizedUserId]}");
        } else {
          print("⚠️ [RoomScreen] Cannot add user - normalized userId is empty");
        }
      } else {
        print("⚠️ [RoomScreen] Cannot add user - userId is null or empty");
      }

      // ✅ Fetch tags for joined user (for tag badge display)
      _requestUserTags(userId);

      // ✅ Check if we've already processed this user:joined event recently (within 5 seconds)
      // This prevents duplicate messages when backend sends the same event multiple times
      final normalizedUserId = _normalizeUserId(userId);
      if (normalizedUserId.isNotEmpty) {
        final now = DateTime.now();
        final lastProcessed = _processedUserJoinedEvents[normalizedUserId];

        if (lastProcessed != null) {
          final timeDiff = now.difference(lastProcessed);
          if (timeDiff.inSeconds < 5) {
            print(
              "⚠️ [RoomScreen] Duplicate user:joined event detected for user $normalizedUserId (within ${timeDiff.inSeconds}s) - skipping message",
            );
            print("👤 [RoomScreen] ======================================");
            return; // Skip processing this duplicate event
          }
        }

        // Mark this event as processed
        _processedUserJoinedEvents[normalizedUserId] = now;
      }

      if (message != null && message.isNotEmpty && userId != null) {
        final finalUserName = userName ?? 'User';

        final joinedMessage = SendMessageRoomModel.createFromWebSocket(
          userId: userId,
          roomId: widget.roomId,
          message: message,
          userName: finalUserName,
          profileUrl: normalizedProfileUrl,
          timestamp: timestamp,
        );

        messageProvider.addReceivedMessage(joinedMessage);
        print(
          "✅ 'Joined the room' message added from user:joined event: $finalUserName - $message",
        );
      } else {
        print("⚠️ [RoomScreen] user:joined event missing message or userId");
      }

      print("👤 [RoomScreen] ======================================");
    };

    // ✅ User left room
    // ✅ REMOVED: Local message sending - backend sends "left room" messages via WebSocket
    // ✅ Backend handles all message sending - this callback is kept for potential future UI updates only
    seatProvider.onUserLeft = (data) {
      print("👋 [RoomScreen] ===== USER LEFT EVENT RECEIVED =====");
      print("👋 [RoomScreen] Event data: $data");

      // ✅ Remove user from room tracking - normalize user ID
      final userIdRaw = data['user_id'];
      String? userId;
      if (userIdRaw != null) {
        userId = userIdRaw.toString();
      }
      if (userId != null && userId.isNotEmpty) {
        final normalizedUserId = _normalizeUserId(userId);
        if (normalizedUserId.isNotEmpty) {
          // Find and remove user with normalized ID (handles different formats)
          String? existingUser;
          try {
            existingUser = _usersInRoom.keys.firstWhere(
              (key) => _normalizeUserId(key) == normalizedUserId,
            );
          } catch (e) {
            existingUser = null;
          }

          if (existingUser != null) {
            _usersInRoom.remove(existingUser);
            if (mounted) {
              setState(() {}); // Update UI to show updated user count
            }
            print(
              "👋 [RoomScreen] User $normalizedUserId (normalized from $userId) removed from room. Total users: ${_usersInRoom.length}",
            );
          } else {
            print(
              "⚠️ [RoomScreen] User $normalizedUserId not found in room tracking",
            );
          }
        }
      }

      print(
        "👋 [RoomScreen] Backend will send 'left room' message via WebSocket - no local message needed",
      );
      print("👋 [RoomScreen] =====================================");
    };

    // ✅ Seat occupied (for seat join messages)
    // ✅ Backend sends seat:occupied events - check if it includes message, otherwise create one
    seatProvider.onSeatOccupied = (data) async {
      print("🪑 [RoomScreen] ===== SEAT OCCUPIED EVENT RECEIVED =====");
      print("🪑 [RoomScreen] Event data: $data");

      // ✅ Check if backend sent a message in the event
      final message =
          data['message'] as String? ?? data['message_text'] as String?;
      final userId = data['user_id']?.toString();
      final userName =
          data['username'] as String? ?? data['user_name'] as String?;
      final seatNumber = data['seat_number'] as int?;
      final profileUrl = data['profile_url'] as String?;
      final timestamp =
          data['timestamp'] as String? ?? data['created_at'] as String?;

      // ✅ Check if this is the current user - if so, start audio publishing
      final databaseUserId = await _getDatabaseUserId();
      if (databaseUserId != null && userId != null && seatNumber != null) {
        // Normalize user IDs for comparison (remove leading zeros)
        final normalizedEventUserId = userId.replaceFirst(RegExp(r'^0+'), '');
        final normalizedCurrentUserId = databaseUserId.replaceFirst(
          RegExp(r'^0+'),
          '',
        );

        print(
          "🔍 [RoomScreen] Checking if seat occupation is for current user:",
        );
        print("   - Event User ID (normalized): $normalizedEventUserId");
        print("   - Current User ID (normalized): $normalizedCurrentUserId");
        print(
          "   - Match: ${normalizedEventUserId == normalizedCurrentUserId}",
        );

        if (normalizedEventUserId == normalizedCurrentUserId) {
          print(
            "✅ [RoomScreen] Current user occupied seat $seatNumber - starting audio publishing",
          );
          // ✅ Start publishing audio stream via Zego
          final zegoProvider = Provider.of<ZegoVoiceProvider>(
            context,
            listen: false,
          );

          // ✅ Check if Zego is ready
          if (!zegoProvider.isInitialized) {
            print("⚠️ [RoomScreen] Zego not initialized, initializing now...");
            final initSuccess = await zegoProvider.initialize();
            if (!initSuccess) {
              print(
                "❌ [RoomScreen] Failed to initialize Zego: ${zegoProvider.errorMessage}",
              );
              return;
            }
          }

          if (!zegoProvider.isInRoom) {
            print("⚠️ [RoomScreen] Not in Zego room, joining now...");
            String? token;
            if (_databaseUserId != null && _databaseUserId!.isNotEmpty) {
              try {
                token = await ApiManager.getZegoToken(
                  roomId: widget.roomId.toString(),
                  userId: _databaseUserId!,
                );
              } catch (_) {}
            }
            final joinSuccess = await zegoProvider.joinRoom(
              widget.roomId.toString(),
              token: token,
            );
            if (!joinSuccess) {
              print(
                "❌ [RoomScreen] Failed to join Zego room: ${zegoProvider.errorMessage}",
              );
              return;
            }
          }

          print(
            "🎤 [RoomScreen] Starting audio publishing from seat:occupied event...",
          );
          print(
            "🎤 [RoomScreen] - Is Initialized: ${zegoProvider.isInitialized}",
          );
          print("🎤 [RoomScreen] - Is In Room: ${zegoProvider.isInRoom}");
          print(
            "🎤 [RoomScreen] - Current Room ID: ${zegoProvider.currentRoomID}",
          );
          print(
            "🎤 [RoomScreen] - Current User ID: ${zegoProvider.currentUserID}",
          );

          final publishSuccess = await zegoProvider.startPublishing();
          if (publishSuccess) {
            print(
              "✅ [RoomScreen] Successfully started Zego audio publishing from seat:occupied event",
            );
            print("✅ [RoomScreen] Audio stream is now active");
          } else {
            final errorMsg = zegoProvider.errorMessage ?? 'Unknown error';
            print("❌ [RoomScreen] Failed to start audio publishing: $errorMsg");
          }
        }
      }

      // ✅ If backend didn't send a message, create one from the event data
      final finalMessage =
          message ??
          (seatNumber != null && userName != null
              ? "$userName joined seat $seatNumber"
              : null);

      if (finalMessage != null && finalMessage.isNotEmpty && userId != null) {
        // ✅ Normalize profile URL if it's a relative path
        String? normalizedProfileUrl = profileUrl;
        if (normalizedProfileUrl != null &&
            normalizedProfileUrl.isNotEmpty &&
            !normalizedProfileUrl.startsWith('http')) {
          normalizedProfileUrl =
              'https://shaheenstar.online/$normalizedProfileUrl';
        }

        final finalUserName = userName ?? 'User';

        final seatJoinMessage = SendMessageRoomModel.createFromWebSocket(
          userId: userId,
          roomId: widget.roomId,
          message: finalMessage,
          userName: finalUserName,
          profileUrl: normalizedProfileUrl,
          timestamp: timestamp,
        );

        messageProvider.addReceivedMessage(seatJoinMessage);
        print(
          "✅ 'Joined seat' message added from seat:occupied event: $finalUserName - $finalMessage",
        );
      } else {
        print(
          "⚠️ [RoomScreen] seat:occupied event missing required data for message",
        );
      }

      print("🪑 [RoomScreen] ======================================");
    };

    // ✅ Mic status changed
    // ✅ REMOVED: Local message sending - backend sends mic status messages via WebSocket
    // ✅ Backend handles all message sending - this callback is kept for potential future UI updates only
    seatProvider.onMicStatusChanged = (data) {
      print("🎤 [RoomScreen] ===== MIC STATUS CHANGED EVENT RECEIVED =====");
      print("🎤 [RoomScreen] Event data: $data");
      print(
        "🎤 [RoomScreen] Backend will send mic status message via WebSocket - no local message needed",
      );
      print("🎤 [RoomScreen] =============================================");
    };

    // ✅ User speaking
    // ✅ REMOVED: Local message sending - backend sends speaking messages via WebSocket
    // ✅ Backend handles all message sending - this callback is kept for potential future UI updates only
    seatProvider.onUserSpeaking = (data) {
      print("🗣️ [RoomScreen] ===== USER SPEAKING EVENT RECEIVED =====");
      print("🗣️ [RoomScreen] Event data: $data");
      print(
        "🗣️ [RoomScreen] Backend will send speaking message via WebSocket - no local message needed",
      );
      print("🗣️ [RoomScreen] =======================================");
    };

    // ✅ Gift sent event
    seatProvider.onGiftSent = (data) async {
      print("🎁 Gift sent event received in room screen");
      print("   Data: $data");

      Map<String, dynamic> payload = data;
      if (data['data'] != null && data['data'] is Map) {
        payload = Map<String, dynamic>.from(data['data'] as Map);
      }

      int safeInt(dynamic value) {
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      double safeDouble(dynamic value) {
        return double.tryParse(value?.toString() ?? '') ?? 0.0;
      }

      String? safeString(dynamic value) {
        if (value == null) return null;
        final s = value.toString().trim();
        if (s.isEmpty || s.toLowerCase() == 'null') return null;
        return s;
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

      String? normalizeMediaUrl(String? raw) {
        if (raw == null) return null;
        var url = raw.trim();
        if (url.isEmpty || url.toLowerCase() == 'null') return null;
        if (url.startsWith('http://') || url.startsWith('https://')) return url;
        if (url.startsWith('/')) url = url.substring(1);
        return 'https://shaheenstar.online/$url';
      }

      // ✅ Check if gift belongs to this room - filter out gifts from other rooms
      final giftRoomId =
          payload['room_id']?.toString() ?? data['room_id']?.toString();
      final currentRoomId = widget.roomId.toString();

      if (giftRoomId != null && giftRoomId != currentRoomId) {
        print(
          "⏭️ [RoomScreen] Gift belongs to different room (gift room_id: $giftRoomId, current room_id: $currentRoomId) - ignoring",
        );
        return;
      }

      print(
        "✅ [RoomScreen] Gift belongs to current room (room_id: ${giftRoomId ?? currentRoomId}) - processing",
      );

      // ✅ Handle gift display via GiftDisplayProvider
      final giftDisplayProvider = Provider.of<GiftDisplayProvider>(
        context,
        listen: false,
      );
      final giftId = safeInt(payload['gift_id']) > 0
          ? safeInt(payload['gift_id'])
          : (safeInt(payload['giftId']) > 0
                ? safeInt(payload['giftId'])
                : safeInt(nestedString(payload, ['gift', 'id'])));

      final senderId = safeString(payload['sender_id']);
      final receiverId = safeString(payload['receiver_id']);
      final senderIdInt = safeInt(senderId);
      final receiverIdInt = safeInt(receiverId);

      final receiverSeatNumber = safeInt(
        payload['seat_number'] ??
            payload['receiver_seat'] ??
            payload['to_seat'] ??
            payload['receiver_seat_number'],
      );

      // ✅ Robust Name Extraction (using safeString to avoid " " empty strings)
      var senderName =
          safeString(payload['sender_name']) ??
          safeString(payload['sender_username']) ??
          safeString(payload['sender']) ??
          safeString(payload['from_name']) ??
          nestedString(payload, ['sender', 'name']) ??
          nestedString(payload, ['sender', 'username']) ??
          'User';

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

      var senderAvatar =
          safeString(payload['sender_avatar']) ??
          safeString(payload['sender_image']) ??
          safeString(payload['sender_profile']) ??
          safeString(payload['sender_profile_url']) ??
          nestedString(payload, ['sender', 'profile_url']) ??
          nestedString(payload, ['sender', 'avatar']);

      var receiverAvatar =
          safeString(payload['receiver_avatar']) ??
          safeString(payload['receiver_image']) ??
          safeString(payload['receiver_profile']) ??
          safeString(payload['receiver_profile_url']) ??
          nestedString(payload, ['receiver', 'profile_url']) ??
          nestedString(payload, ['receiver', 'avatar']);

      final quantity = safeInt(payload['quantity']) > 0
          ? safeInt(payload['quantity'])
          : 1;

      final giftName =
          safeString(payload['gift_name']) ??
          safeString(payload['gift']) ??
          nestedString(payload, ['gift', 'gift_name']) ??
          nestedString(payload, ['gift', 'name']);

      final payloadGiftValue =
          double.tryParse(payload['gift_value']?.toString() ?? '0') ?? 0.0;

      // ✅ Fetch sender and receiver profile data from seat provider if avatars are missing
      if ((senderAvatar == null ||
              senderAvatar.isEmpty ||
              receiverAvatar == null ||
              receiverAvatar.isEmpty ||
              senderName.isEmpty ||
              receiverName.isEmpty) &&
          (senderId != null || receiverId != null || receiverSeatNumber > 0)) {
        try {
          // ✅ Get sender profile from seat
          if ((senderAvatar == null || senderAvatar.isEmpty) &&
              senderIdInt > 0) {
            try {
              final senderSeat = seatProvider.seats.firstWhere(
                (s) =>
                    s.isOccupied &&
                    (safeInt(s.userId) == senderIdInt ||
                        s.userId?.toString() == senderId?.toString()),
              );
              if (senderSeat.profileUrl != null &&
                  senderSeat.profileUrl!.isNotEmpty) {
                senderAvatar = senderSeat.profileUrl;
                if (!senderAvatar!.startsWith('http://') &&
                    !senderAvatar.startsWith('https://')) {
                  senderAvatar = 'https://shaheenstar.online/$senderAvatar';
                }
                print("✅ Got sender avatar from seat: $senderAvatar");
              }
              if ((senderName.isEmpty || senderName == 'User') &&
                  (senderSeat.userName != null ||
                      senderSeat.username != null)) {
                senderName =
                    senderSeat.userName ?? senderSeat.username ?? 'User';
                print("✅ Got sender name from seat: $senderName");
              }
            } catch (e) {
              print("⚠️ Sender not found on seats: $e");
            }
          }

          // ✅ Get receiver profile from seat
          if ((receiverAvatar == null || receiverAvatar.isEmpty) &&
              receiverIdInt > 0) {
            try {
              final receiverSeat = seatProvider.seats.firstWhere(
                (s) =>
                    s.isOccupied &&
                    (safeInt(s.userId) == receiverIdInt ||
                        s.userId?.toString() == receiverId?.toString()),
              );
              if (receiverSeat.profileUrl != null &&
                  receiverSeat.profileUrl!.isNotEmpty) {
                receiverAvatar = receiverSeat.profileUrl;
                if (!receiverAvatar!.startsWith('http://') &&
                    !receiverAvatar.startsWith('https://')) {
                  receiverAvatar = 'https://shaheenstar.online/$receiverAvatar';
                }
                print("✅ Got receiver avatar from seat: $receiverAvatar");
              }
              if ((receiverName.isEmpty || receiverName == 'User') &&
                  (receiverSeat.userName != null ||
                      receiverSeat.username != null)) {
                receiverName =
                    receiverSeat.userName ?? receiverSeat.username ?? 'User';
                print("✅ Got receiver name from seat: $receiverName");
              }
            } catch (e) {
              print("⚠️ Receiver not found on seats: $e");
            }
          }

          // ✅ Fallback: find receiver by seat number
          if ((receiverName.isEmpty || receiverName == 'User') &&
              receiverSeatNumber > 0) {
            try {
              final seatByNumber = seatProvider.seats.firstWhere(
                (s) => s.isOccupied && s.seatNumber == receiverSeatNumber,
              );
              if (seatByNumber.userName != null ||
                  seatByNumber.username != null) {
                receiverName =
                    seatByNumber.userName ?? seatByNumber.username ?? 'User';
                print("✅ Got receiver name from seat number: $receiverName");
              }
              if ((receiverAvatar == null || receiverAvatar.isEmpty) &&
                  seatByNumber.profileUrl != null &&
                  seatByNumber.profileUrl!.isNotEmpty) {
                receiverAvatar = seatByNumber.profileUrl;
                if (!receiverAvatar!.startsWith('http://') &&
                    !receiverAvatar!.startsWith('https://')) {
                  receiverAvatar = 'https://shaheenstar.online/$receiverAvatar';
                }
              }
            } catch (e) {
              print("⚠️ Receiver seat number not found: $e");
            }
          }
        } catch (e) {
          print("⚠️ Error getting profile data from seats: $e");
        }
      }

      // ✅ Normalize and validate avatar URLs - add base URL if they're relative paths
      if (senderAvatar != null && senderAvatar.isNotEmpty) {
        final trimmed = senderAvatar.trim().toLowerCase();
        // ✅ Filter out invalid values
        final invalidValues = [
          'upload',
          'profile url',
          'profile_url',
          'jgh',
          'null',
          'yyyy',
          'profile',
          'avatar',
          'image',
        ];
        if (invalidValues.contains(trimmed) || trimmed.length < 5) {
          print(
            "⚠️ Invalid sender avatar value: '$senderAvatar' - setting to null",
          );
          senderAvatar = null;
        } else if (!senderAvatar.startsWith('http://') &&
            !senderAvatar.startsWith('https://')) {
          senderAvatar = 'https://shaheenstar.online/$senderAvatar';
          print("✅ Normalized sender avatar URL: $senderAvatar");
        } else {
          print("✅ Sender avatar URL is already valid: $senderAvatar");
        }
      } else {
        print("⚠️ Sender avatar is null or empty");
      }

      if (receiverAvatar != null && receiverAvatar.isNotEmpty) {
        final trimmed = receiverAvatar.trim().toLowerCase();
        // ✅ Filter out invalid values
        final invalidValues = [
          'upload',
          'profile url',
          'profile_url',
          'jgh',
          'null',
          'yyyy',
          'profile',
          'avatar',
          'image',
        ];
        if (invalidValues.contains(trimmed) || trimmed.length < 5) {
          print(
            "⚠️ Invalid receiver avatar value: '$receiverAvatar' - setting to null",
          );
          receiverAvatar = null;
        } else if (!receiverAvatar.startsWith('http://') &&
            !receiverAvatar.startsWith('https://')) {
          receiverAvatar = 'https://shaheenstar.online/$receiverAvatar';
          print("✅ Normalized receiver avatar URL: $receiverAvatar");
        } else {
          print("✅ Receiver avatar URL is already valid: $receiverAvatar");
        }
      } else {
        print("⚠️ Receiver avatar is null or empty");
      }

      // ✅ Find gift model if giftId is available
      if (giftId != null || (giftName != null && giftName.isNotEmpty)) {
        final giftProvider = Provider.of<GiftProvider>(context, listen: false);
        GiftModel gift;
        GiftModel? giftFromProvider;

        try {
          if (giftId != null) {
            giftFromProvider = giftProvider.allGifts.firstWhere(
              (g) => g.id == giftId,
            );
          } else if (giftName != null && giftName.isNotEmpty) {
            giftFromProvider = giftProvider.allGifts.firstWhere(
              (g) => g.name.toLowerCase() == giftName.toLowerCase(),
            );
          }
        } catch (_) {
          giftFromProvider = null;
        }

        if (giftFromProvider == null && giftProvider.allGifts.isEmpty) {
          await giftProvider.fetchAllGifts();
          try {
            if (giftId != null) {
              giftFromProvider = giftProvider.allGifts.firstWhere(
                (g) => g.id == giftId,
              );
            } else if (giftName != null && giftName.isNotEmpty) {
              giftFromProvider = giftProvider.allGifts.firstWhere(
                (g) => g.name.toLowerCase() == giftName.toLowerCase(),
              );
            }
          } catch (_) {
            giftFromProvider = null;
          }
        }

        final animFileFromPayload =
            payload['gift_animation'] as String? ??
            payload['gift_svg'] as String? ??
            payload['animation_file'] as String? ??
            payload['gift_file'] as String? ??
            nestedString(payload, ['gift', 'gift_svg']) ??
            nestedString(payload, ['gift', 'gift_animation']);
        String? normalizedAnimFile = animFileFromPayload;
        if (normalizedAnimFile != null && normalizedAnimFile.isNotEmpty) {
          if (!normalizedAnimFile.startsWith('http://') &&
              !normalizedAnimFile.startsWith('https://')) {
            normalizedAnimFile =
                'https://shaheenstar.online/$normalizedAnimFile';
          }
        }

        final giftImageRaw =
            payload['gift_image'] as String? ??
            payload['gift_img'] as String? ??
            payload['gift_icon'] as String? ??
            payload['gift_file'] as String? ??
            nestedString(payload, ['gift', 'gift_image']) ??
            nestedString(payload, ['gift', 'image']);
        final normalizedGiftImage = normalizeMediaUrl(giftImageRaw);

        if (giftFromProvider != null) {
          gift = GiftModel(
            id: giftFromProvider.id,
            name: giftFromProvider.name,
            price: giftFromProvider.price,
            category: giftFromProvider.category,
            coinType: giftFromProvider.coinType,
            description: giftFromProvider.description,
            image:
                (giftFromProvider.image != null &&
                    giftFromProvider.image!.isNotEmpty)
                ? giftFromProvider.image
                : (normalizedGiftImage ?? ''),
            animationFile:
                (giftFromProvider.animationFile != null &&
                    giftFromProvider.animationFile!.isNotEmpty)
                ? giftFromProvider.animationFile
                : normalizedAnimFile,
            isActive: giftFromProvider.isActive,
            createdAt: giftFromProvider.createdAt,
            updatedAt: giftFromProvider.updatedAt,
          );
        } else {
          // Gift not found in provider - create from data
          gift = GiftModel(
            id: giftId,
            name: giftName ?? 'Gift',
            price:
                double.tryParse(payload['gift_value']?.toString() ?? '0') ??
                0.0,
            image: normalizedGiftImage ?? '',
            category: 'normal',
            coinType: 'normal',
            isActive: true,
            animationFile: normalizedAnimFile,
          );
        }

        // ✅ Ensure broadcast uses resolved names/images on this client
        final effectivePrice = gift.price > 0 ? gift.price : payloadGiftValue;
        final baseTotal = (effectivePrice * quantity).toDouble();
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
        final totalValue = rewardAmount > 0
            ? rewardAmount
            : (multiplier > 0 && baseTotal > 0)
            ? baseTotal * multiplier
            : baseTotal;
        final isLucky =
            gift.category.toLowerCase().contains('lucky') ||
            (safeString(
                  payload['gift_category'],
                )?.toLowerCase().contains('lucky') ??
                false) ||
            (safeString(payload['category'])?.toLowerCase().contains('lucky') ??
                false) ||
            (giftName?.toLowerCase().contains('lucky') ?? false);
        if (isLucky) {
          print("🚀 [RoomScreen] Preparing Broadcast...");
          print("   SenderName arg: '$senderName'");
          print("   ReceiverName arg: '$receiverName'");

          final finalSender = senderName.isEmpty ? 'User' : senderName;
          final finalReceiver = receiverName.isEmpty ? 'User' : receiverName;

          print("   Final Sender: '$finalSender'");
          print("   Final Receiver: '$finalReceiver'");

          final broadcastProvider = Provider.of<BroadcastProvider>(
            context,
            listen: false,
          );
          final broadcastGiftImage =
              safeString(gift.image) ??
              normalizeMediaUrl(
                payload['gift_image'] ??
                    payload['gift_img'] ??
                    payload['gift_icon'] ??
                    payload['gift_file'],
              ) ??
              '';
          print("   Gift Image: '$broadcastGiftImage'");

          final senderKey = senderId ?? '';
          if (senderKey.isNotEmpty) {
            _luckyGiftSnapshots[senderKey] = _LuckyGiftSnapshot(
              senderName: finalSender,
              senderAvatar: senderAvatar ?? '',
              giftName: gift.name,
              baseTotal: baseTotal,
            );
          }

          if (rewardAmount <= 0 && multiplier <= 0) {
            print(
              "⏳ [RoomScreen] Lucky gift sent; waiting for result to show multiplied coins",
            );
            // ✅ FORCE TRIGGER: If this is a SUCCESS event, it might contain the result even if multiplier parsing failed earlier
            // Try to force update anyway if we have sender info
            // broadcastProvider.showBroadcastOverlay(...) is called below regardless
          } else {
            // Logic for normal result handling
            final displayMultiplier = multiplier > 0
                ? multiplier.round()
                : (baseTotal > 0 && rewardAmount > 0)
                ? (rewardAmount / baseTotal).round()
                : 0;
            if (displayMultiplier > 0) {
              _showLuckyResultDialog(
                multiplier: displayMultiplier,
                reward: totalValue,
                giftPrice: baseTotal,
                senderName: finalSender,
                senderUserId: senderId,
                senderProfileUrl: senderAvatar,
              );
            }
          }

          // Trigger Local Room Banner (Top Patti)
          print(
            '[DEBUG] Calling showBroadcastOverlay for gift value: $totalValue, image: ' +
                ((totalValue >= 100000)
                    ? 'assets/images/broadcasting_image.png'
                    : broadcastGiftImage),
          );
          broadcastProvider.showBroadcastOverlay(
            senderName: finalSender,
            senderProfileUrl: senderAvatar ?? '',
            receiverName: finalReceiver,
            giftName: gift.name,
            giftImage: (totalValue >= 100000)
                ? 'assets/images/broadcasting_image.png'
                : broadcastGiftImage,
            giftCount: quantity,
            giftAmount: totalValue,
            source: 'RoomScreen',
          );

          // Update winner's balance after lucky gift reward
          if (rewardAmount > 0 && receiverId != null && receiverId.isNotEmpty) {
            // Call balance update API for winner
            final balanceResponse = await ApiManager.getUserCoinsBalance(
              userId: receiverId,
            );
            if (balanceResponse != null && balanceResponse.isSuccess) {
              // Optionally update UI or provider with new balance
              print(
                '✅ Lucky Gift Winner Balance Updated: ${balanceResponse.balance}',
              );
              // You can update provider or state here if needed
            } else {
              print('⚠️ Failed to update winner balance after lucky gift');
            }
          }
        } else if (!isLucky && totalValue >= 100000) {
          // ✅ Show broadcast banner for non-Lucky gifts >= 100k coins
          final broadcastProvider = Provider.of<BroadcastProvider>(
            context,
            listen: false,
          );
          broadcastProvider.showBroadcastOverlay(
            senderName: senderName.isEmpty ? 'User' : senderName,
            senderProfileUrl: senderAvatar ?? '',
            receiverName: receiverName.isEmpty ? 'User' : receiverName,
            giftName: gift.name,
            giftImage: 'assets/images/broadcasting_image.png',
            giftCount: quantity,
            giftAmount: totalValue,
            source: 'RoomScreen',
          );
        }

        // ✅ Check if gift has SVGA animation file
        if (gift.hasAnimation &&
            gift.animationFile != null &&
            gift.animationFile!.isNotEmpty) {
          print('[DEBUG] Gift has animation file: ${gift.animationFile}');
          final animUrl = gift.animationFile!.toLowerCase();
          final isSvga =
              animUrl.endsWith('.svga') ||
              animUrl.endsWith('.mp4') ||
              animUrl.contains('.svga?') ||
              animUrl.contains('.svga&') ||
              (animUrl.contains('svga') &&
                  !animUrl.contains('.svg') &&
                  !animUrl.endsWith('.svg'));

          if (isSvga) {
            // ✅ Always show full-screen SVGA animation overlay AFTER gift is sent
            print(
              '[DEBUG] Showing GiftAnimationOverlay for animation: ${gift.animationFile}',
            );
            // Force show animation overlay for high-value gifts
            if (gift.hasAnimation &&
                gift.animationFile != null &&
                gift.animationFile!.isNotEmpty) {
              print(
                '[DEBUG] Forcing GiftAnimationOverlay for high-value gift: ${gift.animationFile}',
              );
              if (mounted) {
                setState(() {
                  _currentGiftAnimation = gift;
                  _currentGiftQuantity = quantity;
                  _currentGiftSenderName = senderName;
                  _currentGiftSenderAvatar = senderAvatar;
                  _currentGiftReceiverName = receiverName;
                  _currentGiftReceiverAvatar = receiverAvatar;
                  _currentGiftIsMultipleReceivers =
                      data['is_multiple_receivers'] == true ||
                      data['receiver_ids'] != null;
                });
              }
            }
            print(
              "🎬 Showing SVGA animation overlay for ${gift.name} (quantity: $quantity)",
            );
            print("   - Animation URL: ${gift.animationFile}");
            if (mounted) {
              setState(() {
                _currentGiftAnimation = gift;
                _currentGiftQuantity = quantity;
                _currentGiftSenderName = senderName;
                _currentGiftSenderAvatar = senderAvatar;
                _currentGiftReceiverName = receiverName;
                _currentGiftReceiverAvatar = receiverAvatar;
                // Check if multiple receivers (for now, assume single unless data indicates otherwise)
                _currentGiftIsMultipleReceivers =
                    data['is_multiple_receivers'] == true ||
                    data['receiver_ids'] != null;
              });
            }
          } else {
            print("⚠️ Gift has animation but not SVGA format: $animUrl");
          }
        } else {
          print("⚠️ Gift ${gift.name} does not have animation file");
        }

        // ✅ Always show normal gift display (skip Lucky gifts)
        final isLuckyForDisplay = gift.category.toLowerCase().contains('lucky');
        if (!isLuckyForDisplay) {
          giftDisplayProvider.addGift(
            gift: gift,
            senderName: senderName,
            senderAvatar: senderAvatar,
            receiverName: receiverName,
            receiverAvatar: receiverAvatar,
            quantity: quantity,
          );
          print(
            "✅ Gift added to display: ${gift.name} (x$quantity) from $senderName to $receiverName",
          );
        }
      }
    };

    // ✅ Room message received (broadcast from other users)
    seatProvider.onMessageReceived = (data) {
      // ✅ Handle message asynchronously to fetch missing user data
      _handleReceivedMessageAsync(data, seatProvider, messageProvider);
    };

    // ✅ Chat history received (when user joins room)
    seatProvider.onChatHistoryReceived = (messages) {
      if (_ignoreChatHistory) {
        _messageProvider?.clearMessages();
        _skipInitialChatHistory = false;
        print("🧹 Ignored chat history payloads");
        return;
      }
      print("📜 [RoomScreen] ===== CHAT HISTORY RECEIVED =====");
      print(
        "📜 [RoomScreen] Received ${messages.length} messages from chat history",
      );

      // ✅ Filter messages: Only show messages sent AFTER user joined the room
      // This ensures new joiners don't see previous chat history
      // Users already in the room will continue to see their chat history
      int filteredCount = 0;
      int addedCount = 0;

      // ✅ Process each message and add to RoomMessageProvider
      for (var msgData in messages) {
        try {
          // ✅ Extract message data
          final userId =
              msgData['user_id']?.toString() ??
              msgData['sender_id']?.toString() ??
              '';
          final roomId =
              msgData['room_id']?.toString() ?? widget.roomId.toString();
          final message =
              msgData['message']?.toString() ??
              msgData['message_text']?.toString() ??
              '';
          final userName =
              msgData['username']?.toString() ??
              msgData['user_name']?.toString() ??
              msgData['sender_name']?.toString() ??
              'User';
          final profileUrl =
              msgData['profile_url']?.toString() ??
              msgData['avatar']?.toString() ??
              msgData['sender_avatar']?.toString();
          final timestamp =
              msgData['timestamp']?.toString() ??
              msgData['created_at']?.toString() ??
              msgData['sent_at']?.toString();

          // ✅ Only add if message is not empty and belongs to current room
          if (message.isNotEmpty && roomId == widget.roomId.toString()) {
            // ✅ FILTER BY TIMESTAMP: Only show messages sent AFTER user joined
            bool shouldShowMessage = true;

            if (_userJoinedAt != null &&
                timestamp != null &&
                timestamp.isNotEmpty) {
              try {
                // Parse message timestamp
                DateTime? messageTime;

                // Try parsing different timestamp formats
                if (timestamp.contains('T')) {
                  // ISO 8601 format: "2025-12-04T14:44:33" or "2025-12-04T14:44:33.000Z"
                  messageTime = DateTime.tryParse(timestamp);
                } else if (timestamp.contains('-') && timestamp.contains(':')) {
                  // MySQL datetime format: "2025-12-04 14:44:33"
                  final parts = timestamp.split(' ');
                  if (parts.length == 2) {
                    final dateParts = parts[0].split('-');
                    final timeParts = parts[1].split(':');
                    if (dateParts.length == 3 && timeParts.length >= 2) {
                      messageTime = DateTime(
                        int.parse(dateParts[0]),
                        int.parse(dateParts[1]),
                        int.parse(dateParts[2]),
                        int.parse(timeParts[0]),
                        int.parse(timeParts[1]),
                        timeParts.length > 2
                            ? int.parse(timeParts[2].split('.')[0])
                            : 0,
                      );
                    }
                  }
                }

                if (messageTime != null) {
                  // Only show message if it was sent AFTER user joined
                  shouldShowMessage = messageTime.isAfter(_userJoinedAt!);

                  if (!shouldShowMessage) {
                    filteredCount++;
                    print(
                      "⏰ [RoomScreen] Filtered out old message: $userName: $message (sent: $timestamp, joined: $_userJoinedAt)",
                    );
                  }
                } else {
                  print(
                    "⚠️ [RoomScreen] Could not parse timestamp: $timestamp",
                  );
                  // If we can't parse timestamp, show the message (safer default)
                }
              } catch (e) {
                print(
                  "⚠️ [RoomScreen] Error parsing timestamp '$timestamp': $e",
                );
                // If parsing fails, show the message (safer default)
              }
            }

            // ✅ Only add message if it should be shown (after join timestamp)
            if (shouldShowMessage) {
              // ✅ Normalize profile URL if it's a relative path
              String? normalizedProfileUrl = profileUrl;
              if (normalizedProfileUrl != null &&
                  normalizedProfileUrl.isNotEmpty &&
                  !normalizedProfileUrl.startsWith('http')) {
                normalizedProfileUrl =
                    'https://shaheenstar.online/$normalizedProfileUrl';
              }

              final chatHistoryMessage =
                  SendMessageRoomModel.createFromWebSocket(
                    userId: userId,
                    roomId: roomId,
                    message: message,
                    userName: userName,
                    profileUrl: normalizedProfileUrl,
                    timestamp: timestamp,
                  );

              messageProvider.addReceivedMessage(chatHistoryMessage);
              addedCount++;
              print(
                "✅ [RoomScreen] Added chat history message: $userName: $message",
              );
            }
          }
        } catch (e) {
          print("❌ [RoomScreen] Error processing chat history message: $e");
          print("❌ [RoomScreen] Message data: $msgData");
        }
      }

      print("📜 [RoomScreen] Chat history summary:");
      print("   - Total messages received: ${messages.length}");
      print("   - Messages filtered (before join): $filteredCount");
      print("   - Messages added (after join): $addedCount");
      print("📜 [RoomScreen] =====================================");

      print("📜 [RoomScreen] =====================================");
    };

    // ✅ Listen to Gifts WebSocket (port 8085) for gift:sent events
    // This is needed because gifts are sent via Gifts WebSocket, not SeatProvider WebSocket
    final giftWsService = GiftWebSocketService.instance;
    final currentRoomIdForGifts = widget.roomId.toString();

    giftWsService.on('gift:sent', (data) {
      print("🎁 [RoomScreen] ========== GIFT:SENT EVENT RECEIVED ==========");
      print("🎁 [RoomScreen] Gift sent event received from Gifts WebSocket");
      print("🎁 [RoomScreen] Data: $data");

      // ✅ Log transaction clarity fields (new backend fields)
      final dataMap = data;
      final senderPaidCoinType =
          dataMap['sender_paid_coin_type']?.toString() ??
          (dataMap['data'] as Map<String, dynamic>?)?['sender_paid_coin_type']
              ?.toString();
      final receiverReceivedCoinType =
          dataMap['receiver_received_coin_type']?.toString() ??
          (dataMap['data']
                  as Map<String, dynamic>?)?['receiver_received_coin_type']
              ?.toString();

      if (senderPaidCoinType != null || receiverReceivedCoinType != null) {
        print("💰 [RoomScreen] Transaction Details:");
        print("   - Sender Paid Coin Type: ${senderPaidCoinType ?? 'unknown'}");
        print(
          "   - Receiver Received Coin Type: ${receiverReceivedCoinType ?? 'unknown'}",
        );
      }

      // ✅ Check if gift belongs to this room before processing
      final giftRoomId =
          dataMap['room_id']?.toString() ??
          (dataMap['data'] as Map<String, dynamic>?)?['room_id']?.toString();

      if (giftRoomId != null && giftRoomId != currentRoomIdForGifts) {
        print(
          "⏭️ [RoomScreen] Gift belongs to different room (gift room_id: $giftRoomId, current room_id: $currentRoomIdForGifts) - ignoring",
        );
        return;
      }

      print(
        "✅ [RoomScreen] Gift belongs to current room (room_id: ${giftRoomId ?? currentRoomIdForGifts}) - processing",
      );
      print("🎁 [RoomScreen] ==============================================");

      // ✅ Handle gift animation overlay (async)
      Future.microtask(() => _handleGiftSentEvent(data));
    });

    // ✅ Listen for lucky_gift:result event (and variations)
    // ✅ Generic Handler for Lucky Gift Results to be used by multiple event names
    final luckyGiftHandler = (dynamic data) {
      // ... INLINE logic to fix scoping/brace issues
      double safeDouble(dynamic value) {
        return double.tryParse(value?.toString() ?? '') ?? 0.0;
      }

      print("🍀 [RoomScreen] ========== LUCKY GIFT RESULT RECEIVED ==========");
      print("🍀 [RoomScreen] Data: $data");

      // Normalize payload
      final resultPayload = (data is Map && data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'] as Map)
          : (data is Map
                ? Map<String, dynamic>.from(data as Map)
                : <String, dynamic>{});

      // RELAXED ROOM CHECK
      final giftRoomId =
          resultPayload['room_id']?.toString() ?? data['room_id']?.toString();
      if (giftRoomId != null && giftRoomId != currentRoomIdForGifts) {
        print(
          "⚠️ [RoomScreen] Room ID mismatch ($giftRoomId vs $currentRoomIdForGifts) but attempting to show Lucky Banner",
        );
      }

      // Extract result details
      final reward = resultPayload['reward_type']?.toString() ?? 'reward';
      final amountDouble = safeDouble(
        resultPayload['win_coins'] ??
            resultPayload['amount'] ??
            resultPayload['reward_amount'] ??
            resultPayload['win_amount'],
      );
      final resultMultiplier = safeDouble(
        resultPayload['multiplier'] ??
            resultPayload['reward_multiplier'] ??
            resultPayload['lucky_multiplier'] ??
            resultPayload['x'],
      );
      final message =
          resultPayload['message']?.toString() ??
          data['message']?.toString() ??
          'Lucky spin completed!';
      final senderId = resultPayload['sender_id']?.toString();
      final resultGiftPrice = safeDouble(
        resultPayload['gift_price'] ?? resultPayload['gift_value'],
      );

      // Update UI
      if (mounted) {
        final broadcastProvider = Provider.of<BroadcastProvider>(
          context,
          listen: false,
        );
        final senderKey = senderId ?? '';
        final snapshot = _luckyGiftSnapshots[senderKey];
        String senderName = snapshot?.senderName ?? 'User';
        String senderAvatar = snapshot?.senderAvatar ?? '';
        String giftName = snapshot?.giftName ?? 'Lucky';
        final baseTotal = (resultGiftPrice > 0)
            ? resultGiftPrice
            : (snapshot?.baseTotal ?? 0.0);

        // CALCULATE WIN
        final calculatedWin = (baseTotal > 0 && resultMultiplier > 0)
            ? baseTotal * resultMultiplier
            : 0.0;
        final finalCoins = (calculatedWin > amountDouble)
            ? calculatedWin
            : (amountDouble > 0 ? amountDouble : baseTotal);

        // Sender info fallback
        if (senderAvatar.isEmpty && senderKey.isNotEmpty) {
          try {
            final seatProvider = Provider.of<SeatProvider>(
              context,
              listen: false,
            );
            final senderSeat = seatProvider.seats.firstWhere(
              (s) =>
                  s.isOccupied &&
                  (s.userId?.toString() == senderKey || s.userId == senderKey),
            );
            senderName =
                senderSeat.userName ?? senderSeat.username ?? senderName;
            senderAvatar = senderSeat.profileUrl ?? senderAvatar;
            if (senderAvatar.isNotEmpty && !senderAvatar.startsWith('http')) {
              senderAvatar = 'https://shaheenstar.online/$senderAvatar';
            }
          } catch (_) {}
        }

        // Display Logic
        double displayMultiplier = 0.0;
        if (resultMultiplier > 0)
          displayMultiplier = resultMultiplier;
        else if (baseTotal > 0 && amountDouble > 0)
          displayMultiplier = amountDouble / baseTotal;
        if (displayMultiplier == 0 &&
            amountDouble == baseTotal &&
            baseTotal > 0)
          displayMultiplier = 1.0;

        print(
          "🍀 [RoomScreen] Display Multiplier: $displayMultiplier",
        ); // LOGGING

        if (displayMultiplier > 0) {
          _showLuckyResultDialog(
            multiplier: displayMultiplier.round(),
            reward: finalCoins,
            giftPrice: baseTotal,
            senderName: senderName,
            senderUserId: senderId,
            senderProfileUrl: senderAvatar.isNotEmpty ? senderAvatar : null,
          );
        } else {
          print(
            "⚠️ [RoomScreen] Display Multiplier is 0, attempting fallback show...",
          );
          _showLuckyResultDialog(
            multiplier: 1, // Fallback
            reward: finalCoins,
            giftPrice: baseTotal,
            senderName: senderName,
            senderUserId: senderId,
            senderProfileUrl: senderAvatar.isNotEmpty ? senderAvatar : null,
          );
        }

        // Top Banner (Patti)
        broadcastProvider.showBroadcastOverlay(
          senderName: senderName,
          senderProfileUrl: senderAvatar,
          receiverName: '',
          giftName: giftName,
          giftAmount: finalCoins,
          source: 'LuckyResult',
        );

        // Show Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🍀 $message ($reward: ${finalCoins.toStringAsFixed(0)})',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh Seats & Balance
        try {
          Provider.of<SeatProvider>(
            context,
            listen: false,
          ).getSeats(widget.roomId.toString());
        } catch (_) {}
        try {
          Provider.of<GiftProvider>(context, listen: false).fetchUserBalance();
        } catch (_) {}
      }
    };

    // ✅ Bind Generic Handler to all Lucky Gift Event Variations
    giftWsService.on('lucky_gift:result', luckyGiftHandler);
    giftWsService.on('lucky_gift_result', luckyGiftHandler);
    giftWsService.on('lucky_gift:spin_result', luckyGiftHandler);

    // ✅ Also listen for 'success' event as fallback
    giftWsService.on('success', (data) {
      print("✅ [RoomScreen] Success event received from Gifts WebSocket");
      print("   Data: $data");
      // Check if this is a gift success event
      if (data.containsKey('gift_id')) {
        // ✅ Check if gift belongs to this room before processing
        final giftRoomId =
            data['room_id']?.toString() ?? data['data']?['room_id']?.toString();

        if (giftRoomId != null && giftRoomId != currentRoomIdForGifts) {
          print(
            "⏭️ [RoomScreen] Gift success event belongs to different room (gift room_id: $giftRoomId, current room_id: $currentRoomIdForGifts) - ignoring",
          );
          return;
        }

        print(
          "✅ [RoomScreen] Gift belongs to current room (room_id: ${giftRoomId ?? currentRoomIdForGifts}) - processing",
        );
        print(
          "✅ [RoomScreen] This is a gift success event - triggering animation",
        );
        Future.microtask(() => _handleGiftSentEvent(data));
      }
    });

    print("✅ WebSocket event listeners set up for chat messages and gifts");
    print("✅ Gifts WebSocket event listener set up for gift:sent events");
  }

  // ✅ Helper method to handle gift sent events (from both WebSocket services)
  void _handleGiftSentEvent(Map<String, dynamic> data) async {
    print("🎁 [RoomScreen] ========== PROCESSING GIFT SENT EVENT ==========");
    print("🎁 [RoomScreen] Processing gift sent event for animation overlay");
    print("🎁 [RoomScreen] Full data: $data");

    // ✅ Check if gift belongs to this room - filter out gifts from other rooms
    final giftRoomId =
        data['room_id']?.toString() ?? data['data']?['room_id']?.toString();
    final currentRoomId = widget.roomId.toString();

    // Relaxed check for Lucky Gifts success events that might be mis-routed
    final isLuckySuccess =
        data['category']?.toString().contains('lucky') == true ||
        data['gift_category']?.toString().contains('lucky') == true;

    if (giftRoomId != null && giftRoomId != currentRoomId) {
      if (isLuckySuccess) {
        print(
          "⚠️ [RoomScreen] Lucky gift success with room mismatch ($giftRoomId vs $currentRoomId) - ALLOWING for update check",
        );
      } else {
        print(
          "⏭️ [RoomScreen] Gift belongs to different room (gift room_id: $giftRoomId, current room_id: $currentRoomId) - ignoring",
        );
        return;
      }
    }

    print(
      "✅ [RoomScreen] Gift belongs to current room (room_id: ${giftRoomId ?? currentRoomId}) - processing",
    );

    final giftId = data['gift_id'] as int?;
    final senderId = data['sender_id']?.toString();
    final receiverId = data['receiver_id']?.toString();
    var senderName =
        data['sender_name'] as String? ??
        data['sender_username'] as String? ??
        'User';
    var receiverName =
        data['receiver_name'] as String? ??
        data['receiver_username'] as String? ??
        'User';
    var senderAvatar = data['sender_avatar'] as String?;
    var receiverAvatar = data['receiver_avatar'] as String?;
    var quantity = data['quantity'] as int? ?? 1;
    final giftName = data['gift_name'] as String?;

    // ✅ Preserve quantity if animation is already playing for the same gift
    // This prevents the server event (which doesn't include quantity) from overriding
    // the correct quantity from the first event
    if (_currentGiftAnimation != null &&
        _currentGiftAnimation!.id == giftId &&
        _currentGiftQuantity > 0) {
      // If we already have a quantity set and the new quantity is 1 (default),
      // preserve the existing quantity
      if (quantity == 1 && _currentGiftQuantity > 1) {
        print(
          "🔄 [RoomScreen] Preserving existing quantity: $_currentGiftQuantity (new event has default quantity: $quantity)",
        );
        quantity = _currentGiftQuantity;
      } else if (quantity > _currentGiftQuantity) {
        // Use the higher quantity if the new one is higher
        print(
          "🔄 [RoomScreen] Using higher quantity: $quantity (was: $_currentGiftQuantity)",
        );
      } else {
        print(
          "🔄 [RoomScreen] Keeping existing quantity: $_currentGiftQuantity (new: $quantity)",
        );
        quantity = _currentGiftQuantity;
      }
    }

    // ✅ Fetch sender and receiver profile data from seat provider if avatars are missing
    if ((senderAvatar == null ||
            senderAvatar.isEmpty ||
            receiverAvatar == null ||
            receiverAvatar.isEmpty) &&
        (senderId != null || receiverId != null)) {
      try {
        final seatProvider = Provider.of<SeatProvider>(context, listen: false);

        // ✅ Get sender profile from seat
        if ((senderAvatar == null || senderAvatar.isEmpty) &&
            senderId != null) {
          try {
            final senderSeat = seatProvider.seats.firstWhere(
              (s) =>
                  s.isOccupied && s.userId?.toString() == senderId.toString(),
            );
            if (senderSeat.profileUrl != null &&
                senderSeat.profileUrl!.isNotEmpty) {
              senderAvatar = senderSeat.profileUrl;
              if (!senderAvatar!.startsWith('http://') &&
                  !senderAvatar.startsWith('https://')) {
                senderAvatar = 'https://shaheenstar.online/$senderAvatar';
              }
              print(
                "✅ [RoomScreen] Got sender avatar from seat: $senderAvatar",
              );
            }
            if ((senderName.isEmpty || senderName == 'User') &&
                (senderSeat.userName != null || senderSeat.username != null)) {
              senderName = senderSeat.userName ?? senderSeat.username ?? 'User';
              print("✅ [RoomScreen] Got sender name from seat: $senderName");
            }
          } catch (e) {
            print("⚠️ [RoomScreen] Sender not found on seats: $e");
          }
        }

        // ✅ Get receiver profile from seat
        if ((receiverAvatar == null || receiverAvatar.isEmpty) &&
            receiverId != null) {
          try {
            final receiverSeat = seatProvider.seats.firstWhere(
              (s) =>
                  s.isOccupied && s.userId?.toString() == receiverId.toString(),
            );
            if (receiverSeat.profileUrl != null &&
                receiverSeat.profileUrl!.isNotEmpty) {
              receiverAvatar = receiverSeat.profileUrl;
              if (!receiverAvatar!.startsWith('http://') &&
                  !receiverAvatar.startsWith('https://')) {
                receiverAvatar = 'https://shaheenstar.online/$receiverAvatar';
              }
              print(
                "✅ [RoomScreen] Got receiver avatar from seat: $receiverAvatar",
              );
            }
            if ((receiverName.isEmpty || receiverName == 'User') &&
                (receiverSeat.userName != null ||
                    receiverSeat.username != null)) {
              receiverName =
                  receiverSeat.userName ?? receiverSeat.username ?? 'User';
              print(
                "✅ [RoomScreen] Got receiver name from seat: $receiverName",
              );
            }
          } catch (e) {
            print("⚠️ [RoomScreen] Receiver not found on seats: $e");
          }
        }
      } catch (e) {
        print("⚠️ [RoomScreen] Error getting profile data from seats: $e");
      }
    }

    // ✅ Normalize and validate avatar URLs - add base URL if they're relative paths
    if (senderAvatar != null && senderAvatar.isNotEmpty) {
      final trimmed = senderAvatar.trim().toLowerCase();
      // ✅ Filter out invalid values
      final invalidValues = [
        'upload',
        'profile url',
        'profile_url',
        'jgh',
        'null',
        'yyyy',
        'profile',
        'avatar',
        'image',
      ];
      if (invalidValues.contains(trimmed) || trimmed.length < 5) {
        print(
          "⚠️ [RoomScreen] Invalid sender avatar value: '$senderAvatar' - setting to null",
        );
        senderAvatar = null;
      } else if (!senderAvatar.startsWith('http://') &&
          !senderAvatar.startsWith('https://')) {
        senderAvatar = 'https://shaheenstar.online/$senderAvatar';
        print("✅ [RoomScreen] Normalized sender avatar URL: $senderAvatar");
      } else {
        print(
          "✅ [RoomScreen] Sender avatar URL is already valid: $senderAvatar",
        );
      }
    } else {
      print("⚠️ [RoomScreen] Sender avatar is null or empty");
    }

    // ✅ FORCE CHECK FOR LUCKY RESULT IN GENERIC EVENT (Fix for missing Bottom Banner)
    // Sometimes the specific 'lucky_gift:result' event is missed, but 'gift:sent' or 'success' has the data.
    // If multiplier is missing but it IS a lucky gift, fallback to base price so SOMETHING shows.
    final possibleMultiplier =
        double.tryParse(
          data['multiplier']?.toString() ??
              data['data']?['multiplier']?.toString() ??
              '0',
        ) ??
        0.0;

    final isLikelyLucky =
        (giftName?.toLowerCase().contains('lucky') ?? false) ||
        (data['gift_name']?.toString().toLowerCase().contains('lucky') ??
            false);

    if (possibleMultiplier > 0 || isLikelyLucky) {
      print(
        "🍀 [RoomScreen] _handleGiftSentEvent: Lucky Check - Multiplier: $possibleMultiplier, IsLuckyName: $isLikelyLucky",
      );

      final possibleWinCoins =
          double.tryParse(
            data['win_coins']?.toString() ??
                data['data']?['win_coins']?.toString() ??
                '0',
          ) ??
          0.0;
      final possiblePrice =
          double.tryParse(
            data['gift_price']?.toString() ?? data['price']?.toString() ?? '0',
          ) ??
          0.0;

      // Determine final values with fallback
      double finalMultiplier = possibleMultiplier;
      double finalWinAmount = 0.0;

      if (finalMultiplier <= 0) {
        // No multiplier from server? Default to 1x and Show Base Price
        // This ensures the banner appears even if the specific result data is missing from this event
        finalMultiplier = 1.0;
        finalWinAmount = possibleWinCoins > 0
            ? possibleWinCoins
            : possiblePrice;
        print(
          "⚠️ [RoomScreen] Lucky Gift with NO multiplier data. Defaulting to 1x (Amount: $finalWinAmount)",
        );
      } else {
        finalWinAmount = possibleWinCoins > 0
            ? possibleWinCoins
            : (possiblePrice * finalMultiplier);
      }

      Future.microtask(() {
        if (mounted) {
          _showLuckyResultDialog(
            multiplier: finalMultiplier.round(),
            reward: finalWinAmount,
            giftPrice: possiblePrice,
            senderName: senderName,
            senderUserId: senderId,
            senderProfileUrl: senderAvatar,
          );

          // ✅ TRIGGER TOP BANNER (PATTI) with correct multiplied amount
          Provider.of<BroadcastProvider>(
            context,
            listen: false,
          ).showBroadcastOverlay(
            senderName: senderName,
            senderProfileUrl: senderAvatar ?? '',
            receiverName: receiverName,
            giftName: giftName ?? 'Lucky Gift',
            giftImage: '',
            giftCount: quantity,
            giftAmount: finalWinAmount, // MULTIPLIED (or fallback) AMOUNT
            source: 'RoomScreen_LuckyFallback',
          );
        }
      });
    }

    if (receiverAvatar != null && receiverAvatar.isNotEmpty) {
      final trimmed = receiverAvatar.trim().toLowerCase();
      // ✅ Filter out invalid values
      final invalidValues = [
        'upload',
        'profile url',
        'profile_url',
        'jgh',
        'null',
        'yyyy',
        'profile',
        'avatar',
        'image',
      ];
      if (invalidValues.contains(trimmed) || trimmed.length < 5) {
        print(
          "⚠️ [RoomScreen] Invalid receiver avatar value: '$receiverAvatar' - setting to null",
        );
        receiverAvatar = null;
      } else if (!receiverAvatar.startsWith('http://') &&
          !receiverAvatar.startsWith('https://')) {
        receiverAvatar = 'https://shaheenstar.online/$receiverAvatar';
        print("✅ [RoomScreen] Normalized receiver avatar URL: $receiverAvatar");
      } else {
        print(
          "✅ [RoomScreen] Receiver avatar URL is already valid: $receiverAvatar",
        );
      }
    } else {
      print("⚠️ [RoomScreen] Receiver avatar is null or empty");
    }

    print("🎁 [RoomScreen] Extracted data:");
    print("   - Gift ID: $giftId");
    print("   - Sender Name: $senderName");
    print("   - Sender Avatar: $senderAvatar");
    print("   - Receiver Name: $receiverName");
    print("   - Receiver Avatar: $receiverAvatar");
    print("   - Quantity: $quantity");
    print("   - Gift Name: $giftName");

    // ✅ Find gift model if giftId is available
    if (giftId != null) {
      final giftProvider = Provider.of<GiftProvider>(context, listen: false);
      GiftModel gift;

      try {
        gift = giftProvider.allGifts.firstWhere((g) => g.id == giftId);
        print("✅ [RoomScreen] Found gift in provider: ${gift.name}");
      } catch (e) {
        // Gift not found in provider - create from data
        print(
          "⚠️ [RoomScreen] Gift not found in provider, creating from event data",
        );
        final animFile =
            data['gift_animation'] as String? ??
            data['gift_svg'] as String? ??
            data['animation_file'] as String?;

        // ✅ Normalize animation file URL if it's a relative path
        String? normalizedAnimFile = animFile;
        if (normalizedAnimFile != null && normalizedAnimFile.isNotEmpty) {
          if (!normalizedAnimFile.startsWith('http://') &&
              !normalizedAnimFile.startsWith('https://')) {
            normalizedAnimFile =
                'https://shaheenstar.online/$normalizedAnimFile';
          }
        }

        gift = GiftModel(
          id: giftId,
          name: giftName ?? 'Gift',
          price: data['gift_value'] as double? ?? 0.0,
          image: data['gift_image'] as String? ?? '',
          category: 'normal',
          coinType: 'normal',
          isActive: true,
          animationFile: normalizedAnimFile,
        );
      }

      // ✅ Show broadcast banner for non-Lucky gifts >= 100k coins
      final totalValueForBanner = (gift.price * quantity).toDouble();
      final isLuckyForBanner = gift.category.toLowerCase().contains('lucky');
      if (!isLuckyForBanner && totalValueForBanner >= 100000) {
        final broadcastProvider = Provider.of<BroadcastProvider>(
          context,
          listen: false,
        );
        broadcastProvider.showBroadcastOverlay(
          senderName: senderName,
          senderProfileUrl: senderAvatar ?? '',
          receiverName: receiverName,
          giftName: gift.name,
          giftImage: 'assets/images/broadcasting_image.png',
          giftCount: quantity,
          giftAmount: totalValueForBanner,
          source: 'RoomScreen_HighValue',
        );
      }

      // ✅ Check if gift has SVGA animation file
      if (gift.hasAnimation &&
          gift.animationFile != null &&
          gift.animationFile!.isNotEmpty) {
        final animUrl = gift.animationFile!.toLowerCase();
        final isSvga =
            animUrl.endsWith('.svga') ||
            animUrl.endsWith('.mp4') ||
            animUrl.contains('.svga?') ||
            animUrl.contains('.svga&') ||
            (animUrl.contains('svga') &&
                !animUrl.contains('.svg') &&
                !animUrl.endsWith('.svg'));

        if (isSvga) {
          // ✅ Check if animation is already playing for the same gift
          // If so, skip processing this duplicate event to avoid resetting the animation
          if (_currentGiftAnimation != null &&
              _currentGiftAnimation!.id == giftId &&
              _currentGiftQuantity > 0) {
            print(
              "⏭️ [RoomScreen] Animation already playing for gift ${gift.name} with quantity $_currentGiftQuantity - skipping duplicate event (new quantity: $quantity)",
            );
            print(
              "⏭️ [RoomScreen] This prevents the animation from being reset mid-play",
            );
            // Still add to gift display overlay, but don't reset the animation (unless 1L+ non-Lucky → broadcast only)
            final totalValue = (gift.price * quantity).toDouble();
            final isLucky = gift.category.toLowerCase().contains('lucky');
            if (!isLucky && !(totalValue > 100000 && !isLucky)) {
              final giftDisplayProvider = Provider.of<GiftDisplayProvider>(
                context,
                listen: false,
              );
              giftDisplayProvider.addGift(
                gift: gift,
                senderName: senderName,
                senderAvatar: senderAvatar,
                receiverName: receiverName,
                receiverAvatar: receiverAvatar,
                quantity: quantity,
              );
            }
            return; // Skip processing this duplicate event
          }

          // ✅ Show full-screen SVGA animation overlay AFTER gift is sent (including 100k+ non-Lucky gifts)
          print(
            "🎬 [RoomScreen] ========== SHOWING SVGA ANIMATION OVERLAY ==========",
          );
          print(
            "🎬 [RoomScreen] Showing SVGA animation overlay for ${gift.name} (quantity: $quantity)",
          );
          print("🎬 [RoomScreen] Animation URL: ${gift.animationFile}");
          print("🎬 [RoomScreen] Sender: $senderName (Avatar: $senderAvatar)");
          print(
            "🎬 [RoomScreen] Receiver: $receiverName (Avatar: $receiverAvatar)",
          );
          if (mounted) {
            setState(() {
              _currentGiftAnimation = gift;
              _currentGiftQuantity = quantity;
              _currentGiftSenderName = senderName;
              _currentGiftSenderAvatar = senderAvatar;
              _currentGiftReceiverName = receiverName;
              _currentGiftReceiverAvatar = receiverAvatar;
              // Check if multiple receivers
              _currentGiftIsMultipleReceivers =
                  data['is_multiple_receivers'] == true ||
                  data['receiver_ids'] != null;
            });
            print(
              "✅ [RoomScreen] Animation overlay state updated successfully",
            );
            print(
              "✅ [RoomScreen] _currentGiftAnimation: ${_currentGiftAnimation?.name}",
            );
            print("✅ [RoomScreen] _currentGiftQuantity: $_currentGiftQuantity");
            print(
              "✅ [RoomScreen] ====================================================",
            );
          } else {
            print("⚠️ [RoomScreen] Widget not mounted, cannot show animation");
          }
        } else {
          print(
            "⚠️ [RoomScreen] Gift has animation but not SVGA format: $animUrl",
          );
        }
      } else {
        print("⚠️ [RoomScreen] Gift ${gift.name} does not have animation file");
        print("   - hasAnimation: ${gift.hasAnimation}");
        print("   - animationFile: ${gift.animationFile}");
      }

      // ✅ Add to gift display overlay (small notification) – skip Lucky and 1 lakh+ non-Lucky
      final totalValue = (gift.price * quantity).toDouble();
      final isLucky = gift.category.toLowerCase().contains('lucky');
      if (!isLucky && !(totalValue > 100000 && !isLucky)) {
        final giftDisplayProvider = Provider.of<GiftDisplayProvider>(
          context,
          listen: false,
        );
        giftDisplayProvider.addGift(
          gift: gift,
          senderName: senderName,
          senderAvatar: senderAvatar,
          receiverName: receiverName,
          receiverAvatar: receiverAvatar,
          quantity: quantity,
        );
        print(
          "✅ [RoomScreen] Gift added to display: ${gift.name} (x$quantity) from $senderName to $receiverName",
        );
      } else {
        print(
          "✅ [RoomScreen] Gift ${gift.name} (${totalValue.toStringAsFixed(0)} coins) – broadcast only, skipping normal gift display",
        );
      }

      // ✅ Lucky gift UI now relies on lucky_gift:result for real multiplier values

      // ✅ Update receiver's diamond coins if receiver is current user
      _updateReceiverDiamondCoinsFromGift(data, receiverId);
    } else {
      print("⚠️ [RoomScreen] Gift sent event received but gift_id is null");
    }
  }

  /// Update receiver's diamond coins balance if receiver is current user
  /// Works for both: self-gifts (sender = receiver) and gifts from others (receiver = current user)
  Future<void> _updateReceiverDiamondCoinsFromGift(
    Map<String, dynamic> data,
    String? receiverIdStr,
  ) async {
    try {
      print(
        "💎 [RoomScreen] ===== CHECKING RECEIVER DIAMOND COINS UPDATE =====",
      );

      if (receiverIdStr == null || receiverIdStr.isEmpty) {
        print("⚠️ [RoomScreen] Receiver ID is null or empty");
        return;
      }

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      dynamic userIdValue = prefs.get('user_id');
      int? currentUserId;

      if (userIdValue is int) {
        currentUserId = userIdValue;
      } else if (userIdValue is String) {
        currentUserId = int.tryParse(userIdValue);
      }

      if (currentUserId == null) {
        print("⚠️ [RoomScreen] Cannot determine current user ID");
        return;
      }

      print("💎 [RoomScreen] Current user ID: $currentUserId");
      print("💎 [RoomScreen] Receiver ID from event: $receiverIdStr");

      // ✅ Check if receiver is current user (works for both self-gifts and gifts from others)
      final receiverId = int.tryParse(receiverIdStr);
      if (receiverId == null || receiverId != currentUserId) {
        print(
          "ℹ️ [RoomScreen] Receiver (ID: $receiverId) is not current user (ID: $currentUserId) - skipping diamond coins update",
        );
        return;
      }

      print(
        "✅ [RoomScreen] Receiver is current user - proceeding with diamond coins update",
      );

      // Extract receiver_received_coin_type for logging
      String? receiverReceivedCoinType;
      if (data.containsKey('receiver_received_coin_type')) {
        receiverReceivedCoinType = data['receiver_received_coin_type']
            ?.toString()
            .toLowerCase();
      } else if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        receiverReceivedCoinType = dataMap['receiver_received_coin_type']
            ?.toString()
            .toLowerCase();
      }

      print(
        "💎 [RoomScreen] Receiver Received Coin Type: ${receiverReceivedCoinType ?? 'unknown'} (should be 'diamond')",
      );

      // Extract receiver_balance from response
      Map<String, dynamic>? receiverBalance;

      if (data.containsKey('receiver_balance') &&
          data['receiver_balance'] is Map) {
        receiverBalance = Map<String, dynamic>.from(
          data['receiver_balance'] as Map,
        );
      } else if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        if (dataMap.containsKey('receiver_balance') &&
            dataMap['receiver_balance'] is Map) {
          receiverBalance = Map<String, dynamic>.from(
            dataMap['receiver_balance'] as Map,
          );
        }
      }

      if (receiverBalance == null) {
        print(
          "⚠️ [RoomScreen] No receiver_balance found in gift event - trying alternative extraction",
        );
        // Try alternative extraction methods
        if (data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'] as Map<String, dynamic>;
          // Check if receiver_balance is nested deeper
          if (dataMap.containsKey('receiver_balance') &&
              dataMap['receiver_balance'] is Map) {
            receiverBalance = Map<String, dynamic>.from(
              dataMap['receiver_balance'] as Map,
            );
          }
        }

        if (receiverBalance == null) {
          print("ℹ️ [RoomScreen] No receiver_balance found in gift event");
          return;
        }
      }

      // Extract diamond coins from receiver_balance
      final diamondCoinsStr = receiverBalance['diamond_coins']?.toString();
      if (diamondCoinsStr != null && diamondCoinsStr.isNotEmpty) {
        final diamondCoins = double.tryParse(diamondCoinsStr);
        if (diamondCoins != null) {
          // Cache receiver's diamond coins balance
          final userId = currentUserId.toString();
          await prefs.setDouble('diamond_coins_$userId', diamondCoins);
          print("💎 [RoomScreen] ===== RECEIVER DIAMOND COINS UPDATED =====");
          print(
            "💎 [RoomScreen] Receiver ID: $receiverId (Current User: $currentUserId)",
          );
          print("💎 [RoomScreen] Diamond Coins: $diamondCoins");
          print(
            "💎 [RoomScreen] Cached to SharedPreferences: diamond_coins_$userId",
          );
          print("💎 [RoomScreen] ==========================================");
        }
      } else {
        print("⚠️ [RoomScreen] No diamond_coins found in receiver_balance");
      }
    } catch (e, stackTrace) {
      print("❌ [RoomScreen] Error updating receiver diamond coins: $e");
      print("❌ [RoomScreen] Stack trace: $stackTrace");
    }
  }

  // ✅ Helper method to handle received messages with user data fetching
  Future<void> _handleReceivedMessageAsync(
    Map<String, dynamic> data,
    SeatProvider seatProvider,
    RoomMessageProvider messageProvider,
  ) async {
    // ✅ CRITICAL: Backend sends nested structure: {event: 'message', data: {...}}
    // Extract data from nested structure if present
    Map<String, dynamic> messageData = data;
    if (data['data'] != null && data['data'] is Map) {
      messageData = Map<String, dynamic>.from(data['data'] as Map);
      print("💬 [RoomScreen] Extracted message data from nested 'data' field");
    }

    final receivedUsername =
        messageData['username'] as String? ??
        messageData['user_name'] as String? ??
        data['username'] as String? ??
        data['user_name'] as String?;
    final receivedUserId =
        messageData['user_id']?.toString() ?? data['user_id']?.toString();
    final receivedMessage =
        messageData['message'] as String? ??
        messageData['message_text'] as String? ??
        data['message'] as String? ??
        data['message_text'] as String?;

    // ✅ Check for backend issues with username
    if (receivedUsername != null &&
        RegExp(
          r'^User\s+\d+$',
          caseSensitive: false,
        ).hasMatch(receivedUsername.trim())) {
      print(
        "❌ [RoomScreen] Backend sent generic username: '$receivedUsername' (should be real username)",
      );
    }

    final currentUserId = _databaseUserId;
    final normalizedReceivedUserId = UserIdUtils.getNumericValue(
      receivedUserId,
    )?.toString();
    final normalizedCurrentUserId = UserIdUtils.getNumericValue(
      currentUserId,
    )?.toString();
    final isFromCurrentUser =
        normalizedReceivedUserId == normalizedCurrentUserId;

    if (!isFromCurrentUser) {
      print(
        "✅ [RoomScreen] Message from another user: $receivedUsername - '$receivedMessage'",
      );
    }

    // ✅ Extract message data (use messageData first, fallback to data)
    final userId =
        messageData['user_id']?.toString() ??
        messageData['sender_id']?.toString() ??
        data['user_id']?.toString() ??
        data['sender_id']?.toString();
    var userName =
        messageData['username'] as String? ??
        messageData['user_name'] as String? ??
        messageData['sender_name'] as String? ??
        data['username'] as String? ??
        data['user_name'] as String? ??
        data['sender_name'] as String?;
    final message =
        messageData['message'] as String? ??
        messageData['message_text'] as String? ??
        data['message'] as String? ??
        data['message_text'] as String? ??
        '';
    var profileUrl =
        messageData['profile_url'] as String? ??
        messageData['avatar'] as String? ??
        messageData['sender_avatar'] as String? ??
        data['profile_url'] as String? ??
        data['avatar'] as String? ??
        data['sender_avatar'] as String?;
    final timestamp =
        messageData['timestamp'] as String? ??
        messageData['created_at'] as String? ??
        data['timestamp'] as String? ??
        data['created_at'] as String?;

    // ✅ Ensure tags are loaded for this user
    _requestUserTags(userId);
    if (message.isNotEmpty && userId != null) {
      // ✅ CHECK ROOM ID - Only add messages for current room
      final messageRoomId =
          messageData['room_id']?.toString() ?? data['room_id']?.toString();
      final currentRoomId = widget.roomId.toString();

      if (messageRoomId != currentRoomId) {
        print(
          "⚠️ Message from different room ($messageRoomId) - ignoring (current room: $currentRoomId)",
        );
        return;
      }

      // ✅ Add message to chat (only if not from current user to avoid duplicates)
      // ✅ Compare with database user_id, not google_id
      // ✅ Normalize both IDs to numeric values for comparison (handles "100252" vs "00100252")
      final currentDatabaseUserId = _databaseUserId;
      final normalizedReceivedUserId = UserIdUtils.getNumericValue(
        userId,
      )?.toString();
      final normalizedCurrentUserId = UserIdUtils.getNumericValue(
        currentDatabaseUserId,
      )?.toString();
      final isFromCurrentUser =
          normalizedReceivedUserId == normalizedCurrentUserId;

      if (!isFromCurrentUser) {
        // ✅ PRODUCTION: Use exactly what backend sends - NO FALLBACKS
        // Backend MUST provide real username and profile_url

        // ✅ Normalize profile URL if it's a relative path (only normalization, no fetching)
        String? normalizedProfileUrl = profileUrl;
        if (normalizedProfileUrl != null &&
            normalizedProfileUrl.isNotEmpty &&
            !normalizedProfileUrl.startsWith('http')) {
          normalizedProfileUrl =
              'https://shaheenstar.online/$normalizedProfileUrl';
        }

        final finalUserName = userName ?? 'User';

        final receivedMessage = SendMessageRoomModel.createFromWebSocket(
          userId: userId,
          roomId: widget.roomId,
          message: message,
          userName: finalUserName,
          profileUrl: normalizedProfileUrl,
          timestamp: timestamp,
        );

        messageProvider.addReceivedMessage(receivedMessage);
        print("✅ Message added to chat from user $finalUserName: $message");
        if (normalizedProfileUrl != null) {
          print("   - Profile URL: $normalizedProfileUrl");
        } else {
          print(
            "   ⚠️ Backend did not send profile_url - profile image will not show",
          );
        }
      } else {
        // ✅ Allow "joined the room" and "joined seat" messages to be shown even if from current user
        // Backend broadcasts these to all users, so we show them when received
        final isJoinedMessage =
            message.toLowerCase().contains('joined the room') ||
            message.toLowerCase().contains('joined seat');

        if (isJoinedMessage) {
          // ✅ PRODUCTION: Use exactly what backend sends - NO FALLBACKS
          // Backend MUST provide real username and profile_url

          // ✅ Normalize profile URL if it's a relative path (only normalization, no fetching)
          String? normalizedProfileUrl = profileUrl;
          if (normalizedProfileUrl != null &&
              normalizedProfileUrl.isNotEmpty &&
              !normalizedProfileUrl.startsWith('http')) {
            normalizedProfileUrl =
                'https://shaheenstar.online/$normalizedProfileUrl';
          }

          final finalUserName = userName ?? 'User';

          final joinedMessage = SendMessageRoomModel.createFromWebSocket(
            userId: userId,
            roomId: widget.roomId,
            message: message,
            userName: finalUserName,
            profileUrl: normalizedProfileUrl,
            timestamp: timestamp,
          );

          messageProvider.addReceivedMessage(joinedMessage);
          print(
            "✅ 'Joined the room' message added: $finalUserName (profile: ${normalizedProfileUrl ?? 'none'})",
          );
          if (normalizedProfileUrl == null) {
            print(
              "   ⚠️ Backend did not send profile_url - profile image will not show",
            );
          }
        } else {
          print(
            "ℹ️ Message from current user - skipping (already added locally)",
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _luckyBannerAnimationController?.dispose();
    print("🗑️ Disposing RoomScreen...");

    // ✅ Set disposing flag to prevent setState in async operations
    _isDisposing = true;

    // ✅ Cancel periodic seat refresh timer
    _seatRefreshTimer?.cancel();
    _seatRefreshTimer = null;
    print("🗑️ Cancelled periodic seat refresh timer");

    // ✅ Dispose message controller first
    _messageController.dispose();

    // ✅ Clear messages when leaving room (using stored reference, not context)
    // Skip notification since widget tree is locked during dispose
    try {
      _messageProvider?.clearMessages(skipNotification: true);
      print("🗑️ Cleared messages on room dispose");
    } catch (e) {
      print("⚠️ Error clearing messages during dispose: $e");
    }

    // ✅ Disconnect WebSocket when leaving room (using stored reference)
    try {
      _seatProvider?.disconnect();
      print("🔌 Disconnected WebSocket on room dispose");
    } catch (e) {
      print("⚠️ Error disconnecting WebSocket during dispose: $e");
    }

    // ✅ Leave Zego room and cleanup (using stored reference)
    try {
      final zegoProvider = Provider.of<ZegoVoiceProvider>(
        context,
        listen: false,
      );
      zegoProvider.stopPublishing();
      zegoProvider.leaveRoom();
      print("🎤 Disconnected Zego on room dispose");
    } catch (e) {
      print("⚠️ Error disconnecting Zego during dispose: $e");
    }

    // Cancel Baishun EventChannel subscription
    try {
      _bsEventSub?.cancel();
      _bsEventSub = null;
      print('🗑️ Cancelled baishunChannel subscription');
    } catch (e) {
      print('⚠️ Error cancelling baishunChannel subscription: $e');
    }

    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
    print("✅ RoomScreen disposed successfully");
  }

  Future<bool> _onWillPop() async {
    // ✅ Prevent navigation if gift animation is playing
    if (_currentGiftAnimation != null && _currentGiftQuantity > 0) {
      print("⚠️ Cannot navigate - gift animation is playing");
      return false;
    }

    // If input is shown, close keyboard first
    if (showInput) {
      FocusScope.of(context).unfocus();
      return false;
    }

    // Directly leave the room (no exit confirmation dialog)
    _leaveRoom(context);
    return false;
  }

  void _showFullScreenExitDialog() {
    // Legacy helper — perform immediate leave instead of showing dialog
    _leaveRoom(context);
  }

  /// Show lucky gift congratulations in room chat (not overlay)
  void _showLuckyResultDialog({
    required int multiplier,
    required double reward,
    required double giftPrice,
    String senderName = 'User',
    String? senderUserId,
    String? senderProfileUrl,
  }) {
    if (!mounted) return;
    try {
      final messageProvider = context.read<RoomMessageProvider>();
      messageProvider.addLuckyCongratulationsMessage(
        roomId: widget.roomId.toString(),
        senderName: senderName,
        multiplier: multiplier,
        reward: reward,
        senderUserId: senderUserId,
        senderProfileUrl: senderProfileUrl,
      );
    } catch (e) {
      print('⚠️ [RoomScreen] Failed to add Lucky congratulations to chat: $e');
    }
  }

  void _leaveRoom(BuildContext context) async {
    final leaveProvider = context.read<LeaveRoomProvider>();
    final seatProvider = context.read<SeatProvider>();
    final messageProvider = context.read<RoomMessageProvider>();

    print("🚀 Leaving room...");

    // ✅ 1. CLEAR MESSAGES WHEN LEAVING ROOM
    messageProvider.clearMessages();
    print("🗑️ Cleared messages when leaving room ${widget.roomId}");

    // ✅ 2. Stop Zego publishing and leave Zego room
    final zegoProvider = context.read<ZegoVoiceProvider>();
    await zegoProvider.stopPublishing();
    await zegoProvider.leaveRoom();
    print("✅ Stopped Zego publishing and left Zego room");

    // ✅ 3. PHIR SEAT VACATE KARO
    final databaseUserId = await _getDatabaseUserId();
    if (databaseUserId != null && databaseUserId.isNotEmpty) {
      await seatProvider.vacateSeat(
        roomId: widget.roomId,
        userId: databaseUserId,
      );
    }

    // ✅ 4. FINALLY ROOM LEAVE KARO
    leaveProvider.forceLeaveRoom();

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    print("✅ Room left successfully");
  }

  void _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    final profileProvider = context.read<ProfileUpdateProvider>();
    final messageProvider = context.read<RoomMessageProvider>();

    // ✅ Get database user_id instead of Google ID for WebSocket
    final databaseUserId = await _getDatabaseUserId();
    if (databaseUserId == null || databaseUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: Could not get user ID')));
      }
      return;
    }

    await messageProvider.sendMessage(
      userId: databaseUserId, // ✅ Use database user_id, not google_id
      roomId: widget.roomId,
      message: messageText,
      userName: profileProvider.username ?? 'You',
      profileUrl:
          profileProvider.profile_url ?? '', // ✅ Pass actual profile URL
    );

    _messageController.clear();
    _controller.clear();
  }

  // ✅ MAIN SEAT TAP HANDLER
  void _onSeatTap(Seat seat) {
    print("🎯 Seat ${seat.seatNumber} tapped");
    print("🔍 Current User ID: $_currentUserId");

    final isCurrentUser = seat.userId == _currentUserId;
    final seatProvider = context.read<SeatProvider>();

    // ✅ Check if user is already on ANY seat
    Seat? currentUserSeat;
    try {
      currentUserSeat = seatProvider.seats.firstWhere(
        (s) => s.userId == _currentUserId && s.isOccupied,
      );
      print("✅ User already on seat: ${currentUserSeat.seatNumber}");
    } catch (e) {
      currentUserSeat = null;
      print("ℹ️ User is not on any seat");
    }

    final userIsAlreadySeated =
        currentUserSeat != null && currentUserSeat.seatNumber > 0;
    print("🪑 User Already Seated: $userIsAlreadySeated");

    print(
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
    );
    print(
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    );
    print(
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
    );
    print(
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    );
    print(
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
    );
    print(
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    );
    print(
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
    );
    print(
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    );
    print(seat.isReserved);
    print(!isCurrentUser);
    // 1️⃣ Check if seat is reserved/locked
    if (seat.isReserved && !isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Seat ${seat.seatNumber} is locked'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2️⃣ Check if seat is occupied by someone else
    if (seat.isOccupied && !isCurrentUser) {
      // ✅ Store this seat as selected for gift sending
      // ✅ CRITICAL: Create a copy to preserve userId even if original seat object changes
      final seatCopy = Seat(
        seatNumber: seat.seatNumber,
        isOccupied: seat.isOccupied,
        isReserved: seat.isReserved,
        userId: seat.userId, // ✅ Preserve userId
        username: seat.username,
        userName: seat.userName,
        profileUrl: seat.profileUrl,
      );
      setState(() {
        _selectedSeatForGift = seatCopy;
      });
      print(
        "✅ Selected seat ${seat.seatNumber} for gift sending (User: ${seat.userName ?? seat.username ?? 'Unknown'}, ID: ${seat.userId})",
      );
      print("   - Seat copy created with userId: ${seatCopy.userId}");

      // ✅ Get username with fallback for null values
      final occupantName = seat.userName ?? seat.username ?? 'User';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Seat ${seat.seatNumber} is already occupied by $occupantName',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 3️⃣ If current user is already on this seat - show seat action options
    if (seat.isOccupied && isCurrentUser) {
      _showSeatActionBottomSheet(seat);
      return;
    }

    // 4️⃣ If seat is empty - allow joining, but don't store for gift sending
    if (!seat.isOccupied) {
      // ✅ Clear any previous gift selection (empty seat can't receive gifts)
      setState(() {
        _selectedSeatForGift = null;
      });
      print(
        "✅ Seat ${seat.seatNumber} is empty - allowing join (not storing for gift sending)",
      );
    }

    // 5️⃣ If user is not seated anywhere - show join options
    if (!userIsAlreadySeated) {
      _showJoinSeatBottomSheet(seat);
    } else {
      // User already seated - show switch option
      _showSwitchSeatBottomSheet(currentUserSeat, seat);
    }
  }

  // ✅ JOIN SEAT BOTTOM SHEET (When user is not seated) - WHITE DESIGN
  void _showJoinSeatBottomSheet(Seat seat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),

            Divider(color: Colors.grey[300]),

            // Join Options - Centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Get on microphone by yourself
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      // icon: Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        'Get on the microphone by yourself',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _joinSeatDirect(seat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  // Invite to microphone
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      // icon: Icon(Icons.mic, color: Colors.white),
                      label: Text(
                        'Invite to the microphone',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showInviteToMicDialog(seat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  // Mic Locked option
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.mic_off, color: Colors.white),
                      label: Text(
                        'Mic Locked',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showMicLockedMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            // Cancel Button
            Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ Lock or Join Seat
  void _showLockJoinSeatBottomSheet(Seat seat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),

            Divider(color: Colors.grey[300]),

            // Join Options - Centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      // icon: Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        'Join Seat',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        _onSeatTap(seat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  // Lock Option
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      // icon: Icon(Icons.mic, color: Colors.white),
                      label: Text(
                        'Lock Seat',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onPressed: () {
                        Navigator.pop(context);

                        if (seat.isReserved == true) {
                        } else {}
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            // Cancel Button
            Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ SWITCH SEAT BOTTOM SHEET - WHITE DESIGN
  void _showSwitchSeatBottomSheet(Seat currentSeat, Seat newSeat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),

            // Switch Info - Centered
            Center(
              child: Column(
                children: [
                  Text(
                    'Switch Seat?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Seat ${currentSeat.seatNumber}',
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        'Seat ${newSeat.seatNumber}',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey[300]),

            // Switch Options - Centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Switch to this seat
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.swap_horiz, color: Colors.white),
                      label: Text('Switch to this seat'),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _switchSeat(currentSeat, newSeat);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  // Cancel switch
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSeatActionBottomSheet(Seat seat) {
    final isCurrentUser = seat.userId == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),

            Divider(color: Colors.grey[300]),

            if (seat.isOccupied && isCurrentUser) ...[
              // 2. Leave Seat
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: ElevatedButton.icon(
                  // icon: Icon(Icons.exit_to_app, color: Colors.white),
                  label: Text(
                    'Leave Seat',
                    style: TextStyle(color: Colors.black54),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _vacateSeat(seat);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),
            // Cancel Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ✅ Helper method to get database user_id from SharedPreferences
  Future<String?> _getDatabaseUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ FIRST: Try to get user_id (database ID) from SharedPreferences
      dynamic userIdValue = prefs.get('user_id');
      print(
        "🔍 Getting database user_id from SharedPreferences: $userIdValue (Type: ${userIdValue?.runtimeType})",
      );

      if (userIdValue != null) {
        // ✅ Format user_id to 8 digits
        final formattedUserId = UserIdUtils.formatTo8DigitsFromDynamic(
          userIdValue,
        );
        if (formattedUserId != null) {
          print(
            "✅ User ID formatted to 8 digits: $formattedUserId (original: $userIdValue)",
          );
          return formattedUserId;
        }
      }

      // ✅ If user_id not found, try to fetch it using google_id
      String? googleId = prefs.getString('google_id');
      if (googleId == null || googleId.isEmpty) {
        // Try user-specific google_id keys
        final allKeys = prefs.getKeys();
        for (String key in allKeys) {
          if (key.startsWith('google_id')) {
            googleId = prefs.getString(key);
            if (googleId != null && googleId.isNotEmpty) {
              break;
            }
          }
        }
      }

      if (googleId != null && googleId.isNotEmpty) {
        print("🔄 Fetching user_id from API using google_id: $googleId");
        final userData = await ApiManager.googleLogin(google_id: googleId);
        if (userData != null && userData.id.isNotEmpty) {
          // ✅ Format user_id to 8 digits and save for future use
          final formattedUserId = UserIdUtils.formatTo8Digits(userData.id);
          if (formattedUserId != null) {
            await prefs.setString('user_id', formattedUserId);
            print(
              "✅ Fetched and saved database user_id (8 digits): $formattedUserId (original: ${userData.id})",
            );
            return formattedUserId;
          } else {
            await prefs.setString('user_id', userData.id);
            print("✅ Fetched and saved database user_id: ${userData.id}");
            return userData.id;
          }
        }
      }

      print("❌ Could not determine database user_id");
      return null;
    } catch (e) {
      print("❌ Error getting database user_id: $e");
      return null;
    }
  }

  Future<void> _joinSeatDirect(Seat seat) async {
    final seatProvider = context.read<SeatProvider>();

    // ✅ Get database user_id instead of Google ID
    final databaseUserId = await _getDatabaseUserId();
    if (databaseUserId == null || databaseUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '❌ Unable to determine user ID. Please try logging in again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ✅ CHECK IF USER IS ALREADY ON A SEAT
    // ✅ CRITICAL: Use databaseUserId (not _currentUserId which is Google ID)
    // Normalize user IDs for comparison (handle leading zeros)
    final normalizedDatabaseUserId = databaseUserId.replaceFirst(
      RegExp(r'^0+'),
      '',
    );

    Seat? currentUserSeat;
    try {
      currentUserSeat = seatProvider.seats.firstWhere((s) {
        if (!s.isOccupied || s.userId == null) return false;
        final normalizedSeatUserId = s.userId!.replaceFirst(RegExp(r'^0+'), '');
        return normalizedSeatUserId == normalizedDatabaseUserId;
      });
      print("⚠️ User is already on seat: ${currentUserSeat.seatNumber}");
    } catch (e) {
      currentUserSeat = null;
      print("ℹ️ User is not on any seat - can join");
    }

    // ✅ PREVENT JOINING IF USER IS ALREADY SEATED
    if (currentUserSeat != null &&
        currentUserSeat.seatNumber != seat.seatNumber) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ You are already on seat ${currentUserSeat.seatNumber}. Please leave your current seat first.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print(
        "❌ Blocked: User already on seat ${currentUserSeat.seatNumber}, cannot join seat ${seat.seatNumber}",
      );
      return;
    }

    // ✅ If user is already on this exact seat, allow it (no-op)
    if (currentUserSeat != null &&
        currentUserSeat.seatNumber == seat.seatNumber) {
      print("ℹ️ User is already on seat ${seat.seatNumber} - no action needed");
      return;
    }

    print("🚀 Joining seat ${seat.seatNumber} for user $databaseUserId");

    // ✅ SNACKBAR: JOINING SEAT
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Joining seat ${seat.seatNumber}...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );

    // ✅ Clear any previous error
    seatProvider.clearError();

    // ✅ Get current username and profileUrl from ProfileUpdateProvider (NO SharedPreferences fallback)
    final profileProvider = Provider.of<ProfileUpdateProvider>(
      context,
      listen: false,
    );
    final currentUsername = profileProvider.username;
    final currentProfileUrl = profileProvider.profile_url;

    print(
      "📡 [RoomScreen] Using ProfileUpdateProvider data for seat occupation:",
    );
    print("   - Username: $currentUsername (NO SharedPreferences fallback)");
    print(
      "   - Profile URL: $currentProfileUrl (NO SharedPreferences fallback)",
    );

    final success = await seatProvider.occupySeat(
      roomId: widget.roomId,
      userId: databaseUserId,
      seatNumber: seat.seatNumber,
      username: currentUsername,
      profileUrl: currentProfileUrl,
    );

    if (success) {
      // ✅ Wait for server response (check every 200ms, up to 2.5 seconds)
      bool hasError = false;
      String? detectedError;
      for (int i = 0; i < 13; i++) {
        await Future.delayed(Duration(milliseconds: 200));
        final errorMessage = seatProvider.errorMessage;
        if (errorMessage.isNotEmpty) {
          hasError = true;
          detectedError = errorMessage;
          print("❌ Server error detected (iteration $i): $errorMessage");
          break;
        }
        // ✅ Also check if seat was successfully occupied by checking seats list
        try {
          final updatedSeat = seatProvider.seats.firstWhere(
            (s) => s.seatNumber == seat.seatNumber && s.isOccupied,
          );
          // ✅ Check if this seat is occupied by the current user (database ID)
          final seatUserId = updatedSeat.userId?.toString();

          // Normalize user IDs for comparison (remove leading zeros)
          final normalizedSeatUserId =
              seatUserId?.replaceFirst(RegExp(r'^0+'), '') ?? '';
          final normalizedDatabaseUserId = databaseUserId.replaceFirst(
            RegExp(r'^0+'),
            '',
          );

          print(
            "🔍 [RoomScreen] Checking seat occupation in loop (iteration $i):",
          );
          print("   - Seat Number: ${seat.seatNumber}");
          print("   - Seat User ID (raw): $seatUserId");
          print("   - Seat User ID (normalized): $normalizedSeatUserId");
          print("   - Current User ID (normalized): $normalizedDatabaseUserId");
          print(
            "   - Match: ${normalizedSeatUserId == normalizedDatabaseUserId}",
          );

          if (normalizedSeatUserId == normalizedDatabaseUserId) {
            print("✅ Seat successfully occupied by current user - no error");
            // ✅ Start publishing audio stream via Zego
            print("🎤 [RoomScreen] ===== STARTING AUDIO PUBLISHING =====");
            final zegoProvider = Provider.of<ZegoVoiceProvider>(
              context,
              listen: false,
            );

            // ✅ Check if Zego is ready
            if (!zegoProvider.isInitialized) {
              print(
                "⚠️ [RoomScreen] Zego not initialized, initializing now...",
              );
              final initSuccess = await zegoProvider.initialize();
              if (!initSuccess) {
                print(
                  "❌ [RoomScreen] Failed to initialize Zego: ${zegoProvider.errorMessage}",
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Audio initialization failed: ${zegoProvider.errorMessage ?? "Unknown error"}',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                break;
              }
            }

            if (!zegoProvider.isInRoom) {
              print("⚠️ [RoomScreen] Not in Zego room, joining now...");
              String? token;
              if (_databaseUserId != null && _databaseUserId!.isNotEmpty) {
                try {
                  token = await ApiManager.getZegoToken(
                    roomId: widget.roomId.toString(),
                    userId: _databaseUserId!,
                  );
                } catch (_) {}
              }
              final joinSuccess = await zegoProvider.joinRoom(
                widget.roomId.toString(),
                token: token,
              );
              if (!joinSuccess) {
                print(
                  "❌ [RoomScreen] Failed to join Zego room: ${zegoProvider.errorMessage}",
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to join audio room: ${zegoProvider.errorMessage ?? "Unknown error"}',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                break;
              }
            }

            print("🎤 [RoomScreen] Starting audio publishing...");
            print(
              "🎤 [RoomScreen] - Is Initialized: ${zegoProvider.isInitialized}",
            );
            print("🎤 [RoomScreen] - Is In Room: ${zegoProvider.isInRoom}");
            print(
              "🎤 [RoomScreen] - Current Room ID: ${zegoProvider.currentRoomID}",
            );
            print(
              "🎤 [RoomScreen] - Current User ID: ${zegoProvider.currentUserID}",
            );

            final publishSuccess = await zegoProvider.startPublishing();
            if (publishSuccess) {
              print(
                "✅ [RoomScreen] Successfully started Zego audio publishing",
              );
              print("✅ [RoomScreen] Audio stream is now active");
            } else {
              final errorMsg = zegoProvider.errorMessage ?? 'Unknown error';
              print(
                "❌ [RoomScreen] Failed to start audio publishing: $errorMsg",
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to start audio: $errorMsg'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
            break;
          }
        } catch (e) {
          // Seat not occupied yet, continue waiting
        }
      }

      // ✅ Final check for errors
      final finalErrorMessage = seatProvider.errorMessage;
      final errorToShow = detectedError ?? finalErrorMessage;

      print("🔍 Final error check:");
      print("   - hasError: $hasError");
      print("   - detectedError: $detectedError");
      print("   - finalErrorMessage: $finalErrorMessage");
      print("   - errorToShow: $errorToShow");

      if (hasError ||
          (errorToShow.isNotEmpty &&
              (errorToShow.toLowerCase().contains('already seated') ||
                  errorToShow.toLowerCase().contains('already on') ||
                  errorToShow.toLowerCase().contains('error')))) {
        // ✅ Server says user is already seated - show error and don't send chat message
        print("❌ ERROR DETECTED - NOT sending chat message");
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ ${errorToShow.isNotEmpty ? errorToShow : "Failed to join seat"}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // ✅ Request updated seats to sync local state
        Future.delayed(Duration(milliseconds: 300), () {
          seatProvider.getSeats(widget.roomId.toString());
        });
        return;
      }

      // ✅ REMOVED: Local "joined seat" message sending
      // ✅ Backend will send this message via WebSocket when user occupies seat
      print(
        "✅ NO ERROR DETECTED - waiting for backend to send 'joined seat' message via WebSocket",
      );

      // ✅ SNACKBAR: SEAT JOIN SUCCESS
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Successfully joined Seat ${seat.seatNumber}!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print("✅ User successfully joined seat ${seat.seatNumber}");
    } else {
      // ✅ SNACKBAR: SEAT JOIN FAILED
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final errorMsg = seatProvider.errorMessage.isNotEmpty
          ? seatProvider.errorMessage
          : 'Failed to join seat ${seat.seatNumber}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ VACATE SEAT FUNCTION
  Future<void> _vacateSeat(Seat seat) async {
    final seatProvider = context.read<SeatProvider>();

    print("👋 Leaving seat ${seat.seatNumber}");

    // ✅ Get database user_id instead of Google ID
    final databaseUserId = await _getDatabaseUserId();
    if (databaseUserId == null || databaseUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '❌ Unable to determine user ID. Please try logging in again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ✅ Stop publishing audio stream via Zego before vacating seat
    final zegoProvider = Provider.of<ZegoVoiceProvider>(context, listen: false);
    await zegoProvider.stopPublishing();
    print("✅ Stopped Zego audio publishing");

    final success = await seatProvider.vacateSeat(
      roomId: widget.roomId,
      userId: databaseUserId,
    );

    if (success) {
      // ✅ REMOVED: Local "left seat" message sending
      // ✅ Backend will send this message via WebSocket when user vacates seat
      print(
        "✅ [RoomScreen] Waiting for backend to send 'left seat' message via WebSocket",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👋 Left Seat ${seat.seatNumber}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ WebSocket automatically updates seats via seat:vacated event
      // ✅ Backend will send "left seat" message via WebSocket
      // No need to manually call getSeats() or send local messages
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to leave seat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInviteToMicDialog(Seat seat) {
    // Implement invite functionality
    print("📨 Inviting someone to seat ${seat.seatNumber}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📨 Invitation sent for Seat ${seat.seatNumber}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showMicLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔒 Microphone is locked for this seat'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getMessageProfileImage(
    String? profileUrl, {
    bool isCurrentUser = false,
  }) {
    print("🖼️ Getting profile image for message");
    print("   - Profile URL: '$profileUrl'");
    print("   - Is Current User: $isCurrentUser");

    // ✅ For current user, always use ProfileUpdateProvider (most reliable)
    if (isCurrentUser) {
      try {
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        print(
          "   - ProfileProvider profile_url: '${profileProvider.profile_url}'",
        );

        if (profileProvider.profile_url != null &&
            profileProvider.profile_url!.isNotEmpty) {
          final url = profileProvider.profile_url!;

          // ✅ STRICT VALIDATION for current user profile
          if (_isValidImageUrl(url)) {
            print("   - ✅ Using ProfileProvider URL: $url");
            return url;
          } else {
            print("   - ⚠️ ProfileProvider URL failed validation: '$url'");
          }
        } else {
          print("   - ⚠️ ProfileProvider profile_url is null or empty");
        }
      } catch (e) {
        print("   - ❌ Error getting ProfileProvider: $e");
      }
    }

    // ✅ For other users, use the profileUrl from message WITH STRICT VALIDATION
    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (_isValidImageUrl(profileUrl)) {
        print("   - ✅ Using valid profile URL: $profileUrl");
        return profileUrl;
      } else {
        print("   - ❌ INVALID profile URL rejected: '$profileUrl'");
      }
    } else {
      print("   - ⚠️ Profile URL is null or empty");
    }

    // ✅ DEFAULT: Use person.png (which exists in your assets)
    print("   - 🟡 Using default placeholder image");
    return 'assets/images/person.png';
  }

  // ✅ NEW: Strict URL validation method
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    final trimmedUrl = url.trim();
    final lowerUrl = trimmedUrl.toLowerCase();

    // ❌ REJECT invalid values that look like asset names
    final invalidValues = [
      'jgh',
      'upload',
      'profile url',
      'profile_url',
      'null',
      'yyyy',
      ' ',
      'profile',
      'avatar',
      'image',
    ];

    if (invalidValues.contains(lowerUrl)) {
      print("   - 🚫 Rejected invalid value: '$url'");
      return false;
    }

    // ✅ Check minimum length
    if (trimmedUrl.length < 5) {
      print("   - 🚫 URL too short: '$url'");
      return false;
    }

    // ✅ Check for spaces (invalid in URLs)
    if (trimmedUrl.contains(' ')) {
      print("   - 🚫 URL contains spaces: '$url'");
      return false;
    }

    // ✅ Only allow valid HTTP/HTTPS URLs or file paths
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return true;
    }

    // ✅ Allow local file paths (if they exist)
    if (trimmedUrl.startsWith('/data/') ||
        trimmedUrl.startsWith('/storage/') ||
        trimmedUrl.contains('cache')) {
      try {
        File file = File(trimmedUrl);
        if (file.existsSync()) {
          return true;
        } else {
          print("   - 🚫 Local file not found: '$url'");
          return false;
        }
      } catch (e) {
        print("   - 🚫 Error checking local file: '$url' - $e");
        return false;
      }
    }

    // ❌ Reject everything else (including invalid asset names)
    print("   - 🚫 Not a valid URL or file path: '$url'");
    return false;
  }

  // ✅ Helper method for message profile images
  // ImageProvider _getMessageProfileImage(String? profileUrl, {bool isCurrentUser = false}) {
  //   // ✅ For current user, always use ProfileUpdateProvider (most reliable)
  //   if (isCurrentUser) {
  //     try {
  //       final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
  //       print("🖼️ Getting message avatar for CURRENT USER");
  //       print("   - ProfileProvider profile_url: ${profileProvider.profile_url}");

  //       if (profileProvider.profile_url != null &&
  //           profileProvider.profile_url!.isNotEmpty) {
  //         final url = profileProvider.profile_url!;
  //         print("   - ✅ Using ProfileProvider URL for message: $url");
  //         // ✅ Validate URL before using
  //         if (url.startsWith('http://') || url.startsWith('https://')) {
  //           return NetworkImage(url);
  //         } else {
  //           print("   - ⚠️ ProfileProvider URL is not valid HTTP/HTTPS: $url");
  //         }
  //       } else {
  //         print("   - ⚠️ ProfileProvider profile_url is null or empty for message");
  //       }
  //     } catch (e) {
  //       print("   - ❌ Error getting ProfileProvider for message: $e");
  //     }
  //   }

  //   // ✅ For other users, use the profileUrl from message
  //   if (profileUrl != null && profileUrl.isNotEmpty) {
  //     final lowerUrl = profileUrl.toLowerCase().trim();

  //     // ✅ STRICT VALIDATION: Reject invalid profile URLs
  //     if (profileUrl.length < 5 ||
  //         profileUrl.contains(' ') ||
  //         lowerUrl == 'upload' ||
  //         lowerUrl == 'profile url' ||
  //         lowerUrl == 'profile_url' ||
  //         lowerUrl == 'jgh' ||
  //         lowerUrl == 'null' ||
  //         lowerUrl.isEmpty) {
  //       print("⚠️ Invalid message profile URL rejected: '$profileUrl' - using placeholder");
  //       return const AssetImage('assets/images/person.png');
  //     }

  //     // ✅ Only use NetworkImage for valid HTTP/HTTPS URLs
  //     if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
  //       return NetworkImage(profileUrl);
  //     } else {
  //       // ✅ Not a valid URL - don't try to load as asset
  //       print("⚠️ Message profile URL is not a valid URL: '$profileUrl' - using placeholder");
  //       return const AssetImage('assets/images/person.png');
  //     }
  //   }
  //   // ✅ Use person.png instead of default_avatar.png (which doesn't exist)
  //   return const AssetImage('assets/images/person.png');
  // }

  String _getProfileImage(String? profileUrl, bool isCurrentUser) {
    print("🖼️ Getting profile image for seat");
    print("   - Profile URL: '$profileUrl'");
    print("   - Is Current User: $isCurrentUser");

    // ✅ For current user, always use ProfileUpdateProvider
    if (isCurrentUser) {
      try {
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        print(
          "   - ProfileProvider profile_url: '${profileProvider.profile_url}'",
        );

        if (profileProvider.profile_url != null &&
            profileProvider.profile_url!.isNotEmpty) {
          final url = profileProvider.profile_url!;

          if (_isValidImageUrl(url)) {
            print("   - ✅ Using ProfileProvider URL: $url");
            return url;
          } else {
            print("   - ⚠️ ProfileProvider URL failed validation: '$url'");
          }
        } else {
          print("   - ⚠️ ProfileProvider profile_url is null or empty");
        }
      } catch (e) {
        print("   - ❌ Error getting ProfileProvider: $e");
      }
    }

    // ✅ For other users, use the profileUrl with strict validation
    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (_isValidImageUrl(profileUrl)) {
        print("   - ✅ Using valid profile URL: $profileUrl");
        return profileUrl;
      } else {
        print("   - ❌ INVALID profile URL rejected: '$profileUrl'");
      }
    } else {
      print("   - ⚠️ Profile URL is null or empty");
    }

    // ✅ DEFAULT: Use person.png
    print("   - 🟡 Using default placeholder image");
    return 'assets/images/person.png';
  }
  // ImageProvider _getProfileImage(String? profileUrl, bool isCurrentUser) {
  //   // ✅ For current user, always use ProfileUpdateProvider (most reliable)
  //   if (isCurrentUser) {
  //     try {
  //       final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
  //       print("🖼️ Getting profile image for CURRENT USER");
  //       print("   - ProfileProvider profile_url: ${profileProvider.profile_url}");
  //       print("   - Seat profileUrl: $profileUrl");

  //       if (profileProvider.profile_url != null &&
  //           profileProvider.profile_url!.isNotEmpty) {
  //         final url = profileProvider.profile_url!;
  //         print("   - ✅ Using ProfileProvider URL: $url");
  //         // ✅ Validate URL before using
  //         if (url.startsWith('http://') || url.startsWith('https://')) {
  //           return NetworkImage(url);
  //         } else {
  //           print("   - ⚠️ ProfileProvider URL is not valid HTTP/HTTPS: $url");
  //         }
  //       } else {
  //         print("   - ⚠️ ProfileProvider profile_url is null or empty");
  //       }
  //     } catch (e) {
  //       print("   - ❌ Error getting ProfileProvider: $e");
  //     }
  //   }

  //   if (profileUrl != null && profileUrl.isNotEmpty && profileUrl != 'yyyy') {
  //     final lowerUrl = profileUrl.toLowerCase().trim();

  //     // ✅ STRICT VALIDATION: Reject invalid profile URLs that look like asset names
  //     // These should NEVER be passed to AssetImage
  //     if (profileUrl.length < 5 ||
  //         profileUrl.contains(' ') ||
  //         lowerUrl == 'upload' ||
  //         lowerUrl == 'profile url' ||
  //         lowerUrl == 'profile_url' ||
  //         lowerUrl == 'jgh' ||
  //         lowerUrl == 'null' ||
  //         lowerUrl.isEmpty) {
  //       print("⚠️ Invalid profile URL rejected: '$profileUrl' - using placeholder");
  //       return const AssetImage('assets/images/person.png');
  //     }

  //     // ✅ Only allow valid URLs or file paths
  //     // Check if it's a local file path
  //     if (profileUrl.startsWith('/data/') || profileUrl.startsWith('/storage/') || profileUrl.contains('cache')) {
  //       try {
  //         File file = File(profileUrl);
  //         if (file.existsSync()) {
  //           return FileImage(file);
  //         } else {
  //           print("⚠️ Profile file not found: $profileUrl - using placeholder");
  //           return const AssetImage('assets/images/person.png');
  //         }
  //       } catch (e) {
  //         print('❌ Error loading profile file: $e');
  //         return const AssetImage('assets/images/person.png');
  //       }
  //     } else if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
  //       return NetworkImage(profileUrl);
  //     } else {
  //       // ✅ Not a valid URL or file path - don't try to load as asset
  //       print("⚠️ Profile URL is not a valid URL or file path: '$profileUrl' - using placeholder");
  //       return const AssetImage('assets/images/person.png');
  //     }
  //   }

  //   return const AssetImage('assets/images/person.png');
  // }

  bool showInput = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  //    @override
  // void dispose() {
  //   _focusNode.dispose();
  //   _controller.dispose();
  //   super.dispose();
  // }

  void openChat() {
    print('[RoomScreen] openChat() called');
    setState(() {
      _selectedMessageTab = 1; // 1: Message tab (room chat)
      showInput = true;
      print('[RoomScreen] showInput set to true');
    });
    // Request focus for the message input after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        print('[RoomScreen] Requesting focus for message input');
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[RoomScreen] build() called, showInput: '
      '${showInput.toString()}',
    );
    final backbackProvider = Provider.of<BackpackProvider>(
      context,
      listen: false,
    );
    final profileProvider = context.watch<ProfileUpdateProvider>();
    final joinProvider = context.watch<JoinRoomProvider>();
    final leaveProvider = context.watch<LeaveRoomProvider>();
    final messageProvider = context.watch<RoomMessageProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final seatProvider = context.watch<SeatProvider>();
    final size = MediaQuery.of(context).size;

    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_currentUserId == null) {
      return _buildLoginRequiredScreen(size);
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive scale based on screen width
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final isSmallScreen = screenWidth < 360;
              final scale = (screenWidth / 375).clamp(0.85, 1.15);

              return SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF052E0D), // Exact dark green background
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        /// ================= MAIN COLUMN UI =================
                        Column(
                          children: [
                            // HEADER (New Design)
                            _buildNewHeaderSection(
                              size,
                              seatProvider,
                              profileProvider,
                              scale,
                            ),

                            // CHAIRS GRID (NO Expanded here)
                            _buildChairsGrid(size, seatProvider),

                            // TABS NAVIGATION
                            _buildTabsNavigation(scale),

                            // MESSAGES (ONLY ONE Expanded in Column ✅)
                            Expanded(
                              child: _buildMessagesSection(
                                size,
                                profileProvider,
                                messageProvider,
                              ),
                            ),

                            // SHARE ROOM BUTTON
                            _buildShareRoomButton(scale),

                            // FOOTER (New Design)
                            _buildNewFooterSection(
                              size,
                              messageProvider,
                              scale,
                            ),
                          ],
                        ),

                        /// ================= FLOATING ICONS (Right Side) =================
                        Positioned(
                          right: 12 * scale,
                          bottom: 120 * scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // First Recharge Gift Box Icon (Above 202.png)
                              GestureDetector(
                                onTap: () => _openCategoryBottomSheet(context),
                                child: Container(
                                  width: 54 * scale,
                                  height: 54 * scale,
                                  decoration: BoxDecoration(),
                                  child: AppImage.asset(
                                    'assets/icons/101.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              // Game controller and Combo button container
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Game icon (tappable)
                                  GestureDetector(
                                    onTap: () => _showGamesBottomSheet(context),
                                    child: Container(
                                      width: 64 * scale,
                                      height: 64 * scale,
                                      padding: EdgeInsets.all(6 * scale),
                                      decoration: const BoxDecoration(),
                                      child: AppImage.asset(
                                        'assets/icons/202.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  // Combo button specific spacing
                                  SizedBox(height: 4 * scale),

                                  // Combo button positioned below game icon
                                  Consumer<GiftProvider>(
                                    builder: (context, giftProvider, _) {
                                      if (!giftProvider.isComboActive)
                                        return const SizedBox.shrink();
                                      return GestureDetector(
                                        onTap: () {
                                          giftProvider.triggerCombo();
                                        },
                                        child: Container(
                                          width: 80 * scale,
                                          height: 80 * scale,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/images/combo.png',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${giftProvider.comboCount}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22 * scale,
                                                  fontWeight: FontWeight.w900,
                                                  fontStyle: FontStyle.italic,
                                                  shadows: const [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 4,
                                                      offset: Offset(2, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'Combo',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10 * scale,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: const [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (showInput)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 56 * scale,
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * scale,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      focusNode: _focusNode,
                                      controller: _controller,
                                      //controller: _messageController,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      cursorColor: Colors.blue,
                                      decoration: InputDecoration(
                                        hintText: "Type a message...",
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16 * scale,
                                          vertical: 12 * scale,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      _sendMessage();
                                      FocusScope.of(context).unfocus();
                                      Future.delayed(
                                        const Duration(milliseconds: 150),
                                        () {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (mounted && !_isDisposing) {
                                                  setState(
                                                    () => showInput = false,
                                                  );
                                                }
                                              });
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        /// ================= OVERLAYS =================
                        if (_showAnnouncement) _buildAnnouncementPopup(size),

                        if (_currentGiftAnimation != null &&
                            _currentGiftQuantity > 0)
                          GiftAnimationOverlay(
                            gift: _currentGiftAnimation!,
                            quantity: _currentGiftQuantity,
                            senderName: _currentGiftSenderName,
                            senderAvatar: _currentGiftSenderAvatar,
                            receiverName: _currentGiftReceiverName,
                            receiverAvatar: _currentGiftReceiverAvatar,
                            isMultipleReceivers:
                                _currentGiftIsMultipleReceivers,
                            hideHeader:
                                (_currentGiftAnimation!.price *
                                    _currentGiftQuantity) >=
                                100000,
                            onComplete: () {
                              setState(() {
                                _currentGiftAnimation = null;
                                _currentGiftQuantity = 0;
                                _currentGiftSenderName = null;
                                _currentGiftSenderAvatar = null;
                                _currentGiftReceiverName = null;
                                _currentGiftReceiverAvatar = null;
                                _currentGiftIsMultipleReceivers = false;
                              });
                            },
                          ),

                        // Lucky congratulations now shown in room chat, not as overlay
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        onTap: () {
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 150), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposing) {
                setState(() => showInput = false);
              }
            });
          });
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A), // Dark background fallback
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Loading Room...",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                "Please wait while we set up your seats",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequiredScreen(Size size) {
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/room_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You need to login to access rooms",
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  "Go to Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ New Header Section Design
  Widget _buildNewHeaderSection(
    Size size,
    SeatProvider seatProvider,
    ProfileUpdateProvider profileProvider,
    double scale,
  ) {
    // Count all users in room (whether on seats or not)
    final totalUsersInRoom = _usersInRoom.length;

    final allRoomProvider = Provider.of<GetAllRoomProvider>(
      context,
      listen: false,
    );
    final creatorIdRaw = widget.roomCreatorId;
    final creatorId = int.tryParse(creatorIdRaw);
    final creatorData = creatorId != null
        ? allRoomProvider.allUsersMap[creatorId]
        : null;
    final ownerName = _displayRoomName;
    final ownerProfileUrl = creatorData?['profile_url']?.toString();
    final roomProfileUrl = _normalizeRoomProfileUrl(_displayRoomProfileUrl);

    ImageProvider imageProvider;
    try {
      if (roomProfileUrl != null) {
        imageProvider = CachedNetworkImageProvider(roomProfileUrl);
      } else if (ownerProfileUrl != null &&
          ownerProfileUrl.isNotEmpty &&
          (ownerProfileUrl.startsWith('http://') ||
              ownerProfileUrl.startsWith('https://'))) {
        imageProvider = CachedNetworkImageProvider(ownerProfileUrl);
      } else {
        imageProvider = const AssetImage('assets/images/person.png');
      }
    } catch (e) {
      print('❌ [cachedImage] Error: $roomProfileUrl - Exception: $e');
      imageProvider = const AssetImage('assets/images/person.png');
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF052E0D), // Match page background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Side: User Profile & Info
          Expanded(
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2 * scale),
                  ),
                  child: ClipOval(
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => AppImage.asset(
                        'assets/images/person.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Username & ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username (Yellow)
                      Text(
                        ownerName,
                        style: TextStyle(
                          color: const Color(0xFFFFD700), // Golden yellow
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 3 * scale),
                      // Room owner ID - plain text, no background
                      Text(
                        creatorIdRaw ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5 * scale),
                      GestureDetector(
                        onTap: () => _showRankingTypeBottomSheet(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppImage.asset(
                              'assets/icons/winning_1.png',
                              width: 20 * scale,
                              height: 20 * scale,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 5 * scale),
                            Text(
                              totalCoins ?? '0',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right Side: Share/Exit and Participant Count
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _openShareToMembersBottomSheet(context),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _leaveRoom(context),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20 * scale,
                    height: 20 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1.5 * scale,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Image(
                            image: imageProvider,
                            width: 16 * scale,
                            height: 16 * scale,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => AppImage.asset(
                              'assets/images/person.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: -2,
                          child: Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFFFD700),
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 5 * scale),
                  GestureDetector(
                    onTap: () => _showUsersListBottomSheet(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * scale,
                        vertical: 2 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E3A17),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2F6F36)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 11 * scale,
                          ),
                          SizedBox(width: 3 * scale),
                          Text(
                            totalUsersInRoom.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRankingTypeBottomSheet(BuildContext context) {
    final roomIdInt = int.tryParse(widget.roomId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.78 + 100,
        child: RoomRankingScreen(
          roomId: roomIdInt,
          initialFilter: "sender",
          isPopup: true,
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Size size, SeatProvider seatProvider) {
    // Count all users in room (whether on seats or not)
    final totalUsersInRoom = _usersInRoom.length;
    print(
      "👥 [RoomScreen] _buildRoomAdminSection - Total users in room: $totalUsersInRoom",
    );
    print("👥 [RoomScreen] Users list: $_usersInRoom");
    return Consumer<ProfileUpdateProvider>(
      builder: (context, profileProvider, child) {
        // ✅ Use room profile URL first (if provided), then user profile, then local file, then default
        ImageProvider imageProvider;
        try {
          // ✅ Priority 1: Room profile URL (network URL)
          final roomProfileUrl = _normalizeRoomProfileUrl(
            widget.roomProfileUrl,
          );
          if (roomProfileUrl != null) {
            imageProvider = CachedNetworkImageProvider(roomProfileUrl);
          }
          // ✅ Priority 3: Local file (avatarUrl)
          else if (widget.avatarUrl != null && widget.avatarUrl!.existsSync()) {
            imageProvider = FileImage(widget.avatarUrl!);
          }
          // ✅ Priority 4: Default placeholder
          else {
            imageProvider = const AssetImage('assets/images/person.png');
          }
        } catch (e) {
          print(
            '❌ [cachedImage] Error: ${_normalizeRoomProfileUrl(widget.roomProfileUrl)} - Exception: $e',
          );
          imageProvider = const AssetImage('assets/images/person.png');
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container(color: Colors.red,width:MediaQuery.of(context).size.width / 2,
            // child:Stack(children: [
            //                       Positioned(right: -10,bottom: 0,top:0,left:20,child: Container(color:Colors.yellow

            //     // child:
            //     //  AppImage.asset(
            //     //   "assets/images/room_profile_br.png",
            //     //   fit: BoxFit.cover,

            //     // ),

            // )),

            // Positioned(right: 130,left:15,child:
            //             Container(
            //                     width: 50,
            //                     height:50,

            //     decoration: BoxDecoration(
            //       color: Colors.green,
            //       border: Border.all(color: Colors.white, width: 2),
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(10),
            //       // child:

            //       //  Image(
            //       //   image: imageProvider,
            //       //   fit: BoxFit.cover,
            //       //   errorBuilder: (_, __, ___) =>
            //       //       AppImage.asset('assets/images/person.png', fit: BoxFit.cover),
            //       // ),
            //     ),
            //   ),),

            // ])
            // ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: 0,
                    top: 0,
                    left: 20,
                    child: SizedBox(
                      child: AppImage.asset(
                        "assets/images/room_profile_br.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    top: 17,
                    child: Container(
                      width: 55,
                      height: 55,

                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => AppImage.asset(
                            'assets/images/person.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    bottom: 0,
                    top: 30,
                    left: MediaQuery.of(context).size.width / 5.2,
                    child: InkWell(
                      onTap: _runDebugTest,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment:
                            MainAxisAlignment.start, // 👈 important
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayRoomName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),

                          Wrap(
                            verticalDirection: VerticalDirection.up,
                            children: [
                              Text(
                                "⾕ ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepPurpleAccent,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                "Room ID: ${widget.roomId}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _openShareToMembersBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),

                          child: AppImage.asset(
                            "assets/images/share.png",
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () => _leaveRoom(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),

                          child: AppImage.asset(
                            "assets/images/room_left.png",
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => AppImage.asset(
                              'assets/images/person.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),

                      GestureDetector(
                        onTap: () {
                          _showUsersListBottomSheet(context);
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
                          width: 70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFFFFD700), // 👈 golden color
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.person_3,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),

                              Text(
                                totalUsersInRoom.toString(),
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Show users list bottom sheet
  void _showUsersListBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Prefer listing users the current user has one-to-one chats with
        final chatProvider = Provider.of<UserMessageProvider>(
          context,
          listen: false,
        );
        final currentNormalizedId = _normalizeUserId(_databaseUserId);
        final currentIdInt = int.tryParse(currentNormalizedId) ?? 0;

        final usersFromChat = chatProvider.chatRooms.map((room) {
          final otherId = room.getOtherUserId(currentIdInt).toString();
          final otherName = room.getOtherUserName(currentIdInt);
          return MapEntry(otherId, {"name": otherName, "profileUrl": null});
        }).toList();

        // If there are chat contacts, show them; otherwise fall back to online room users
        final users = usersFromChat.isNotEmpty
            ? usersFromChat
            : _usersInRoom.entries.toList();
        final vipCount = users.length;
        final audienceCount = 0;

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE3EC), Color(0xFFFFF5E6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Online user',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD24B7A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AppImage.asset(
                            'assets/icons/Group_182.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'VIP User  ($vipCount)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Become VIP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'No Data',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      ...users.map((entry) {
                        final originalUserId = entry.key;
                        final userInfo = entry.value;
                        final userName =
                            userInfo['name'] ?? userInfo['username'] ?? 'User';
                        final profileUrl = userInfo['profileUrl'];
                        final normalizedUserId = _normalizeUserId(
                          originalUserId,
                        );
                        final normalizedCurrentUserId = _normalizeUserId(
                          _databaseUserId,
                        );
                        final isCurrentUser =
                            normalizedUserId.isNotEmpty &&
                            normalizedCurrentUserId.isNotEmpty &&
                            normalizedUserId == normalizedCurrentUserId;
                        final displayUserId = normalizedUserId.isNotEmpty
                            ? normalizedUserId
                            : originalUserId;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showProfileBottomSheet(
                              profileUrl: profileUrl,
                              userName: userName,
                              userId: originalUserId,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFD180),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 27,
                                  backgroundImage: _getUserAvatarProvider(
                                    profileUrl,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCurrentUser)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                'You',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      UserIdDisplay(userId: displayUserId),
                                      // Badges will be shown from API response
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFFB300),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Audience  ($audienceCount)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (audienceCount == 0)
                      Center(
                        child: Text(
                          'No Data',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Share room with selected members (multi-select list)
  void _openShareToMembersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final selected = <String>{};
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select members to share room',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selected.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Consumer<UserMessageProvider>(
                      builder: (ctx, chatProv, _) {
                        final currentNormalizedId = _normalizeUserId(
                          _databaseUserId,
                        );
                        final currentIdInt =
                            int.tryParse(currentNormalizedId) ?? 0;
                        final usersFromChat = chatProv.chatRooms.map((room) {
                          final otherId = room
                              .getOtherUserId(currentIdInt)
                              .toString();
                          final otherName = room.getOtherUserName(currentIdInt);
                          // Prefer room-known profile, then cached chat profile
                          String? profile =
                              _usersInRoom[otherId]?['profileUrl'] ??
                              _chatUserProfiles[otherId];

                          // If we still don't have a profile url, fetch it async and cache it.
                          if (profile == null &&
                              !_chatUserProfiles.containsKey(otherId)) {
                            final idInt = int.tryParse(otherId);
                            if (idInt != null && idInt > 0) {
                              ApiManager.getUserInfoById(idInt)
                                  .then((ui) {
                                    if (ui != null && ui.isNotEmpty) {
                                      final avatar =
                                          ui['profile_url'] ??
                                          ui['user_avatar'] ??
                                          ui['avatar'] ??
                                          ui['profile_pic'];
                                      final resolved =
                                          (avatar != null &&
                                              avatar.toString().isNotEmpty)
                                          ? (avatar.toString().startsWith(
                                                  'http',
                                                )
                                                ? avatar.toString()
                                                : 'https://shaheenstar.online/$avatar')
                                          : null;
                                      setState(() {
                                        _chatUserProfiles[otherId] = resolved;
                                      });
                                    } else {
                                      setState(() {
                                        _chatUserProfiles[otherId] = null;
                                      });
                                    }
                                  })
                                  .catchError((e) {
                                    setState(() {
                                      _chatUserProfiles[otherId] = null;
                                    });
                                  });
                            } else {
                              _chatUserProfiles[otherId] = null;
                            }
                          }

                          return MapEntry(otherId, {
                            "name": otherName,
                            "profileUrl": profile,
                          });
                        }).toList();

                        final displayList = usersFromChat.isNotEmpty
                            ? usersFromChat
                            : _usersInRoom.entries.toList();

                        if (displayList.isEmpty)
                          return const Center(child: Text('No members online'));

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayList.length,
                          itemBuilder: (ctx, i) {
                            final originalUserId = displayList[i].key;
                            final info = displayList[i].value;
                            final name =
                                info['name'] ?? info['username'] ?? 'User';
                            final profileUrl = info['profileUrl'];
                            final normalized = _normalizeUserId(originalUserId);
                            final isMe =
                                normalized.isNotEmpty &&
                                _normalizeUserId(_databaseUserId) == normalized;
                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: isMe
                                  ? null
                                  : () {
                                      setState(() {
                                        if (selected.contains(originalUserId))
                                          selected.remove(originalUserId);
                                        else
                                          selected.add(originalUserId);
                                      });
                                    },
                              child: CheckboxListTile(
                                value: selected.contains(originalUserId),
                                onChanged: isMe
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true)
                                            selected.add(originalUserId);
                                          else
                                            selected.remove(originalUserId);
                                        });
                                      },
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: _getUserAvatarProvider(
                                        profileUrl,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () async {
                                    // send private chat invites to selected members
                                    final fromId = int.tryParse(
                                      _normalizeUserId(_databaseUserId),
                                    );
                                    if (fromId == null || fromId == 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Your user id not available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final roomInfo =
                                        'Join my room: ${widget.roomId}';
                                    int success = 0;
                                    final chatProv =
                                        Provider.of<UserChatProvider>(
                                          context,
                                          listen: false,
                                        );
                                    for (final to in selected) {
                                      final toId = int.tryParse(
                                        _normalizeUserId(to),
                                      );
                                      if (toId == null || toId == 0) continue;
                                      try {
                                        final existing = chatProv
                                            .getChatroomByUserId(toId);
                                        var room = existing;
                                        if (room == null) {
                                          room = await chatProv.createChatroom(
                                            toId,
                                          );
                                        }

                                        if (room != null) {
                                          await chatProv.setCurrentChatroom(
                                            room.id,
                                          );
                                          final ok = await chatProv
                                              .sendChatMessage(roomInfo);
                                          if (ok) success++;
                                        } else {
                                          // fallback to HTTP send when chatroom couldn't be created
                                          final ok =
                                              await ApiManager.sendChatMessage(
                                                fromUserId: fromId,
                                                toUserId: toId,
                                                message: roomInfo,
                                              );
                                          if (ok) success++;
                                        }
                                      } catch (e) {
                                        print(
                                          '[ShareToMembers] send error for $toId: $e',
                                        );
                                        try {
                                          final ok =
                                              await ApiManager.sendChatMessage(
                                                fromUserId: fromId,
                                                toUserId: toId,
                                                message: roomInfo,
                                              );
                                          if (ok) success++;
                                        } catch (_) {}
                                      }
                                    }
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Shared with $success/${selected.length}',
                                        ),
                                      ),
                                    );
                                  },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Share'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ Tabs Navigation (All, Message, Gift)
  Widget _buildTabsNavigation(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 4 * scale,
      ),
      child: Row(
        children: [
          _buildTab('All', 0, scale),
          SizedBox(width: 20 * scale),
          _buildTab('Message', 1, scale),
          SizedBox(width: 20 * scale),
          _buildTab('Gift', 2, scale),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, double scale) {
    final isSelected = _selectedMessageTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessageTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 15 * scale,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 3 * scale),
              height: 3,
              width: 28 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700), // Golden underline
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Share Room Button
  Widget _buildShareRoomButton(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 4 * scale,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Share your room to others!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openShareToMembersBottomSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 7 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: const Text(
                  'Share',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAdminSection(
    Size size,
    File? avatarUrl,
    SeatProvider seatProvider,
  ) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 10, right: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              print("this is the room id ${widget.roomId}");
              final roomIdInt = int.tryParse(widget.roomId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomRankingScreen(roomId: roomIdInt),
                ),
              );
            },
            child: Stack(
              children: [
                SizedBox(
                  width: 100,

                  child: AppImage.asset(
                    "assets/images/room_admin_br.png",
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 45,
                  child: Text(
                    totalCoins == ""
                        ? "0.0"
                        : formatNumberReadable(int.parse(totalCoins!)),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              SizedBox(
                width: 100,
                child: AppImage.asset(
                  "assets/images/room_admin_br.png",
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 20,
                left: 43,
                child: Text(
                  "Notice",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChairsGrid(Size size, SeatProvider seatProvider) {
    return seatProvider.isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : seatProvider.seats.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_seat, size: 50, color: Colors.white54),
                const SizedBox(height: 10),
                const Text(
                  "No Seats Available",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Tap refresh to load seats",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive sizing based on available width
              final availableWidth = constraints.maxWidth;
              final horizontalPadding = 16.0;
              final crossAxisSpacing = 8.0;
              final crossAxisCount = 5;

              // Calculate item width to prevent overflow
              final totalSpacing =
                  (crossAxisCount - 1) * crossAxisSpacing +
                  (horizontalPadding * 2);
              final itemWidth =
                  (availableWidth - totalSpacing) / crossAxisCount;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: seatProvider.seats.length > 20
                      ? 20
                      : seatProvider.seats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: 12,
                    childAspectRatio:
                        itemWidth /
                        (itemWidth + 15), // Dynamic ratio to prevent overflow
                  ),
                  itemBuilder: (context, index) {
                    final seat = seatProvider.seats[index];
                    return _buildSeatItem(seat, index);
                  },
                ),
              );
            },
          );
  }

  Widget _buildSeatItem(Seat seat, int index) {
    // ✅ Compare with database user ID, not Google ID
    // seat.userId is database ID (e.g., "1152"), not Google ID
    // Get database user ID for comparison (use stored value or get from SharedPreferences)
    // ✅ CRITICAL: Normalize IDs for comparison (handles "100623" vs "00100623")
    final currentDatabaseUserId = _databaseUserId;
    final seatUserIdNormalized = seat.userId != null
        ? UserIdUtils.getNumericValue(seat.userId.toString())?.toString()
        : null;
    final currentUserIdNormalized = UserIdUtils.getNumericValue(
      currentDatabaseUserId,
    )?.toString();
    final isCurrentUser =
        seatUserIdNormalized != null &&
        currentUserIdNormalized != null &&
        seatUserIdNormalized == currentUserIdNormalized;
    final isOccupied = seat.isOccupied;

    // ✅ DEBUG: Log seat data for ALL users (not just current user) to diagnose the issue
    if (isOccupied) {
      print("🖼️ ===== Building seat ${seat.seatNumber} =====");
      print("   - Is Current User: $isCurrentUser");
      print("   - Seat userId: ${seat.userId}");
      print("   - Current Database userId: $currentDatabaseUserId");
      print("   - Current Google userId: $_currentUserId");
      print("   - Seat username: ${seat.username}");
      print("   - Seat userName: ${seat.userName}");
      print("   - Seat profileUrl: ${seat.profileUrl}");
      print("   - Is Occupied: $isOccupied");
      print("   ==========================================");
    }
    final currentUserId = UserIdUtils.getNumericValue(
      _databaseUserId,
    )?.toString();
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        // final profileUrl = provider.loadBackpack(seat.userId);
        // ✅ Use ProfileWithFrame to show purchased items as frames
        return LayoutBuilder(
          builder: (context, constraints) {
            // Make seat size responsive to available space
            final seatSize = constraints.maxWidth.clamp(45.0, 55.0);

            return GestureDetector(
              onTap: () {
                final profileUrl = provider.loadBackpack(seat.userId);
                if (widget.roomCreatorId == currentUserId) {
                  _showLockJoinSeatBottomSheet(seat);
                } else {
                  _onSeatTap(seat);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,

                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Seat base
                      ((widget.roomCreatorId == currentUserId) &&
                              (seat.isReserved == true))
                          ? Container(
                              width: seatSize,
                              height: seatSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                  image: AssetImage('assets/images/lock.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: seatSize,
                              height: seatSize,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icons/room_seat.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      // ✅ User avatar if occupied - keep SVG visible as base
                      if (isOccupied)
                        SizedBox(
                          width: seatSize,
                          height: seatSize,
                          child: ClipOval(
                            child: ProfileWithFrame(
                              userId:
                                  (seat.userId != null &&
                                      seat.userId!.isNotEmpty &&
                                      seat.userId != '0')
                                  ? seat.userId
                                  : null,
                              size: seatSize,
                              profileUrl: seat.profileUrl,
                              showPlaceholder: true,
                              fitToSize: true,
                            ),
                          ),
                        ),

                      // ✅ Microphone mute/unmute button (only for current user when on seat)
                      if (isOccupied && isCurrentUser)
                        Positioned(
                          bottom: 0,
                          right: -2,
                          child: Builder(
                            builder: (context) {
                              final zegoProvider =
                                  Provider.of<ZegoVoiceProvider>(
                                    context,
                                    listen: true,
                                  );
                              return GestureDetector(
                                onTap: () async {
                                  // ✅ Get current mic state before toggling
                                  final currentMicState =
                                      zegoProvider.isMicrophoneEnabled;

                                  // ✅ Toggle microphone
                                  await zegoProvider.toggleMicrophone();

                                  // ✅ Send mic status to backend (state is now inverted)
                                  final seatProvider =
                                      Provider.of<SeatProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final databaseUserId =
                                      await _getDatabaseUserId();
                                  if (databaseUserId != null) {
                                    await seatProvider.sendMicStatus(
                                      roomId: widget.roomId.toString(),
                                      userId: databaseUserId,
                                      isMuted:
                                          !currentMicState, // Use previous state (now toggled)
                                      seatNumber: seat.seatNumber,
                                    );
                                  }
                                },
                                child: Container(
                                  width: seatSize * 0.47,
                                  height: seatSize * 0.47,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Colors.black,
                                    // shape: BoxShape.circle,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     color: Colors.black.withOpacity(0.2),
                                    //     blurRadius: 4,
                                    //     spreadRadius: 1,
                                    //   ),
                                    // ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: AppImage.asset(
                                      zegoProvider.isMicrophoneEnabled
                                          ? "assets/images/microphone.png"
                                          : "assets/images/microphone_off.png",
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // ✅ Special overlay icons for specific seats (when not occupied)
                      if (!isOccupied)
                        if (seat.seatNumber == 15)
                          Positioned(
                            bottom:
                                -2, // Moved slightly outside to avoid overlap
                            right:
                                -4, // Moved more to the right to avoid overlap
                            child: Container(
                              width: seatSize * 0.33,
                              height: seatSize * 0.33,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.grey[700],
                                border: Border.all(
                                  color: const Color(0xFF052E0D),
                                  width: 1.5,
                                ), // Border to separate from seat icon
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: AppImage.asset(
                                  'assets/icons/202.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          )
                        else if (seat.seatNumber == 20)
                          Positioned(
                            bottom:
                                -2, // Moved slightly outside to avoid overlap
                            right:
                                -4, // Moved more to the right to avoid overlap
                            child: Container(
                              width: seatSize * 0.33,
                              height: seatSize * 0.33,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF052E0D),
                                  width: 1.5,
                                ), // Border to separate from seat icon
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: AppImage.asset(
                                  'assets/icons/303.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),

                  /// ---------- SEAT LABEL (User name if occupied) ----------
                  const SizedBox(
                    height: 2,
                  ), // Reduced spacing to prevent overflow
                  Text(
                    isOccupied
                        ? (seat.userName ?? seat.username ?? 'User')
                        : '${seat.seatNumber}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // Widget _buildHeaderSection(Size size, SeatProvider seatProvider) {
  //   return Padding(
  //     padding: EdgeInsets.only(right: size.width * 0.03),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Flexible(
  //           child: Container(
  //             width: size.width * 0.6,
  //             padding: EdgeInsets.symmetric(
  //               horizontal: size.width * 0.03,
  //               vertical: size.height * 0.005,
  //             ),
  //             decoration: BoxDecoration(
  //               color: Colors.black.withOpacity(0.4),
  //               borderRadius: const BorderRadius.only(
  //                 topRight: Radius.circular(30),
  //                 bottomRight: Radius.circular(30),
  //               ),
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Consumer<ProfileUpdateProvider>(
  //                   builder: (context, profileProvider, child) {
  //                     // ✅ Use room profile URL first (if provided), then user profile, then local file, then default
  //                     ImageProvider imageProvider;

  //                     // ✅ Priority 1: Room profile URL (network URL)
  //                     if (widget.roomProfileUrl != null &&
  //                         widget.roomProfileUrl!.isNotEmpty &&
  //                         (widget.roomProfileUrl!.startsWith('http://') ||
  //                             widget.roomProfileUrl!.startsWith('https://'))) {
  //                       imageProvider = NetworkImage(widget.roomProfileUrl!);
  //                     }
  //                     // ✅ Priority 3: Local file (avatarUrl)
  //                     else if (widget.avatarUrl != null &&
  //                         widget.avatarUrl!.existsSync()) {
  //                       imageProvider = FileImage(widget.avatarUrl!);
  //                     }
  //                     // ✅ Priority 4: Default placeholder
  //                     else {
  //                       imageProvider = const AssetImage(
  //                         'assets/images/person.png',
  //                       );
  //                     }

  //                     return CircleAvatar(
  //                       radius: 22,
  //                       backgroundImage: imageProvider,
  //                       onBackgroundImageError: (exception, stackTrace) {
  //                         // ✅ Fallback to placeholder if network image fails
  //                       },
  //                     );
  //                   },
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Flexible(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       InkWell(
  //                         onTap: _runDebugTest,
  //                         child: Text(
  //                           widget.roomName,
  //                           style: const TextStyle(
  //                             color: Colors.red,
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                           overflow: TextOverflow.ellipsis,
  //                           maxLines: 1,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Container(
  //                         padding: EdgeInsets.symmetric(
  //                           horizontal: 12,
  //                           vertical: 4,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.purple.withOpacity(0.3),
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: Text(
  //                           "Room ID: ${widget.roomId}",
  //                           style: const TextStyle(
  //                             fontSize: 12,
  //                             color: Colors.white,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const SizedBox(width: 10),
  //             // GestureDetector(
  //             //   onTap: () => print("👥 Members button pressed"),
  //             //   child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.7), shape: BoxShape.circle), child: Icon(Icons.indeterminate_check_box_rounded, color: Colors.white, size: 22)),
  //             // ),
  //             const SizedBox(width: 10),
  //             GestureDetector(
  //               onTap: _showFullScreenExitDialog,
  //               child: Container(
  //                 padding: const EdgeInsets.all(6),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red.withOpacity(0.7),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Icon(
  //                   Icons.power_settings_new,
  //                   color: Colors.white,
  //                   size: 22,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRoomAdminSection(
  //   Size size,
  //   File? avatarUrl,
  //   SeatProvider seatProvider,
  // ) {
  //   // Count all users in room (whether on seats or not)
  //   final totalUsersInRoom = _usersInRoom.length;
  //   print(
  //     "👥 [RoomScreen] _buildRoomAdminSection - Total users in room: $totalUsersInRoom",
  //   );
  //   print("👥 [RoomScreen] Users list: $_usersInRoom");

  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Wrap(
  //           spacing: 10,
  //           runSpacing: 5,
  //           children: [
  //             InkWell(
  //               onTap: () {
  //                 print("this is the room id ${widget.roomId}");
  //                 final roomIdInt = int.tryParse(widget.roomId);
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) =>
  //                         RoomRankingScreen(roomId: roomIdInt),
  //                   ),
  //                 );
  //               },
  //               child: Container(
  //                 height: 28,
  //                 decoration: BoxDecoration(
  //                   color: Colors.black.withOpacity(0.4),
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //                 child: const Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 8.0),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       CircleAvatar(
  //                         radius: 10,
  //                         backgroundImage: AssetImage(
  //                           'assets/images/mine_family.png',
  //                         ),
  //                       ),
  //                       SizedBox(width: 3),
  //                       Text("0.0m", style: TextStyle(color: Colors.white)),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               height: 28,
  //               decoration: BoxDecoration(
  //                 color: Colors.black.withOpacity(0.4),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: const Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 8.0),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     CircleAvatar(
  //                       radius: 10,
  //                       backgroundImage: AssetImage(
  //                         'assets/images/mine_family.png',
  //                       ),
  //                     ),
  //                     SizedBox(width: 3),
  //                     Text("Notice", style: TextStyle(color: Colors.white)),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             CircleAvatar(
  //               radius: 10,
  //               backgroundImage: avatarUrl != null && avatarUrl.existsSync()
  //                   ? FileImage(avatarUrl)
  //                   : const AssetImage('assets/images/person.png')
  //                         as ImageProvider,
  //             ),
  //             const SizedBox(width: 4),
  //             GestureDetector(
  //               onTap: () {
  //                 _showUsersListBottomSheet(context);
  //               },
  //               child: CircleAvatar(
  //                 backgroundColor: Colors.black.withOpacity(0.4),
  //                 radius: 10,
  //                 child: Center(
  //                   child: Text(
  //                     totalUsersInRoom.toString(),
  //                     style: const TextStyle(color: Colors.white, fontSize: 8),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // // ✅ Show users list bottom sheet
  // void _showUsersListBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return Container(
  //         height: MediaQuery.of(context).size.height * 0.7,
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.only(
  //             topLeft: Radius.circular(20),
  //             topRight: Radius.circular(20),
  //           ),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const SizedBox(height: 10),
  //             // Header
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 16),
  //               child: Text(
  //                 'Online Users',
  //                 style: TextStyle(
  //                   color: Colors.black,
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             // Users list
  //             Expanded(
  //               child: ListView.builder(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16),
  //                 itemCount: _usersInRoom.length,
  //                 itemBuilder: (context, index) {
  //                   // ✅ Get original userId from map key (normalized format)
  //                   final originalUserId = _usersInRoom.keys.elementAt(index);
  //                   final userInfo = _usersInRoom[originalUserId]!;
  //                   final userName =
  //                       userInfo['name'] ?? userInfo['username'] ?? 'User';
  //                   final profileUrl = userInfo['profileUrl'];
  //                   // ✅ Normalize both IDs for comparison
  //                   final normalizedUserId = _normalizeUserId(originalUserId);
  //                   final normalizedCurrentUserId = _normalizeUserId(
  //                     _databaseUserId,
  //                   );
  //                   final isCurrentUser =
  //                       normalizedUserId.isNotEmpty &&
  //                       normalizedCurrentUserId.isNotEmpty &&
  //                       normalizedUserId == normalizedCurrentUserId;
  //                   // ✅ Display userId (normalized, without leading zeros)
  //                   final displayUserId = normalizedUserId.isNotEmpty
  //                       ? normalizedUserId
  //                       : originalUserId;

  //                   return GestureDetector(
  //                     onTap: () {
  //                       // ✅ Close the users list bottom sheet first
  //                       Navigator.pop(context);
  //                       // ✅ Then open the profile bottom sheet with original userId
  //                       _showProfileBottomSheet(
  //                         profileUrl: profileUrl,
  //                         userName: userName,
  //                         userId:
  //                             originalUserId, // Use original userId from map key
  //                       );
  //                     },
  //                     child: Container(
  //                       margin: const EdgeInsets.symmetric(vertical: 4),
  //                       padding: const EdgeInsets.all(12),
  //                       decoration: BoxDecoration(
  //                         color: isCurrentUser
  //                             ? Colors.black.withOpacity(0.2)
  //                             : Colors.black.withOpacity(0.05),
  //                         borderRadius: BorderRadius.circular(12),
  //                         border: isCurrentUser
  //                             ? Border.all(
  //                                 color: Colors.black.withOpacity(0.5),
  //                                 width: 1,
  //                               )
  //                             : null,
  //                       ),
  //                       child: Row(
  //                         children: [
  //                           // Profile image (with frame for current user)
  //                           isCurrentUser
  //                               ? ProfileWithFrame(
  //                                   size: 50,
  //                                   profileUrl: profileUrl,
  //                                   showPlaceholder: true,
  //                                 )
  //                               : CircleAvatar(
  //                                   radius: 25,
  //                                   backgroundImage:
  //                                       profileUrl != null &&
  //                                           profileUrl.isNotEmpty
  //                                       ? NetworkImage(profileUrl)
  //                                       : const AssetImage(
  //                                               'assets/images/person.png',
  //                                             )
  //                                             as ImageProvider,
  //                                   onBackgroundImageError:
  //                                       (exception, stackTrace) {
  //                                         // Handle image load error
  //                                       },
  //                                 ),
  //                           const SizedBox(width: 12),
  //                           // User info
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Row(
  //                                   children: [
  //                                     Flexible(
  //                                       child: Text(
  //                                         userName,
  //                                         style: const TextStyle(
  //                                           color: Colors.black,
  //                                           fontSize: 16,
  //                                           fontWeight: FontWeight.w500,
  //                                         ),
  //                                         overflow: TextOverflow.ellipsis,
  //                                       ),
  //                                     ),
  //                                     if (isCurrentUser) ...[
  //                                       const SizedBox(width: 8),
  //                                       Container(
  //                                         padding: const EdgeInsets.symmetric(
  //                                           horizontal: 6,
  //                                           vertical: 2,
  //                                         ),
  //                                         decoration: BoxDecoration(
  //                                           color: Colors.white,
  //                                           borderRadius: BorderRadius.circular(
  //                                             10,
  //                                           ),
  //                                         ),
  //                                         child: const Text(
  //                                           'You',
  //                                           style: TextStyle(
  //                                             color: Colors.black,
  //                                             fontSize: 10,
  //                                             fontWeight: FontWeight.bold,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ],
  //                                 ),
  //                                 const SizedBox(height: 4),
  //                                 Text(
  //                                   'ID: $displayUserId',
  //                                   style: const TextStyle(
  //                                     color: Colors.black,
  //                                     fontSize: 12,
  //                                   ),
  //                                 ),
  //                                 if (userInfo['country'] != null &&
  //                                     userInfo['country']!.isNotEmpty) ...[
  //                                   const SizedBox(height: 4),
  //                                   Text(
  //                                     'Country: ${userInfo['country']}',
  //                                     style: const TextStyle(
  //                                       color: Colors.black,
  //                                       fontSize: 12,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _buildChairsGrid(Size size, SeatProvider seatProvider) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: size.width * 0.01),
  //     child: seatProvider.isLoading
  //         ? Center(child: CircularProgressIndicator(color: Colors.white))
  //         : seatProvider.seats.isEmpty
  //         ? Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.event_seat, size: 50, color: Colors.white54),
  //                 SizedBox(height: 10),
  //                 Text(
  //                   "No Seats Available",
  //                   style: TextStyle(color: Colors.white, fontSize: 16),
  //                 ),
  //                 SizedBox(height: 5),
  //                 Text(
  //                   "Tap refresh to load seats",
  //                   style: TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //               ],
  //             ),
  //           )
  //         : GridView.builder(
  //             shrinkWrap: true,
  //             physics: const NeverScrollableScrollPhysics(),
  //             itemCount: seatProvider.seats.length,
  //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: 5,
  //               crossAxisSpacing: 16,
  //               mainAxisSpacing: 16,
  //               childAspectRatio: 2 / 3,
  //             ),
  //             itemBuilder: (context, index) {
  //               final seat = seatProvider.seats[index];
  //               return _buildSeatItem(seat, index);
  //             },
  //           ),
  //   );
  // }

  Future<void> _switchSeat(Seat oldSeat, Seat newSeat) async {
    final seatProvider = context.read<SeatProvider>();

    // ✅ Get database user_id instead of Google ID
    final databaseUserId = await _getDatabaseUserId();
    if (databaseUserId == null || databaseUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '❌ Unable to determine user ID. Please try logging in again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print(
      "🔄 Switching: Seat ${oldSeat.seatNumber} → Seat ${newSeat.seatNumber}",
    );

    // ✅ SNACKBAR: SWITCHING SEAT
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Switching to Seat ${newSeat.seatNumber}...'),
          ],
        ),
        duration: Duration(seconds: 10), // Long duration for network delay
      ),
    );

    // Step 1: Leave current seat
    final leaveSuccess = await seatProvider.vacateSeat(
      roomId: widget.roomId,
      userId: databaseUserId,
    );

    if (!leaveSuccess) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to leave current seat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Future.delayed(Duration(milliseconds: 500));

    // Step 2: Join new seat
    final joinSuccess = await seatProvider.occupySeat(
      roomId: widget.roomId,
      userId: databaseUserId,
      seatNumber: newSeat.seatNumber,
    );

    if (joinSuccess) {
      // ✅ SNACKBAR: SWITCH SUCCESS
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Successfully switched to Seat ${newSeat.seatNumber}!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print("✅ User successfully switched to seat ${newSeat.seatNumber}");
    } else {
      // ✅ SNACKBAR: SWITCH FAILED
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to switch seat. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      // ✅ WebSocket automatically updates seats via seat:vacated event
      // No need to manually call getSeats()
    }
  }

  // Widget _buildSeatItem(Seat seat, int index) {
  //   // ✅ Compare with database user ID, not Google ID
  //   // seat.userId is database ID (e.g., "1152"), not Google ID
  //   // Get database user ID for comparison (use stored value or get from SharedPreferences)
  //   // ✅ CRITICAL: Normalize IDs for comparison (handles "100623" vs "00100623")
  //   final currentDatabaseUserId = _databaseUserId;
  //   final seatUserIdNormalized = seat.userId != null
  //       ? UserIdUtils.getNumericValue(seat.userId.toString())?.toString()
  //       : null;
  //   final currentUserIdNormalized = UserIdUtils.getNumericValue(
  //     currentDatabaseUserId,
  //   )?.toString();
  //   final isCurrentUser =
  //       seatUserIdNormalized != null &&
  //       currentUserIdNormalized != null &&
  //       seatUserIdNormalized == currentUserIdNormalized;
  //   final isOccupied = seat.isOccupied;

  //   // ✅ DEBUG: Log seat data for ALL users (not just current user) to diagnose the issue
  //   if (isOccupied) {
  //     print("🖼️ ===== Building seat ${seat.seatNumber} =====");
  //     print("   - Is Current User: $isCurrentUser");
  //     print("   - Seat userId: ${seat.userId}");
  //     print("   - Current Database userId: $currentDatabaseUserId");
  //     print("   - Current Google userId: $_currentUserId");
  //     print("   - Seat username: ${seat.username}");
  //     print("   - Seat userName: ${seat.userName}");
  //     print("   - Seat profileUrl: ${seat.profileUrl}");
  //     print("   - Is Occupied: $isOccupied");
  //     print("   ==========================================");
  //   }

  //   return GestureDetector(
  //     onTap: () => _onSeatTap(seat),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Stack(
  //           alignment: Alignment.center,
  //           clipBehavior: Clip.none,
  //           children: [
  //             // Seat base
  //             Container(
  //               width: 35,
  //               height: 35,
  //               decoration: BoxDecoration(
  //                 image: DecorationImage(
  //                   image: AssetImage('assets/images/yellow_seat.png'),
  //                   fit: BoxFit.cover,
  //                 ),
  //               ),
  //             ),

  //             // ✅ User avatar if occupied - Show profile image with purchased frame
  //             if (isOccupied)
  //               ClipOval(
  //                 child: isCurrentUser
  //                     ? ProfileWithFrame(
  //                         size: 42,
  //                         profileUrl: seat.profileUrl,
  //                         showPlaceholder: true,
  //                         fitToSize:
  //                             true, // ✅ Fit frame within exact size to not disturb seat
  //                       )
  //                     : Container(
  //                         width: 42,
  //                         height: 42,
  //                         decoration: BoxDecoration(
  //                           shape: BoxShape.circle,
  //                           border: Border.all(color: Colors.orange, width: 2),
  //                         ),
  //                         child: CircleAvatar(
  //                           radius: 21,
  //                           backgroundImage: _getProfileImage(
  //                             seat.profileUrl,
  //                             isCurrentUser,
  //                           ),
  //                         ),
  //                       ),
  //               ),

  //             // ✅ Microphone mute/unmute button (only for current user when on seat)
  //             if (isOccupied && isCurrentUser)
  //               Positioned(
  //                 bottom: -8,
  //                 right: -8,
  //                 child: Builder(
  //                   builder: (context) {
  //                     final zegoProvider = Provider.of<ZegoVoiceProvider>(
  //                       context,
  //                       listen: true,
  //                     );
  //                     return GestureDetector(
  //                       onTap: () async {
  //                         // ✅ Get current mic state before toggling
  //                         final currentMicState =
  //                             zegoProvider.isMicrophoneEnabled;

  //                         // ✅ Toggle microphone
  //                         await zegoProvider.toggleMicrophone();

  //                         // ✅ Send mic status to backend (state is now inverted)
  //                         final seatProvider = Provider.of<SeatProvider>(
  //                           context,
  //                           listen: false,
  //                         );
  //                         final databaseUserId = await _getDatabaseUserId();
  //                         if (databaseUserId != null) {
  //                           await seatProvider.sendMicStatus(
  //                             roomId: widget.roomId.toString(),
  //                             userId: databaseUserId,
  //                             isMuted:
  //                                 !currentMicState, // Use previous state (now toggled)
  //                             seatNumber: seat.seatNumber,
  //                           );
  //                         }
  //                       },
  //                       child: Container(
  //                         width: 24,
  //                         height: 24,
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           shape: BoxShape.circle,
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.2),
  //                               blurRadius: 4,
  //                               spreadRadius: 1,
  //                             ),
  //                           ],
  //                         ),
  //                         child: Icon(
  //                           zegoProvider.isMicrophoneEnabled
  //                               ? Icons.mic
  //                               : Icons.mic_off,
  //                           color: zegoProvider.isMicrophoneEnabled
  //                               ? Colors.green
  //                               : Colors.red,
  //                           size: 16,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //           ],
  //         ),

  //         SizedBox(height: 4),

  //         // ✅ Show user name with country flag (matching image design)
  //         if (isOccupied)
  //           Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // ✅ User name with country flag
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Flexible(
  //                     child: Text(
  //                       isCurrentUser
  //                           ? (() {
  //                               try {
  //                                 final profileProvider =
  //                                     Provider.of<ProfileUpdateProvider>(
  //                                       context,
  //                                       listen: false,
  //                                     );
  //                                 return profileProvider.username ?? 'You';
  //                               } catch (e) {
  //                                 return seat.userName ??
  //                                     seat.username ??
  //                                     'You';
  //                               }
  //                             })()
  //                           : (seat.userName ?? seat.username ?? 'User'),
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           )
  //         else
  //           Text(
  //             'Seat ${seat.seatNumber}',
  //             style: TextStyle(
  //               color: Colors.white.withOpacity(0.8),
  //               fontSize: 11,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  void _showProfileBottomSheet({
    required String? profileUrl,
    required String? userName,
    required String? userId,
  }) {
    final currentDatabaseUserId = _databaseUserId;
    final isCurrentUser = userId == currentDatabaseUserId?.toString();

    print("👤 ===== SHOW PROFILE BOTTOM SHEET =====");
    print("👤 User Name: $userName");
    print("👤 User ID: $userId");
    print("👤 Current User ID: $currentDatabaseUserId");
    print("👤 Is Current User: $isCurrentUser");
    print("👤 Profile URL: $profileUrl");

    // ✅ Handle null values
    final displayName = userName ?? 'Unknown User';
    final displayUserId = userId ?? 'Unknown ID';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // ✅ YEH IMPORTANT HAI - Provider ko builder ke andar access karo with listen: true
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: true,
        );
        return RoomBottomSheetContent(
          profileProvider: profileProvider,
          databaseId: _databaseUserId,
          currentDatabaseUserId: currentDatabaseUserId,
          userId: userId,
          userName: userName,
          profileUrl: profileUrl,
          isCurrentUser: isCurrentUser,
          roomId: widget.roomId,
        );

        // final userCountry = profileProvider.country; // Directly updated country

        // print("🎯 ========== BOTTOM SHEET BUILDER ==========");
        // print("🎯 Profile Provider Country: '$userCountry'");
        // print("🎯 =========================================");

        // // ✅ Fetch user levels and tags when bottom sheet opens
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (userId != null && userId.isNotEmpty) {
        //     // profileProvider.fetchUserLevels(userId);
        //     // profileProvider.fetchUserTags(userId);
        //     print(
        //       "📊 [ProfileBottomSheet] Fetching levels and tags for user: $userId",
        //     );
        //   }
        // });

        // return Container(
        //   height: MediaQuery.of(context).size.height * 0.52,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.only(
        //       topLeft: Radius.circular(20),
        //       topRight: Radius.circular(20),
        //     ),
        //   ),
        //   child: Column(
        //     children: [
        //       // ✅ Header
        //       Expanded(
        //         child: SingleChildScrollView(
        //           child: Column(
        //             children: [
        //               SizedBox(height: 20),

        //               // ✅ Profile Picture with Purchased Frame (no border, frame on top)
        //               ClipOval(
        //                 child: ProfileWithFrame(
        //                   size: 70,
        //                   profileUrl: profileUrl,
        //                   showPlaceholder: true,
        //                   userId:
        //                       userId, // ✅ Pass userId to load that user's backpack
        //                 ),
        //               ),

        //               SizedBox(height: 8),

        //               // ✅ User Name with UPDATED COUNTRY FLAG
        //               Row(
        //                 mainAxisAlignment: MainAxisAlignment.center,
        //                 crossAxisAlignment: CrossAxisAlignment.center,
        //                 children: [
        //                   Text(
        //                     displayName,
        //                     style: TextStyle(
        //                       fontSize: 20,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.black,
        //                     ),
        //                   ),
        //                   SizedBox(width: 8),
        //                   if (userCountry != null &&
        //                       userCountry.isNotEmpty) ...[
        //                     Text(
        //                       CountryFlagUtils.getFlagEmoji(userCountry),
        //                       style: TextStyle(fontSize: 16),
        //                     ),
        //                   ],
        //                 ],
        //               ),

        //               SizedBox(height: 8),

        //               // ✅ User Tags Section
        //               Consumer<ProfileUpdateProvider>(
        //                 builder: (context, provider, _) {
        //                   final tags = provider.tags;
        //                   if (tags.isNotEmpty) {
        //                     return Padding(
        //                       padding: const EdgeInsets.symmetric(
        //                         horizontal: 20.0,
        //                       ),
        //                       child: Column(
        //                         crossAxisAlignment: CrossAxisAlignment.start,
        //                         children: [
        //                           Wrap(
        //                             spacing: 8,
        //                             runSpacing: 8,
        //                             alignment: WrapAlignment.center,
        //                             children: tags.map((tag) {
        //                               return Container(
        //                                 padding: const EdgeInsets.symmetric(
        //                                   horizontal: 12,
        //                                   vertical: 6,
        //                                 ),
        //                                 decoration: BoxDecoration(
        //                                   gradient: const LinearGradient(
        //                                     colors: [
        //                                       Color(0xFFFD5BFF),
        //                                       Color(0xFF8C68FF),
        //                                     ],
        //                                     begin: Alignment.topLeft,
        //                                     end: Alignment.bottomRight,
        //                                   ),
        //                                   borderRadius: BorderRadius.circular(
        //                                     20,
        //                                   ),
        //                                   boxShadow: [
        //                                     BoxShadow(
        //                                       color: Colors.purple.withOpacity(
        //                                         0.3,
        //                                       ),
        //                                       blurRadius: 4,
        //                                       offset: const Offset(0, 2),
        //                                     ),
        //                                   ],
        //                                 ),
        //                                 child: Text(
        //                                   tag,
        //                                   style: const TextStyle(
        //                                     color: Colors.white,
        //                                     fontSize: 12,
        //                                     fontWeight: FontWeight.w500,
        //                                   ),
        //                                 ),
        //                               );
        //                             }).toList(),
        //                           ),
        //                           const SizedBox(height: 8),
        //                         ],
        //                       ),
        //                     );
        //                   }
        //                   return const SizedBox.shrink();
        //                 },
        //               ),

        //               SizedBox(height: 8),
        //               if (isCurrentUser) ...[
        //                 // ✅ User ID with current user badge
        //                 Container(
        //                   padding: EdgeInsets.symmetric(
        //                     horizontal: 12,
        //                     vertical: 6,
        //                   ),
        //                   decoration: BoxDecoration(
        //                     color: Colors.grey[200],
        //                     borderRadius: BorderRadius.circular(12),
        //                   ),
        //                   child: Row(
        //                     mainAxisSize: MainAxisSize.min,
        //                     children: [
        //                       Text(
        //                         "ID: $displayUserId",
        //                         style: TextStyle(
        //                           color: Colors.grey[700],
        //                           fontSize: 14,
        //                         ),
        //                       ),
        //                       SizedBox(width: 8),
        //                       Container(
        //                         child: Stack(
        //                           children: [
        //                             // Background Image (lv30_bg.png)
        //                             Container(
        //                               height: 25,
        //                               width: 90,
        //                               padding: EdgeInsets.symmetric(
        //                                 horizontal: 6,
        //                                 vertical: 2,
        //                               ),
        //                               decoration: BoxDecoration(
        //                                 image: DecorationImage(
        //                                   image: AssetImage(
        //                                     'assets/images/lv100_bg.png',
        //                                   ),
        //                                   fit: BoxFit.fill,
        //                                 ),
        //                                 borderRadius: BorderRadius.circular(4),
        //                               ),
        //                               child: Center(
        //                                 child: Consumer<ProfileUpdateProvider>(
        //                                   builder: (context, provider, _) {
        //                                     // ✅ Get the higher of sending or receiving level
        //                                     final receivingLevel =
        //                                         provider
        //                                             .userLevels
        //                                             ?.receiving
        //                                             .currentLevel ??
        //                                         0;

        //                                     // ✅ If levels not loaded yet, show 0 or loading
        //                                     if (provider.userLevels == null &&
        //                                         !provider.isLoading) {
        //                                       return Text(
        //                                         "lvl 0",
        //                                         style: TextStyle(
        //                                           fontSize: 12,
        //                                           color: Colors.white,
        //                                         ),
        //                                       );
        //                                     }

        //                                     return Text(
        //                                       "lvl $receivingLevel",
        //                                       style: TextStyle(
        //                                         fontSize: 12,
        //                                         color: Colors.white,
        //                                       ),
        //                                     );
        //                                   },
        //                                 ),
        //                               ),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),

        //                 SizedBox(height: 16),

        //                 Padding(
        //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
        //                   child: Row(
        //                     children: [
        //                       Expanded(
        //                         child: Container(
        //                           height: 50,
        //                           decoration: BoxDecoration(
        //                             borderRadius: BorderRadius.circular(10),
        //                             image: DecorationImage(
        //                               image: AssetImage(
        //                                 "assets/images/mine_vip.png",
        //                               ),
        //                               fit: BoxFit.cover,
        //                             ),
        //                           ),
        //                         ),
        //                       ),
        //                       SizedBox(width: 8),
        //                       Expanded(
        //                         child: Container(
        //                           height: 50,
        //                           decoration: BoxDecoration(
        //                             borderRadius: BorderRadius.circular(10),
        //                             image: DecorationImage(
        //                               image: AssetImage(
        //                                 "assets/images/mine_earning.png",
        //                               ),
        //                               fit: BoxFit.cover,
        //                             ),
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),

        //                 SizedBox(height: 56),

        //                 // Edit Profile, Follow, and Gift buttons
        //                 Row(
        //                   children: [
        //                     Expanded(
        //                       child: ElevatedButton(
        //                         onPressed: () {
        //                           Navigator.push(
        //                             context,
        //                             MaterialPageRoute(
        //                               builder: (_) => DetailedProfileScreen(),
        //                             ),
        //                           );
        //                         },
        //                         style: ElevatedButton.styleFrom(
        //                           backgroundColor: Colors.green,
        //                           padding: EdgeInsets.symmetric(vertical: 12),
        //                           shape: RoundedRectangleBorder(
        //                             borderRadius: BorderRadius.circular(12),
        //                           ),
        //                         ),
        //                         child: Text(
        //                           "Edit Profile",
        //                           style: TextStyle(
        //                             color: Colors.white,
        //                             fontSize: 14,
        //                             fontWeight: FontWeight.bold,
        //                           ),
        //                         ),
        //                       ),
        //                     ),
        //                     SizedBox(width: 8),
        //                     Expanded(
        //                       child: ElevatedButton(
        //                         onPressed: () {
        //                           print("🎁 Send gift to: $displayName");
        //                           Navigator.pop(context);

        //                           if (userId != null) {
        //                             final seatProvider =
        //                                 Provider.of<SeatProvider>(
        //                                   context,
        //                                   listen: false,
        //                                 );
        //                             try {
        //                               final userSeat = seatProvider.seats
        //                                   .firstWhere(
        //                                     (seat) =>
        //                                         seat.userId == userId &&
        //                                         seat.isOccupied,
        //                                   );

        //                               setState(() {
        //                                 _selectedSeatForGift = userSeat;
        //                               });

        //                               print(
        //                                 "✅ Selected seat ${userSeat.seatNumber} for gift sending",
        //                               );
        //                               _openCategoryBottomSheet(context);
        //                             } catch (e) {
        //                               print("❌ User not on any seat: $e");
        //                               ScaffoldMessenger.of(
        //                                 context,
        //                               ).showSnackBar(
        //                                 SnackBar(
        //                                   content: Text(
        //                                     "$displayName is not on any seat",
        //                                   ),
        //                                   backgroundColor: Colors.orange,
        //                                 ),
        //                               );
        //                             }
        //                           }
        //                         },
        //                         style: ElevatedButton.styleFrom(
        //                           backgroundColor: Colors.orange,
        //                           padding: EdgeInsets.symmetric(vertical: 12),
        //                           shape: RoundedRectangleBorder(
        //                             borderRadius: BorderRadius.circular(12),
        //                           ),
        //                         ),
        //                         child: Icon(
        //                           Icons.card_giftcard,
        //                           color: Colors.white,
        //                           size: 20,
        //                         ),
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //               ] else ...[
        //                 // Other user - show Follow and Gift buttons
        //                 Container(
        //                   padding: EdgeInsets.symmetric(
        //                     horizontal: 12,
        //                     vertical: 6,
        //                   ),
        //                   decoration: BoxDecoration(
        //                     color: Colors.grey[200],
        //                     borderRadius: BorderRadius.circular(12),
        //                   ),
        //                   child: Row(
        //                     mainAxisSize: MainAxisSize.min,
        //                     children: [
        //                       Text(
        //                         "ID: $displayUserId",
        //                         style: TextStyle(
        //                           color: Colors.grey[700],
        //                           fontSize: 14,
        //                         ),
        //                       ),
        //                       SizedBox(width: 8),
        //                       Stack(
        //                         children: [
        //                           // Background Image (lv30_bg.png)
        //                           Container(
        //                             height: 25,
        //                             width: 90,
        //                             padding: EdgeInsets.symmetric(
        //                               horizontal: 6,
        //                               vertical: 2,
        //                             ),
        //                             decoration: BoxDecoration(
        //                               image: DecorationImage(
        //                                 image: AssetImage(
        //                                   'assets/images/lv100_bg.png',
        //                                 ),
        //                                 fit: BoxFit.fill,
        //                               ),
        //                               borderRadius: BorderRadius.circular(4),
        //                             ),
        //                             child: Center(
        //                               child: Consumer<ProfileUpdateProvider>(
        //                                 builder: (context, provider, _) {
        //                                   // ✅ Get the higher of sending or receiving level
        //                                   final receivingLevel =
        //                                       provider
        //                                           .userLevels
        //                                           ?.receiving
        //                                           .currentLevel ??
        //                                       0;

        //                                   // ✅ If levels not loaded yet, show 0 or loading
        //                                   if (provider.userLevels == null &&
        //                                       !provider.isLoading) {
        //                                     return Text(
        //                                       "lvl 0",
        //                                       style: TextStyle(
        //                                         fontSize: 12,
        //                                         color: Colors.white,
        //                                       ),
        //                                     );
        //                                   }

        //                                   return Text(
        //                                     "lvl $receivingLevel",
        //                                     style: TextStyle(
        //                                       fontSize: 12,
        //                                       color: Colors.white,
        //                                     ),
        //                                   );
        //                                 },
        //                               ),
        //                             ),
        //                           ),
        //                         ],
        //                       ),
        //                     ],
        //                   ),
        //                 ),

        //                 SizedBox(height: 12),

        //                 Padding(
        //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
        //                   child: Row(
        //                     children: [
        //                       Expanded(
        //                         child: AppImage.asset(
        //                           "assets/images/mine_vip.png",
        //                           fit: BoxFit.contain,
        //                         ),
        //                       ),
        //                       SizedBox(width: 8),
        //                       Expanded(
        //                         child: AppImage.asset(
        //                           "assets/images/mine_earning.png",
        //                           fit: BoxFit.contain,
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),

        //                 SizedBox(height: 12),

        //                 // Follow button with dynamic state
        //                 Padding(
        //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
        //                   child: Consumer<UserFollowProvider>(
        //                     builder: (context, followProvider, _) {
        //                       final targetUserId = int.tryParse(userId ?? '');
        //                       if (targetUserId == null) {
        //                         return const SizedBox.shrink();
        //                       }

        //                       return FollowButton(
        //                         targetUserId: targetUserId,
        //                         initialIsFollowing: followProvider.isFollowing(
        //                           targetUserId,
        //                         ),
        //                         width: double.infinity,
        //                         height: 48,
        //                         fontSize: 14,
        //                       );
        //                     },
        //                   ),
        //                 ),

        //                 SizedBox(height: 12),

        //                 // ⭐ Messages, Following, and Gift buttons
        //                 Padding(
        //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
        //                   child: Row(
        //                     children: [
        //                       // ⭐ MESSAGES BUTTON - Navigate to chat
        //                       Expanded(
        //                         child: ElevatedButton(
        //                           onPressed: () async {
        //                             print(
        //                               "💬 Opening chat with: $displayName (ID: $userId)",
        //                             );
        //                             Navigator.pop(
        //                               context,
        //                             ); // Close bottom sheet

        //                             // Get chat provider
        //                             final chatProvider =
        //                                 Provider.of<UserChatProvider>(
        //                                   context,
        //                                   listen: false,
        //                                 );

        //                             if (userId != null) {
        //                               final targetUserId = int.tryParse(userId);
        //                               if (targetUserId != null) {
        //                                 // Check if chatroom already exists
        //                                 final existingRoom = chatProvider
        //                                     .getChatroomByUserId(targetUserId);

        //                                 if (existingRoom != null) {
        //                                   // Navigate to existing chat
        //                                   print(
        //                                     "✅ Found existing chatroom: ${existingRoom.id}",
        //                                   );
        //                                   Navigator.push(
        //                                     context,
        //                                     MaterialPageRoute(
        //                                       builder: (context) => ChatScreen(
        //                                         chatRoom: existingRoom,
        //                                       ),
        //                                     ),
        //                                   );
        //                                 } else {
        //                                   // Create new chatroom
        //                                   print(
        //                                     "🆕 Creating new chatroom with user $targetUserId",
        //                                   );
        //                                   await chatProvider.createChatroom(
        //                                     targetUserId,
        //                                   );

        //                                   // Wait a bit for chatroom creation
        //                                   await Future.delayed(
        //                                     Duration(milliseconds: 500),
        //                                   );

        //                                   // Try to get the newly created room
        //                                   final newRoom = chatProvider
        //                                       .getChatroomByUserId(
        //                                         targetUserId,
        //                                       );
        //                                   if (newRoom != null) {
        //                                     Navigator.push(
        //                                       context,
        //                                       MaterialPageRoute(
        //                                         builder: (context) =>
        //                                             ChatScreen(
        //                                               chatRoom: newRoom,
        //                                             ),
        //                                       ),
        //                                     );
        //                                   } else {
        //                                     print(
        //                                       "⚠️ Failed to create chatroom",
        //                                     );
        //                                     ScaffoldMessenger.of(
        //                                       context,
        //                                     ).showSnackBar(
        //                                       SnackBar(
        //                                         content: Text(
        //                                           "Failed to open chat. Please try again.",
        //                                         ),
        //                                         backgroundColor: Colors.red,
        //                                       ),
        //                                     );
        //                                   }
        //                                 }
        //                               }
        //                             }
        //                           },
        //                           style: ElevatedButton.styleFrom(
        //                             backgroundColor: Colors.green,
        //                             padding: EdgeInsets.symmetric(vertical: 12),
        //                             shape: RoundedRectangleBorder(
        //                               borderRadius: BorderRadius.circular(12),
        //                             ),
        //                           ),
        //                           child: Text(
        //                             "Messages",
        //                             style: TextStyle(
        //                               color: Colors.white,
        //                               fontSize: 14,
        //                               fontWeight: FontWeight.bold,
        //                             ),
        //                           ),
        //                         ),
        //                       ),

        //                       SizedBox(width: 8),

        //                       // Following button (placeholder)
        //                       Expanded(
        //                         child: ElevatedButton(
        //                           onPressed: () {
        //                             print(
        //                               "👥 View following for: $displayName",
        //                             );
        //                             // TODO: Implement following screen navigation
        //                           },
        //                           style: ElevatedButton.styleFrom(
        //                             backgroundColor: Colors.blue,
        //                             padding: EdgeInsets.symmetric(vertical: 12),
        //                             shape: RoundedRectangleBorder(
        //                               borderRadius: BorderRadius.circular(12),
        //                             ),
        //                           ),
        //                           child: Text(
        //                             "Following",
        //                             style: TextStyle(
        //                               color: Colors.white,
        //                               fontSize: 14,
        //                               fontWeight: FontWeight.bold,
        //                             ),
        //                           ),
        //                         ),
        //                       ),

        //                       SizedBox(width: 8),

        //                       // Gift button
        //                       Expanded(
        //                         child: ElevatedButton(
        //                           onPressed: () {
        //                             print("🎁 Send gift to: $displayName");
        //                             Navigator.pop(context);

        //                             if (userId != null) {
        //                               final seatProvider =
        //                                   Provider.of<SeatProvider>(
        //                                     context,
        //                                     listen: false,
        //                                   );
        //                               try {
        //                                 final userSeat = seatProvider.seats
        //                                     .firstWhere(
        //                                       (seat) =>
        //                                           seat.userId == userId &&
        //                                           seat.isOccupied,
        //                                     );

        //                                 setState(() {
        //                                   _selectedSeatForGift = userSeat;
        //                                 });

        //                                 print(
        //                                   "✅ Selected seat ${userSeat.seatNumber} for gift sending",
        //                                 );
        //                                 _openCategoryBottomSheet(context);
        //                               } catch (e) {
        //                                 print("❌ User not on any seat: $e");
        //                                 ScaffoldMessenger.of(
        //                                   context,
        //                                 ).showSnackBar(
        //                                   SnackBar(
        //                                     content: Text(
        //                                       "$displayName is not on any seat",
        //                                     ),
        //                                     backgroundColor: Colors.orange,
        //                                   ),
        //                                 );
        //                               }
        //                             }
        //                           },
        //                           style: ElevatedButton.styleFrom(
        //                             backgroundColor: Colors.orange,
        //                             padding: EdgeInsets.symmetric(vertical: 12),
        //                             shape: RoundedRectangleBorder(
        //                               borderRadius: BorderRadius.circular(12),
        //                             ),
        //                           ),
        //                           child: Icon(
        //                             Icons.card_giftcard,
        //                             color: Colors.white,
        //                             size: 20,
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               ],
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // );
      },
    );
  }

  // ✅ New Footer Section Design
  Widget _buildNewFooterSection(
    Size size,
    RoomMessageProvider messageProvider,
    double scale,
  ) {
    void openToolsBottomSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ToolsBottomSheet(
          roomId: widget.roomId,
          userId: _databaseUserId,
          roomName: _displayRoomName,
          roomProfileUrl: _displayRoomProfileUrl,
          onRoomUpdated: (newName, newProfile) {
            setState(() {
              _displayRoomName = newName;
              if (newProfile != null && newProfile.isNotEmpty)
                _displayRoomProfileUrl = newProfile;
            });
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 6 * scale,
      ),
      decoration: const BoxDecoration(color: Color(0xFF052E0D)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left icons group
          Row(
            children: [
              // Chat
              GestureDetector(
                onTap: openChat,
                child: AppImage.asset(
                  'assets/icons/707.png',
                  width: 24 * scale,
                  height: 24 * scale,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 16 * scale),
              // Speaker
              Builder(
                builder: (context) {
                  final zegoProvider = Provider.of<ZegoVoiceProvider>(
                    context,
                    listen: true,
                  );
                  final seatProvider = Provider.of<SeatProvider>(
                    context,
                    listen: false,
                  );

                  final currentUserSeat = seatProvider.seats.firstWhere(
                    (seat) {
                      if (!seat.isOccupied || seat.userId == null) return false;
                      final seatUserId = UserIdUtils.getNumericValue(
                        seat.userId.toString(),
                      )?.toString();
                      final currentUserId = UserIdUtils.getNumericValue(
                        _databaseUserId,
                      )?.toString();
                      return seatUserId != null &&
                          currentUserId != null &&
                          seatUserId == currentUserId;
                    },
                    orElse: () => Seat(
                      seatNumber: 0,
                      isOccupied: false,
                      isReserved: false,
                    ),
                  );

                  final isUserOnSeat = currentUserSeat.isOccupied;

                  return GestureDetector(
                    onTap: isUserOnSeat
                        ? () async {
                            final currentSpeakerState =
                                zegoProvider.isSpeakerEnabled;
                            await zegoProvider.toggleSpeaker();
                            final databaseUserId = await _getDatabaseUserId();
                            if (databaseUserId != null) {
                              await seatProvider.sendMicStatus(
                                roomId: widget.roomId.toString(),
                                userId: databaseUserId,
                                isMuted: !currentSpeakerState,
                                seatNumber: currentUserSeat.seatNumber,
                              );
                            }
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please join a seat first to use speaker',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    child: Opacity(
                      opacity: zegoProvider.isSpeakerEnabled ? 1.0 : 0.5,
                      child: AppImage.asset(
                        'assets/icons/606.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              // Seat
              GestureDetector(
                onTap: () {
                  // TODO: Wire to seat/people action when confirmed
                },
                child: AppImage.asset(
                  'assets/icons/505.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 18),
              // Grid/Menu
              GestureDetector(
                onTap: () {
                  final currentUserId = UserIdUtils.getNumericValue(
                    _databaseUserId,
                  )?.toString();
                  if (widget.roomCreatorId == currentUserId) {
                    openToolsBottomSheet(context);
                  }
                },
                child: AppImage.asset(
                  'assets/icons/404.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          // Center Chat List Navigation
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chat, size: 18, color: Colors.green),
            ),
          ),
          // Right gift button
          GestureDetector(
            onTap: () => _openCategoryBottomSheet(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3FD06D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppImage.asset(
                'assets/icons/303.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(Size size, RoomMessageProvider messageProvider) {
    void openToolsBottomSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ToolsBottomSheet(
          roomId: widget.roomId,
          userId: _databaseUserId,
          roomName: _displayRoomName,
          roomProfileUrl: _displayRoomProfileUrl,
          onRoomUpdated: (newName, newProfile) {
            setState(() {
              _displayRoomName = newName;
              if (newProfile != null && newProfile.isNotEmpty)
                _displayRoomProfileUrl = newProfile;
            });
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.02,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,

              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(20),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black.withOpacity(0.1),
              //       blurRadius: 4,
              //       offset: const Offset(0, 2),
              //     ),
              //   ],
              // ),
              child: Row(
                children: [
                  GestureDetector(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: AppImage.asset(
                        "assets/images/message_send_icon.png",
                        width: 40,
                      ),
                    ),
                    onTap: () {
                      openChat();
                    },
                  ),
                  // Expanded(
                  //   child: TextField(
                  //     controller: _messageController,
                  //     style: const TextStyle(
                  //       color: Colors.black87,
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w400,
                  //     ),
                  //     cursorColor: Colors.blue,
                  //     decoration: const InputDecoration(
                  //       hintText: "Type a message...",
                  //       hintStyle: TextStyle(
                  //         color: Colors.grey,
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w400,
                  //       ),
                  //       contentPadding: EdgeInsets.symmetric(
                  //         horizontal: 16,
                  //         vertical: 12,
                  //       ),
                  //       border: InputBorder.none,
                  //       enabledBorder: InputBorder.none,
                  //       focusedBorder: InputBorder.none,
                  //     ),
                  //     onSubmitted: (_) => _sendMessage(),
                  //   ),
                  // ),

                  // IconButton(
                  //   icon: const Icon(Icons.send, color: Color.fromARGB(255, 172, 155, 57), size: 22),
                  //   onPressed: _sendMessage,
                  //   padding: const EdgeInsets.all(8),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              // GIFT BUTTON
              GestureDetector(
                onTap: () => _openCategoryBottomSheet(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppImage.asset(
                      "assets/images/gift_icon.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),

              //              GestureDetector(
              //   onTap: () async {
              //     final prefs = await SharedPreferences.getInstance();
              //     int? senderId = prefs.getInt('user_id') ?? int.tryParse(_currentUserId ?? '');

              //     if (senderId == null) {
              //       if (mounted) {
              //         showDialog(
              //           context: context,
              //           builder: (context) => AlertDialog(
              //             title: Text("Login Required"),
              //             content: Text("Unable to determine your user ID. Please log in again."),
              //             actions: [
              //               TextButton(
              //                 onPressed: () => Navigator.of(context).pop(),
              //                 child: Text("OK"),
              //               ),
              //             ],
              //           ),
              //         );
              //       }
              //       return;
              //     }

              //     showModalBottomSheet(
              //       context: context,
              //       isScrollControlled: true,
              //       backgroundColor: Colors.transparent,
              //       builder: (context) => Container(
              //         height: MediaQuery.of(context).size.height * 0.9, // almost full screen
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              //         ),
              //         child: LivePage(
              //           senderid: widget.senderId.toString(), // Pass your sender ID
              //           liveID: JoinRoomProvider, // Pass your live stream ID
              //           isHost: false, // Or true if sender is host
              //         ),
              //       ),
              //     );
              //   },

              //   child: Container(
              //     width: 40,
              //     height: 40,
              //     decoration: BoxDecoration(
              //       color: Colors.white60,
              //       shape: BoxShape.circle,
              //     ),
              //     child: Center(
              //       child: Icon(
              //         Icons.card_giftcard_rounded,
              //         color: Colors.white,
              //         size: 22,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(width: 5),
              // TOOLS BUTTON
              GestureDetector(
                onTap: () {
                  final currentUserId = UserIdUtils.getNumericValue(
                    _databaseUserId,
                  )?.toString();
                  if (widget.roomCreatorId == currentUserId) {
                    openToolsBottomSheet(context);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppImage.asset(
                      "assets/images/window_icon.jpg",
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // // Email BUTTON
              // GestureDetector(
              //   onTap: () => _openCategoryBottomSheet(context),
              //   child: Container(
              //     width: 40,
              //     height: 40,
              //     decoration: BoxDecoration(
              //       color: Colors.white60,
              //       shape: BoxShape.circle,
              //     ),
              //     child: Center(
              //       child:
              //       AppImage.asset("assets/images/message_icon.png",width: 40,
              //         height: 40,)

              //     ),
              //   ),
              // ),
              // Game BUTTON
              GestureDetector(
                onTap: () => _showGamesBottomSheet(context),
                child: Container(
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppImage.asset(
                      "assets/images/game_icon.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
              // Volume BUTTON
              const SizedBox(width: 5),
              Builder(
                builder: (context) {
                  final zegoProvider = Provider.of<ZegoVoiceProvider>(
                    context,
                    listen: true,
                  );
                  final seatProvider = Provider.of<SeatProvider>(
                    context,
                    listen: false,
                  );

                  // ✅ Check if current user is on any seat (normalize IDs for comparison)
                  final currentUserSeat = seatProvider.seats.firstWhere(
                    (seat) {
                      if (!seat.isOccupied || seat.userId == null) return false;
                      final seatUserId = UserIdUtils.getNumericValue(
                        seat.userId.toString(),
                      )?.toString();
                      final currentUserId = UserIdUtils.getNumericValue(
                        _databaseUserId,
                      )?.toString();
                      return seatUserId != null &&
                          currentUserId != null &&
                          seatUserId == currentUserId;
                    },
                    orElse: () => Seat(
                      seatNumber: 0,
                      isOccupied: false,
                      isReserved: false,
                    ),
                  );

                  final isUserOnSeat = currentUserSeat.isOccupied;

                  return GestureDetector(
                    onTap: isUserOnSeat
                        ? () async {
                            final currentMicState =
                                zegoProvider.isSpeakerEnabled;

                            // ✅ Toggle microphone
                            await zegoProvider.toggleSpeaker();

                            // ✅ Send mic status to backend
                            final databaseUserId = await _getDatabaseUserId();
                            if (databaseUserId != null) {
                              await seatProvider.sendMicStatus(
                                roomId: widget.roomId.toString(),
                                userId: databaseUserId,
                                isMuted: !currentMicState,
                                seatNumber: currentUserSeat.seatNumber,
                              );
                            }
                          }
                        : () {
                            // ✅ Show message if user is not on a seat
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please join a seat first to use speaker',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    child: Container(
                      width: 40,
                      height: 40,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.black,

                        // isUserOnSeat
                        //         ? (zegoProvider.isSpeakerEnabled
                        //               ? Colors.yellow.withOpacity(0.7)
                        //               : Colors.yellow.withOpacity(0.7))
                        //         : Colors.white60,
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: AppImage.asset(
                            isUserOnSeat
                                ? (zegoProvider.isSpeakerEnabled
                                      ? "assets/images/volume.png"
                                      : "assets/images/volume_off.png")
                                : "assets/images/volume.png",

                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // MICROPHONE BUTTON
              const SizedBox(width: 5),
              Builder(
                builder: (context) {
                  final zegoProvider = Provider.of<ZegoVoiceProvider>(
                    context,
                    listen: true,
                  );
                  final seatProvider = Provider.of<SeatProvider>(
                    context,
                    listen: false,
                  );

                  // ✅ Check if current user is on any seat (normalize IDs for comparison)
                  final currentUserSeat = seatProvider.seats.firstWhere(
                    (seat) {
                      if (!seat.isOccupied || seat.userId == null) return false;
                      final seatUserId = UserIdUtils.getNumericValue(
                        seat.userId.toString(),
                      )?.toString();
                      final currentUserId = UserIdUtils.getNumericValue(
                        _databaseUserId,
                      )?.toString();
                      return seatUserId != null &&
                          currentUserId != null &&
                          seatUserId == currentUserId;
                    },
                    orElse: () => Seat(
                      seatNumber: 0,
                      isOccupied: false,
                      isReserved: false,
                    ),
                  );
                  final isUserOnSeat = currentUserSeat.isOccupied;

                  return GestureDetector(
                    onTap: isUserOnSeat
                        ? () async {
                            // ✅ Get current mic state before toggling
                            final currentMicState =
                                zegoProvider.isMicrophoneEnabled;

                            // ✅ Toggle microphone
                            await zegoProvider.toggleMicrophone();

                            // ✅ Send mic status to backend
                            final databaseUserId = await _getDatabaseUserId();
                            if (databaseUserId != null) {
                              await seatProvider.sendMicStatus(
                                roomId: widget.roomId.toString(),
                                userId: databaseUserId,
                                isMuted: !currentMicState,
                                seatNumber: currentUserSeat.seatNumber,
                              );
                            }
                          }
                        : () {
                            // ✅ Show message if user is not on a seat
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please join a seat first to use microphone',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(100),
                        //  isUserOnSeat
                        //         ? (zegoProvider.isMicrophoneEnabled
                        //               ? Colors.yellow.withOpacity(0.7)
                        //               : Colors.yellow.withOpacity(0.7))
                        //         : Colors.white60,
                        // shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: AppImage.asset(
                            isUserOnSeat
                                ? (zegoProvider.isMicrophoneEnabled
                                      ? "assets/images/microphone.png"
                                      : "assets/images/microphone_off.png")
                                : "assets/images/microphone.png",

                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  // void _showProfileBottomSheet({
  //   required String? profileUrl,
  //   required String? userName,
  //   required String? userId,
  // }) {
  //   final currentDatabaseUserId = _databaseUserId;
  //   final isCurrentUser = userId == currentDatabaseUserId?.toString();

  //   print("👤 ===== SHOW PROFILE BOTTOM SHEET =====");
  //   print("👤 User Name: $userName");
  //   print("👤 User ID: $userId");
  //   print("👤 Current User ID: $currentDatabaseUserId");
  //   print("👤 Is Current User: $isCurrentUser");
  //   print("👤 Profile URL: $profileUrl");

  //   // ✅ Handle null values
  //   final displayName = userName ?? 'Unknown User';
  //   final displayUserId = userId ?? 'Unknown ID';

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (context) {
  //       // ✅ YEH IMPORTANT HAI - Provider ko builder ke andar access karo with listen: true
  //       final profileProvider = Provider.of<ProfileUpdateProvider>(
  //         context,
  //         listen: true,
  //       );
  //       final userCountry = profileProvider.country; // Directly updated country

  //       print("🎯 ========== BOTTOM SHEET BUILDER ==========");
  //       print("🎯 Profile Provider Country: '$userCountry'");
  //       print("🎯 =========================================");

  //       return Container(
  //         height: MediaQuery.of(context).size.height * 0.5,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.only(
  //             topLeft: Radius.circular(20),
  //             topRight: Radius.circular(20),
  //           ),
  //         ),
  //         child: Column(
  //           children: [
  //             // ✅ Header
  //             Expanded(
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   children: [
  //                     SizedBox(height: 20),

  //                     // ✅ Profile Picture
  //                     Container(
  //                       width: 80,
  //                       height: 80,
  //                       decoration: BoxDecoration(
  //                         shape: BoxShape.circle,
  //                         border: Border.all(
  //                           color: isCurrentUser ? Colors.green : Colors.blue,
  //                           width: 3,
  //                         ),
  //                       ),
  //                       child: CircleAvatar(
  //                         radius: 60,
  //                         backgroundImage: _getMessageProfileImage(
  //                           profileUrl,
  //                           isCurrentUser: isCurrentUser,
  //                         ),
  //                       ),
  //                     ),

  //                     SizedBox(height: 8),

  //                     // ✅ User Name with UPDATED COUNTRY FLAG
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       children: [
  //                         Text(
  //                           displayName,
  //                           style: TextStyle(
  //                             fontSize: 20,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.red,
  //                           ),
  //                         ),
  //                         SizedBox(width: 8),
  //                         // ✅ DIRECTLY UPDATED COUNTRY FLAG - Provider se directly
  //                         CountryUtils.getCountryFlag(
  //                           userCountry, // Ye updated country hai
  //                           height: 16,
  //                           width: 16,
  //                         ),
  //                       ],
  //                     ),

  //                     SizedBox(height: 8),
  //                     if (isCurrentUser) ...[
  //                       // ✅ User ID with current user badge
  //                       Container(
  //                         padding: EdgeInsets.symmetric(
  //                           horizontal: 12,
  //                           vertical: 6,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[200],
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         child: Row(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Text(
  //                               "ID: $displayUserId",
  //                               style: TextStyle(
  //                                 color: Colors.grey[700],
  //                                 fontSize: 14,
  //                               ),
  //                             ),
  //                             // if (isCurrentUser) ...[
  //                             SizedBox(width: 8),
  //                             Container(
  //                               // width: 100,
  //                               child: Stack(
  //                                 children: [
  //                                   // Background Image (lv30_bg.png)
  //                                   Container(
  //                                     height: 25,
  //                                     width: 90,
  //                                     padding: EdgeInsets.symmetric(
  //                                       horizontal: 6,
  //                                       vertical: 2,
  //                                     ),
  //                                     decoration: BoxDecoration(
  //                                       image: DecorationImage(
  //                                         image: AssetImage(
  //                                           'assets/images/lv30_bg.png',
  //                                         ),
  //                                         fit: BoxFit.fill,
  //                                       ),
  //                                       borderRadius: BorderRadius.circular(4),
  //                                     ),
  //                                     child: Center(
  //                                       child: Text(
  //                                         "lvl 30",
  //                                         style: TextStyle(
  //                                           fontSize: 12,
  //                                           color: Colors.white,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),

  //                                   Positioned(
  //                                     top: 0, // Adjust according to your design
  //                                     left:
  //                                         0, // Adjust according to your design
  //                                     child: Container(
  //                                       height: 25,
  //                                       width: 25,
  //                                       padding: EdgeInsets.symmetric(
  //                                         horizontal: 6,
  //                                         vertical: 2,
  //                                       ),
  //                                       decoration: BoxDecoration(
  //                                         image: DecorationImage(
  //                                           image: AssetImage(
  //                                             'assets/images/lv30.png',
  //                                           ),
  //                                           fit: BoxFit.cover,
  //                                         ),
  //                                         borderRadius: BorderRadius.circular(
  //                                           4,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),

  //                       SizedBox(height: 16),

  //                       Padding(
  //                         padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //                         child: Row(
  //                           children: [
  //                             Expanded(
  //                               child: Container(
  //                                 height: 50,
  //                                 decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(10),
  //                                   image: DecorationImage(
  //                                     image: AssetImage(
  //                                       "assets/images/mine_vip.png",
  //                                     ),
  //                                     fit: BoxFit.cover,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             SizedBox(width: 8),
  //                             Expanded(
  //                               child: Container(
  //                                 height: 50,
  //                                 decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(10),
  //                                   image: DecorationImage(
  //                                     image: AssetImage(
  //                                       "assets/images/mine_earning.png",
  //                                     ),
  //                                     fit: BoxFit.cover,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),

  //                       SizedBox(height: 56),

  //                       // Edit Profile, Follow, and Gift buttons
  //                       if (isCurrentUser) ...[
  //                         // Current user - show Edit Profile and Gift buttons
  //                       Row(
  //                         children: [
  //                           Expanded(
  //                             child: ElevatedButton(
  //                               onPressed: () {
  //                                 Navigator.push(
  //                                   context,
  //                                   MaterialPageRoute(
  //                                     builder: (_) => DetailedProfileScreen(),
  //                                   ),
  //                                 );
  //                               },
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: Colors.green,
  //                                 padding: EdgeInsets.symmetric(vertical: 12),
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                               ),
  //                               child: Text(
  //                                 "Edit Profile",
  //                                 style: TextStyle(
  //                                   color: Colors.white,
  //                                   fontSize: 14,
  //                                   fontWeight: FontWeight.bold,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           SizedBox(width: 8),
  //                             Expanded(
  //                               child: ElevatedButton(
  //                                 onPressed: () {
  //                                   print("🎁 Send gift to: $displayName");
  //                                   Navigator.pop(context);

  //                                   if (userId != null) {
  //                                     final seatProvider =
  //                                         Provider.of<SeatProvider>(
  //                                           context,
  //                                           listen: false,
  //                                         );
  //                                     try {
  //                                       final userSeat = seatProvider.seats
  //                                           .firstWhere(
  //                                             (seat) =>
  //                                                 seat.userId == userId &&
  //                                                 seat.isOccupied,
  //                                           );

  //                                       setState(() {
  //                                         _selectedSeatForGift = userSeat;
  //                                       });

  //                                       print(
  //                                         "✅ Selected seat ${userSeat.seatNumber} for gift sending",
  //                                       );
  //                                       _openCategoryBottomSheet(context);
  //                                     } catch (e) {
  //                                       print("❌ User not on any seat: $e");
  //                                       ScaffoldMessenger.of(
  //                                         context,
  //                                       ).showSnackBar(
  //                                         SnackBar(
  //                                           content: Text(
  //                                             "$displayName is not on any seat",
  //                                           ),
  //                                           backgroundColor: Colors.orange,
  //                                         ),
  //                                       );
  //                                     }
  //                                   }
  //                                 },
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: Colors.orange,
  //                                   padding: EdgeInsets.symmetric(vertical: 12),
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(12),
  //                                   ),
  //                                 ),
  //                                 child: Icon(
  //                                   Icons.card_giftcard,
  //                                   color: Colors.white,
  //                                   size: 20,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ] else ...[
  //                         // Other user - show Follow and Gift buttons
  //                         Row(
  //                           children: [
  //                             Expanded(
  //                               child: Consumer<UserFollowProvider>(
  //                                 builder: (context, followProvider, _) {
  //                                   final targetUserId = int.tryParse(userId ?? '');
  //                                   if (targetUserId == null) {
  //                                     return const SizedBox.shrink();
  //                                   }

  //                                   return FollowButton(
  //                                     targetUserId: targetUserId,
  //                                     initialIsFollowing: followProvider.isFollowing(targetUserId),
  //                                     width: double.infinity,
  //                                     height: 48,
  //                                     fontSize: 14,
  //                                   );
  //                                 },
  //                               ),
  //                             ),
  //                             SizedBox(width: 8),
  //                           Expanded(
  //                             child: ElevatedButton(
  //                               onPressed: () {
  //                                 print("🎁 Send gift to: $displayName");
  //                                 Navigator.pop(context);

  //                                 if (userId != null) {
  //                                   final seatProvider =
  //                                       Provider.of<SeatProvider>(
  //                                         context,
  //                                         listen: false,
  //                                       );
  //                                   try {
  //                                     final userSeat = seatProvider.seats
  //                                         .firstWhere(
  //                                           (seat) =>
  //                                               seat.userId == userId &&
  //                                               seat.isOccupied,
  //                                         );

  //                                     setState(() {
  //                                       _selectedSeatForGift = userSeat;
  //                                     });

  //                                     print(
  //                                       "✅ Selected seat ${userSeat.seatNumber} for gift sending",
  //                                     );
  //                                     _openCategoryBottomSheet(context);
  //                                   } catch (e) {
  //                                     print("❌ User not on any seat: $e");
  //                                     ScaffoldMessenger.of(
  //                                       context,
  //                                     ).showSnackBar(
  //                                       SnackBar(
  //                                         content: Text(
  //                                           "$displayName is not on any seat",
  //                                         ),
  //                                         backgroundColor: Colors.orange,
  //                                       ),
  //                                     );
  //                                   }
  //                                 }
  //                               },
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: Colors.orange,
  //                                 padding: EdgeInsets.symmetric(vertical: 12),
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.card_giftcard,
  //                                 color: Colors.white,
  //                                 size: 20,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       ],
  //                     ],
  //                     // Rest of your existing code...
  //                     Column(
  //                       children: [
  //                         // if (!isCurrentUser) ...[
  //                         //   // Your existing code for other users...
  //                         // ],
  //                         if (!isCurrentUser) ...[
  //                           Container(
  //                             padding: EdgeInsets.symmetric(
  //                               horizontal: 12,
  //                               vertical: 6,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[200],
  //                               borderRadius: BorderRadius.circular(12),
  //                             ),
  //                             child: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Text(
  //                                   "ID: $displayUserId",
  //                                   style: TextStyle(
  //                                     color: Colors.grey[700],
  //                                     fontSize: 14,
  //                                   ),
  //                                 ),
  //                                 // if (!isCurrentUser) ...[
  //                                 SizedBox(width: 8),
  //                                 Container(
  //                                   // width: 100,
  //                                   child: Stack(
  //                                     children: [
  //                                       // Background Image (lv30_bg.png)
  //                                       Container(
  //                                         height: 25,
  //                                         width: 90,
  //                                         padding: EdgeInsets.symmetric(
  //                                           horizontal: 6,
  //                                           vertical: 2,
  //                                         ),
  //                                         decoration: BoxDecoration(
  //                                           image: DecorationImage(
  //                                             image: AssetImage(
  //                                               'assets/images/lv30_bg.png',
  //                                             ),
  //                                             fit: BoxFit.fill,
  //                                           ),
  //                                           borderRadius: BorderRadius.circular(
  //                                             4,
  //                                           ),
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             "lvl 30",
  //                                             style: TextStyle(
  //                                               fontSize: 12,
  //                                               color: Colors.white,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),

  //                                       Positioned(
  //                                         top:
  //                                             0, // Adjust according to your design
  //                                         left:
  //                                             0, // Adjust according to your design
  //                                         child: Container(
  //                                           height: 25,
  //                                           width: 25,
  //                                           padding: EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             image: DecorationImage(
  //                                               image: AssetImage(
  //                                                 'assets/images/lv30.png',
  //                                               ),
  //                                               fit: BoxFit.cover,
  //                                             ),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(4),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),

  //                                 // ],
  //                               ],
  //                             ),
  //                           ),
  //                           SizedBox(height: 16),

  //                           Padding(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 10.0,
  //                             ),
  //                             child: Row(
  //                               children: [
  //                                 Expanded(
  //                                   child: Container(
  //                                     height: 50,
  //                                     decoration: BoxDecoration(
  //                                       borderRadius: BorderRadius.circular(10),
  //                                       image: DecorationImage(
  //                                         image: AssetImage(
  //                                           "assets/images/mine_vip.png",
  //                                         ),
  //                                         fit: BoxFit.cover,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 SizedBox(width: 8),
  //                                 Expanded(
  //                                   child: Container(
  //                                     height: 50,
  //                                     decoration: BoxDecoration(
  //                                       borderRadius: BorderRadius.circular(10),
  //                                       image: DecorationImage(
  //                                         image: AssetImage(
  //                                           "assets/images/mine_earning.png",
  //                                         ),
  //                                         fit: BoxFit.cover,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),

  //                           SizedBox(height: 56),

  //                           // Edit Profile and Gift buttons
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: ElevatedButton(
  //                                   onPressed: () {

  //                                   },
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: Colors.green,
  //                                     padding: EdgeInsets.symmetric(
  //                                       vertical: 12,
  //                                     ),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(12),
  //                                     ),
  //                                   ),
  //                                   child: Text(
  //                                     "Messages",
  //                                     style: TextStyle(
  //                                       color: Colors.white,
  //                                       fontSize: 14,
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),

  //                               SizedBox(width: 8),

  //                                Expanded(
  //                                 child: ElevatedButton(
  //                                   onPressed: () {

  //                                   },
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: Colors.blue,
  //                                     padding: EdgeInsets.symmetric(
  //                                       vertical: 12,
  //                                     ),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(12),
  //                                     ),
  //                                   ),
  //                                   child: Text(
  //                                     "Following",
  //                                     style: TextStyle(
  //                                       color: Colors.white,
  //                                       fontSize: 14,
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                                  SizedBox(width: 8),

  //                               Expanded(
  //                                 child: ElevatedButton(
  //                                   onPressed: () {
  //                                     print("🎁 Send gift to: $displayName");
  //                                     Navigator.pop(context);

  //                                     if (userId != null) {
  //                                       final seatProvider =
  //                                           Provider.of<SeatProvider>(
  //                                             context,
  //                                             listen: false,
  //                                           );
  //                                       try {
  //                                         final userSeat = seatProvider.seats
  //                                             .firstWhere(
  //                                               (seat) =>
  //                                                   seat.userId == userId &&
  //                                                   seat.isOccupied,
  //                                             );

  //                                         setState(() {
  //                                           _selectedSeatForGift = userSeat;
  //                                         });

  //                                         print(
  //                                           "✅ Selected seat ${userSeat.seatNumber} for gift sending",
  //                                         );
  //                                         _openCategoryBottomSheet(context);
  //                                       } catch (e) {
  //                                         print("❌ User not on any seat: $e");
  //                                         ScaffoldMessenger.of(
  //                                           context,
  //                                         ).showSnackBar(
  //                                           SnackBar(
  //                                             content: Text(
  //                                               "$displayName is not on any seat",
  //                                             ),
  //                                             backgroundColor: Colors.orange,
  //                                           ),
  //                                         );
  //                                       }
  //                                     }
  //                                   },
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: Colors.orange,
  //                                     padding: EdgeInsets.symmetric(
  //                                       vertical: 12,
  //                                     ),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(12),
  //                                     ),
  //                                   ),
  //                                   child: Icon(
  //                                     Icons.card_giftcard,
  //                                     color: Colors.white,
  //                                     size: 20,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildMessageBubble(
    SendMessageRoomModel message,
    ProfileUpdateProvider profileProvider,
  ) {
    final currentDatabaseUserId = _databaseUserId;
    final isCurrentUser =
        message.userId != 'system' &&
        (message.userId == currentDatabaseUserId ||
            message.userId == profileProvider.userId);

    print("💬 ===== MESSAGE BUBBLE DEBUG =====");
    print("💬 Message User ID: ${message.userId}");
    print("💬 Current User ID: $currentDatabaseUserId");
    print("💬 Is Current User: $isCurrentUser");
    print("💬 Message User Name: ${message.userName ?? 'NULL'}");
    print("💬 Message Profile URL: ${message.profileUrl ?? 'NULL'}");
    if (message.userName == null ||
        message.userName!.isEmpty ||
        message.userName == 'User') {
      print("⚠️ ISSUE: Username is missing or generic!");
    }
    if (message.profileUrl == null || message.profileUrl!.isEmpty) {
      print("⚠️ ISSUE: Profile URL is missing!");
    }
    print("💬 ================================");

    // ✅ Lucky congratulations message - golden background like the old overlay
    final isLuckyCongratulations =
        message.message.toLowerCase().contains('lucky gift event') &&
        message.message.toLowerCase().contains('congratulations');
    if (isLuckyCongratulations) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0x996A4B00),
                  Color(0x99FFE08A),
                  Color(0x999E6B00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xCCFFD700), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ✅ System messages ke liye
    if (message.userId == 'system') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B3A16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'System: ',
                style: TextStyle(
                  color: Color(0xFF7CFF8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: message.message,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ USER MESSAGE WITH TITLE (USERNAME) & SUBTITLE (MESSAGE)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image - CLICKABLE (with frame for current user)
          GestureDetector(
            onTap: () {
              print("🖱️ PROFILE IMAGE TAPPED!");
              print("🖱️ Tapped user: ${message.userName}");
              print("🖱️ Tapped user ID: ${message.userId}");
              _showProfileBottomSheet(
                profileUrl: message.profileUrl,
                userName: message.userName,
                userId: message.userId,
              );
            },
            child:
                //  ProfileWithFrame(
                //                      // userId: message.userId,
                //                         size: 35,
                //                         profileUrl: message.profileUrl,
                //                         showPlaceholder: true,
                //                       ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.transparent,

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox.expand(
                      child: cachedImage(
                        _getMessageProfileImage(
                          message.profileUrl,
                          isCurrentUser: isCurrentUser,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
          ),
          const SizedBox(width: 10),

          // Message Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ TITLE: Username + Badges Row
                Row(
                  children: [
                    // Username with color (TITLE)
                    Text(
                      message.userName ?? 'User', // ✅ TITLE - USERNAME
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Badges/Icons
                    ..._getUserBadges(message).map(
                      (iconPath) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AppImage.asset(
                          iconPath,
                          width: 18,
                          height: 18,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ✅ SUBTITLE: Message Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3A16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsernameColor(String userId) {
    // Different users ko different colors
    final colors = [
      const Color(0xFF00D9FF), // Cyan
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFFFFA500), // Orange
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF4444), // Red
      const Color(0xFFFFD700), // Gold
      const Color(0xFF9D4EDD), // Purple
    ];

    // User ID ke hash se color select karo
    final index = userId.hashCode % colors.length;
    return colors[index.abs()];
  }

  // ============================================
  // HELPER METHOD - User Badges
  // ============================================

  List<String> _getUserBadges(SendMessageRoomModel message) {
    // ✅ Tumhare API se badges aayenge
    // Yeh example hai, apne logic se replace karo

    List<String> badges = [];

    // Example: If user has specific level or membership
    // if (message.userLevel != null && message.userLevel > 10) {
    //   badges.add('assets/icons/level_badge.png');
    // }

    // if (message.isMember == true) {
    //   badges.add('assets/icons/member_badge.png');
    // }

    // if (message.isVip == true) {
    //   badges.add('assets/icons/vip_badge.png');
    // }

    // Temporary: Add some default badges for testing
    badges.add('assets/images/lvl30_bg.png');
    badges.add('assets/images/lvl30_bg.png');

    return badges;
  }

  Widget _buildMessagesSection(
    Size size,
    ProfileUpdateProvider profileProvider,
    RoomMessageProvider messageProvider,
  ) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Column(
            children: [
              messageProvider.isLoading
                  ?
                    // Header with loading indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (messageProvider.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),

              //  Padding(padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 5),child: Row(children: [

              // Expanded(child:Container(
              //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              //               decoration: BoxDecoration(
              //                 color: Colors.grey[800]!.withOpacity(0.7),
              //                 borderRadius: BorderRadius.circular(16),
              //               ),
              //               child: Text(
              //                 "This platform is for chatting and making friends. If the room name, cover, content, and comments contain vulgarity, temptation, and politics, etc., you will be punished; beware of fraudulent behavior such as depositing value on behalf of you, protect property safety, and avoid losses. Inspectors conduct 24 hour online inspections.",
              //                 style: const TextStyle(
              //                   color: Colors.white,
              //                   fontSize: 12,
              //                   fontStyle: FontStyle.italic,
              //                 ),
              //               ),
              //             ),),
              // ]),),
              // Messages List
              Expanded(
                child: Builder(
                  builder: (context) {
                    final allMessages = messageProvider.messages;

                    // ✅ Filter messages based on selected tab
                    // Note: Gift messages are handled separately via GiftDisplayProvider
                    // So "Gift" tab will show empty or we can show gift notifications
                    final filteredMessages = _selectedMessageTab == 0
                        ? allMessages // All: Show all messages
                        : _selectedMessageTab == 1
                        ? allMessages
                              .where((m) {
                                // Show all messages except system messages
                                // BUT allow "joined seat", "left seat", "joined room" messages
                                if (m.userId == 'system' &&
                                    m.isSystemMessage != true) {
                                  return false; // Hide pure system messages
                                }
                                final msg = m.message.toLowerCase();
                                if (msg.contains('joined seat') ||
                                    msg.contains('left seat') ||
                                    msg.contains('joined the room') ||
                                    msg.contains('left the room')) {
                                  return true; // Always show seat/room join/leave messages
                                }
                                return true; // Show all other messages
                              })
                              .toList() // Message: Show all non-system messages + seat/room messages
                        : <
                            SendMessageRoomModel
                          >[]; // Gift: Gift messages are handled via animations, not in message list

                    if (messageProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (filteredMessages.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedMessageTab == 0
                              ? "No messages yet\nStart the conversation!"
                              : _selectedMessageTab == 1
                              ? "No messages yet"
                              : "No gifts yet",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return Consumer<StoreProvider>(
                      builder: (context, storeProvider, _) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          reverse: true,
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final message = filteredMessages[index];
                            return _buildMessageBubble(
                              message,
                              profileProvider,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildFooterSection(Size size, RoomMessageProvider messageProvider) {
  //   void openToolsBottomSheet(BuildContext context) {
  //     showModalBottomSheet(
  //       context: context,
  //       backgroundColor: Colors.transparent,
  //       isScrollControlled: true,
  //       builder: (context) => const ToolsBottomSheet(),
  //     );
  //   }

  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: size.width * 0.04,
  //       vertical: 10,
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Container(
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.1),
  //                   blurRadius: 4,
  //                   offset: const Offset(0, 2),
  //                 ),
  //               ],
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: TextField(
  //                     controller: _messageController,
  //                     style: const TextStyle(
  //                       color: Colors.black87,
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w400,
  //                     ),
  //                     cursorColor: Colors.blue,
  //                     decoration: const InputDecoration(
  //                       hintText: "Type a message...",
  //                       hintStyle: TextStyle(
  //                         color: Colors.grey,
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w400,
  //                       ),
  //                       contentPadding: EdgeInsets.symmetric(
  //                         horizontal: 16,
  //                         vertical: 12,
  //                       ),
  //                       border: InputBorder.none,
  //                       enabledBorder: InputBorder.none,
  //                       focusedBorder: InputBorder.none,
  //                     ),
  //                     onSubmitted: (_) => _sendMessage(),
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: const Icon(Icons.send, color: Colors.blue, size: 22),
  //                   onPressed: _sendMessage,
  //                   padding: const EdgeInsets.all(8),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         Row(
  //           children: [
  //             // TOOLS BUTTON
  //             GestureDetector(
  //               onTap: () => openToolsBottomSheet(context),
  //               child: Container(
  //                 width: 40,
  //                 height: 40,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white60,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Center(
  //                   child: SvgPicture.asset(
  //                     'assets/svg/window_icon.svg',
  //                     width: 20,
  //                     height: 20,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 10),
  //             // GIFT BUTTON
  //             GestureDetector(
  //               onTap: () => _openCategoryBottomSheet(context),
  //               child: Container(
  //                 width: 40,
  //                 height: 40,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white60,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Center(
  //                   child: Icon(
  //                     Icons.card_giftcard_rounded,
  //                     color: Colors.white,
  //                     size: 22,
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             //              GestureDetector(
  //             //   onTap: () async {
  //             //     final prefs = await SharedPreferences.getInstance();
  //             //     int? senderId = prefs.getInt('user_id') ?? int.tryParse(_currentUserId ?? '');

  //             //     if (senderId == null) {
  //             //       if (mounted) {
  //             //         showDialog(
  //             //           context: context,
  //             //           builder: (context) => AlertDialog(
  //             //             title: Text("Login Required"),
  //             //             content: Text("Unable to determine your user ID. Please log in again."),
  //             //             actions: [
  //             //               TextButton(
  //             //                 onPressed: () => Navigator.of(context).pop(),
  //             //                 child: Text("OK"),
  //             //               ),
  //             //             ],
  //             //           ),
  //             //         );
  //             //       }
  //             //       return;
  //             //     }

  //             //     showModalBottomSheet(
  //             //       context: context,
  //             //       isScrollControlled: true,
  //             //       backgroundColor: Colors.transparent,
  //             //       builder: (context) => Container(
  //             //         height: MediaQuery.of(context).size.height * 0.9, // almost full screen
  //             //         decoration: BoxDecoration(
  //             //           color: Colors.white,
  //             //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //             //         ),
  //             //         child: LivePage(
  //             //           senderid: widget.senderId.toString(), // Pass your sender ID
  //             //           liveID: JoinRoomProvider, // Pass your live stream ID
  //             //           isHost: false, // Or true if sender is host
  //             //         ),
  //             //       ),
  //             //     );
  //             //   },

  //             //   child: Container(
  //             //     width: 40,
  //             //     height: 40,
  //             //     decoration: BoxDecoration(
  //             //       color: Colors.white60,
  //             //       shape: BoxShape.circle,
  //             //     ),
  //             //     child: Center(
  //             //       child: Icon(
  //             //         Icons.card_giftcard_rounded,
  //             //         color: Colors.white,
  //             //         size: 22,
  //             //       ),
  //             //     ),
  //             //   ),
  //             // ),
  //             const SizedBox(width: 10),
  //             GestureDetector(
  //               onTap: () => _openCategoryBottomSheet(context),
  //               child: Container(
  //                 width: 40,
  //                 height: 40,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white60,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Center(
  //                   child: Icon(
  //                     Icons.card_giftcard_rounded,
  //                     color: Colors.white,
  //                     size: 22,
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             // MICROPHONE BUTTON
  //             const SizedBox(width: 10),
  //             Builder(
  //               builder: (context) {
  //                 final zegoProvider = Provider.of<ZegoVoiceProvider>(
  //                   context,
  //                   listen: true,
  //                 );
  //                 final seatProvider = Provider.of<SeatProvider>(
  //                   context,
  //                   listen: false,
  //                 );

  //                 // ✅ Check if current user is on any seat (normalize IDs for comparison)
  //                 final currentUserSeat = seatProvider.seats.firstWhere(
  //                   (seat) {
  //                     if (!seat.isOccupied || seat.userId == null) return false;
  //                     final seatUserId = UserIdUtils.getNumericValue(
  //                       seat.userId.toString(),
  //                     )?.toString();
  //                     final currentUserId = UserIdUtils.getNumericValue(
  //                       _databaseUserId,
  //                     )?.toString();
  //                     return seatUserId != null &&
  //                         currentUserId != null &&
  //                         seatUserId == currentUserId;
  //                   },
  //                   orElse: () => Seat(
  //                     seatNumber: 0,
  //                     isOccupied: false,
  //                     isReserved: false,
  //                   ),
  //                 );

  //                 final isUserOnSeat = currentUserSeat.isOccupied;

  //                 return GestureDetector(
  //                   onTap: isUserOnSeat
  //                       ? () async {
  //                           // ✅ Get current mic state before toggling
  //                           final currentMicState =
  //                               zegoProvider.isMicrophoneEnabled;

  //                           // ✅ Toggle microphone
  //                           await zegoProvider.toggleMicrophone();

  //                           // ✅ Send mic status to backend
  //                           final databaseUserId = await _getDatabaseUserId();
  //                           if (databaseUserId != null) {
  //                             await seatProvider.sendMicStatus(
  //                               roomId: widget.roomId.toString(),
  //                               userId: databaseUserId,
  //                               isMuted: !currentMicState,
  //                               seatNumber: currentUserSeat.seatNumber,
  //                             );
  //                           }
  //                         }
  //                       : () {
  //                           // ✅ Show message if user is not on a seat
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             SnackBar(
  //                               content: Text(
  //                                 'Please join a seat first to use microphone',
  //                               ),
  //                               backgroundColor: Colors.orange,
  //                               duration: Duration(seconds: 2),
  //                             ),
  //                           );
  //                         },
  //                   child: Container(
  //                     width: 40,
  //                     height: 40,
  //                     decoration: BoxDecoration(
  //                       color: isUserOnSeat
  //                           ? (zegoProvider.isMicrophoneEnabled
  //                                 ? Colors.green.withOpacity(0.7)
  //                                 : Colors.red.withOpacity(0.7))
  //                           : Colors.white60,
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: Center(
  //                       child: Icon(
  //                         isUserOnSeat
  //                             ? (zegoProvider.isMicrophoneEnabled
  //                                   ? Icons.mic
  //                                   : Icons.mic_off)
  //                             : Icons.mic,
  //                         color: Colors.white,
  //                         size: 22,
  //                       ),
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _openCategoryBottomSheet(BuildContext context) async {
    // ✅ FIRST: Try to get user_id from SharedPreferences (actual database ID)
    final prefs = await SharedPreferences.getInstance();
    int? senderId;

    // Try to get user_id (database ID) first
    dynamic userIdValue = prefs.get('user_id');
    print(
      "🔍 Checking user_id from SharedPreferences: $userIdValue (Type: ${userIdValue?.runtimeType})",
    );

    if (userIdValue != null) {
      if (userIdValue is int) {
        senderId = userIdValue;
        print("✅ Found user_id as int: $senderId");
      } else if (userIdValue is String) {
        senderId = int.tryParse(userIdValue);
        print("✅ Found user_id as string: $userIdValue -> $senderId");
      }
    }

    // ✅ If user_id not found, try to parse _currentUserId (might be Google ID)
    if (senderId == null && _currentUserId != null) {
      print(
        "⚠️ user_id not found, trying to parse _currentUserId: $_currentUserId",
      );
      senderId = int.tryParse(_currentUserId!);
      if (senderId == null) {
        print("❌ Failed to parse _currentUserId as int (might be Google ID)");
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Login Required"),
              content: const Text(
                "Unable to determine your user ID. Please try logging in again.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return; // Exit early if we can't determine sender ID
      }
    }

    if (senderId == null) {
      print("❌ Could not determine sender ID");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Login Required"),
            content: const Text("Please login to send gifts."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Get room ID as integer
    int? roomId = int.tryParse(widget.roomId);

    // ✅ NEW FLOW: Allow opening gift sheet WITHOUT receiver
    // User will select receiver from the list after selecting a gift
    int? receiverId;

    // ✅ Try to get receiver ID from selected seat (if user tapped on a seat first)
    try {
      final seatProvider = Provider.of<SeatProvider>(context, listen: false);

      // ✅ Update _selectedSeatForGift with fresh data from seats list
      if (_selectedSeatForGift != null) {
        final originalUserId = _selectedSeatForGift!.userId;
        final originalUserName = _selectedSeatForGift!.userName;

        final updatedSeat = seatProvider.seats.firstWhere(
          (s) => s.seatNumber == _selectedSeatForGift!.seatNumber,
          orElse: () => _selectedSeatForGift!,
        );

        if (updatedSeat.userId == null || updatedSeat.userId!.isEmpty) {
          _selectedSeatForGift = Seat(
            seatNumber: updatedSeat.seatNumber,
            isOccupied: updatedSeat.isOccupied,
            isReserved: updatedSeat.isReserved,
            userId: originalUserId,
            username: updatedSeat.username ?? originalUserName,
            userName: updatedSeat.userName ?? originalUserName,
            profileUrl: updatedSeat.profileUrl,
          );
        } else {
          _selectedSeatForGift = updatedSeat;
        }
      }

      // ✅ If we have a selected seat, try to get receiver ID from it
      if (_selectedSeatForGift != null &&
          _selectedSeatForGift!.isOccupied &&
          _selectedSeatForGift!.userId != null &&
          _selectedSeatForGift!.userId!.isNotEmpty) {
        receiverId = int.tryParse(_selectedSeatForGift!.userId!);

        if (receiverId == null) {
          // Try to get from SharedPreferences or API
          final receiverUserIdValue = prefs.get(
            'user_id_${_selectedSeatForGift!.userId}',
          );
          if (receiverUserIdValue != null) {
            if (receiverUserIdValue is int) {
              receiverId = receiverUserIdValue;
            } else if (receiverUserIdValue is String) {
              receiverId = int.tryParse(receiverUserIdValue);
            }
          }
        }

        if (receiverId != null) {
          print("✅ Pre-selected receiver ID from seat: $receiverId");
        }
      }
    } catch (e) {
      print("⚠️ Could not get receiver from selected seat: $e");
    }

    // ✅ NEW: Allow opening gift sheet WITHOUT receiver
    // The user will select receiver(s) from the user list after selecting a gift
    // receiverId can be null - CategoryBottomSheet will handle user selection

    if (!mounted) return;

    print("✅ Opening gift sheet (receiver will be selected from user list)");
    print("   - Sender ID: $senderId");
    print(
      "   - Pre-selected Receiver ID: ${receiverId ?? 'None (will select from list)'}",
    );
    print("   - Room ID: $roomId");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CategoryBottomSheet(
        senderId: senderId,
        receiverId: receiverId, // ✅ Can be null - user will select from list
        roomId: roomId,
      ),
    );
  }

  ImageProvider _getUserAvatarProvider(String? profileUrl) {
    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (profileUrl.startsWith('http://') ||
          profileUrl.startsWith('https://')) {
        return CachedNetworkImageProvider(profileUrl);
      }

      try {
        final file = File(profileUrl);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {
        // Fallback below
      }
    }

    return const AssetImage('assets/images/person.png');
  }

  Widget _buildExitDialog(Size size, LeaveRoomProvider leaveProvider) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    leaveProvider.setShowExitDialog(false);
                    _leaveRoom(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    fixedSize: const Size(96, 96),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: ClipOval(
                    child: AppImage.asset(
                      'assets/images/leave.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => leaveProvider.setShowExitDialog(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    fixedSize: const Size(96, 96),
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: ClipOval(
                    child: AppImage.asset(
                      'assets/images/minimize.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => leaveProvider.setShowExitDialog(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementPopup(Size size) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _showAnnouncement ? 1 : 0,
            child: Container(
              width: size.width * 0.8,
              height: size.height * 0.3,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color.fromARGB(255, 87, 79, 34)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Announcement",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.topic.isNotEmpty
                            ? widget.topic
                            : "Welcome to the room!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() => _showAnnouncement = false),
                    child: const Text(
                      "All right",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
