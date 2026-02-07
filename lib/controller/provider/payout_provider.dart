import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';
import 'package:shaheen_star_app/model/withdrawal_model.dart';

class PayoutProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSheetShowing = false;
  String _amount = '';
  String _selectedBank = '';
  String _accountNumber = '';
  String? _errorMessage;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingPaymentMethods = false;
  PaymentMethod? _selectedPaymentMethod;

  bool get isLoading => _isLoading;
  bool get isSheetShowing => _isSheetShowing;
  String get amount => _amount;
  String get selectedBank => _selectedBank;
  String get accountNumber => _accountNumber;
  String? get errorMessage => _errorMessage;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoadingPaymentMethods => _isLoadingPaymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;

  void showPayoutSheet() {
    if (!_isSheetShowing) {
      _isSheetShowing = true;
      notifyListeners();
    }
  }

  void hidePayoutSheet() {
    _isSheetShowing = false;
    notifyListeners();
  }

  void setAmount(String value) {
    _amount = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedBank(String value) {
    _selectedBank = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedPaymentMethod(PaymentMethod? method) {
    _selectedPaymentMethod = method;
    _selectedBank = method?.name ?? '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    _isLoadingPaymentMethods = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("📤 ========== PAYOUT PROVIDER - LOAD PAYMENT METHODS ==========");
      print("   📤 Calling ApiManager.getPaymentMethods()...");
      
      final response = await ApiManager.getPaymentMethods();
      
      if (response != null && response.isSuccess) {
        print("   ✅ API Response received successfully");
        print("   ✅ Total payment methods from API: ${response.paymentMethods.length}");
        
        // Filter only active methods
        _paymentMethods = response.paymentMethods.where((method) => method.isActive).toList();
        print("   ✅ Active payment methods: ${_paymentMethods.length}");
        
        // Log each payment method
        for (int i = 0; i < _paymentMethods.length; i++) {
          final method = _paymentMethods[i];
          print("      [$i] ID: ${method.id}, Name: ${method.name}, Active: ${method.isActive}, Description: ${method.description}");
        }
      } else {
        _errorMessage = response?.message ?? 'Failed to load payment methods';
        print("   ❌ Failed to load payment methods");
        print("   ❌ Error Message: $_errorMessage");
        print("   ❌ Response Status: ${response?.status ?? 'null'}");
      }
    } catch (e, stackTrace) {
      print("   ❌ Exception loading payment methods: $e");
      print("   ❌ Exception Type: ${e.runtimeType}");
      print("   ❌ Stack Trace: $stackTrace");
      _errorMessage = 'Failed to load payment methods. Please try again.';
    } finally {
      _isLoadingPaymentMethods = false;
      notifyListeners();
    }
  }

  void setAccountNumber(String value) {
    _accountNumber = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> submitPayout(BuildContext context) async {
    // Validate form
    if (_selectedPaymentMethod == null) {
      _errorMessage = 'Please select a payment method';
      notifyListeners();
      return;
    }

    if (_accountNumber.isEmpty) {
      _errorMessage = 'Please enter account number';
      notifyListeners();
      return;
    }

    // Note: Backend automatically withdraws full balance - amount field not needed

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Safely get user_id (handles both int and String types)
      String userIdStr = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userIdStr = userIdInt.toString();
        } else {
          userIdStr = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userIdStr = userIdValue.toString();
        }
      }

      if (userIdStr.isEmpty) {
        _errorMessage = 'User ID not found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        _errorMessage = 'Invalid user ID. Please login again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Parse amount if provided (optional)
      double? amountValue;
      if (_amount.isNotEmpty) {
        amountValue = double.tryParse(_amount);
        if (amountValue == null || amountValue <= 0) {
          _errorMessage = 'Please enter a valid amount';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      print("📤 ========== PAYOUT PROVIDER - REQUEST WITHDRAWAL ==========");
      print("   🔍 User ID from SharedPreferences (String): $userIdStr");
      print("   🔍 User ID converted to int: $userId");
      print("   🔍 Payment Method ID: ${_selectedPaymentMethod!.id} (type: ${_selectedPaymentMethod!.id.runtimeType})");
      print("   🔍 Payment Method Name: ${_selectedPaymentMethod!.name}");
      print("   🔍 User Account: $_accountNumber (type: ${_accountNumber.runtimeType})");
      print("   🔍 Account Number Length: ${_accountNumber.length}");
      print("   🔍 Amount: ${amountValue != null ? amountValue.toStringAsFixed(2) : 'Not specified (full balance will be withdrawn)'}");
      
      // ✅ Get diamond balance BEFORE withdrawal to calculate correctly
      double? diamondBalanceBefore;
      try {
        final prefs = await SharedPreferences.getInstance();
        // ✅ Safely get user_id (handles both int and String types)
      String userIdStr = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userIdStr = userIdInt.toString();
        } else {
          userIdStr = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userIdStr = userIdValue.toString();
        }
      }
        final balanceResponse = await ApiManager.getUserCoinsBalance(userId: userIdStr);
        if (balanceResponse != null && balanceResponse.isSuccess) {
          diamondBalanceBefore = balanceResponse.diamondCoins ?? 0.0;
          print("   💎 Diamond balance BEFORE withdrawal: $diamondBalanceBefore");
        }
      } catch (e) {
        print("   ⚠️ Could not get balance before withdrawal: $e");
      }
      
      print("   📤 Calling ApiManager.requestWithdrawal()...");

      final response = await ApiManager.requestWithdrawal(
        userId: userId,
        paymentMethodId: _selectedPaymentMethod!.id,
        userAccount: _accountNumber,
        amount: amountValue, // Optional amount
      );

      if (response != null && response.isSuccess) {
        print("✅ Withdrawal request submitted successfully");
        print("   - Message: ${response.message}");
        
        // ✅ PRIORITIZE USER-ENTERED AMOUNT over backend response
        // Backend may return incorrect amount, so always use what user entered
        double? withdrawnAmount = amountValue;
        
        // Only use backend response amount if user didn't specify an amount (full balance withdrawal)
        if (withdrawnAmount == null && response.data != null && response.data!['amount'] != null) {
          withdrawnAmount = double.tryParse(response.data!['amount'].toString());
          print("   ⚠️ Using backend response amount (user didn't specify): $withdrawnAmount");
        } else if (withdrawnAmount != null) {
          print("   ✅ Using user-entered amount: $withdrawnAmount");
        }
        
        // Subtract diamond amount from user's total diamond balance
        if (withdrawnAmount != null && withdrawnAmount > 0) {
          try {
            final prefs = await SharedPreferences.getInstance();
            // ✅ Safely get user_id (handles both int and String types)
      String userIdStr = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userIdStr = userIdInt.toString();
        } else {
          userIdStr = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userIdStr = userIdValue.toString();
        }
      }
            
            // ✅ Calculate new balance: Use balance BEFORE withdrawal minus withdrawn amount
            // This ensures correct calculation even if backend deducted incorrectly
            double newDiamondCoins = 0.0;
            
            if (diamondBalanceBefore != null) {
              // Use balance before withdrawal to calculate correctly
              newDiamondCoins = (diamondBalanceBefore - withdrawnAmount).clamp(0.0, double.infinity);
              
              print("💎 ========== UPDATING DIAMOND BALANCE ==========");
              print("   💎 Diamond Balance BEFORE withdrawal: $diamondBalanceBefore");
              print("   💎 Withdrawn Amount: $withdrawnAmount");
              print("   💎 Calculated New Diamond Coins: $newDiamondCoins");
              
              // Also get current balance from API to verify
            final balanceResponse = await ApiManager.getUserCoinsBalance(userId: userIdStr);
            if (balanceResponse != null && balanceResponse.isSuccess) {
                double currentDiamondCoins = balanceResponse.diamondCoins ?? 0.0;
                print("   💎 Current Diamond Coins from API: $currentDiamondCoins");
                
                // ✅ Use calculated value (from before withdrawal) instead of API value
                // This ensures correct balance even if backend deducted wrong amount
                await prefs.setDouble('diamond_coins_$userIdStr', newDiamondCoins);
                print("   ✅ Diamond balance updated in cache: $newDiamondCoins");
                print("   ⚠️ Note: Using calculated value, not API value (backend may have deducted incorrectly)");
              } else {
                // If API call fails, still update cache with calculated value
                await prefs.setDouble('diamond_coins_$userIdStr', newDiamondCoins);
                print("   ✅ Diamond balance updated in cache: $newDiamondCoins");
              }
              
              print("💎 ========== DIAMOND BALANCE UPDATED ==========");
            } else {
              // Fallback: Get balance from API after withdrawal
              final balanceResponse = await ApiManager.getUserCoinsBalance(userId: userIdStr);
              if (balanceResponse != null && balanceResponse.isSuccess) {
                double currentDiamondCoins = balanceResponse.diamondCoins ?? 0.0;
                await prefs.setDouble('diamond_coins_$userIdStr', currentDiamondCoins);
                print("   ⚠️ Using API balance (could not get balance before withdrawal): $currentDiamondCoins");
              }
            }
          } catch (e) {
            print("⚠️ Could not update diamond balance: $e");
          }
        }
        
        // Reset form
        resetForm();
        
        // Refresh withdraw provider to update balance and transactions
        try {
          final withdrawProvider = Provider.of<WithdrawProvider>(context, listen: false);
          withdrawProvider.refresh();
        } catch (e) {
          print("⚠️ Could not refresh withdraw provider: $e");
        }
        
        // Close sheet
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty 
                  ? response.message 
                  : 'Withdrawal request submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _errorMessage = response?.message ?? 'Failed to submit withdrawal request. Please try again.';
        print("❌ Withdrawal request failed: $_errorMessage");
        _isLoading = false;
        notifyListeners();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error submitting withdrawal: $e");
      _errorMessage = 'Failed to submit withdrawal request. Please try again.';
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetForm() {
    _amount = '';
    _selectedBank = '';
    _accountNumber = '';
    _selectedPaymentMethod = null;
    _errorMessage = null;
    notifyListeners();
  }
}

