import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/transaction_model.dart';

class WithdrawProvider with ChangeNotifier {
  // User balance state
  double _userBalance = 0.0;
  bool _isLoadingBalance = false;
  String? _balanceError;

  // Transaction history state
  List<TransactionModel> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionsError;

  // Getters
  double get userBalance => _userBalance;
  bool get isLoadingBalance => _isLoadingBalance;
  String? get balanceError => _balanceError;
  
  List<TransactionModel> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String? get transactionsError => _transactionsError;

  /// Helper method to safely get user_id from SharedPreferences
  /// Handles both int and String types
  /// Tries int first since it's commonly stored as int
  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get as int first (since it's often stored as int)
      // This avoids the type cast error when user_id is stored as int
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        print('🔍 [WithdrawProvider] user_id found as int: $userIdInt, converting to String');
        return userIdInt.toString();
      }
      
      // If not found as int, try as String
      String? userIdString = prefs.getString('user_id');
      if (userIdString != null && userIdString.isNotEmpty) {
        print('🔍 [WithdrawProvider] user_id found as String: $userIdString');
        return userIdString;
      }
      
      print('⚠️ [WithdrawProvider] user_id not found in SharedPreferences');
      return '';
    } catch (e) {
      // If there's an error, try alternative methods
      print('🔍 [WithdrawProvider] Error getting user_id, trying fallback methods: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Try the opposite type first
        String? userIdString = prefs.getString('user_id');
        if (userIdString != null && userIdString.isNotEmpty) {
          print('🔍 [WithdrawProvider] user_id found as String (fallback): $userIdString');
          return userIdString;
        }
        
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          print('🔍 [WithdrawProvider] user_id found as int (fallback): $userIdInt, converting to String');
          return userIdInt.toString();
        }
      } catch (e2) {
        print('❌ [WithdrawProvider] Error in fallback user_id retrieval: $e2');
      }
      
      // Final fallback: try to get as dynamic and convert
      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic userId = prefs.get('user_id');
        if (userId != null) {
          print('🔍 [WithdrawProvider] user_id found as dynamic: $userId (${userId.runtimeType}), converting to String');
          return userId.toString();
        }
      } catch (e3) {
        print('❌ [WithdrawProvider] Error in final fallback user_id retrieval: $e3');
      }
      return '';
    }
  }

  /// Load user balance from API
  Future<void> loadUserBalance() async {
    _isLoadingBalance = true;
    _balanceError = null;
    notifyListeners();

    try {
      String userId = await _getUserId();

      if (userId.isEmpty) {
        _isLoadingBalance = false;
        _balanceError = 'User ID not found';
        notifyListeners();
        return;
      }

      print('📊 ========== WITHDRAW PROVIDER - LOAD BALANCE ==========');
      print('   📤 User ID: $userId');
      print('   📤 User ID type: ${userId.runtimeType}');
      print('   📤 User ID length: ${userId.length}');
      print('   📤 Calling ApiManager.getUserCoinsBalance()...');

      final response = await ApiManager.getUserCoinsBalance(userId: userId);
      print('   📥 API call completed');
      print('   📥 Response is null: ${response == null}');
      
      if (response != null) {
        print('   📥 Response status: ${response.status}');
        print('   📥 Response isSuccess: ${response.isSuccess}');
        print('   📥 Response message: ${response.message}');
        print('   📥 Response balance: ${response.balance}');
        print('   📥 Response goldCoins: ${response.goldCoins}');
        print('   📥 Response diamondCoins: ${response.diamondCoins}');
        print('   📥 Response merchantCoins: ${response.merchantCoins}');
        print('   📥 Response userId: ${response.userId}');
        
        if (response.isSuccess) {
        // ✅ Use diamond_coins for withdrawal (not gold_coins)
        _userBalance = response.diamondCoins ?? 0.0;
        _balanceError = null;
        print('   ✅ Balance loaded: $_userBalance');
        print('   💎 Diamond Coins: ${response.diamondCoins ?? 0.0}');
        print('   💰 Gold Coins: ${response.goldCoins ?? 0.0}');
        print('   📊 Balance (legacy): ${response.balance}');
      } else {
          _balanceError = response.message ?? 'Failed to load balance';
          print('   ❌ API returned error: $_balanceError');
        }
      } else {
        _balanceError = 'API returned null response';
        print('   ❌ API returned null response');
      }
    } catch (e, stackTrace) {
      _balanceError = 'Error loading balance: $e';
      print('   ❌ Exception loading balance: $e');
      print('   ❌ Exception type: ${e.runtimeType}');
      print('   ❌ Stack trace: $stackTrace');
    } finally {
      _isLoadingBalance = false;
      notifyListeners();
    }
  }

  /// Load transaction history from API
  Future<void> loadTransactionHistory() async {
    _isLoadingTransactions = true;
    _transactionsError = null;
    notifyListeners();

    try {
      String userId = await _getUserId();

      if (userId.isEmpty) {
        _isLoadingTransactions = false;
        _transactionsError = 'User ID not found';
        notifyListeners();
        return;
      }

      print('📊 ========== WITHDRAW PROVIDER - LOAD TRANSACTIONS ==========');
      print('   📤 User ID: $userId');
      print('   📤 User ID type: ${userId.runtimeType}');
      print('   📤 Calling ApiManager.getTransactionHistory()...');

      final response = await ApiManager.getTransactionHistory(userId: userId);
      print('   📥 API call completed');
      print('   📥 Response is null: ${response == null}');
      
      if (response != null) {
        print('   📥 Response status: ${response.status}');
        print('   📥 Response message: ${response.message}');
        print('   📥 Response transactions count: ${response.transactions.length}');
        
        if (response.status.toLowerCase() == 'success') {
        _transactions = response.transactions;
        _transactionsError = null;
        print('   ✅ Transactions loaded: ${_transactions.length}');
      } else {
        _transactions = [];
          _transactionsError = response.message ?? 'Failed to load transactions';
          print('   ❌ API returned error: $_transactionsError');
        }
      } else {
        _transactions = [];
        _transactionsError = 'API returned null response';
        print('   ❌ API returned null response');
      }
    } catch (e, stackTrace) {
      _transactions = [];
      _transactionsError = 'Error loading transactions: $e';
      print('   ❌ Exception loading transactions: $e');
      print('   ❌ Exception type: ${e.runtimeType}');
      print('   ❌ Stack trace: $stackTrace');
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Refresh both balance and transactions
  Future<void> refresh() async {
    await Future.wait([
      loadUserBalance(),
      loadTransactionHistory(),
    ]);
  }

  /// Clear all state
  void clear() {
    _userBalance = 0.0;
    _isLoadingBalance = false;
    _balanceError = null;
    _transactions = [];
    _isLoadingTransactions = false;
    _transactionsError = null;
    notifyListeners();
  }
}

