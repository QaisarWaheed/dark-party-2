import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/model/user_register_model.dart';
// aapke model ka path

class AuthService {
  static const String token = "mySuperSecretStaticToken123";

  Future<RegisterResponseModel> registerUser({
    required String username,
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
    required String gender,
    required String dob,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.register),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    // FORM DATA
    request.fields.addAll({
      "username": username,
      "email": email,
      "password": password,
      "name": name,
      "phone": phone,
      "country": country,
      "gender": gender,
      "dob": dob,
    });

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final jsonData = json.decode(body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RegisterResponseModel.fromJson(jsonData);
    } else {
      throw Exception(jsonData['message'] ?? "Registration failed");
    }
  }
}
