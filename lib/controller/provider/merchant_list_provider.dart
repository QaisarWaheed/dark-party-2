import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/merchant_model.dart';

class MerchantListProvider with ChangeNotifier {
  List<MerchantModel> _merchants = [];
  List<MerchantModel> _filteredMerchants = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<MerchantModel> get merchants =>
      _filteredMerchants.isEmpty && _searchQuery.isEmpty
          ? _merchants
          : _filteredMerchants;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Fetch all users and filter merchants (merchant == 1)
  Future<void> fetchMerchants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final users = await ApiManager.getAllUsers();
      print("📊 Total users fetched: ${users.length}");

      final merchantsList =
          users
              .where((user) {
                final userMap = user as Map<String, dynamic>;

                // Merchant field exists, check if user is a merchant
                final merchant = userMap['merchant'];

                // Try different ways to parse merchant value
                int? merchantValue;
                if (merchant is int) {
                  merchantValue = merchant;
                } else if (merchant is String) {
                  merchantValue = int.tryParse(merchant);
                } else if (merchant != null) {
                  merchantValue = int.tryParse(merchant.toString());
                }

                // Only include users with merchant == 1 (merchants)
                // Exclude users with merchant == 0 (regular users)
                final isMerchant = merchantValue != null && merchantValue == 1;

                return isMerchant;
              })
              .map(
                (user) => MerchantModel.fromJson(user as Map<String, dynamic>),
              )
              .toList();

      _merchants = merchantsList;
      _filteredMerchants = _merchants;
    } catch (e, stackTrace) {
      print("❌ Error fetching merchants: $e");
      print("❌ Stack trace: $stackTrace");
      _merchants = [];
      _filteredMerchants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search merchants by ID or name
  void searchMerchants(String query) {
    _searchQuery = query.toLowerCase().trim();

    if (_searchQuery.isEmpty) {
      _filteredMerchants = _merchants;
    } else {
      _filteredMerchants =
          _merchants.where((merchant) {
            final id =
                merchant.uniqueUserId?.toLowerCase() ??
                merchant.id.toLowerCase();
            final name = merchant.name.toLowerCase();
            return id.contains(_searchQuery) || name.contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredMerchants = _merchants;
    notifyListeners();
  }
}
