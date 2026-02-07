import 'package:flutter/material.dart';
import 'package:shaheen_star_app/admin/admin_service.dart';
import 'package:shaheen_star_app/admin/ban_user_model.dart';

class BanUserProvider extends ChangeNotifier {
  final BanUserService _service = BanUserService();

  bool isLoading = false;
  String? errorMessage;
  BanUserResponse? banResponse;

  Future<void> banUser({
    required int adminUserId,
    required int targetUserId,
    required int roomId,
    required String banDuration,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      banResponse = await _service.banUser(
        adminUserId: adminUserId,
        targetUserId: targetUserId,
        roomId: roomId,
        banDuration: banDuration,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
