import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/utils/user_session.dart';

class StoreProvider with ChangeNotifier {
  final UserSession _session = UserSession();

  // State variables
  List<StoreCategory> _categories = [];
  Map<String, List<StoreItem>> _itemsByCategory = {};
  List<BackpackItem> _backpackItems = [];
  
  bool _isLoading = false;
  bool _isLoadingBackpack = false;
  bool _isPurchasing = false;
  String? _errorMessage;
  String? _selectedCategoryId;
  StoreItem? _selectedItem;
  int _selectedDays = 30; // Default 30 days

  // Getters
  List<StoreCategory> get categories => _categories;
  Map<String, List<StoreItem>> get itemsByCategory => _itemsByCategory;
  List<StoreItem> getItemsForCategory(String categoryId) {
    return _itemsByCategory[categoryId.toLowerCase()] ?? [];
  }
  List<BackpackItem> get backpackItems => _backpackItems;
  List<BackpackItem> get activeBackpackItems {
    return _backpackItems.where((item) => item.isActive).toList();
  }
  List<BackpackItem> get expiredBackpackItems {
    return _backpackItems.where((item) => item.isExpired).toList();
  }
  
  bool get isLoading => _isLoading;
  bool get isLoadingBackpack => _isLoadingBackpack;
  bool get isPurchasing => _isPurchasing;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  StoreItem? get selectedItem => _selectedItem;
  int get selectedDays => _selectedDays;
  int? get currentUserId => _session.userId;

  /// Initialize and load mall data
  Future<void> loadMallData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🛒 [StoreProvider] Loading mall data...');
      
      final response = await ApiManager.getMallData();
      
      if (response != null && response.isSuccess) {
        _categories = response.categories;
        _itemsByCategory = response.itemsByCategory;
        _errorMessage = null;
        print('✅ [StoreProvider] Loaded ${_categories.length} categories');
      } else {
        _errorMessage = response?.message ?? 'Failed to load store data';
        print('❌ [StoreProvider] Error: $_errorMessage');
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Error loading store: $e';
      print('❌ [StoreProvider] Exception: $e');
      print('❌ [StoreProvider] Stack: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's backpack items
  Future<void> loadBackpack(String? userId) async {
    try {
      await _session.loadSession();
      
      if (_session.userId == null) {
        _errorMessage = 'Please login to view backpack';
        notifyListeners();
        return;
      }

      _isLoadingBackpack = true;
      _errorMessage = null;
      notifyListeners();

      // Use current session user if userId is null, empty, or "0"
      final effectiveUserId = (userId != null && userId.trim().isNotEmpty && userId != '0')
          ? (int.tryParse(userId.trim()) ?? _session.userId!)
          : _session.userId!;
      if (effectiveUserId == 0) {
        print('🎒 [StoreProvider] Skipping backpack load: effective user_id is 0');
        _isLoadingBackpack = false;
        notifyListeners();
        return;
      }
      print('🎒 [StoreProvider] Loading backpack for user $effectiveUserId...');

      final response = await ApiManager.getBackpack(
        userId: effectiveUserId,
      );
      
      if (response != null && response.isSuccess) {
        _backpackItems = response.items;
        _errorMessage = null;
        print('✅ [StoreProvider] Loaded ${_backpackItems.length} backpack items');
      } else {
        _errorMessage = response?.message ?? 'Failed to load backpack';
        print('❌ [StoreProvider] Error: $_errorMessage');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = 'Error loading backpack: $e';
      print('❌ [StoreProvider] Exception: $e');
      print('❌ [StoreProvider] Stack: $stackTrace');
    } finally {
      _isLoadingBackpack = false;
      notifyListeners();
    }
  }

  /// Select a category
  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId.toLowerCase();
    _selectedItem = null; // Reset selected item when category changes
    notifyListeners();
  }

  /// Select an item
  void selectItem(StoreItem? item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// Set selected days for purchase
  void setSelectedDays(int days) {
    _selectedDays = days;
    notifyListeners();
  }

  /// Purchase an item
  Future<PurchaseResponse?> purchaseItem({
    required int itemId,
    int? days,
  }) async {
    try {
      await _session.loadSession();
      
      if (_session.userId == null) {
        _errorMessage = 'Please login to purchase items';
        notifyListeners();
        return null;
      }

      _isPurchasing = true;
      _errorMessage = null;
      notifyListeners();

      final purchaseDays = days ?? _selectedDays;
      
      print('💰 [StoreProvider] Purchasing item $itemId for $purchaseDays days...');
      
      final response = await ApiManager.purchaseItem(
        userId: _session.userId!,
        itemId: itemId,
        days: purchaseDays,
      );
      
      if (response != null && response.isSuccess) {
        _errorMessage = null;
        _selectedItem = null; // Clear selection after purchase
        print('✅ [StoreProvider] Purchase successful! New balance: ${response.newBalance}');
        
        // Reload backpack to show new item
        await loadBackpack("");
        
        notifyListeners();
        return response;
      } else {
        // Use exact backend error message - no fallbacks
        _errorMessage = response?.message ?? 'Purchase failed';
        print('❌ [StoreProvider] Purchase failed: $_errorMessage');
        print('❌ [StoreProvider] Backend error status: ${response?.status}');
        notifyListeners();
        return response; // Return error response so UI can display exact message
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Error purchasing item: $e';
      print('❌ [StoreProvider] Exception: $e');
      print('❌ [StoreProvider] Stack: $stackTrace');
      notifyListeners();
      return null;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset selection
  void resetSelection() {
    _selectedItem = null;
    _selectedCategoryId = null;
    notifyListeners();
  }
}

