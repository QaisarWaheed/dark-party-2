import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';

class MerchantProfileProvider with ChangeNotifier {
  bool _isTransferSheetVisible = false;
  bool _isSheetShowing = false; // Track if modal is currently showing
  String _amount = '';
  String _receiverId = '';
  double _availableCoins = 0.0;
  bool _isLoadingCoins = false;
  bool _isTransferring = false;
  String? _transferError;

  bool get isTransferSheetVisible => _isTransferSheetVisible;
  bool get isSheetShowing => _isSheetShowing;
  String get amount => _amount;
  String get receiverId => _receiverId;
  double get availableCoins => _availableCoins;
  bool get isLoadingCoins => _isLoadingCoins;
  bool get isTransferring => _isTransferring;
  String? get transferError => _transferError;

  // Load merchant coins from API (always fresh, no cache)
  Future<void> loadMerchantCoins() async {
    _isLoadingCoins = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Get user_id
      String userId = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userId = userIdInt.toString();
        } else {
          userId = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userId = userIdValue.toString();
        }
      }
      
      if (userId.isEmpty) {
        print("❌ [MerchantProvider] User ID not found - cannot load merchant coins");
        _availableCoins = 0.0;
        _isLoadingCoins = false;
        notifyListeners();
        return;
      }

      print("💰 [MerchantProvider] ===== FETCHING MERCHANT COINS FROM API =====");
      print("💰 [MerchantProvider] User ID: $userId");
      
      // Fetch merchant_coins from google_auth.php (returns user data from users table)
      // Try to get google_id first, otherwise use user_id
      String? googleId = prefs.getString('google_id_$userId') ?? prefs.getString('google_id');
      
      final uri = Uri.parse(ApiConstants.singleUserupdate);
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Accept': 'application/json'});
      
      if (googleId != null && googleId.isNotEmpty) {
        request.fields['google_id'] = googleId.trim();
        print("💰 [MerchantProvider] Using google_id: $googleId");
      }
      // Always include user_id (id) parameter
      request.fields['id'] = userId;
      print("💰 [MerchantProvider] Using user_id: $userId");
      
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();
      
      print("💰 [MerchantProvider] API Response Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(responseBody);
          
          if (data['status'] == 'success' && data['user'] != null) {
            final userData = data['user'] as Map<String, dynamic>;
            
            // Extract merchant_coins from user data
            if (userData['merchant_coins'] != null) {
              double? coins;
              final merchantCoinsValue = userData['merchant_coins'];
              if (merchantCoinsValue is int) {
                coins = merchantCoinsValue.toDouble();
              } else if (merchantCoinsValue is double) {
                coins = merchantCoinsValue;
              } else {
                coins = double.tryParse(merchantCoinsValue.toString());
              }
              
              if (coins != null) {
                _availableCoins = coins;
                print("✅ [MerchantProvider] Loaded merchant coins from google_auth.php: $_availableCoins");
              } else {
                _availableCoins = 0.0;
                print("⚠️ [MerchantProvider] merchant_coins value could not be parsed: ${userData['merchant_coins']}");
              }
            } else {
              _availableCoins = 0.0;
              print("⚠️ [MerchantProvider] merchant_coins field not found in response");
            }
          } else {
            _availableCoins = 0.0;
            print("⚠️ [MerchantProvider] API response status is not 'success' or user data is null");
          }
        } catch (e) {
          _availableCoins = 0.0;
          print("❌ [MerchantProvider] Error parsing API response: $e");
        }
      } else {
        _availableCoins = 0.0;
        print("❌ [MerchantProvider] API returned status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [MerchantProvider] Error loading merchant coins: $e");
      _availableCoins = 0.0;
    } finally {
      _isLoadingCoins = false;
      notifyListeners();
    }
  }

  void showTransferSheet() {
    if (!_isSheetShowing) {
      _isTransferSheetVisible = true;
      _isSheetShowing = true;
      notifyListeners();
    }
  }

  void hideTransferSheet() {
    _isTransferSheetVisible = false;
    _isSheetShowing = false;
    notifyListeners();
  }

  void setAmount(String value) {
    _amount = value;
    notifyListeners();
  }

  void setReceiverId(String value) {
    _receiverId = value;
    notifyListeners();
  }

  void setAvailableCoins(double value) {
    _availableCoins = value;
    notifyListeners();
  }

  void resetForm() {
    _amount = '';
    _receiverId = '';
    _transferError = null;
    notifyListeners();
  }

  /// Transfer coins from merchant to user
  /// Returns true if successful, false otherwise
  Future<bool> transferCoins(BuildContext context) async {
    print('💸 ========== TRANSFER COINS METHOD CALLED ==========');
    print('   - Amount: $_amount');
    print('   - Receiver ID: $_receiverId');
    print('   - Available Coins: $_availableCoins');
    
    // Validate inputs
    if (_amount.isEmpty || double.tryParse(_amount) == null || double.parse(_amount) <= 0) {
      _transferError = 'Please enter a valid amount';
      print('❌ Validation Failed: Invalid amount');
      notifyListeners();
      return false;
    }

    if (_receiverId.isEmpty) {
      _transferError = 'Please enter receiver ID';
      print('❌ Validation Failed: Receiver ID is empty');
      notifyListeners();
      return false;
    }

    final amountValue = double.parse(_amount);
    if (amountValue > _availableCoins) {
      _transferError = 'Insufficient balance. Available: $_availableCoins';
      print('❌ Validation Failed: Insufficient balance');
      print('   - Requested: $amountValue');
      print('   - Available: $_availableCoins');
      notifyListeners();
      return false;
    }

    print('✅ Validation Passed');
    _isTransferring = true;
    _transferError = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Safely get user_id (handles both int and String types)
      String merchantId = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          merchantId = userIdInt.toString();
        } else {
          merchantId = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          merchantId = userIdValue.toString();
        }
      }

      if (merchantId.isEmpty) {
        _transferError = 'User ID not found. Please login again.';
        print('❌ User ID not found in SharedPreferences');
        _isTransferring = false;
        notifyListeners();
        return false;
      }

      print('💸 ========== MERCHANT TRANSFER API CALL ==========');
      print('   - API Endpoint: https://shaheenstar.online/Merchant_Coins_Distribution_API.php');
      print('   - API Method: POST');
      print('   - Merchant ID: $merchantId');
      print('   - Receiver ID: $_receiverId');
      print('   - Amount: $_amount');
      print('   - Request Fields:');
      print('     * admin_id: $merchantId');
      print('     * merchant_id: $merchantId');
      print('     * user_id: $_receiverId');
      print('     * amount: $_amount');
      print('     * action_type: merchant_to_user');

      print('📡 Calling ApiManager.transferCoinsMerchantToUser()...');
      final response = await ApiManager.transferCoinsMerchantToUser(
        merchantId: merchantId,
        receiverId: _receiverId,
        amount: _amount,
      );

      print('📥 ========== TRANSFER API RESPONSE ==========');
      print('   - Response is null: ${response == null}');
      
      if (response != null) {
        print('   - Status: ${response.status}');
        print('   - Message: ${response.message}');
        print('   - Is Success: ${response.isSuccess}');
        print('   - Transaction ID: ${response.transactionId ?? 'N/A'}');
        print('   - New Balance: ${response.newBalance ?? 'N/A'}');
        print('   - Merchant Balance: ${response.merchantBalance ?? 'N/A'}');
      }

      if (response != null && response.isSuccess) {
        print('✅ Transfer successful');
        
        // Update merchant balance if new balance is provided
        if (response.merchantBalance != null) {
          _availableCoins = response.merchantBalance!;
          print('💰 Updated merchant balance: $_availableCoins');
        } else {
          // Deduct from current balance if new balance not provided
          _availableCoins -= amountValue;
          print('💰 Deducted amount from balance: $_availableCoins');
        }

        // Reset form
        resetForm();

        _isTransferring = false;
        notifyListeners();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty 
                  ? response.message 
                  : 'Coins transferred successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        return true;
      } else {
        _transferError = response?.message ?? 'Transfer failed. Please try again.';
        print('❌ Transfer failed: $_transferError');
        _isTransferring = false;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_transferError!),
              backgroundColor: Colors.red,
            ),
          );
        }

        return false;
      }
    } catch (e) {
      _transferError = 'Error transferring coins: ${e.toString()}';
      print('❌ Transfer exception: $e');
      _isTransferring = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_transferError!),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }
}

