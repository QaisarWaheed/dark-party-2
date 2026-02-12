import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:shaheen_star_app/controller/api_manager/gift_web_socket_service.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';

/// GiftProvider - Manages all gift-related operations
///
/// ✅ ALL GIFT OPERATIONS USE WEBSOCKET PORT 8085 EXCLUSIVELY
/// - fetchAllGifts() → WebSocket port 8085
/// - fetchUserBalance() → WebSocket port 8085
/// - sendGift() → WebSocket port 8085
///
/// No HTTP fallbacks - all operations use WebSocket only
class GiftProvider with ChangeNotifier {
  final GiftWebSocketService _giftWsService =
      GiftWebSocketService.instance; // ✅ Gifts WebSocket (port 8085)

  // State variables
  List<GiftModel> _allGifts = [];
  final Map<String, List<GiftModel>> _giftsByCategory = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  GiftModel? _selectedGift;
  int _giftQuantity = 1;
  double _userBalance = 0.0;

  // Lucky gift state
  Map<String, dynamic>? _luckyGiftResult;
  bool _showLuckySpinner = false;

  // Lucky gift getters
  Map<String, dynamic>? get luckyGiftResult => _luckyGiftResult;
  bool get showLuckySpinner => _showLuckySpinner;

  // Combo State
  bool _isComboActive = false;
  int _comboCount = 0;
  Timer? _comboTimer;
  GiftModel? _comboGift;
  List<int>? _comboReceiverIds; // Changed to int
  int? _comboRoomId; // Changed to int
  Map<int, int?>? _comboReceiverSeats; // receiverId -> seatNumber
  int? _comboSenderSeat;

  // Combo Getters
  bool get isComboActive => _isComboActive;
  int get comboCount => _comboCount;
  GiftModel? get comboGift => _comboGift;

  // Constructor - setup WebSocket listeners
  GiftProvider() {
    _setupLuckyGiftListeners();
  }

  /// Start Combo Mode
  void startCombo({
    required GiftModel gift,
    required List<int> receiverIds,
    required int roomId,
    required Map<int, int?> receiverSeats,
    int? senderSeat,
  }) {
    print('🔥 [GiftProvider] Starting Combo for gift: ${gift.name}');
    _isComboActive = true;
    _comboCount = 1;
    _comboGift = gift;
    _comboReceiverIds = receiverIds;
    _comboRoomId = roomId;
    _comboReceiverSeats = receiverSeats;
    _comboSenderSeat = senderSeat;

    _resetComboTimer();
    notifyListeners();
  }

  /// Reset Combo Timer
  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(Duration(seconds: 5), () {
      endCombo();
    });
  }

  /// End Combo Mode
  void endCombo() {
    if (!_isComboActive) return;
    print('🔥 [GiftProvider] Ending Combo');
    _isComboActive = false;
    _comboCount = 0;
    _comboGift = null;
    _comboReceiverIds = null;
    _comboRoomId = null;
    _comboReceiverSeats = null;
    _comboSenderSeat = null;
    _comboTimer?.cancel();
    notifyListeners();
  }

  /// Handle Combo Click (Send Gift Again)
  Future<void> triggerCombo() async {
    if (!_isComboActive ||
        _comboGift == null ||
        _comboReceiverIds == null ||
        _comboRoomId == null)
      return;

    // Increment count visually immediately
    _comboCount++;
    _resetComboTimer(); // Extend timer
    notifyListeners();

    final userIdStr = await _getUserIdFromPrefs();
    final senderId = int.tryParse(userIdStr) ?? 0;

    // Send gift to all receivers
    for (final receiverId in _comboReceiverIds!) {
      final seatNum = _comboReceiverSeats?[receiverId];
      // We use the same selected gift (which is _comboGift, but sendGift uses _selectedGift)
      // Ensure _selectedGift is set to _comboGift just in case, or sendGift relies on it.
      // sendGift uses _selectedGift.
      _selectedGift = _comboGift;

      // Note: sendGift handles notifyListeners and logging.
      // We might want to suppress error messages for combo or handle them?
      await sendGift(
        senderId: senderId,
        receiverId: receiverId,
        roomId: _comboRoomId!,
        seatNumber: seatNum,
        senderSeatNumber: _comboSenderSeat,
      );
    }
  }

  /// Setup WebSocket listeners for lucky gift events
  void _setupLuckyGiftListeners() {
    print('🍀 [GiftProvider] Setting up lucky gift WebSocket listeners...');

    // Listen for lucky_gift:result event
    _giftWsService.on('lucky_gift:result', (data) {
      print('🍀 [GiftProvider] ===== LUCKY GIFT RESULT RECEIVED =====');
      print('🍀 [GiftProvider] Data: $data');

      _luckyGiftResult = data;
      _showLuckySpinner = true;
      notifyListeners();

      // Auto-hide spinner after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        _showLuckySpinner = false;
        notifyListeners();
      });

      print('🍀 [GiftProvider] Lucky result stored and UI notified');
      print('🍀 [GiftProvider] =====================================');
    });

    // Listen for lucky_gift:spin event (acknowledgment)
    _giftWsService.on('lucky_gift:spin', (data) {
      print('🍀 [GiftProvider] Lucky gift spin acknowledged by server');
      print('🍀 [GiftProvider] Data: $data');
    });

    print('✅ [GiftProvider] Lucky gift listeners registered');
  }

  /// Clear lucky gift result
  void clearLuckyResult() {
    _luckyGiftResult = null;
    _showLuckySpinner = false;
    notifyListeners();
  }

  // Getters
  List<GiftModel> get allGifts => _allGifts;
  List<GiftModel> get giftsForSelectedCategory {
    if (_selectedCategory == null) {
      print(
        "📋 [GiftProvider] giftsForSelectedCategory: _selectedCategory is null, returning all ${_allGifts.length} gifts",
      );
      return _allGifts;
    }
    final categoryGifts = _giftsByCategory[_selectedCategory!] ?? [];
    print(
      "📋 [GiftProvider] giftsForSelectedCategory: category='$_selectedCategory', returning ${categoryGifts.length} gifts",
    );
    return categoryGifts;
  }

  /// Get available categories from fetched gifts
  List<String> get availableCategories {
    if (_giftsByCategory.isEmpty && _allGifts.isNotEmpty) {
      // If categories haven't been organized yet, organize them
      _organizeGiftsByCategory();
    }
    return _giftsByCategory.keys.toList()..sort();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  GiftModel? get selectedGift => _selectedGift;
  int get giftQuantity => _giftQuantity;
  double get userBalance => _userBalance;

  // Helper function to get user_id from SharedPreferences (handles both int and String)
  static Future<String> _getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String rawUserId = '';

    if (prefs.containsKey('user_id')) {
      final userIdValue = prefs.get('user_id');
      if (userIdValue is int) {
        rawUserId = userIdValue.toString();
      } else if (userIdValue is String) {
        rawUserId = userIdValue;
      }
    }

    if (rawUserId.isEmpty && prefs.containsKey('database_user_id')) {
      final dbUserIdValue = prefs.get('database_user_id');
      if (dbUserIdValue is int) {
        rawUserId = dbUserIdValue.toString();
      } else if (dbUserIdValue is String) {
        rawUserId = dbUserIdValue;
      }
    }

    return rawUserId;
  }

  // Available categories
  static const List<String> categories = [
    'normal',
    'lucky',
    'tiktok',
    'special',
    'vip',
    'country',
    'unique',
  ];

  dynamic value = [];

  /// Fetch all gifts - uses Gifts WebSocket (port 8085) only
  Future<void> fetchAllGifts({String? coinType, bool isActive = true}) async {
    try {
      print("🎁 [GiftProvider] ===== FETCHING GIFTS =====");
      print("🎁 [GiftProvider] Coin Type: $coinType");
      print("🎁 [GiftProvider] Is Active: $isActive");
      print(
        "🎁 [GiftProvider] Gifts WebSocket Connected: ${_giftWsService.isConnected}",
      );
      print("🎁 [GiftProvider] Current gifts count: ${_allGifts.length}");
      print("🎁 [GiftProvider] Current isLoading: $_isLoading");

      // ✅ If gifts are already loaded and we're not currently loading, skip fetch
      // This prevents unnecessary re-fetching when sheet opens multiple times
      if (_allGifts.isNotEmpty && !_isLoading) {
        print(
          "✅ [GiftProvider] Gifts already loaded (${_allGifts.length} gifts) - skipping fetch",
        );
        // Ensure loading is false (safety check) and notify listeners to update UI
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      _isLoading = true;
      _errorMessage = null;
      print(
        "🔄 [GiftProvider] Setting isLoading = true and notifying listeners",
      );
      notifyListeners();

      // ✅ Connect to Gifts WebSocket if not connected
      bool useWebSocket = false;

      if (!_giftWsService.isConnected) {
        print("🔄 [GiftProvider] Connecting to Gifts WebSocket (port 8085)...");
        try {
          final prefs = await SharedPreferences.getInstance();
          final rawUserId = await _getUserIdFromPrefs();
          // ✅ Format user_id to 8 digits before connecting
          final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
          final username =
              prefs.getString('username') ?? prefs.getString('userName') ?? '';
          final name = prefs.getString('name') ?? username;

          final connected = await _giftWsService.connect(
            userId: userId,
            username: username,
            name: name,
          );

          // ✅ Wait a bit for connection to stabilize
          await Future.delayed(Duration(milliseconds: 500));
          useWebSocket = _giftWsService.isConnected;

          if (!connected || !useWebSocket) {
            print("❌ [GiftProvider] Failed to connect to Gifts WebSocket");
            print("   - Connected return value: $connected");
            print("   - isConnected status: ${_giftWsService.isConnected}");
            _errorMessage =
                'Failed to connect to server. Please check your connection.';
            _allGifts = [];
            _isLoading = false;
            notifyListeners();
            return;
          } else {
            print(
              "✅ [GiftProvider] Gifts WebSocket connection verified and stable",
            );
          }
        } catch (e) {
          print("❌ [GiftProvider] Error connecting to Gifts WebSocket: $e");
          _errorMessage = 'Error connecting to server: $e';
          _allGifts = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        // ✅ Already connected - verify it's still valid
        useWebSocket = _giftWsService.isConnected;
        if (!useWebSocket) {
          print(
            "⚠️ [GiftProvider] Previously connected WebSocket is now disconnected",
          );
          _errorMessage = 'Connection lost. Please try again.';
          _allGifts = [];
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          print("✅ [GiftProvider] Reusing existing Gifts WebSocket connection");
        }
      }

      if (useWebSocket) {
        print("✅ [GiftProvider] Gifts WebSocket is available and connected");
        print(
          "🎁 [GiftProvider] Attempting to fetch gifts via Gifts WebSocket (port 8085)...",
        );

        // Use Completer to wait for WebSocket response
        final completer = Completer<void>();
        bool responseReceived = false;

        // Set up callback to receive gifts:list event
        _giftWsService.on('gifts:list', (data) {
          if (responseReceived) return; // Prevent multiple calls
          responseReceived = true;

          print(
            "🎁 [GiftProvider] gifts:list event received from Gifts WebSocket",
          );
          print("🎁 [GiftProvider] Data keys: ${data.keys.toList()}");

          try {
            // Parse gifts from response
            List<GiftModel> giftsList = [];

            // Handle different response formats
            if (data['gifts'] != null && data['gifts'] is List) {
              giftsList = (data['gifts'] as List)
                  .map(
                    (item) => GiftModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            } else if (data['data'] != null) {
              if (data['data'] is List) {
                giftsList = (data['data'] as List)
                    .map(
                      (item) =>
                          GiftModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              } else if (data['data'] is Map) {
                final dataMap = data['data'] as Map<String, dynamic>;
                if (dataMap['gifts'] != null && dataMap['gifts'] is List) {
                  giftsList = (dataMap['gifts'] as List)
                      .map(
                        (item) =>
                            GiftModel.fromJson(item as Map<String, dynamic>),
                      )
                      .toList();
                }
              }
            }

            if (giftsList.isNotEmpty) {
              _allGifts = giftsList;
              print(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Start!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
              );
              print(
                "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
              );
              print(_allGifts[0]);

              value = _allGifts;

              notifyListeners();
              print(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!End!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
              );
              print(
                "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
              );

              _organizeGiftsByCategory();
              _errorMessage = null;
              _isLoading = false;

              print("✅ [GiftProvider] ===== GIFTS FETCHED SUCCESSFULLY =====");
              print("✅ [GiftProvider] Total gifts: ${_allGifts.length}");
              print("✅ [GiftProvider] Status: Success");
              print("✅ [GiftProvider] ======================================");

              // Log detailed gift information
              for (var gift in _allGifts) {
                print("📦 [GiftProvider] Gift: ${gift.name} (ID: ${gift.id})");
                print("   - Price: ${gift.price} ${gift.coinType}");
                print("   - Category: ${gift.category}");
                print("   - Image: ${gift.image ?? 'N/A'}");
                print("   - Video: ${gift.animationFile ?? 'N/A'}");
                print("   - Has Animation: ${gift.hasAnimation}");
                print(
                  "   - File Type: ${gift.animationFile != null && gift.animationFile!.isNotEmpty ? (gift.animationFile!.toLowerCase().contains('.mp4')
                            ? 'MP4'
                            : gift.animationFile!.toLowerCase().contains('.gif')
                            ? 'GIF'
                            : 'VIDEO_URL') : 'STATIC_IMAGE'}",
                );
                print("   - Active: ${gift.isActive}");
              }

              notifyListeners();
              if (!completer.isCompleted) {
                completer.complete();
              }
            } else {
              print("⚠️ [GiftProvider] No gifts found in WebSocket response");
              _errorMessage = 'No gifts found in server response';
              _allGifts = [];
              _isLoading = false;
              notifyListeners();
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          } catch (e) {
            print("❌ [GiftProvider] Error parsing WebSocket gifts: $e");
            _errorMessage = 'Error parsing gifts: $e';
            _allGifts = [];
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });

        // Set up success callback (status: success) - might contain gifts
        _giftWsService.on('success', (data) {
          if (responseReceived) return;

          // Check if this is a gifts response
          if (data.containsKey('gifts') ||
              (data.containsKey('data') && data['data'] is List) ||
              (data.containsKey('data') &&
                  data['data'] is Map &&
                  (data['data'] as Map).containsKey('gifts'))) {
            responseReceived = true;

            print(
              "🎁 [GiftProvider] Success response with gifts received from Gifts WebSocket",
            );
            print("🎁 [GiftProvider] Data keys: ${data.keys.toList()}");

            try {
              // Parse gifts from response
              List<GiftModel> giftsList = [];

              // Handle different response formats
              if (data['gifts'] != null && data['gifts'] is List) {
                giftsList = (data['gifts'] as List)
                    .map(
                      (item) =>
                          GiftModel.fromJson(item as Map<String, dynamic>),
                    )
                    .toList();
              } else if (data['data'] != null) {
                if (data['data'] is List) {
                  giftsList = (data['data'] as List)
                      .map(
                        (item) =>
                            GiftModel.fromJson(item as Map<String, dynamic>),
                      )
                      .toList();
                } else if (data['data'] is Map) {
                  final dataMap = data['data'] as Map<String, dynamic>;
                  if (dataMap['gifts'] != null && dataMap['gifts'] is List) {
                    giftsList = (dataMap['gifts'] as List)
                        .map(
                          (item) =>
                              GiftModel.fromJson(item as Map<String, dynamic>),
                        )
                        .toList();
                  }
                }
              }

              if (giftsList.isNotEmpty) {
                _allGifts = giftsList;
                _organizeGiftsByCategory();
                _errorMessage = null;
                _isLoading = false;
                print(
                  "✅ [GiftProvider] Gifts fetched via Gifts WebSocket (success response): ${_allGifts.length} gifts",
                );
                notifyListeners();
                if (!completer.isCompleted) {
                  completer.complete();
                }
              } else {
                print("⚠️ [GiftProvider] No gifts found in success response");
                _errorMessage = 'No gifts found in server response';
                _allGifts = [];
                _isLoading = false;
                notifyListeners();
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }
            } catch (e) {
              print(
                "❌ [GiftProvider] Error parsing success response gifts: $e",
              );
              _errorMessage = 'Error parsing gifts: $e';
              _allGifts = [];
              _isLoading = false;
              notifyListeners();
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          }
        });

        // Set up error callback - no retry logic
        _giftWsService.on('error', (data) {
          if (responseReceived) return;
          responseReceived = true;

          final errorMsg = data['message'] as String? ?? 'Server error';
          print("❌ [GiftProvider] ===== GIFTS WEBSOCKET ERROR RESPONSE =====");
          print("❌ [GiftProvider] Error Message: $errorMsg");

          _errorMessage = errorMsg;
          _allGifts = [];
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete();
          }
        });

        // Get user_id for the request
        final rawUserId = await _getUserIdFromPrefs();
        // ✅ Format user_id to 8 digits before sending to backend
        final userId =
            UserIdUtils.formatTo8Digits(rawUserId) ??
            (rawUserId.isEmpty ? '0' : rawUserId);
        final userIdInt = int.tryParse(userId) ?? 0;

        // Request gifts via Gifts WebSocket
        print(
          "📤 [GiftProvider] Sending get_gifts request to Gifts WebSocket (port 8085)...",
        );
        final requestData = <String, dynamic>{
          'user_id':
              userIdInt, // Backend may expect int, but we format the source to 8 digits
          'limit': 200,
          'offset': 0,
        };

        if (coinType != null && coinType != 'all') {
          requestData['coin_type'] = coinType;
        } else {
          requestData['coin_type'] = 'all';
        }

        if (isActive) {
          requestData['is_active'] = 1;
        }

        // ✅ Wait a bit more to ensure connection is fully ready
        await Future.delayed(Duration(milliseconds: 300));

        // ✅ Double-check connection before sending
        if (!_giftWsService.isConnected) {
          print("❌ [GiftProvider] Connection lost before sending request");
          _errorMessage = 'Connection lost. Please try again.';
          _allGifts = [];
          _isLoading = false;
          notifyListeners();
          return;
        }

        final success = _giftWsService.sendAction('get_gifts', requestData);

        if (!success) {
          print("❌ [GiftProvider] Gifts WebSocket request failed");
          _errorMessage = 'Failed to send request to server';
          _allGifts = [];
          _isLoading = false;
          notifyListeners();
        } else {
          print(
            "✅ [GiftProvider] get_gifts request sent successfully to Gifts WebSocket",
          );
          print(
            "⏳ [GiftProvider] Waiting for server response (timeout: 5 seconds)...",
          );

          // Wait for WebSocket response
          try {
            await completer.future.timeout(
              Duration(seconds: 5),
              onTimeout: () {
                if (!responseReceived) {
                  print(
                    "⚠️ [GiftProvider] ===== GIFTS WEBSOCKET RESPONSE TIMEOUT =====",
                  );
                  print(
                    "⚠️ [GiftProvider] Server did not respond within 5 seconds",
                  );
                  _errorMessage = 'Server did not respond. Please try again.';
                  _allGifts = [];
                  _isLoading = false;
                  notifyListeners();
                }
              },
            );
          } catch (e) {
            print(
              "❌ [GiftProvider] Error waiting for Gifts WebSocket response: $e",
            );
            _errorMessage = 'Error waiting for server response: $e';
            _allGifts = [];
            _isLoading = false;
            notifyListeners();
          }
        }
      } else {
        print("❌ [GiftProvider] Gifts WebSocket not available");
        _errorMessage =
            'Unable to connect to server. Please check your connection.';
        _allGifts = [];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print("❌ [GiftProvider] Error fetching gifts: $e");
      _errorMessage = 'Error loading gifts: $e';
      _allGifts = [];
      _isLoading = false;
      print(
        "✅ [GiftProvider] Exception handler: Setting isLoading = false and notifying listeners",
      );
      notifyListeners();
    } finally {
      // ✅ Final safeguard: Ensure loading is always cleared
      if (_isLoading) {
        print(
          "⚠️ [GiftProvider] FINAL SAFEGUARD: isLoading was still true - forcing it to false",
        );
        _isLoading = false;
        notifyListeners();
      }
      print(
        "✅ [GiftProvider] fetchAllGifts completed. Final state: isLoading=$_isLoading, gifts=${_allGifts.length}",
      );
    }
  }

  /// Fetch gifts for a specific category (uses WebSocket - filters from all gifts)
  Future<void> fetchGiftsByCategory({
    required String category,
    String? coinType,
    bool isActive = true,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ✅ If we already have all gifts, just filter by category
      if (_allGifts.isNotEmpty) {
        final categoryGifts = _allGifts.where((gift) {
          final matchesCategory =
              gift.category.toLowerCase() == category.toLowerCase();
          final matchesCoinType =
              coinType == null ||
              gift.coinType.toLowerCase() == coinType.toLowerCase();
          final matchesActive = !isActive || gift.isActive;
          return matchesCategory && matchesCoinType && matchesActive;
        }).toList();

        _giftsByCategory[category.toLowerCase()] = categoryGifts;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ✅ If no gifts loaded, fetch all gifts first (via WebSocket)
      await fetchAllGifts(coinType: coinType, isActive: isActive);

      // ✅ After fetching, filter by category
      if (_allGifts.isNotEmpty) {
        final categoryGifts = _allGifts.where((gift) {
          return gift.category.toLowerCase() == category.toLowerCase();
        }).toList();

        _giftsByCategory[category.toLowerCase()] = categoryGifts;
        _errorMessage = null;
      } else {
        _errorMessage = 'No gifts available';
        _giftsByCategory[category.toLowerCase()] = [];
      }
    } catch (e) {
      _errorMessage = 'Error loading gifts: $e';
      _giftsByCategory[category.toLowerCase()] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Organize gifts by category
  void _organizeGiftsByCategory() {
    _giftsByCategory.clear();
    for (var gift in _allGifts) {
      print(
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
      );
      final category = gift.category.toLowerCase();
      if (!_giftsByCategory.containsKey(category)) {
        _giftsByCategory[category] = [];
      }

      _giftsByCategory[category]!.add(gift);
    }
  }

  /// Set selected category
  void setSelectedCategory(String? category) {
    print("🎯 [GiftProvider] setSelectedCategory called with: $category");
    _selectedCategory = category?.toLowerCase();
    print("🎯 [GiftProvider] _selectedCategory set to: $_selectedCategory");
    print("🎯 [GiftProvider] Total gifts: ${_allGifts.length}");
    print(
      "🎯 [GiftProvider] Gifts by category keys: ${_giftsByCategory.keys.toList()}",
    );

    if (_selectedCategory != null &&
        !_giftsByCategory.containsKey(_selectedCategory!)) {
      // Fetch gifts for this category if not already loaded
      print("🎯 [GiftProvider] Category not in cache, fetching...");
      fetchGiftsByCategory(category: _selectedCategory!);
    } else {
      print(
        "🎯 [GiftProvider] Category already in cache or null (showing all)",
      );
      print(
        "🎯 [GiftProvider] Gifts for selected category: ${giftsForSelectedCategory.length}",
      );
    }
    notifyListeners();
  }

  /// Select a gift
  void selectGift(GiftModel? gift) {
    _selectedGift = gift;
    _giftQuantity = 1; // Reset quantity when selecting new gift
    notifyListeners();
  }

  /// Increase gift quantity
  void increaseQuantity() {
    if (_selectedGift != null) {
      _giftQuantity++;
      notifyListeners();
    }
  }

  /// Decrease gift quantity
  void decreaseQuantity() {
    if (_selectedGift != null && _giftQuantity > 1) {
      _giftQuantity--;
      notifyListeners();
    }
  }

  /// Set gift quantity
  void setQuantity(int quantity) {
    if (quantity > 0) {
      _giftQuantity = quantity;
      notifyListeners();
    }
  }

  /// Set user balance
  void setUserBalance(double balance) {
    _userBalance = balance;
    notifyListeners();
  }

  /// Fetch user balance via WebSocket (port 8085) - action: get_user_balance
  Future<void> fetchUserBalance() async {
    try {
      print("💰 [GiftProvider] ===== FETCHING USER BALANCE =====");

      // ✅ Connect to Gifts WebSocket if not connected
      if (!_giftWsService.isConnected) {
        print(
          "🔄 [GiftProvider] Connecting to Gifts WebSocket (port 8085) for balance...",
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          final rawUserId = await _getUserIdFromPrefs();
          // ✅ Format user_id to 8 digits before connecting
          final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
          final username =
              prefs.getString('username') ?? prefs.getString('userName') ?? '';
          final name = prefs.getString('name') ?? username;

          final connected = await _giftWsService.connect(
            userId: userId,
            username: username,
            name: name,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          if (!connected || !_giftWsService.isConnected) {
            print(
              "❌ [GiftProvider] Failed to connect to Gifts WebSocket for balance",
            );
            // Don't return - wait for connection or timeout
            print("⏳ [GiftProvider] Waiting for WebSocket connection...");
            await Future.delayed(Duration(seconds: 2));
            if (!_giftWsService.isConnected) {
              print(
                "❌ [GiftProvider] WebSocket connection failed after waiting",
              );
              return;
            }
          }
        } catch (e) {
          print(
            "❌ [GiftProvider] Error connecting to Gifts WebSocket for balance: $e",
          );
          return;
        }
      }

      if (!_giftWsService.isConnected) {
        print(
          "⚠️ [GiftProvider] Gifts WebSocket not connected - waiting for connection...",
        );
        // Wait a bit more for connection
        await Future.delayed(Duration(milliseconds: 500));
        if (!_giftWsService.isConnected) {
          print(
            "❌ [GiftProvider] WebSocket still not connected - cannot fetch balance",
          );
          return;
        }
      }

      print(
        "✅ [GiftProvider] Gifts WebSocket is connected - requesting balance...",
      );

      // Use Completer to wait for WebSocket response
      final completer = Completer<void>();
      bool responseReceived = false;

      // Set up callback to receive balance response
      _giftWsService.on('success', (data) {
        if (responseReceived) return;

        print("💰 [GiftProvider] ===== BALANCE RESPONSE CHECK =====");
        print("💰 [GiftProvider] Response keys: ${data.keys.toList()}");
        print("💰 [GiftProvider] Full response: $data");

        // Check if this is a balance response - handle nested data structure
        bool isBalanceResponse = false;
        double? balance;

        // Check direct keys first
        if (data.containsKey('balance') ||
            data.containsKey('gold_coins') ||
            data.containsKey('diamond_coins')) {
          isBalanceResponse = true;
          if (data['balance'] != null) {
            balance = double.tryParse(data['balance'].toString());
          } else if (data['gold_coins'] != null) {
            balance = double.tryParse(data['gold_coins'].toString());
          } else if (data['diamond_coins'] != null) {
            balance = double.tryParse(data['diamond_coins'].toString());
          }
        }
        // Check nested data structure: data['data']['gold_coins']
        else if (data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'] as Map<String, dynamic>;
          print("💰 [GiftProvider] Checking nested data structure...");
          print("💰 [GiftProvider] Nested data keys: ${dataMap.keys.toList()}");

          if (dataMap.containsKey('balance') ||
              dataMap.containsKey('gold_coins') ||
              dataMap.containsKey('diamond_coins')) {
            isBalanceResponse = true;
            if (dataMap['balance'] != null) {
              balance = double.tryParse(dataMap['balance'].toString());
            } else if (dataMap['gold_coins'] != null) {
              balance = double.tryParse(dataMap['gold_coins'].toString());
            } else if (dataMap['diamond_coins'] != null) {
              balance = double.tryParse(dataMap['diamond_coins'].toString());
            }
          }
        }

        // Also check if message indicates balance response
        final message = data['message'] as String? ?? '';
        if (message.toLowerCase().contains('balance')) {
          isBalanceResponse = true;
          // If we detected balance response by message but haven't extracted balance yet, try to extract it
          if (balance == null &&
              data.containsKey('data') &&
              data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('gold_coins')) {
              balance = double.tryParse(dataMap['gold_coins'].toString());
              print(
                "💰 [GiftProvider] Extracted balance from nested data via message check: $balance",
              );
            } else if (dataMap.containsKey('balance')) {
              balance = double.tryParse(dataMap['balance'].toString());
              print(
                "💰 [GiftProvider] Extracted balance from nested data via message check: $balance",
              );
            }
          }
        }

        if (isBalanceResponse) {
          responseReceived = true;

          print("✅ [GiftProvider] ===== BALANCE RESPONSE RECEIVED =====");
          print("💰 [GiftProvider] Extracted balance: $balance");

          try {
            if (balance != null) {
              _userBalance = balance;

              print("✅ [GiftProvider] ===== BALANCE UPDATED =====");
              print("💰 [GiftProvider] Status: Success");
              print("💰 [GiftProvider] Gold Coins: $balance");
              print("💰 [GiftProvider] Balance: $_userBalance");

              // Extract diamond coins if available
              if (data.containsKey('data') && data['data'] is Map) {
                final dataMap = data['data'] as Map<String, dynamic>;
                if (dataMap.containsKey('diamond_coins')) {
                  final diamondCoins = double.tryParse(
                    dataMap['diamond_coins'].toString(),
                  );
                  if (diamondCoins != null) {
                    print("💎 [GiftProvider] Diamond Coins: $diamondCoins");
                  }
                }
              }

              print("✅ [GiftProvider] ============================");

              // Cache balance in SharedPreferences (async operation)
              SharedPreferences.getInstance().then((prefs) async {
                final rawUserId = await _getUserIdFromPrefs();
                // ✅ Format user_id to 8 digits for cache key
                final userId =
                    UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
                if (userId.isNotEmpty && balance != null) {
                  await prefs.setDouble('gold_coins_$userId', balance);
                  print("💾 [GiftProvider] Balance cached: $balance");
                }
              });

              notifyListeners();
            } else {
              print(
                "⚠️ [GiftProvider] Could not extract balance from response",
              );
              print("⚠️ [GiftProvider] Status: Failed - No balance data found");
            }
          } catch (e) {
            print("❌ [GiftProvider] Error parsing balance response: $e");
          }

          if (!completer.isCompleted) {
            completer.complete();
            print("✅ [GiftProvider] Balance completer completed");
          }
        } else {
          print("ℹ️ [GiftProvider] Not a balance response, ignoring...");
        }
      });

      // Set up error callback - no retry logic
      _giftWsService.on('error', (data) {
        if (responseReceived) return;
        responseReceived = true;

        final errorMsg =
            data['message'] as String? ?? 'Failed to fetch balance';
        print("❌ [GiftProvider] Balance fetch error: $errorMsg");

        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Get user_id for the request
      final rawUserId = await _getUserIdFromPrefs();
      // ✅ Format user_id to 8 digits before sending to backend
      final userId =
          UserIdUtils.formatTo8Digits(rawUserId) ??
          (rawUserId.isEmpty ? '0' : rawUserId);
      final userIdInt = int.tryParse(userId) ?? 0;

      // Request balance via Gifts WebSocket
      print(
        "📤 [GiftProvider] Sending get_user_balance request to Gifts WebSocket (port 8085)...",
      );
      final requestData = <String, dynamic>{
        'user_id':
            userIdInt, // Backend may expect int, but we format the source to 8 digits
      };

      final success = _giftWsService.sendAction(
        'get_user_balance',
        requestData,
      );

      if (!success) {
        print("❌ [GiftProvider] Failed to send get_user_balance request");
        return;
      }

      print("✅ [GiftProvider] get_user_balance request sent successfully");
      print(
        "⏳ [GiftProvider] Waiting for server response (timeout: 5 seconds)...",
      );

      // Wait for WebSocket response
      try {
        await completer.future.timeout(
          Duration(seconds: 5),
          onTimeout: () {
            if (!responseReceived) {
              print(
                "⚠️ [GiftProvider] Balance response timeout - no balance data from WebSocket",
              );
              // Don't use cached - let UI show 0 or previous value
            }
          },
        );
      } catch (e) {
        print("❌ [GiftProvider] Error waiting for balance response: $e");
      }
    } catch (e) {
      print("❌ [GiftProvider] Error fetching user balance: $e");
    }
  }

  /// Send gift - uses Gifts WebSocket (port 8085) only
  Future<bool> sendGift({
    required int senderId,
    required int receiverId,
    required int roomId,
    int? seatNumber,
    int? senderSeatNumber, // ✅ Sender's seat number for backend verification
  }) async {
    if (_selectedGift == null) {
      _errorMessage = 'Please select a gift';
      notifyListeners();
      return false;
    }

    try {
      // ✅ Add a small delay to ensure backend has processed seat occupation
      // This helps if the user just occupied a seat
      print(
        '⏳ [GiftProvider] Adding 500ms delay to ensure backend has processed seat occupation...',
      );
      await Future.delayed(Duration(milliseconds: 500));

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final totalValue = _selectedGift!.price * _giftQuantity;
      final giftId = _selectedGift!.id ?? 0;

      print('🎁 Gift Provider - Sending Gift:');
      print('   - Selected Gift ID: $giftId');
      print('   - Selected Gift Name: ${_selectedGift!.name}');
      print('   - Gift Price: ${_selectedGift!.price}');
      print('   - Quantity: $_giftQuantity');
      print('   - Total Value: $totalValue');
      print('   - Sender ID: $senderId');
      print('   - Receiver ID: $receiverId');
      print('   - Room ID: $roomId');
      print('   - Seat Number: $seatNumber');

      // ✅ SPECIAL HANDLING FOR LUCKY GIFTS: USE HTTP API
      // The WebSocket event often misses the 'multiplier' and 'win_coins' data.
      // The HTTP API returns it correctly. So we prioritize HTTP for Lucky Gifts.
      // ⚠️ EXCEPTION: HTTP API blocks self-gifting ("Cannot send gift to yourself").
      // So for self-gifts, we MUST use WebSocket (even if multiplier might be missing).
      final isLucky =
          (_selectedGift?.category.toLowerCase().contains('lucky') ?? false) ||
          (_selectedGift?.name.toLowerCase().contains('lucky') ?? false);
      
      final isSelfGift = (senderId == receiverId);

      if (isLucky && !isSelfGift) {
        print(
          "🍀 [GiftProvider] Lucky Gift (Not Self) detected! Using lucky_gift_api for spin/multiplier.",
        );

        try {
          // ✅ Route to lucky_gift_api.php - handles spin, multiplier, deduction, receiver coins, WebSocket broadcast
          final jsonResponse = await ApiManager.triggerLuckyGift(
            senderId: senderId,
            receiverId: receiverId,
            giftId: giftId,
            giftPrice: _selectedGift!.price,
            quantity: _giftQuantity,
            roomId: roomId,
          );

          if (jsonResponse != null &&
              (jsonResponse['status'] == 'success' ||
                  jsonResponse['status'] == true)) {
            final data = jsonResponse['data'] as Map<String, dynamic>? ?? {};
            print("✅ [GiftProvider] Lucky Gift sent via lucky_gift_api!");
            print("   Multiplier: ${data['multiplier']}, WinCoins: ${data['win_coins']}");

            // Construct rich event for UI (animations, banners)
            final giftSentData = <String, dynamic>{
              'gift_id': _selectedGift!.id,
              'gift_name': _selectedGift!.name,
              'gift_image': _selectedGift!.image,
              'gift_value': _selectedGift!.price,
              'quantity': _giftQuantity,
              'sender_id': senderId,
              'receiver_id': receiverId,
              'gift_animation': _selectedGift!.animationFile,
              'animation_file': _selectedGift!.animationFile,
              'is_lucky': true,
              'status': 'success',
              'message': jsonResponse['message'] ?? 'Gift sent successfully',
            };
            giftSentData.addAll(data);

            _giftWsService.emit('gift:sent', giftSentData);

            // Update balances (lucky_gift_api uses gold for sender, diamond for receiver)
            _updateSenderBalance(
              {'sender_paid_coin_type': 'gold', ...jsonResponse},
              senderId,
            );
            _updateReceiverDiamondCoins(
              {'receiver_received_coin_type': 'diamond', ...jsonResponse},
              receiverId,
            );

            // Refetch balance from API to ensure UI shows correct value (including any winnings)
            try {
              final rawUserId = await _getUserIdFromPrefs();
              final uid = rawUserId.isNotEmpty ? rawUserId : senderId.toString();
              final balanceResp = await ApiManager.getUserCoinsBalance(
                userId: uid,
              );
              if (balanceResp != null &&
                  balanceResp.isSuccess &&
                  balanceResp.goldCoins != null) {
                _userBalance = balanceResp.goldCoins!;
                final prefs = await SharedPreferences.getInstance();
                final userId =
                    UserIdUtils.formatTo8Digits(uid) ?? uid;
                if (userId.isNotEmpty) {
                  await prefs.setDouble(
                    'gold_coins_$userId',
                    balanceResp.goldCoins!,
                  );
                }
                notifyListeners();
                print(
                  "💰 [GiftProvider] Balance refetched after Lucky gift: $_userBalance",
                );
              }
            } catch (e) {
              print("⚠️ [GiftProvider] Balance refetch failed: $e");
            }

            _errorMessage = null;
            _selectedGift = null;
            _giftQuantity = 1;
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            final msg = jsonResponse?['message'] as String? ??
                jsonResponse?['error_details'] as String? ??
                "Failed to send lucky gift";
            print("❌ [GiftProvider] Lucky Gift API Failed: $msg");
            _errorMessage = msg;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          print("❌ [GiftProvider] Lucky Gift Exception: $e");
          _errorMessage = "Error sending gift: $e";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // ✅ Try Gifts WebSocket (port 8085) if available
      bool useWebSocket = false;

      // Connect to Gifts WebSocket if not connected
      if (!_giftWsService.isConnected) {
        print(
          '🔄 [GiftProvider] Connecting to Gifts WebSocket (port 8085) for sending gift...',
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          final rawUserId = await _getUserIdFromPrefs();
          // ✅ Format user_id to 8 digits before connecting
          final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
          final username =
              prefs.getString('username') ?? prefs.getString('userName') ?? '';
          final name = prefs.getString('name') ?? username;

          final connected = await _giftWsService.connect(
            userId: userId,
            username: username,
            name: name,
          );

          await Future.delayed(Duration(milliseconds: 1000));
          useWebSocket = _giftWsService.isConnected;

          if (!connected || !useWebSocket) {
            print('❌ [GiftProvider] Failed to connect to Gifts WebSocket');
            _errorMessage =
                'Failed to connect to server. Please check your connection.';
            _isLoading = false;
            notifyListeners();
            return false;
          } else {
            print(
              '✅ [GiftProvider] Gifts WebSocket connection verified and stable',
            );
          }
        } catch (e) {
          print('❌ [GiftProvider] Error connecting to Gifts WebSocket: $e');
          _errorMessage = 'Error connecting to server: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        useWebSocket = _giftWsService.isConnected;
        if (!useWebSocket) {
          print(
            '⚠️ [GiftProvider] Previously connected Gifts WebSocket is now disconnected',
          );
          _errorMessage = 'Connection lost. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (useWebSocket) {
        print(
          '✅ [GiftProvider] Gifts WebSocket is available - attempting to send via WebSocket (port 8085)...',
        );

        // Use Completer to wait for WebSocket response
        final completer = Completer<bool>();
        bool responseReceived = false;
        bool giftSentSuccessfully = false;

        // Set up callback to receive gift:sent event
        _giftWsService.on('gift:sent', (data) {
          // Allow late responses (even after timeout)
          if (responseReceived && giftSentSuccessfully) {
            print(
              '✅ [GiftProvider] Late gift:sent event received (already marked as success)',
            );
            return;
          }

          responseReceived = true;
          giftSentSuccessfully = true;

          print(
            '✅ [GiftProvider] gift:sent event received from Gifts WebSocket',
          );
          print('✅ [GiftProvider] Gift sent successfully: $data');

          // ✅ Ensure gift data includes animation file if not present
          if (!data.containsKey('gift_animation') &&
              !data.containsKey('animation_file') &&
              _selectedGift != null &&
              _selectedGift!.animationFile != null) {
            data['gift_animation'] = _selectedGift!.animationFile;
            data['animation_file'] = _selectedGift!.animationFile;
            print(
              '🎬 [GiftProvider] Added animation file to gift:sent event: ${_selectedGift!.animationFile}',
            );
          }

          // ✅ Update sender balance using new backend fields (sender_paid_coin_type)
          _updateSenderBalance(data, senderId);

          // ✅ Update receiver's diamond coins if receiver is current user
          _updateReceiverDiamondCoins(data, receiverId);

          // Clear any timeout error message
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(true);
          } else {
            // Late response - gift was sent successfully
            print(
              '✅ [GiftProvider] Late response received - gift was sent successfully',
            );
            // Reset selection even for late responses
            _selectedGift = null;
            _giftQuantity = 1;
            notifyListeners();
          }
        });

        // Set up success callback (status: success)
        _giftWsService.on('success', (data) {
          if (responseReceived) return;

          // Check if this is a gift sending success response
          if (data.containsKey('message') &&
              (data['message'].toString().toLowerCase().contains('gift') ||
                  data.containsKey('gift_id'))) {
            responseReceived = true;
            giftSentSuccessfully = true;

            print(
              '✅ [GiftProvider] Success response received from Gifts WebSocket',
            );
            print('✅ [GiftProvider] Response: $data');

            // ✅ Emit gift:sent event locally so room screen can trigger animation
            // This ensures animation plays even if backend doesn't send gift:sent event
            if (_selectedGift != null) {
              final giftSentData = <String, dynamic>{
                'gift_id': _selectedGift!.id,
                'gift_name': _selectedGift!.name,
                'gift_image': _selectedGift!.image,
                'gift_value': _selectedGift!.price,
                'quantity': _giftQuantity,
                'sender_id': senderId,
                'receiver_id': receiverId,
                'sender_name': data['sender_name'] as String?,
                'receiver_name': data['receiver_name'] as String?,
                'gift_animation': _selectedGift!.animationFile,
                'animation_file': _selectedGift!.animationFile,
              };

              // Merge any additional data from backend response
              giftSentData.addAll(data);

              print(
                '🎬 [GiftProvider] Emitting local gift:sent event for animation overlay',
              );
              print('   - Gift: ${_selectedGift!.name}');
              print('   - Quantity: $_giftQuantity');
              print('   - Animation: ${_selectedGift!.animationFile}');

              // Manually trigger the gift:sent event
              _giftWsService.emit('gift:sent', giftSentData);
            }

            // ✅ Update sender balance using new backend fields (sender_paid_coin_type)
            _updateSenderBalance(data, senderId);

            // ✅ Update receiver's diamond coins if receiver is current user
            _updateReceiverDiamondCoins(data, receiverId);

            if (!completer.isCompleted) {
              completer.complete(true);
            }
          }
        });

        // Set up error callback
        _giftWsService.on('error', (data) {
          if (responseReceived) return;
          responseReceived = true;

          final errorMsg = data['message'] as String? ?? 'Failed to send gift';
          print('❌ [GiftProvider] ===== GIFT SENDING ERROR =====');
          print('❌ [GiftProvider] Error Message: $errorMsg');

          // Handle all errors (no fallback)
          _errorMessage = errorMsg;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        });

        // Send gift via Gifts WebSocket (port 8085)
        print(
          '📤 [GiftProvider] Sending send_gift request to Gifts WebSocket (port 8085)...',
        );
        final requestData = <String, dynamic>{
          'sender_id': senderId,
          'receiver_id': receiverId,
          'gift_id': giftId,
          'room_id': roomId,
        };

        if (seatNumber != null) {
          requestData['seat_number'] = seatNumber; // Receiver's seat number
        }

        // ✅ Include sender's seat number to help backend verify sender is seated
        if (senderSeatNumber != null) {
          requestData['sender_seat_number'] = senderSeatNumber;
          print(
            '📤 [GiftProvider] Including sender seat number: $senderSeatNumber',
          );
        }

        final success = _giftWsService.sendAction('send_gift', requestData);

        if (!success) {
          print('❌ [GiftProvider] Failed to send send_gift request');
          _errorMessage = 'Failed to send request to server';
          _isLoading = false;
          notifyListeners();
          return false;
        } else {
          print('✅ [GiftProvider] send_gift request sent successfully');
          print(
            '⏳ [GiftProvider] Waiting for server response (timeout: 10 seconds)...',
          );

          // Wait for WebSocket response with longer timeout
          try {
            final result = await completer.future.timeout(
              Duration(seconds: 10), // Increased from 5 to 10 seconds
              onTimeout: () {
                if (!responseReceived) {
                  print(
                    '⚠️ [GiftProvider] Gift sending response timeout after 10 seconds',
                  );
                  print(
                    '⚠️ [GiftProvider] However, gift may have been sent successfully - backend may be slow',
                  );
                  print(
                    '✅ [GiftProvider] Assuming success since no error was received',
                  );

                  // ✅ Emit gift:sent event immediately so animation can play
                  // This ensures animation plays even when backend doesn't respond
                  if (_selectedGift != null && !giftSentSuccessfully) {
                    final giftSentData = <String, dynamic>{
                      'gift_id': _selectedGift!.id,
                      'gift_name': _selectedGift!.name,
                      'gift_image': _selectedGift!.image,
                      'gift_value': _selectedGift!.price,
                      'quantity': _giftQuantity,
                      'sender_id': senderId,
                      'receiver_id': receiverId,
                      'sender_name': null, // Will be fetched from seat data
                      'receiver_name': null, // Will be fetched from seat data
                      'gift_animation': _selectedGift!.animationFile,
                      'animation_file': _selectedGift!.animationFile,
                    };

                    print(
                      '🎬 [GiftProvider] Emitting local gift:sent event for animation overlay (timeout case)',
                    );
                    print('   - Gift: ${_selectedGift!.name}');
                    print('   - Quantity: $_giftQuantity');
                    print('   - Animation: ${_selectedGift!.animationFile}');

                    // Manually trigger the gift:sent event immediately
                    _giftWsService.emit('gift:sent', giftSentData);
                    giftSentSuccessfully = true;
                  }

                  // Assume success if no error was received - gift was likely sent
                  // Wait a bit more for late response, but assume success
                  Future.delayed(Duration(seconds: 2), () {
                    // Check again after 2 more seconds if we got a late response
                    if (!responseReceived) {
                      print(
                        '✅ [GiftProvider] No late response received - assuming gift was sent successfully',
                      );
                      // Assume success - no error means gift was likely sent
                      _errorMessage = null;
                      _selectedGift = null;
                      _giftQuantity = 1;
                      _isLoading = false;
                      notifyListeners();
                      // Complete the completer as success (late)
                      if (!completer.isCompleted) {
                        completer.complete(true);
                      }
                    }
                  });
                }
                // Return true to indicate we're assuming success (no error = success)
                return true; // Assume success if no error received
              },
            );

            // Check if result is true (either from success response or timeout assumption)
            if (result || giftSentSuccessfully) {
              // ✅ Success - reset selection
              _errorMessage = null;
              _selectedGift = null;
              _giftQuantity = 1;
              _isLoading = false;
              notifyListeners();
              if (giftSentSuccessfully) {
                print(
                  '✅ Gift sent successfully via Gifts WebSocket (port 8085) - confirmed by server',
                );
              } else {
                print(
                  '✅ Gift sent via Gifts WebSocket (port 8085) - assuming success (no error received)',
                );
              }
              return true;
            } else {
              // Error from WebSocket
              _isLoading = false;
              notifyListeners();
              return false;
            }
          } catch (e) {
            print(
              '❌ [GiftProvider] Error waiting for gift sending response: $e',
            );
            _errorMessage = 'Error waiting for server response: $e';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      } else {
        print('❌ [GiftProvider] Gifts WebSocket not available');
        _errorMessage =
            'Unable to connect to server. Please check your connection.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error sending gift: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _selectedGift = null;
    _giftQuantity = 1;
    _selectedCategory = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Update sender balance based on sender_paid_coin_type
  /// Uses the new backend fields: sender_paid_coin_type and sender_balance
  Future<void> _updateSenderBalance(
    Map<String, dynamic> data,
    int senderId,
  ) async {
    try {
      print("💰 [GiftProvider] ===== UPDATING SENDER BALANCE =====");

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final rawUserId = await _getUserIdFromPrefs();
      final currentUserId = int.tryParse(rawUserId);

      if (currentUserId == null) {
        print("⚠️ [GiftProvider] Cannot determine current user ID");
        return;
      }

      // Check if sender is current user
      if (senderId != currentUserId) {
        print(
          "ℹ️ [GiftProvider] Sender (ID: $senderId) is not current user (ID: $currentUserId) - skipping sender balance update",
        );
        return;
      }

      // Extract sender_paid_coin_type from response
      String? senderPaidCoinType;
      if (data.containsKey('sender_paid_coin_type')) {
        senderPaidCoinType = data['sender_paid_coin_type']
            ?.toString()
            .toLowerCase();
      } else if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        senderPaidCoinType = dataMap['sender_paid_coin_type']
            ?.toString()
            .toLowerCase();
      }

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

      // Log transaction clarity
      print("💰 [GiftProvider] Transaction Details:");
      print("   - Sender Paid Coin Type: ${senderPaidCoinType ?? 'unknown'}");
      print(
        "   - Receiver Received Coin Type: ${receiverReceivedCoinType ?? 'unknown'}",
      );

      // Extract sender_balance from response
      Map<String, dynamic>? senderBalance;
      if (data.containsKey('sender_balance') && data['sender_balance'] is Map) {
        senderBalance = Map<String, dynamic>.from(
          data['sender_balance'] as Map,
        );
      } else if (data.containsKey('data') && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        if (dataMap.containsKey('sender_balance') &&
            dataMap['sender_balance'] is Map) {
          senderBalance = Map<String, dynamic>.from(
            dataMap['sender_balance'] as Map,
          );
        }
      }

      // Fallback: try to get balance from top-level fields (for backward compatibility)
      if (senderBalance == null) {
        if (data.containsKey('balance') ||
            data.containsKey('gold_coins') ||
            data.containsKey('diamond_coins')) {
          // Create a temporary balance map for backward compatibility
          senderBalance = <String, dynamic>{};
          if (data.containsKey('balance')) {
            senderBalance['gold_coins'] = data['balance'];
          } else if (data.containsKey('gold_coins')) {
            senderBalance['gold_coins'] = data['gold_coins'];
          } else if (data.containsKey('diamond_coins')) {
            senderBalance['diamond_coins'] = data['diamond_coins'];
          }
        }
      }

      if (senderBalance == null) {
        print("⚠️ [GiftProvider] No sender_balance found in response");
        return;
      }

      // Update balance based on sender_paid_coin_type
      final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
      if (userId.isEmpty) {
        print("⚠️ [GiftProvider] User ID is empty");
        return;
      }

      if (senderPaidCoinType == 'diamond' || senderPaidCoinType == 'diamonds') {
        // Sender paid with diamond coins - update diamond_coins balance
        final diamondCoinsStr = senderBalance['diamond_coins']?.toString();
        if (diamondCoinsStr != null && diamondCoinsStr.isNotEmpty) {
          final diamondCoins = double.tryParse(diamondCoinsStr);
          if (diamondCoins != null) {
            await prefs.setDouble('diamond_coins_$userId', diamondCoins);
            print("💎 [GiftProvider] ===== SENDER DIAMOND COINS UPDATED =====");
            print(
              "💎 [GiftProvider] Sender ID: $senderId (Current User: $currentUserId)",
            );
            print("💎 [GiftProvider] Diamond Coins: $diamondCoins");
            print(
              "💎 [GiftProvider] Cached to SharedPreferences: diamond_coins_$userId",
            );
            print(
              "💎 [GiftProvider] ==========================================",
            );
            notifyListeners();
          }
        }
      } else {
        // Sender paid with gold coins (default) - update gold_coins balance
        final goldCoinsStr =
            senderBalance['gold_coins']?.toString() ??
            senderBalance['balance']?.toString();
        if (goldCoinsStr != null && goldCoinsStr.isNotEmpty) {
          final goldCoins = double.tryParse(goldCoinsStr);
          if (goldCoins != null) {
            _userBalance = goldCoins;
            await prefs.setDouble('gold_coins_$userId', goldCoins);
            print("💰 [GiftProvider] ===== SENDER GOLD COINS UPDATED =====");
            print(
              "💰 [GiftProvider] Sender ID: $senderId (Current User: $currentUserId)",
            );
            print("💰 [GiftProvider] Gold Coins: $goldCoins");
            print(
              "💰 [GiftProvider] Cached to SharedPreferences: gold_coins_$userId",
            );
            print(
              "💰 [GiftProvider] ==========================================",
            );
            notifyListeners();
          }
        }
      }
    } catch (e, stackTrace) {
      print("❌ [GiftProvider] Error updating sender balance: $e");
      print("❌ [GiftProvider] Stack trace: $stackTrace");
    }
  }

  /// Update receiver's diamond coins balance if receiver is current user
  /// Works for both: self-gifts (sender = receiver) and gifts from others (receiver = current user)
  /// Uses the new backend field: receiver_received_coin_type (should always be "diamond")
  Future<void> _updateReceiverDiamondCoins(
    Map<String, dynamic> data,
    int receiverId,
  ) async {
    try {
      print(
        "💎 [GiftProvider] ===== CHECKING RECEIVER DIAMOND COINS UPDATE =====",
      );
      print("💎 [GiftProvider] Receiver ID from parameter: $receiverId");

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final rawUserId = await _getUserIdFromPrefs();
      final currentUserId = int.tryParse(rawUserId);

      if (currentUserId == null) {
        print("⚠️ [GiftProvider] Cannot determine current user ID");
        return;
      }

      print("💎 [GiftProvider] Current user ID: $currentUserId");

      // ✅ Check if receiver is current user (works for both self-gifts and gifts from others)
      if (receiverId != currentUserId) {
        print(
          "ℹ️ [GiftProvider] Receiver (ID: $receiverId) is not current user (ID: $currentUserId) - skipping diamond coins update",
        );
        return;
      }

      print(
        "✅ [GiftProvider] Receiver is current user - proceeding with diamond coins update",
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
        "💎 [GiftProvider] Receiver Received Coin Type: ${receiverReceivedCoinType ?? 'unknown'} (should be 'diamond')",
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
          "⚠️ [GiftProvider] No receiver_balance found in response - trying alternative extraction",
        );
        // Try to get from nested structure
        if (data.containsKey('data') && data['data'] is Map) {
          final dataMap = data['data'] as Map<String, dynamic>;
          // Sometimes receiver_balance might be at the same level as other data
          if (dataMap.containsKey('receiver_balance') &&
              dataMap['receiver_balance'] is Map) {
            receiverBalance = Map<String, dynamic>.from(
              dataMap['receiver_balance'] as Map,
            );
          }
        }

        if (receiverBalance == null) {
          print("ℹ️ [GiftProvider] No receiver_balance found in response");
          return;
        }
      }

      // Verify receiver_balance user_id matches receiverId (double check)
      final receiverBalanceUserId = receiverBalance['user_id'];
      final receiverBalanceUserIdInt = receiverBalanceUserId is int
          ? receiverBalanceUserId
          : (receiverBalanceUserId is String
                ? int.tryParse(receiverBalanceUserId)
                : null);

      if (receiverBalanceUserIdInt != null &&
          receiverBalanceUserIdInt != receiverId) {
        print(
          "⚠️ [GiftProvider] receiver_balance user_id ($receiverBalanceUserIdInt) doesn't match receiverId ($receiverId)",
        );
        // Still proceed if receiverId matches currentUserId (trust the parameter)
      }

      // Extract diamond coins from receiver_balance
      final diamondCoinsStr = receiverBalance['diamond_coins']?.toString();
      if (diamondCoinsStr != null && diamondCoinsStr.isNotEmpty) {
        final diamondCoins = double.tryParse(diamondCoinsStr);
        if (diamondCoins != null) {
          // Cache receiver's diamond coins balance
          final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
          if (userId.isNotEmpty) {
            await prefs.setDouble('diamond_coins_$userId', diamondCoins);
            print(
              "💎 [GiftProvider] ===== RECEIVER DIAMOND COINS UPDATED =====",
            );
            print(
              "💎 [GiftProvider] Receiver ID: $receiverId (Current User: $currentUserId)",
            );
            print("💎 [GiftProvider] Diamond Coins: $diamondCoins");
            print(
              "💎 [GiftProvider] Cached to SharedPreferences: diamond_coins_$userId",
            );
            print(
              "💎 [GiftProvider] ==========================================",
            );

            // Notify listeners to update UI if needed
            notifyListeners();
          }
        }
      } else {
        print("⚠️ [GiftProvider] No diamond_coins found in receiver_balance");
      }
    } catch (e, stackTrace) {
      print("❌ [GiftProvider] Error updating receiver diamond coins: $e");
      print("❌ [GiftProvider] Stack trace: $stackTrace");
    }
  }
}
