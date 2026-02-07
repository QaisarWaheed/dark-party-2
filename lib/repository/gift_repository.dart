import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'dart:io';

class GiftRepository {
  /// Get gifts by category
  Future<GiftResponse?> getGiftsByCategory({
    required String category,
    int limit = 50,
    int offset = 0,
    String? coinType,
    bool isActive = true,
  }) async {
    return await ApiManager.getGifts(
      category: category,
      limit: limit,
      offset: offset,
      coinType: coinType,
      isActive: isActive,
    );
  }

  /// Get all gifts
  Future<GiftResponse?> getAllGifts({
    int limit = 100,
    int offset = 0,
    String? coinType,
    bool isActive = true,
  }) async {
    return await ApiManager.getGifts(
      limit: limit,
      offset: offset,
      coinType: coinType,
      isActive: isActive,
    );
  }

  /// Add a new gift (Admin)
  Future<GiftResponse?> addGift({
    required String giftName,
    required double giftPrice,
    required String coinType,
    required String category,
    String? description,
    File? image,
    File? animationFile,
  }) async {
    return await ApiManager.addGift(
      giftName: giftName,
      giftPrice: giftPrice,
      coinType: coinType,
      category: category,
      description: description,
      image: image,
      animationFile: animationFile,
    );
  }

  /// Send a gift
  Future<SendGiftResponse?> sendGift({
    required int senderId,
    required int receiverId,
    required int roomId,
    required double giftValue,
    int? giftId,
  }) async {
    return await ApiManager.sendGift(
      senderId: senderId,
      receiverId: receiverId,
      roomId: roomId,
      giftValue: giftValue,
      giftId: giftId,
    );
  }
}

