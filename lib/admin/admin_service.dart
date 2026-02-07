import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/admin/ban_user_model.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';

class BanUserService {
  Future<BanUserResponse> banUser({
    required int adminUserId,
    required int targetUserId,
    required int roomId,
    required String banDuration,
  }) async {
    final url = Uri.parse(ApiConstants.banAdminUserApi);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Beare"},
      body: jsonEncode({
        "admin_user_id": adminUserId,
        "target_user_id": targetUserId,
        "room_id": roomId,
        "ban_duration": banDuration,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return BanUserResponse.fromJson(decoded);
    } else {
      throw Exception(decoded['message'] ?? "Something went wrong");
    }
  }
}
