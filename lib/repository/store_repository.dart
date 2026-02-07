import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

class StoreRepository {
  /// Get mall data (categories and items)
  /// API: mall_api.php
  static Future<MallResponse?> getMallData() async {
    return await ApiManager.getMallData();
  }

  /// Purchase an item
  /// API: purchase_item.php
  /// Payload: { "user_id": 15, "item_id": 101, "days": 7 }
  static Future<PurchaseResponse?> purchaseItem({
    required int userId,
    required int itemId,
    required int days,
  }) async {
    return await ApiManager.purchaseItem(
      userId: userId,
      itemId: itemId,
      days: days,
    );
  }

  /// Get user's backpack items
  /// API: get_backpack.php
  /// Payload: { "user_id": 15 }
  static Future<BackpackResponse?> getBackpack({
    required int userId,
  }) async {
    return await ApiManager.getBackpack(
      userId: userId,
    );
  }
}

