// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/api_manager/api_service.dart';
import 'package:shaheen_star_app/model/admin_message_model.dart';
import 'package:shaheen_star_app/model/banner_model.dart';
import 'package:shaheen_star_app/model/coin_transfer_model.dart';
import 'package:shaheen_star_app/model/leave_room_model.dart';
import 'package:shaheen_star_app/model/payout_model.dart';
import 'package:shaheen_star_app/model/profile_update_model.dart';
import 'package:shaheen_star_app/model/send_message_room_model.dart';
import 'package:shaheen_star_app/model/transaction_model.dart';
import 'package:shaheen_star_app/model/user_balance_model.dart';
import 'package:shaheen_star_app/model/user_message_model.dart';
import 'package:shaheen_star_app/model/user_system_message_model.dart';
import 'package:shaheen_star_app/model/user_sign_up_model.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:shaheen_star_app/model/gift_transaction_model.dart';
import 'package:shaheen_star_app/model/withdrawal_model.dart';
import 'package:shaheen_star_app/model/user_level_model.dart';
import 'package:shaheen_star_app/model/store_model.dart';

import '../../model/cp_gift_response.dart';
import '../../model/room_gift_response.dart';

class EmailAlreadyExistsException implements Exception {
  final String message;
  EmailAlreadyExistsException(this.message);

  @override
  String toString() => message;
}

class BannedUserException implements Exception {
  final String message;
  final Map<String, dynamic> banDetails;

  BannedUserException({required this.message, required this.banDetails});

  @override
  String toString() => message;
}

class ApiManager {
  // Generate BAISHUN signature fields: nonce, timestamp, signature, app_id, optional app_channel.
  static Map<String, String> _generateSignatureFields({
    bool includeChannel = true,
  }) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(8, (_) => rnd.nextInt(256));
    final signatureNonce = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final timestamp = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000)
        .toString();
    // Warn if the BAISHUN AppKey has not been configured.
    if (ApiConstants.baishunAppKey.isEmpty ||
        ApiConstants.baishunAppKey.contains('REPLACE')) {
      print('[ApiManager] WARNING: ApiConstants.baishunAppKey is not set.');
      print(
        '[ApiManager] Please set the real BAISHUN AppKey in ApiConstants.baishunAppKey (do NOT commit secrets).',
      );
    }

    final data = signatureNonce + ApiConstants.baishunAppKey + timestamp;
    final signature = md5.convert(utf8.encode(data)).toString().toLowerCase();
    final map = <String, String>{
      'signature_nonce': signatureNonce,
      'timestamp': timestamp,
      'signature': signature,
      'app_id': ApiConstants.baishunAppId,
    };
    if (includeChannel) map['app_channel'] = ApiConstants.baishunAppChannel;
    return map;
  }

  // Debug helper: try different signature concatenation orders to diagnose signature failures.
  static Future<Map<String, String>> _tryAlternateSignatures(
    Uri uri,
    String appId,
    int gameListType, {
    required Map<String, String> sigFields,
  }) async {
    final nonce = sigFields['signature_nonce'] ?? '';
    final ts = sigFields['timestamp'] ?? '';
    final appKey = ApiConstants.baishunAppKey;
    final orders = <String, String>{
      'nonce+appKey+ts': '$nonce$appKey$ts',
      'ts+appKey+nonce': '$ts$appKey$nonce',
      'appKey+nonce+ts': '$appKey$nonce$ts',
      'nonce+ts+appKey': '$nonce$ts$appKey',
    };

    final results = <String, String>{};
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    for (final entry in orders.entries) {
      try {
        final s = md5
            .convert(utf8.encode(entry.value))
            .toString()
            .toLowerCase();
        final payload = json.encode({
          'signature_nonce': nonce,
          'timestamp':
              int.tryParse(ts) ??
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          'signature': s,
          'app_id': int.tryParse(appId) ?? appId,
          'app_channel': ApiConstants.baishunAppChannel,
          'game_list_type': gameListType,
        });
        print(
          '[ApiManager] AltSig attempt ${entry.key} -> signature:$s payload:$payload',
        );
        final resp = await http
            .post(uri, headers: headers, body: payload)
            .timeout(const Duration(seconds: 6));
        results[entry.key] =
            'status:${resp.statusCode} body:${resp.body.length > 300 ? "${resp.body.substring(0, 300)}..." : resp.body}';
      } catch (e) {
        results[entry.key] = 'error:$e';
      }
    }

    return results;
  }

  // Helper: POST with automatic local fallback when production returns 404 or fails.
  static Future<http.Response?> _postWithFallback(
    Uri uri, {
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    try {
      // Try primary
      final primaryResp = await http.post(uri, headers: headers, body: body);
      if (primaryResp.statusCode != 404) return primaryResp;
      print(
        '[ApiManager] Primary returned 404 for ${uri.toString()}, attempting local fallback',
      );
    } catch (e) {
      print(
        '[ApiManager] Primary POST failed for ${uri.toString()}: $e — attempting local fallback',
      );
    }
    // If local fallback is disabled, return null instead of trying 127.0.0.1
    if (!ApiConstants.enableLocalFallback) {
      print(
        '[ApiManager] Local fallback disabled (ApiConstants.enableLocalFallback=false). Not attempting local POST.',
      );
      return null;
    }

    // Compute fallback URI by replacing ApiConstants.baseUrl with local host
    try {
      final primaryStr = uri.toString();
      final fallbackBase = 'http://127.0.0.1:8080/';
      if (primaryStr.startsWith(ApiConstants.baseUrl)) {
        final fallbackStr = primaryStr.replaceFirst(
          ApiConstants.baseUrl,
          fallbackBase,
        );
        final fallbackUri = Uri.parse(fallbackStr);
        try {
          final fallbackResp = await http.post(
            fallbackUri,
            headers: headers,
            body: body,
          );
          print(
            '[ApiManager] Fallback POST to $fallbackStr status: ${fallbackResp.statusCode}',
          );
          return fallbackResp;
        } catch (e) {
          print('[ApiManager] Fallback POST failed for $fallbackStr: $e');
          return null;
        }
      } else {
        print(
          '[ApiManager] Primary URI does not start with ApiConstants.baseUrl; no fallback attempted',
        );
        return null;
      }
    } catch (e) {
      print('[ApiManager] Error computing fallback URI: $e');
      return null;
    }
  }

  static Future<UserSignUpModel?> googleSignup({
    required String username,
    required String email,
    required String google_id,
    required String firebaseToken,
    String? name,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.register);
      var request = http.MultipartRequest('POST', uri);

      // ✅ Headers improve karein
      request.headers.addAll({
        'Authorization': 'Bearer $firebaseToken',
        'Accept': 'application/json',
      });

      // ✅ Required fields - matching Postman API structure
      request.fields['google_id'] = google_id.trim();
      request.fields['username'] = username.trim();
      request.fields['email'] = email.trim();

      // ✅ Add name field if provided (from Google account or user input)
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name.trim();
      } else {
        // ✅ Use username as name if name is not provided
        request.fields['name'] = username.trim();
      }

      print('📤 Google Signup Request:');
      print('   - google_id: ${request.fields['google_id']}');
      print('   - username: ${request.fields['username']}');
      print('   - name: ${request.fields['name']}');
      print('   - email: ${request.fields['email']}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Signup Response: ${response.statusCode} - $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data['status'] == 'success' && data['user'] != null) {
          print('✅ Google Signup Successful');
          // ✅ Extract token from top-level response
          final token = data['token']?.toString();
          print('🔑 Token from response: ${token != null ? "exists" : "null"}');

          // ✅ Create user model and add token if available
          final userJson = Map<String, dynamic>.from(data['user']);
          if (token != null && token.isNotEmpty) {
            userJson['api_token'] =
                token; // Add token to user object for model parsing
          }

          // ✅ Add agency_info from root level response to userJson
          if (data.containsKey('agency_info') && data['agency_info'] != null) {
            userJson['agency_info'] = data['agency_info'];
            print('🏢 ========== AGENCY INFO IN SIGNUP RESPONSE ==========');
            print('   📊 agency_info found in response');
            print('   📊 agency_info: ${data['agency_info']}');
            print('🏢 ========== AGENCY INFO END ==========');
          }

          return UserSignUpModel.fromJson(userJson);
        } else {
          // ✅ Check if email already exists
          final errorMessage = data['message']?.toString().toLowerCase() ?? '';
          print('⚠️ Signup API Error: ${data['message']}');

          // ✅ Throw custom exception for email exists case
          if (errorMessage.contains('email already exists') ||
              errorMessage.contains('email exists')) {
            throw EmailAlreadyExistsException(
              data['message'] ?? 'Email already exists',
            );
          }

          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } on EmailAlreadyExistsException {
      // ✅ Re-throw to let provider handle it
      rethrow;
    } catch (e, s) {
      print('❌ Signup Exception: $e\n$s');
      return null;
    }
  }

  static Future<UserSignUpModel?> googleLogin({
    required String google_id,
    int? wealthLevel, // ✅ Added wealth level parameter
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.login);
      var request = http.MultipartRequest('POST', uri);

      // ✅ Headers to match Postman request
      // ⚠️ NOTE: Do NOT set Content-Type manually for MultipartRequest - it's set automatically with boundary
      request.headers.addAll({'Accept': 'application/json'});

      // ✅ Add google_id field (trimmed to avoid whitespace issues)
      request.fields['google_id'] = google_id.trim();

      // ✅ Add wealth_level optional field if provided
      if (wealthLevel != null) {
        request.fields['wealth_level'] = wealthLevel.toString();
      }

      print('📤 ========== GOOGLE LOGIN REQUEST ==========');
      print('   📍 URL: ${uri.toString()}');
      print('   📋 Method: POST');
      print('   📦 Fields: ${request.fields}');
      print('   📋 Headers: ${request.headers}');
      print('📤 ========== REQUEST END ==========');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 ========== GOOGLE LOGIN RESPONSE ==========');
      print('   📊 Status Code: ${response.statusCode}');
      print(
        '   📦 Response Body: ${responseBody.isEmpty ? "(empty)" : responseBody}',
      );
      print('   📋 Response Headers: ${response.headers}');
      print('📥 ========== RESPONSE END ==========');

      // ✅ Handle empty response body for 500 errors
      if (responseBody.isEmpty && response.statusCode == 500) {
        print('❌ Server returned 500 with empty body - Server error occurred');
        print('⚠️ This might be a temporary server issue. Please try again.');
        return null;
      }

      // ✅ Try to detect ban even when response parsing fails or status is non-200
      if (responseBody.isNotEmpty) {
        final loweredBody = responseBody.toLowerCase();
        if (loweredBody.contains('"status"') &&
            loweredBody.contains('"banned"')) {
          print('🚫 ========== USER IS BANNED (STRING MATCH) ==========');
          print('   🚫 Raw response body contains status=banned');
          print('🚫 ========== BAN CHECK END ==========');
          throw BannedUserException(
            message: 'Your account has been banned',
            banDetails: const {},
          );
        }
      }

      // ✅ Try to parse response even for non-200 status codes (sometimes server returns JSON errors)
      if (responseBody.isNotEmpty) {
        try {
          final data = json.decode(responseBody);

          // ⚠️ CHECK IF USER IS BANNED (Backend sends status="banned")
          if (data is Map && data['status'] == 'banned') {
            print('🚫 ========== USER IS BANNED ==========');
            print('   🚫 Message: ${data['message']}');
            print('   🚫 Ban Details: ${data['ban_details']}');
            print('🚫 ========== BAN CHECK END ==========');

            // Throw a special exception that will be caught by the provider
            throw BannedUserException(
              message: data['message'] ?? 'Your account has been banned',
              banDetails: Map<String, dynamic>.from(data['ban_details'] ?? {}),
            );
          }

          if (response.statusCode == 200) {
            if (data['status'] == 'success' && data['user'] != null) {
              print('✅ Google Login Successful');
              // ✅ Extract token from top-level response
              final token = data['token']?.toString();
              print('🔑 ========== LOGIN TOKEN ==========');
              if (token != null && token.isNotEmpty) {
                print('🔑 Token: $token');
                print('🔑 Token Length: ${token.length}');
              } else {
                print('🔑 Token: null or empty');
              }
              print('🔑 ========== TOKEN END ==========');

              // ✅ Create user model and add token if available
              final userJson = Map<String, dynamic>.from(data['user']);
              if (token != null && token.isNotEmpty) {
                userJson['api_token'] =
                    token; // Add token to user object for model parsing
              }

              // ✅ Add agency_info from root level response to userJson
              if (data.containsKey('agency_info') &&
                  data['agency_info'] != null) {
                userJson['agency_info'] = data['agency_info'];
                print('🏢 ========== AGENCY INFO IN API RESPONSE ==========');
                print('   📊 agency_info found in response');
                print('   📊 agency_info: ${data['agency_info']}');
                print('🏢 ========== AGENCY INFO END ==========');
              }

              // ✅ Log merchant status from API response
              print('💼 ========== MERCHANT STATUS IN API RESPONSE ==========');
              print('   📊 Full user JSON: $userJson');
              print('   📊 Raw merchant value: ${userJson['merchant']}');
              print(
                '   📊 Merchant type: ${userJson['merchant']?.runtimeType}',
              );

              final userModel = UserSignUpModel.fromJson(userJson);
              print('   📊 Parsed merchant value: ${userModel.merchant}');
              print('   📊 isMerchant: ${userModel.isMerchant}');
              print('💼 ========== MERCHANT STATUS END ==========');

              return userModel;
            } else {
              print(
                '⚠️ Login API Error: ${data['message'] ?? "Unknown error"}',
              );
              return null;
            }
          } else {
            // ✅ Non-200 status but has JSON response
            print('❌ ========== GOOGLE LOGIN HTTP ERROR ==========');
            print('   ❌ Status Code: ${response.statusCode}');
            print('   ❌ Error Message: ${data['message'] ?? "Unknown error"}');
            print('   ❌ Full Response: $responseBody');
            print(
              '   ⚠️ This means merchant status cannot be fetched from backend',
            );
            print(
              '   ⚠️ App will use cached merchant status from SharedPreferences',
            );
            print('❌ ========== GOOGLE LOGIN ERROR END ==========');
            return null;
          }
        } catch (jsonError) {
          // ✅ Response is not valid JSON
          print('❌ Failed to parse response as JSON: $jsonError');
          print('❌ Raw response: $responseBody');
        }
      }

      // ✅ If we get here, response was empty or couldn't be parsed
      print('❌ ========== GOOGLE LOGIN HTTP ERROR ==========');
      print('   ❌ Status Code: ${response.statusCode}');
      print(
        '   ❌ Response Body: ${responseBody.isEmpty ? "(empty)" : responseBody}',
      );
      print('   ❌ Response Headers: ${response.headers}');
      print('   ⚠️ This means merchant status cannot be fetched from backend');
      print('   ⚠️ App will use cached merchant status from SharedPreferences');
      print('❌ ========== GOOGLE LOGIN ERROR END ==========');
      return null;
    } on BannedUserException {
      rethrow;
    } catch (e, s) {
      print('❌ Login Exception: $e\n$s');
      return null;
    }
  }

  /// GET user banners from backend. Backend returns: message, total, banners[] with image_path, redirect_url.
  /// [userId] optional – pass empty to load global banners when backend supports it.
  /// [apiToken] optional – if provided (e.g. from SharedPreferences), used as Bearer token; else static bearertoken.
  static Future<BannerModel?> getUserBanners({
    String userId = '',
    String? apiToken,
  }) async {
    try {
      final token = apiToken?.isNotEmpty == true
          ? apiToken!
          : ApiConstants.bearertoken;
      var url = Uri.parse('${ApiConstants.baseUrl}get_user_banners.php');
      final queryParams = <String, String>{};
      if (userId.isNotEmpty) queryParams['user_id'] = userId;
      queryParams['api_token'] = token;
      url = url.replace(queryParameters: queryParams);

      var response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'User-Agent': 'PostmanRuntime/7.32.3',
            },
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = response.body;

      if (response.statusCode == 200) {
        if (responseBody.trim().isEmpty) {
          print("❌ [ApiManager] Empty response body!");
          return null;
        }
        final jsonData = jsonDecode(responseBody);
        if (jsonData is! Map) {
          print("❌ [ApiManager] Response is not a JSON object");
          return null;
        }
        final bannerModel = BannerModel.fromJson(
          Map<String, dynamic>.from(jsonData),
        );
        if (bannerModel.banners.isEmpty &&
            (bannerModel.status.isNotEmpty || bannerModel.message.isNotEmpty)) {
          print(
            "🌐 [ApiManager] Banners: ${bannerModel.banners.length} (backend: ${bannerModel.message})",
          );
        }
        return bannerModel;
      } else {
        print(
          '❌ [ApiManager] get_user_banners error: ${response.statusCode} ${response.reasonPhrase}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      print('⚠️ [ApiManager] getUserBanners exception: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createRoom({
    required String name,
    required String topic,
    required String userId,
    required String isPrivate, // "0" = Private, "1" = Public
    required String password, // "" if not private
    String? profile_url,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}create_room.php'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Cookie': 'PHPSESSID=de3e757903f9e681ce3b6506827660ca',
      });

      // ✅ Fields
      request.fields.addAll({
        'user_id': userId,
        'room_name': name,
        'topic': topic,
        'is_private': isPrivate,
        'password': password,
      });

      // ✅ FIXED: Upload room profile image as file (not as string path)
      if (profile_url != null &&
          profile_url.isNotEmpty &&
          profile_url != 'yyyy') {
        try {
          // Check if it's a local file path
          if (profile_url.startsWith('/data/') ||
              profile_url.startsWith('/storage/') ||
              profile_url.contains('/cache/') ||
              profile_url.contains('/data/user/')) {
            final file = File(profile_url);
            if (await file.exists()) {
              // Get file extension
              final extension = profile_url.split('.').last;
              final filename =
                  'room_profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

              // Add file to multipart request
              final multipartFile = await http.MultipartFile.fromPath(
                'room_profile', // Field name for file upload
                profile_url,
                filename: filename,
              );
              request.files.add(multipartFile);

              print("📸 Image file added to request:");
              print("   - File path: $profile_url");
              print("   - Filename: $filename");
              print("   - File size: ${await file.length()} bytes");
            } else {
              print("⚠️ Room profile file does not exist: $profile_url");
            }
          } else if (profile_url.startsWith('http://') ||
              profile_url.startsWith('https://')) {
            // It's already a network URL, don't upload
            print("ℹ️ Room profile is already a network URL: $profile_url");
          } else if (profile_url.startsWith('uploads/')) {
            // It's a server-relative path, don't upload
            print("ℹ️ Room profile is server path: $profile_url");
          }
        } catch (e) {
          print("❌ Error adding room profile file: $e");
        }
      }

      print("📤 Sending to API:");
      print("   - user_id: $userId");
      print("   - room_name: $name");
      print("   - topic: $topic");
      print("   - is_private: $isPrivate");
      print("   - password: $password");
      print(
        "   - room_profile: ${profile_url ?? 'none'} (${request.files.length} file(s))",
      );

      http.StreamedResponse response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📥 API Response: $responseBody");

      if (response.statusCode == 200) {
        try {
          // ✅ Check if response is HTML or empty
          if (responseBody.trim().isEmpty ||
              responseBody.trim().startsWith('<!')) {
            print("❌ Received HTML response instead of JSON");
            return {
              "status": "error",
              "message": "Server returned invalid response format",
            };
          }

          final decoded = json.decode(responseBody) as Map<String, dynamic>;

          // ✅ Validate decoded response
          if (decoded.isEmpty) {
            print("❌ Invalid JSON response format");
            return {
              "status": "error",
              "message": "Invalid response format from server",
            };
          }

          // ✅ DEBUG: Check response structure
          print("🎯 Response Structure:");
          print("   - status: ${decoded["status"]}");
          print("   - message: ${decoded["message"]}");
          print("   - room: ${decoded["room"]}");
          if (decoded["room"] != null) {
            print("   - room_id: ${decoded["room"]["room_id"]}");
            print("   - room_code: ${decoded["room"]["room_code"]}");
          }

          return decoded;
        } catch (jsonError) {
          print("❌ JSON Decode Error: $jsonError");
          print("❌ Response Body: $responseBody");
          return {
            "status": "error",
            "message":
                "Failed to parse server response: ${jsonError.toString()}",
          };
        }
      } else {
        print("❌ Status code: ${response.statusCode}");
        return {
          "status": "error",
          "message": "Server error: ${response.reasonPhrase}",
        };
      }
    } catch (e) {
      print("❌ Exception: $e");
      return {"status": "error", "message": "Network error: ${e.toString()}"};
    }
  }

  /// Update room name – API: update_room_name.php (POST/PUT)
  /// Required: user_id, room_id, room_name
  static Future<Map<String, dynamic>> updateRoomName({
    required String userId,
    required String roomId,
    required String roomName,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.updateRoomNameApi);
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${ApiConstants.bearertoken}',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {'user_id': userId, 'room_id': roomId, 'room_name': roomName},
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body;
      if (response.statusCode != 200) {
        return {'status': 'error', 'message': 'HTTP ${response.statusCode}'};
      }
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        return Map<String, dynamic>.from(map);
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid JSON response'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Update room profile image – API: update_room_profile.php (POST/PUT, multipart)
  /// Required: user_id, room_id; file: room_profile (image)
  /// Optional: room_name to allow simultaneous name update or for server-side validation.
  static Future<Map<String, dynamic>> updateRoomProfile({
    required String userId,
    required String roomId,
    required String imagePath,
    String? roomName,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return {'status': 'error', 'message': 'Image file not found'};
      }
      final uri = Uri.parse(ApiConstants.updateRoomProfileApi);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
        'Accept': 'application/json',
      });
      request.fields['user_id'] = userId;
      request.fields['room_id'] = roomId;
      if (roomName != null && roomName.isNotEmpty)
        request.fields['room_name'] = roomName;
      final ext = imagePath.split('.').last;
      final name = 'room_profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      request.files.add(
        await http.MultipartFile.fromPath(
          'room_profile',
          imagePath,
          filename: name,
        ),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final responseBody = await http.Response.fromStream(
        streamed,
      ).then((r) => r.body);
      if (streamed.statusCode != 200) {
        return {'status': 'error', 'message': 'HTTP ${streamed.statusCode}'};
      }
      try {
        final map = jsonDecode(responseBody) as Map<String, dynamic>;
        return Map<String, dynamic>.from(map);
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid JSON response'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<UpdateProfileModel?> updateProfile({
    required String id,
    required String username,
    required String country,
    required String gender,
    required String dob,
    required String profile_url,
    String? name,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}update_profile.php'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Cookie': 'PHPSESSID=91e1b7e03373eaf6257bbac1471a5b5d',
      });

      // ✅ Extract filename from path for profile_url field (as string, like google_auth.php)
      String profileUrlString = '';
      String? imageFileName;

      if (profile_url.isNotEmpty) {
        try {
          File imageFile = File(profile_url);
          final fileExists = await imageFile.exists();

          if (fileExists) {
            // Get just the filename (e.g., "1000086588.jpg" from full path)
            imageFileName = imageFile.path.split('/').last;
            profileUrlString = imageFileName;
            print('📸 Image file found:');
            print('   - Full path: $profile_url');
            print('   - Filename: $imageFileName');
            print('   - profile_url (string) will be: $profileUrlString');
          } else {
            print('⚠️ Image file does not exist, using empty profile_url');
          }
        } catch (e) {
          print('⚠️ Error extracting filename: $e');
          // If it's already a string/URL, use it as is
          profileUrlString = profile_url;
        }
      }

      // ✅ BASIC FIELDS - profile_url as STRING (like google_auth.php)
      request.fields.addAll({
        'id': id,
        'username': username,
        'name':
            name ?? username, // ✅ Send name field (use username as fallback)
        'country': country,
        'gender': gender,
        'dob': dob,
        'profile_url':
            profileUrlString, // ✅ Send as STRING (filename or URL), not file path
      });

      print('📤 ========== SENDING TO BACKEND ==========');
      print('   - id: $id');
      print('   - username: $username');
      print('   - name: ${name ?? username}');
      print('   - country: $country');
      print('   - gender: $gender');
      print('   - dob: $dob');
      print('   - profile_url (as STRING): $profileUrlString');

      // ✅ PROPER IMAGE FILE UPLOAD - Send file separately if image exists
      if (profile_url.isNotEmpty && imageFileName != null) {
        print('📸 ========== IMAGE UPLOAD PROCESS ==========');
        print('   - Image path received: $profile_url');
        try {
          File imageFile = File(profile_url);
          final fileExists = await imageFile.exists();
          print('   - File exists check: $fileExists');

          if (fileExists) {
            final fileSize = await imageFile.length();
            print('   - File size: ${fileSize / 1024} KB ($fileSize bytes)');

            // Check file permissions
            try {
              final stat = await imageFile.stat();
              print('   - File is readable: true');
              print('   - File last modified: ${stat.modified}');
            } catch (e) {
              print('   ❌ ERROR: Cannot read file stats: $e');
            }

            // ✅ ACTUAL IMAGE FILE UPLOAD - Send as file in request
            print('   - Creating MultipartFile...');

            try {
              // Send file with field name 'profile_image' (or try other common names)
              final multipartFile = await http.MultipartFile.fromPath(
                'profile_image', // ✅ Backend expects this field for file upload
                profile_url,
              );

              print('   - MultipartFile created successfully');
              print('   - Field name: ${multipartFile.field}');
              print('   - Filename: ${multipartFile.filename}');
              print('   - Content length: ${multipartFile.length} bytes');
              print('   - Content type: ${multipartFile.contentType}');

              request.files.add(multipartFile);
              print('   ✅ Image file added to request');
              print('   - Total files in request: ${request.files.length}');

              // Log all files in request for debugging
              for (var file in request.files) {
                print(
                  '   - File in request: field="${file.field}", filename="${file.filename}", length=${file.length}',
                );
              }
            } catch (multipartError) {
              print('   ❌ ERROR creating MultipartFile: $multipartError');
              print('   - Error type: ${multipartError.runtimeType}');
            }
          } else {
            print(
              '   ❌ ERROR: Image file does not exist at path: $profile_url',
            );
            print('   ⚠️ Request will be sent without image file');
          }
        } catch (e, stackTrace) {
          print('   ❌ ERROR in image upload process: $e');
          print('   - Error type: ${e.runtimeType}');
          print('   - Stack trace: $stackTrace');
        }
        print('📸 ========== IMAGE UPLOAD PROCESS END ==========');
      } else {
        print(
          'ℹ️ No image file to upload - only sending profile_url as string',
        );
      }

      print('📡 Sending HTTP request...');
      print('   - Request URL: ${request.url}');
      print('   - Request method: ${request.method}');
      print('   - Headers: ${request.headers}');
      print('   - Fields count: ${request.fields.length}');
      print('   - Files count: ${request.files.length}');
      print('   - All fields: ${request.fields}');
      print('   - All files:');
      for (var file in request.files) {
        print(
          '      * ${file.field}: ${file.filename} (${file.length} bytes, ${file.contentType})',
        );
      }

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 ========== BACKEND RESPONSE ==========');
      print('   - Status code: ${response.statusCode}');
      print('   - Response headers: ${response.headers}');
      print('   - Response body: $responseBody');
      print('📥 ========== BACKEND RESPONSE END ==========');

      if (response.statusCode == 200) {
        print('✅ HTTP 200 - Success');
        try {
          final jsonResponse = json.decode(responseBody);
          print('   - JSON decoded successfully');
          print('   - Response keys: ${jsonResponse.keys}');
          print("this is a profile update json response $jsonResponse");

          final model = UpdateProfileModel.fromJson(jsonResponse);
          print('   - Model created successfully');
          print('   - Model status: ${model.status}');
          print('   - Model profileUrl: ${model.profileUrl}');

          return model;
        } catch (jsonError) {
          print('   ❌ ERROR parsing JSON: $jsonError');
          print('   - Response body: $responseBody');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   - Response body: $responseBody');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ ========== API EXCEPTION ==========');
      print('   - Error: $e');
      print('   - Error type: ${e.runtimeType}');
      print('   - Stack trace: $stackTrace');
      print('❌ ========== API EXCEPTION END ==========');
      return null;
    }
  }

  static const String baseUrl = 'https://shaheenstar.online';

  // CORRECT ENDPOINT - without spaces
  static const String sendMessageEndpoint = '/Send_Message_API.php';

  static const Map<String, String> headers = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Cookie': 'PHPSESSID=915e49cbc9666e24e71f24efcccc8307',
  };

  static const Map<String, String> getMessagesHeaders = {
    'Cookie': 'PHPSESSID=c36087dd6da3bfd55c0563bcab1af03b',
  };

  static Future<Map<String, dynamic>> joinRoom({
    required String userId,
    required String roomId, // Changed from roomCode to roomId
    required String password,
    required bool isPrivate,
  }) async {
    try {
      var headers = {
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      var request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}join_room.php'),
      );

      // ✅ CORRECT FIELDS - room_id use karo, room_code nahi
      request.bodyFields = {
        'user_id': userId,
        'room_id': roomId, // 👈 YEH CHANGE KARO
        'password': password,
        'is_private': isPrivate ? '1' : '0',
      };

      request.headers.addAll(headers);

      print("📤 Join Room API:");
      print("   URL: ${ApiConstants.baseUrl}join_room.php");
      print("   User ID: $userId");
      print("   Room ID: $roomId");
      print("   Password: $password");

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Join Room Response:");
      print("   Status: ${response.statusCode}");
      print("   Body: $responseBody");

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(responseBody);
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("❌ Join Room API Exception: $e");
      return {'status': 'error', 'message': 'Exception: $e'};
    }
  }

  /// Get Zego voice token for token auth (fixes 1001005 when Zego Console uses token authentication).
  /// Backend get_zego_token.php should accept room_id and user_id, return { "token": "04..." } or { "code": 0, "data": { "token": "..." } }.
  static Future<String?> getZegoToken({
    required String roomId,
    required String userId,
  }) async {
    if (userId.isEmpty) return null;
    try {
      final uri = Uri.parse(ApiConstants.getZegoTokenApi);
      final response = await _postWithFallback(
        uri,
        headers: {'Accept': 'application/json'},
        body: {'room_id': roomId, 'user_id': userId},
      ).timeout(const Duration(seconds: 6));
      if (response == null ||
          response.statusCode != 200 ||
          response.body.trim().isEmpty)
        return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final token = decoded['token']?.toString();
      if (token != null && token.isNotEmpty) return token;
      if (decoded['code'] == 0 && decoded['data'] is Map) {
        final t = (decoded['data'] as Map)['token']?.toString();
        if (t != null && t.isNotEmpty) return t;
      }
      return null;
    } catch (e) {
      print('[ApiManager] getZegoToken error: $e');
      return null;
    }
  }

  // ✅ LEAVE ROOM - CORRECTED
  static Future<LeaveRoomModel> leaveRoom({
    required String userId,
    required String roomId,
  }) async {
    try {
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Cookie': 'PHPSESSID=511115a174825e3508bcd1a868eb513a',
      };

      var request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}Leave_Room_API.php'),
      );

      // ✅ IMPORTANT: roomc_id use karo
      request.bodyFields = {'user_id': userId, 'roomc_id': roomId};

      request.headers.addAll(headers);

      print("📤 Leave Room API:");
      print("   User ID: $userId");
      print("   Room ID: $roomId");

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Leave Response: $responseBody");

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = _extractJsonFromMixedResponse(
          responseBody,
        );
        return LeaveRoomModel.fromJson(responseData);
      } else {
        return LeaveRoomModel(
          status: 'error',
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("❌ Leave Room Exception: $e");
      return LeaveRoomModel(status: 'error', message: 'Network error: $e');
    }
  }

  // ✅ GET ROOM MESSAGES - CORRECTED
  static Future<Map<String, dynamic>> getRoomMessages(String roomId) async {
    try {
      var headers = {'Content-Type': 'application/x-www-form-urlencoded'};

      var request = http.Request(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}Get_Room_Messages_API.php'),
      );

      request.bodyFields = {'room_id': roomId};

      request.headers.addAll(headers);

      print("📥 Get Messages API:");
      print("   Room ID: $roomId");

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Get Messages Response:");
      print("   Status: ${response.statusCode}");
      print("   Body: $responseBody");

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = _extractJsonFromMixedResponse(
          responseBody,
        );
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("❌ Get Messages Error: $e");
      return {'status': 'error', 'message': 'Exception: $e'};
    }
  }

  // ✅ JSON EXTRACTION HELPER (object only)
  static Map<String, dynamic> _extractJsonFromMixedResponse(
    String responseBody,
  ) {
    final result = _extractJsonFromMixedResponseDynamic(responseBody);
    if (result is Map<String, dynamic>) return result;
    return {'status': 'error', 'message': 'Invalid JSON format'};
  }

  /// Extracts JSON object or array from mixed response (leading newlines/HTML).
  /// Returns Map or List; use in getConversations when API may return raw array.
  static dynamic _extractJsonFromMixedResponseDynamic(String responseBody) {
    try {
      String cleanResponse = responseBody.trim();
      if (cleanResponse.isEmpty) return null;
      if (cleanResponse.contains('<!')) {
        final objStart = cleanResponse.indexOf('{');
        final arrStart = cleanResponse.indexOf('[');
        int jsonStart = -1;
        if (objStart != -1 && (arrStart == -1 || objStart < arrStart))
          jsonStart = objStart;
        if (arrStart != -1 && (objStart == -1 || arrStart < objStart))
          jsonStart = arrStart;
        if (jsonStart != -1) cleanResponse = cleanResponse.substring(jsonStart);
      }
      final s = cleanResponse;
      if (s.isEmpty) return null;
      final first = s[0];
      if (first == '[') {
        int depth = 0;
        int endIndex = -1;
        for (int i = 0; i < s.length; i++) {
          if (s[i] == '[')
            depth++;
          else if (s[i] == ']') {
            depth--;
            if (depth == 0) {
              endIndex = i;
              break;
            }
          }
        }
        if (endIndex != -1) return jsonDecode(s.substring(0, endIndex + 1));
      }
      if (first == '{') {
        int braceCount = 0;
        int startIndex = 0;
        int endIndex = -1;
        for (int i = 0; i < s.length; i++) {
          if (s[i] == '{') {
            if (startIndex == -1) startIndex = i;
            braceCount++;
          } else if (s[i] == '}') {
            braceCount--;
            if (braceCount == 0 && startIndex != -1) {
              endIndex = i;
              break;
            }
          }
        }
        if (endIndex != -1)
          return jsonDecode(s.substring(startIndex, endIndex + 1))
              as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("❌ JSON Extraction Error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkUserRoom({
    required String userId,
  }) async {
    try {
      var headers = {
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': 'PHPSESSID=de3e757903f9e681ce3b6506827660ca',
      };

      var request = http.Request(
        'POST',
        Uri.parse('https://shaheenstar.online/check_user_room.php'),
      );

      request.bodyFields = {'user_id': userId};
      request.headers.addAll(headers);

      print("📤 Check User Room API:");
      print("   User ID: $userId");

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Check Room Response:");
      print("   Status: ${response.statusCode}");
      print("   Body: $responseBody");

      if (response.statusCode == 200) {
        try {
          // ✅ Extract JSON from mixed response (may contain HTML comments)
          Map<String, dynamic> jsonResponse;

          // Check if response contains HTML comments
          if (responseBody.trim().startsWith('{')) {
            // Response starts with JSON, extract it
            int braceCount = 0;
            int startIndex = responseBody.indexOf('{');
            int endIndex = -1;

            for (int i = startIndex; i < responseBody.length; i++) {
              if (responseBody[i] == '{') {
                braceCount++;
              } else if (responseBody[i] == '}') {
                braceCount--;
                if (braceCount == 0) {
                  endIndex = i;
                  break;
                }
              }
            }

            if (endIndex != -1) {
              String cleanJson = responseBody.substring(
                startIndex,
                endIndex + 1,
              );
              jsonResponse = json.decode(cleanJson) as Map<String, dynamic>;
            } else {
              // Fallback: try to decode entire response
              jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
            }
          } else {
            // Use existing extraction method
            jsonResponse = _extractJsonFromMixedResponse(responseBody);
          }

          return jsonResponse;
        } catch (jsonError) {
          print('🔴 JSON Parse Error: $jsonError');
          print('🔴 Response Body: $responseBody');
          return {
            "status": "error",
            "message":
                "Failed to parse server response: ${jsonError.toString()}",
          };
        }
      } else {
        return {
          "status": "error",
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("❌ Check User Room Exception: $e");
      return {"status": "error", "message": "Network error: ${e.toString()}"};
    }
  }

  // // SEND MESSAGE API - Exact Postman format
  static Future<SendMessageRoomModel> sendMessage({
    required String userId,
    required String roomId,
    required String message,
  }) async {
    try {
      print("🔗 Calling Send_Message_API.php");

      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'PHPSESSID=c36087dd6da3bfd55c0563bcab1af03b',
      };

      var request = http.Request(
        'POST',
        Uri.parse('https://shaheenstar.online/Send_ Message _API.php'),
      );

      // ✅ VERIFY USER ID BEFORE SENDING
      print("🔍 Verifying User ID: $userId, Room ID: $roomId");

      request.body = json.encode({
        "user_id": userId,
        "room_id": roomId,
        "message": message,
      });

      request.headers.addAll(headers);

      print("📤 Request URL: ${request.url}");
      print("📤 Request Body: ${request.body}");

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📤 Response Status: ${response.statusCode}");
      print("📤 Response Body: $responseBody");

      if (response.statusCode == 200) {
        String cleanResponse = responseBody;
        if (cleanResponse.contains('<!saad developer>')) {
          int jsonStart = cleanResponse.indexOf('{');
          if (jsonStart != -1) {
            cleanResponse = cleanResponse.substring(jsonStart);
          }
        }
        cleanResponse = cleanResponse.trim();

        var jsonResponse = json.decode(cleanResponse);
        print("📤 Parsed JSON: $jsonResponse");

        if (jsonResponse['status'] == 'success') {
          print("✅ Message sent successfully via API");

          if (jsonResponse['data'] != null) {
            return SendMessageRoomModel.fromApiData(jsonResponse['data']);
          } else {
            return SendMessageRoomModel.fromApiData({
              'message_id': DateTime.now().millisecondsSinceEpoch,
              'user_id': userId,
              'room_id': roomId,
              'message': message,
              'sent_at': DateTime.now().toIso8601String(),
              'username': 'You',
            });
          }
        } else {
          // ✅ SPECIFIC ERROR HANDLING
          String errorMsg = jsonResponse['message'] ?? 'Unknown error';
          print("❌ API Error: $errorMsg");

          if (errorMsg.contains('foreign key constraint') ||
              errorMsg.contains('user_id')) {
            print(
              "🚨 FOREIGN KEY ERROR: User ID $userId doesn't exist in database",
            );
          }

          return SendMessageRoomModel.createLocal(
            userId: userId,
            roomId: roomId,
            message: message,
            userName: 'You',
          );
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return SendMessageRoomModel.createLocal(
          userId: userId,
          roomId: roomId,
          message: message,
          userName: 'You',
        );
      }
    } catch (e) {
      print("❌ Send Message Exception: $e");
      return SendMessageRoomModel.createLocal(
        userId: userId,
        roomId: roomId,
        message: message,
        userName: 'You',
      );
    }
  }

  // static const String baseUrl = 'https://shaheenstar.online/User-to-User_Chat_API.php';

  static final Map<String, String> userChatHeaders = {
    'Authorization': 'Bearer mySuperSecretStaticToken123',
    'Cookie': 'PHPSESSID=91e1b7e03373eaf6257bbac1471a5b5d',
  };

  // ✅ COMMON API CALL METHOD
  static Future<BaseResponseModel> _makeApiCall(
    Map<String, String> fields,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://shaheenstar.online/User-to-User_Chat_API.php'),
      );
      request.headers.addAll(userChatHeaders);
      request.fields.addAll(fields);

      print('🔵 API Call: ${fields['action']}');
      print('📤 Fields: $fields');

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> jsonResponse = _extractJsonFromMixedResponse(
            responseBody,
          );
          return BaseResponseModel.fromJson(jsonResponse);
        } catch (jsonError) {
          print('🔴 JSON Parse Error: $jsonError');
          return BaseResponseModel(
            success: false,
            message: 'Failed to parse server response',
            status: 'error',
          );
        }
      } else {
        return BaseResponseModel(
          success: false,
          message: response.reasonPhrase ?? 'Request failed',
          status: 'error',
        );
      }
    } catch (e) {
      print('🔴 API Error: $e');
      return BaseResponseModel(
        success: false,
        message: 'Network error: $e',
        status: 'error',
      );
    }
  }

  // ✅ EXTRACT JSON FROM MIXED RESPONSE
  // static Map<String, dynamic> _extractJsonFromMixedResponse(String responseBody) {
  //   try {
  //     if (responseBody.trim().startsWith('{')) {
  //       return json.decode(responseBody) as Map<String, dynamic>;
  //     }

  //     // Find JSON in mixed content
  //     final jsonStart = responseBody.indexOf('{');
  //     final jsonEnd = responseBody.lastIndexOf('}');

  //     if (jsonStart != -1 && jsonEnd != -1) {
  //       String cleanJson = responseBody.substring(jsonStart, jsonEnd + 1);
  //       return json.decode(cleanJson) as Map<String, dynamic>;
  //     }

  //     throw Exception('No JSON found in response');
  //   } catch (e) {
  //     throw Exception('JSON extraction failed: $e');
  //   }
  // }

  // ✅ 1. CREATE/GET CHATROOM
  static Future<BaseResponseModel> createChatroom(
    int user1Id,
    int user2Id,
  ) async {
    return await _makeApiCall({
      'action': 'create_chatroom',
      'user1_id': user1Id.toString(),
      'user2_id': user2Id.toString(),
    });
  }

  // ✅ 2. SEND MESSAGE
  static Future<BaseResponseModel> userSendMessage({
    required int chatroomId,
    required int senderId,
    required String message,
    String messageType = 'text',
  }) async {
    return await _makeApiCall({
      'action': 'send_message',
      'chatroom_id': chatroomId.toString(),
      'user1_id': senderId.toString(),
      'message': message,
      'message_type': messageType,
    });
  }

  // ✅ 3. GET MESSAGES - User-to-User_Chat_API.php action=get_messages
  static Future<List<ChatMessage>> getUserMessages(
    int chatroomId, {
    int? userId,
  }) async {
    final fields = <String, String>{
      'action': 'get_messages',
      'chatroom_id': chatroomId.toString(),
      'limit': '100',
      'offset': '0',
    };
    if (userId != null && userId > 0) {
      fields['user1_id'] = userId.toString();
      fields['user_id'] = userId.toString();
    }
    final response = await _makeApiCall(fields);

    if (response.success && response.data != null) {
      List<dynamic>? rawList;
      if (response.data is List) {
        rawList = response.data as List;
      } else if (response.data is Map &&
          (response.data as Map).containsKey('messages')) {
        final m = (response.data as Map)['messages'];
        if (m is List) rawList = m;
      }
      if (rawList != null && rawList.isNotEmpty) {
        return rawList
            .where((item) => item is Map)
            .map(
              (item) =>
                  ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
    }
    return [];
  }

  // ✅ 4. GET USER CHATROOMS - IMPORTANT: Fix this function
  // static Future<List<ChatRoom>> getUserChatRooms(int userId) async {
  //   final response = await _makeApiCall({
  //     'action': 'get_chatrooms',
  //     'user1_id': userId.toString(),
  //   });

  //   if (response.success) {
  //     // ✅ Check if data is List
  //     if (response.data is List) {
  //       return (response.data as List)
  //           .map((item) => ChatRoom.fromJson(item))
  //           .toList();
  //     }
  //     // ✅ Agar data object hai toh empty list return karo
  //     return [];
  //   }
  //   return [];
  // }

  static Future<List<ChatRoom>> getUserChatRooms(int userId) async {
    try {
      print('🔵 API Call: get_chatrooms');

      // ✅ Use the same endpoint as other chat operations
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}User-to-User_Chat_API.php'),
      );

      request.fields.addAll({
        'action': 'get_chatrooms',
        'user1_id': userId.toString(),
      });

      print('📤 Fields: ${request.fields}');
      request.headers.addAll(userChatHeaders);

      http.StreamedResponse response = await request.send();
      print('📥 Response Status: ${response.statusCode}');

      String responseBody = await response.stream.bytesToString();
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        // ✅ HTML COMMENTS REMOVE KARO
        responseBody = responseBody
            .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
            .trim();

        try {
          Map<String, dynamic> jsonResponse = json.decode(responseBody);

          if (jsonResponse['status'] == 'success') {
            // ✅ NESTED DATA HANDLE KARO
            dynamic dataValue = jsonResponse['data'];
            List<dynamic> chatroomsJson = [];

            if (dataValue != null) {
              if (dataValue is Map<String, dynamic>) {
                // Data is a map, try to get chatrooms array
                if (dataValue['chatrooms'] != null) {
                  chatroomsJson = dataValue['chatrooms'] as List<dynamic>;
                }
              } else if (dataValue is List) {
                // Data is directly a list
                chatroomsJson = dataValue;
              }
            }

            // ✅ Also check top-level chatrooms
            if (chatroomsJson.isEmpty && jsonResponse['chatrooms'] != null) {
              chatroomsJson = jsonResponse['chatrooms'] as List<dynamic>;
            }

            List<ChatRoom> chatRooms = chatroomsJson.map((json) {
              return ChatRoom.fromJson(json);
            }).toList();

            print('✅ Parsed ${chatRooms.length} chat rooms');
            return chatRooms;
          } else {
            print('❌ API Error: ${jsonResponse['message'] ?? 'Unknown error'}');
            return [];
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response body: $responseBody');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('❌ HTTP 404 - Endpoint or action not found');
        print('   - URL: ${request.url}');
        print('   - Action: get_chatrooms');
        print('   - This might mean the backend doesn\'t support this action');
        print('   - Response body: $responseBody');
        // ✅ Return empty list instead of failing completely
        return [];
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   - Response body: $responseBody');
        return [];
      }
    } catch (e) {
      print('❌ Exception: $e');
      return [];
    }
  }

  /// Request a server-minted one-time game code.
  /// Returns the code string on success, or null on failure.
  static Future<String?> requestGameCode({
    required String userId,
    required String roomId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.requestGameCode);
      final headers = {'Accept': 'application/json'};

      print(
        '[ApiManager] requestGameCode -> POST ${uri.toString()} user_id=$userId room_id=$roomId',
      );
      http.Response? response;
      try {
        final sigFields = _generateSignatureFields(includeChannel: false);
        final body = <String, String>{
          ...sigFields,
          'user_id': userId,
          'room_id': roomId,
        };
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] requestGameCode timeout or error: $e');
        return null;
      }

      if (response == null) {
        print(
          '[ApiManager] requestGameCode no response from primary or fallback',
        );
        return null;
      }

      print(
        '[ApiManager] requestGameCode response status: ${response.statusCode}',
      );
      print('[ApiManager] requestGameCode response body: ${response.body}');

      if (response.statusCode != 200) {
        print('[ApiManager] requestGameCode HTTP ${response.statusCode}');
        return null;
      }

      if (response.body.isEmpty) {
        print('[ApiManager] requestGameCode empty body');
        return null;
      }

      final decoded = json.decode(response.body);
      // Accept: { code: 0, data: { code: '<jwt>' } } | { status: 'success', data: { code: '...' } } | top-level code string
      if (decoded is Map) {
        if (decoded.containsKey('code') && decoded['code'] is String) {
          return decoded['code'] as String;
        }
        final data = decoded['data'];
        if (data is Map && data['code'] is String) {
          return data['code'] as String;
        }
        if (decoded['status'] == 'success' &&
            data is Map &&
            data['code'] is String) {
          return data['code'] as String;
        }
      }

      return null;
    } catch (e) {
      print('[ApiManager] requestGameCode error: $e');
      return null;
    }
  }

  /// Fetch game list from backend (BAISHUN `gamelist`)
  /// Returns a list of game objects (maps) or empty list on error.
  static Future<List<Map<String, dynamic>>> getGameList({
    int gameListType = 3,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.gameListApi);
      print(
        '[ApiManager] getGameList -> POST ${uri.toString()} game_list_type=$gameListType',
      );
      http.Response? response;
      Map<String, String> sigFields = {};
      try {
        sigFields = _generateSignatureFields(includeChannel: true);
        final body = <String, String>{
          ...sigFields,
          'game_list_type': gameListType.toString(),
        };

        // VERBOSE DEBUG: print signature components so we can verify exactly
        try {
          final nonce = sigFields['signature_nonce'];
          final ts = sigFields['timestamp'];
          final sig = sigFields['signature'];
          final concat =
              '${nonce ?? ''}${ApiConstants.baishunAppKey}${ts ?? ''}';
          print(
            '[ApiManager] Signature debug -> nonce:$nonce timestamp:$ts signature:$sig',
          );
          print(
            '[ApiManager] Signature debug -> concat (nonce+AppKey+ts): $concat',
          );
          print('[ApiManager] getGameList body fields: $body');
        } catch (e) {
          print('[ApiManager] Failed to print signature debug info: $e');
        }

        // BAISHUN expects JSON POSTs with Content-Type: application/json
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        try {
          // Build JSON payload with correct types (timestamp and app_id as numbers)
          final payload = <String, dynamic>{
            'signature_nonce': sigFields['signature_nonce'],
            'timestamp':
                int.tryParse(sigFields['timestamp'] ?? '') ??
                DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
            'signature': sigFields['signature'],
            'app_id':
                int.tryParse(ApiConstants.baishunAppId) ??
                ApiConstants.baishunAppId,
            'app_channel':
                sigFields['app_channel'] ?? ApiConstants.baishunAppChannel,
            'game_list_type': gameListType,
          };
          final jsonBody = json.encode(payload);
          print('[ApiManager] JSON POST payload: $payload');
          response = await http
              .post(uri, headers: headers, body: jsonBody)
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          // Fallback to previous behavior if direct POST fails
          print(
            '[ApiManager] Direct JSON POST failed: $e — falling back to _postWithFallback',
          );
          response = await _postWithFallback(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: body,
          ).timeout(const Duration(seconds: 8));
        }
      } catch (e) {
        print('[ApiManager] getGameList timeout or error: $e');
        return [];
      }

      if (response == null) {
        print('[ApiManager] getGameList no response from primary or fallback');
        return [];
      }

      print('[ApiManager] getGameList status: ${response.statusCode}');
      if (response.statusCode != 200) return [];
      if (response.body.trim().isEmpty) return [];

      // DEBUG: log raw response body for easier troubleshooting
      try {
        final preview = response.body.length > 400
            ? '${response.body.substring(0, 400)}... (truncated)'
            : response.body;
        print('[ApiManager] getGameList body: $preview');
      } catch (e) {
        print('[ApiManager] getGameList failed to print body: $e');
      }

      final decoded = json.decode(response.body);
      if (decoded is Map) {
        // BAISHUN-style response: { code:0, msg:'success', data: [ ... ] }
        if (decoded.containsKey('code')) {
          final code = decoded['code'];
          if ((code is int && code == 0) || (code is String && code == '0')) {
            final data = decoded['data'];
            if (data is List) {
              return data.map<Map<String, dynamic>>((e) {
                if (e is Map) return Map<String, dynamic>.from(e);
                return <String, dynamic>{};
              }).toList();
            }
          } else {
            print(
              '[ApiManager] getGameList server returned non-zero code: $code',
            );
            // If signature failed (1003), attempt alternative signature orders to debug
            try {
              if (code == 1003) {
                print(
                  '[ApiManager] Attempting alternative signature orders for debugging',
                );
                final altResults = await _tryAlternateSignatures(
                  uri,
                  ApiConstants.baishunAppId,
                  gameListType,
                  sigFields: sigFields,
                );
                print(
                  '[ApiManager] Alternative signature attempts: $altResults',
                );
              }
            } catch (e) {
              print('[ApiManager] Alternative signature probe failed: $e');
            }
            return [];
          }
        }

        // Fallback: traditional { status: 'success', data: [...] }
        final data = decoded['data'];
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
        }
      } else if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }

      return [];
    } catch (e) {
      print('[ApiManager] getGameList error: $e');
      return [];
    }
  }

  /// Fetch one game's info from BAISHUN `/v1/api/one_game_info` endpoint.
  /// Requires: `app_channel`, `app_id`, `game_id`.
  /// Returns a Map of the game's info (e.g., preview_url, load_url) or null on error.
  static Future<Map<String, dynamic>?> getOneGameInfo({
    required String appChannel,
    required String appId,
    required int gameId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.oneGameInfoApi);
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print(
        '[ApiManager] getOneGameInfo -> POST ${uri.toString()} app_channel=$appChannel app_id=$appId game_id=$gameId',
      );

      http.Response? response;
      try {
        final sigFields = _generateSignatureFields(includeChannel: true);

        // Build JSON payload with correct types (app_id and game_id as int, timestamp as int)
        final payload = <String, dynamic>{
          'app_channel': appChannel,
          'app_id': int.tryParse(appId) ?? appId,
          'game_id': gameId,
          'signature_nonce': sigFields['signature_nonce'],
          'timestamp':
              int.tryParse(sigFields['timestamp'] ?? '') ??
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          'signature': sigFields['signature'],
        };

        final jsonBody = json.encode(payload);
        print('[ApiManager] getOneGameInfo JSON payload: $payload');

        response = await http
            .post(uri, headers: headers, body: jsonBody)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getOneGameInfo timeout or error: $e');
        return null;
      }

      if (response == null) {
        print(
          '[ApiManager] getOneGameInfo no response from primary or fallback',
        );
        return null;
      }

      print(
        '[ApiManager] getOneGameInfo response status: ${response.statusCode}',
      );
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;

      final decoded = json.decode(response.body);
      if (decoded is Map) {
        // Prefer nested data object if present
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data'] as Map);
        }
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (e) {
      print('[ApiManager] getOneGameInfo error: $e');
      return null;
    }
  }

  // ----- SUD (Short Video Game SDK) API Wrappers -----
  /// Exchange one-time code for ss_token using BAISHUN-style JSON (app_id, user_id, code, signature).
  /// Use this so the app can pass ss_token in getConfig; some games (e.g. MeshH5) need ss_token in config to login.
  static Future<String?> requestSstokenWithCode({
    required String code,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getSstokenApi);
      final rnd = Random.secure();
      final nonceBytes = List<int>.generate(12, (_) => rnd.nextInt(256));
      final signatureNonce = nonceBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final timestamp = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000)
          .toString();
      final data = signatureNonce + ApiConstants.baishunAppKey + timestamp;
      final signature = md5.convert(utf8.encode(data)).toString().toLowerCase();
      final body = json.encode({
        'app_id':
            int.tryParse(ApiConstants.baishunAppId) ??
            ApiConstants.baishunAppId,
        'user_id': userId,
        'code': code,
        'signature_nonce': signatureNonce,
        'timestamp': timestamp,
        'signature': signature,
      });
      print('[ApiManager] requestSstokenWithCode -> POST $uri (BAISHUN JSON)');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        print(
          '[ApiManager] requestSstokenWithCode HTTP ${response.statusCode}',
        );
        return null;
      }
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final codeResp = decoded['code'] ?? decoded['ret_code'];
      if (codeResp != 0) {
        print(
          '[ApiManager] requestSstokenWithCode server error: ${decoded['message'] ?? decoded['msg']}',
        );
        return null;
      }
      final dataMap = decoded['data'];
      if (dataMap is Map) {
        final token = dataMap['ss_token'] ?? dataMap['sstoken'];
        if (token != null && token.toString().isNotEmpty) {
          print('[ApiManager] requestSstokenWithCode got ss_token');
          return token.toString();
        }
      }
      return null;
    } catch (e) {
      print('[ApiManager] requestSstokenWithCode error: $e');
      return null;
    }
  }

  /// Obtain ss_token from server using a client code (POST /games.php/get_sstoken)
  static Future<Map<String, dynamic>?> getSstoken({
    required String code,
    String? userId,
    bool retryIfMissing = true,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getSstokenApi);
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      http.Response? response;
      try {
        final body = <String, String>{'user_id': userId ?? '', 'code': code};
        print('[ApiManager] getSstoken -> POST $uri (form) body: $body');
        response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 8));
        print(
          '[ApiManager] getSstoken response status: ${response.statusCode}',
        );
        print(
          '[ApiManager] getSstoken response body preview: ${response.body.length > 400 ? "${response.body.substring(0, 400)}..." : response.body}',
        );
      } catch (e) {
        print('[ApiManager] getSstoken POST failed: $e');
        return null;
      }
      final body = response.body.trim();
      if (body.isEmpty) return null;

      if (response.statusCode != 200) {
        print(
          '[ApiManager] getSstoken HTTP status: ${response.statusCode} (will attempt to parse body for error details)',
        );
      }

      // Extract JSON from response (server may send leading blank lines or gzip artifacts)
      final jsonStart = body.indexOf('{');
      final bodyToDecode = jsonStart >= 0 ? body.substring(jsonStart) : body;
      final decoded = json.decode(bodyToDecode);
      if (decoded is Map) {
        final codeResp = decoded['code'] ?? decoded['ret_code'];
        if (codeResp == 0) {
          final data = decoded['data'];
          if (data is Map) {
            if (data.containsKey('ss_token'))
              return Map<String, dynamic>.from(data);
            if (data.containsKey('sstoken'))
              return {
                'ss_token': data['sstoken'],
                ...Map<String, dynamic>.from(data),
              };
            return Map<String, dynamic>.from(data);
          }
        } else {
          final errMsg =
              decoded['message'] ?? decoded['msg'] ?? decoded['ret_msg'];
          print('[ApiManager] getSstoken server error: $errMsg');

          // If token missing, ask backend to generate via its route, then retry once
          final missing =
              (codeResp == 404) ||
              (errMsg != null &&
                  errMsg.toString().toLowerCase().contains('token not found'));
          if (missing && retryIfMissing) {
            try {
              final genUri = Uri.parse(ApiConstants.generateSstokenApi);
              final genBody = <String, String>{'user_id': userId ?? ''};
              print(
                '[ApiManager] Calling backend generate_sstoken -> POST $genUri body: $genBody',
              );
              final genResp = await http
                  .post(genUri, headers: headers, body: genBody)
                  .timeout(const Duration(seconds: 8));
              print(
                '[ApiManager] generate_sstoken status: ${genResp.statusCode} body: ${genResp.body}',
              );
              if (genResp.statusCode == 200) {
                final gdec = json.decode(genResp.body);
                final gcode = gdec['code'] ?? gdec['ret_code'];
                if (gcode == 0) {
                  return await getSstoken(
                    code: code,
                    userId: userId,
                    retryIfMissing: false,
                  );
                }
              }
            } catch (e) {
              print('[ApiManager] generate_sstoken POST failed: $e');
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('[ApiManager] getSstoken error: $e');
      return null;
    }
  }

  /// Refresh ss_token (POST /games.php/update_sstoken)
  static Future<Map<String, dynamic>?> updateSstoken({
    required String ssToken,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sudUpdateSstoken);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'ss_token': ssToken},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] updateSstoken timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['ret_code'] == 0) {
        final data = decoded['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('[ApiManager] updateSstoken error: $e');
      return null;
    }
  }

  /// Get user info using ss_token (POST /games.php/get_user_info)
  static Future<Map<String, dynamic>?> getUserInfoSUD({
    required String ssToken,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sudGetUserInfo);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'ss_token': ssToken},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getUserInfoSUD timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final code = decoded['code'] ?? decoded['ret_code'];
      if (code == 0 || code == '0') {
        final data = decoded['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('[ApiManager] getUserInfoSUD error: $e');
      return null;
    }
  }

  /// Get user info by user id (POST /get_user_info.php)
  static Future<Map<String, dynamic>?> getUserInfoById(int userId) async {
    try {
      final uri = Uri.parse(ApiConstants.getUserInfoApi);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'user_id': userId.toString()},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getUserInfoById timeout or error: $e');
        return null;
      }

      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;

      final decoded = json.decode(response.body);
      if (decoded is Map) {
        // Accept both { status: 'success', data: { ... } } and { data: { ... } }
        if (decoded['status'] == 'success' && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data'] as Map);
        }
        if (decoded['data'] is Map)
          return Map<String, dynamic>.from(decoded['data'] as Map);
      }

      return null;
    } catch (e) {
      print('[ApiManager] getUserInfoById error: $e');
      return null;
    }
  }

  /// Report game info (game_start / game_settle) (POST /games.php/report_game_info)
  static Future<bool> reportGameInfo({
    required String reportType,
    required Map<String, dynamic> reportMsg,
    required String uid,
    required String ssToken,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sudReportGameInfo);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        final body = <String, String>{
          'report_type': reportType,
          'report_msg': json.encode(reportMsg),
          'uid': uid,
          'ss_token': ssToken,
        };
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] reportGameInfo timeout or error: $e');
        return false;
      }
      if (response == null) return false;
      if (response.statusCode != 200) return false;
      if (response.body.trim().isEmpty) return false;
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['ret_code'] == 0) return true;
      print(
        '[ApiManager] reportGameInfo failed: ${decoded['ret_msg'] ?? decoded}',
      );
      return false;
    } catch (e) {
      print('[ApiManager] reportGameInfo error: $e');
      return false;
    }
  }

  /// Get account info (POST /games.php/get_account)
  static Future<Map<String, dynamic>?> getAccount({required String uid}) async {
    try {
      final uri = Uri.parse(ApiConstants.sudGetAccount);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'uid': uid},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getAccount timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['ret_code'] == 0) {
        final data = decoded['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('[ApiManager] getAccount error: $e');
      return null;
    }
  }

  // ----------------- User Chat HTTP helpers -----------------
  /// Send a private chat message via backend
  static Future<bool> sendChatMessage({
    required int fromUserId,
    required int toUserId,
    required String message,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sendChatMessageUrl);
      final headers = {'Accept': 'application/json'};
      final body = <String, String>{
        // include both naming conventions for compatibility
        'from_user_id': fromUserId.toString(),
        'to_user_id': toUserId.toString(),
        'sender_id': fromUserId.toString(),
        'receiver_id': toUserId.toString(),
        'message': message,
      };
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] sendChatMessage timeout or error: $e');
        return false;
      }
      if (response == null) return false;
      if (response.statusCode != 200) return false;
      if (response.body.trim().isEmpty) return false;
      final decoded = json.decode(response.body);
      if (decoded is Map &&
          (decoded['status'] == 'success' || decoded['ret_code'] == 0))
        return true;
      print('[ApiManager] sendChatMessage failed: ${response.body}');
      return false;
    } catch (e) {
      print('[ApiManager] sendChatMessage error: $e');
      return false;
    }
  }

  /// Send a voice message via multipart form-data.
  /// Matches backend fields: sender_id, receiver_id, message (optional), voice (file), duration (seconds)
  static Future<bool> sendVoiceMessage({
    required int fromUserId,
    required int toUserId,
    File? voiceFile,
    int? duration,
    String? message,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sendChatMessageUrl);
      // Build multipart request
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Accept': 'application/json'});

      // Fields (include both naming conventions for compatibility)
      request.fields['sender_id'] = fromUserId.toString();
      request.fields['receiver_id'] = toUserId.toString();
      request.fields['from_user_id'] = fromUserId.toString();
      request.fields['to_user_id'] = toUserId.toString();
      // Backend DB often has message_type ENUM('text','image') only — use 'text' to avoid "Data truncated"
      // Voice file is still sent via 'voice' field; app shows as voice by attachmentType/attachmentUrl
      request.fields['message_type'] = 'text';
      if (message != null) request.fields['message'] = message;
      if (duration != null) request.fields['duration'] = duration.toString();

      // Attach voice file if provided
      if (voiceFile != null && await voiceFile.exists()) {
        final filename = voiceFile.path.split(Platform.pathSeparator).last;
        final mf = await http.MultipartFile.fromPath(
          'voice',
          voiceFile.path,
          filename: filename,
        );
        request.files.add(mf);
      }

      // Send request
      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        print(
          '[ApiManager] sendVoiceMessage failed status: ${response.statusCode} body: ${response.body}',
        );
        return false;
      }
      if (response.body.trim().isEmpty) return false;
      final decoded = json.decode(response.body);
      if (decoded is Map &&
          (decoded['status'] == 'success' || decoded['ret_code'] == 0))
        return true;
      print('[ApiManager] sendVoiceMessage failed: ${response.body}');
      return false;
    } catch (e) {
      print('[ApiManager] sendVoiceMessage error: $e');
      return false;
    }
  }

  /// Send an image attachment as a chat message via multipart form-data.
  /// Fields supported: sender_id, receiver_id, message (optional), image (file)
  static Future<Map<String, dynamic>?> sendImageMessage({
    required int fromUserId,
    required int toUserId,
    File? imageFile,
    String? message,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sendChatMessageUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Accept': 'application/json'});

      request.fields['sender_id'] = fromUserId.toString();
      request.fields['receiver_id'] = toUserId.toString();
      request.fields['from_user_id'] = fromUserId.toString();
      request.fields['to_user_id'] = toUserId.toString();
      if (message != null) request.fields['message'] = message;

      if (imageFile != null && await imageFile.exists()) {
        final filename = imageFile.path.split(Platform.pathSeparator).last;
        final mf = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: filename,
        );
        request.files.add(mf);
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        print(
          '[ApiManager] sendImageMessage failed status: ${response.statusCode} body: ${response.body}',
        );
        return null;
      }
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
        if (map['status'] == 'success' || map['ret_code'] == 0) return map;
        print('[ApiManager] sendImageMessage failed: ${response.body}');
        return map;
      }
      print(
        '[ApiManager] sendImageMessage unexpected response: ${response.body}',
      );
      return null;
    } catch (e) {
      print('[ApiManager] sendImageMessage error: $e');
      return null;
    }
  }

  /// Get list of conversations for a user
  static Future<List<dynamic>?> getConversations({required int userId}) async {
    try {
      final uri = Uri.parse(ApiConstants.getConversationsUrl);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'user_id': userId.toString()},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getConversations timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      dynamic decoded;
      try {
        decoded = _extractJsonFromMixedResponseDynamic(response.body);
        if (decoded == null) {
          decoded = json.decode(response.body);
        }
      } catch (_) {
        return null;
      }
      if (decoded == null) return null;
      // Normalize various possible shapes into a List<dynamic>
      try {
        // If API returns list directly (empty is valid)
        if (decoded is List) {
          return decoded;
        }

        if (decoded is Map<String, dynamic>) {
          // Common patterns: { "conversations": [...] } or { "data": [...] }
          if (decoded['conversations'] is List) {
            return List<dynamic>.from(decoded['conversations']);
          }
          if (decoded['data'] is List) {
            return List<dynamic>.from(decoded['data']);
          }

          // Some APIs wrap the list under data->conversations (empty is valid)
          if (decoded['data'] is Map &&
              decoded['data']['conversations'] is List) {
            return List<dynamic>.from(decoded['data']['conversations']);
          }

          // Sometimes the API returns a map keyed by id: { "conversations": { "123": {...}, "124": {...} } }
          if (decoded['conversations'] is Map) {
            final vals = (decoded['conversations'] as Map).values
                .map((e) => e)
                .toList();
            if (vals.isNotEmpty) return vals;
          }
          if (decoded['data'] is Map) {
            final m = decoded['data'] as Map;
            // If data contains conversation objects keyed by id, return values
            if (m.values.isNotEmpty && m.values.first is Map) {
              final vals = m.values.map((e) => e).toList();
              if (vals.isNotEmpty) return vals;
            }
          }
        }
      } catch (e) {
        print('[ApiManager] getConversations decode normalization error: $e');
        print('[ApiManager] response body: ${response.body}');
        return null;
      }

      // Unknown format or empty result. Try alternative endpoint (legacy User-to-User_Chat_API.php)
      print(
        '[ApiManager] getConversations: unexpected response format or empty: ${response.body}',
      );

      try {
        // Try legacy User-to-User_Chat_API.php using existing _makeApiCall helper with action=get_chatrooms
        final legacyResponse = await _makeApiCall({
          'action': 'get_chatrooms',
          'user1_id': userId.toString(),
        });

        if (legacyResponse.success) {
          final d = legacyResponse.data;
          if (d is List) return d;
          if (d is Map) {
            if (d['conversations'] is List)
              return List<dynamic>.from(d['conversations']);
            if (d['chatrooms'] is List)
              return List<dynamic>.from(d['chatrooms']);
            if (d['data'] is List) return List<dynamic>.from(d['data']);
            // If single conversation returned in data object
            if (d.containsKey('id') || (d['id'] != null)) return [d];
          }
          // If legacyResponse.data is a primitive or unexpected, fallthrough
          print(
            '[ApiManager] legacy get_chatrooms returned unexpected data: ${legacyResponse.data}',
          );
        } else {
          print(
            '[ApiManager] legacy get_chatrooms failed: ${legacyResponse.message}',
          );
        }
      } catch (e) {
        print('[ApiManager] legacy get_chatrooms error: $e');
      }

      return null;
    } catch (e) {
      print('[ApiManager] getConversations error: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<dynamic>?> getConversationMessages({
    int? conversationId,
    int? userId,
    int? otherUserId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getConversationMessagesUrl);
      final headers = {'Accept': 'application/json'};
      final body = <String, String>{};

      // Accept either conversation_id OR user_id + other_user_id as supported by the API
      if (conversationId != null && conversationId > 0) {
        body['conversation_id'] = conversationId.toString();
      } else if (userId != null &&
          otherUserId != null &&
          userId > 0 &&
          otherUserId > 0) {
        body['user_id'] = userId.toString();
        body['other_user_id'] = otherUserId.toString();
      } else {
        print(
          '[ApiManager] getConversationMessages called without valid identifiers',
        );
        return null;
      }

      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getConversationMessages timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        // Prefer 'data.messages' shape
        if (decoded.containsKey('data') &&
            decoded['data'] is Map &&
            (decoded['data'] as Map).containsKey('messages')) {
          final msgs = (decoded['data'] as Map)['messages'];
          if (msgs is List) return msgs;
        }
        // Or top-level 'messages'
        if (decoded.containsKey('messages') && decoded['messages'] is List)
          return decoded['messages'] as List<dynamic>;
        // Or 'data' directly as list
        if (decoded.containsKey('data') && decoded['data'] is List)
          return decoded['data'] as List<dynamic>;
      }
      if (decoded is List) return decoded;
      return null;
    } catch (e) {
      print('[ApiManager] getConversationMessages error: $e');
      return null;
    }
  }

  /// Get chat user status (online/blocked/etc)
  static Future<Map<String, dynamic>?> getChatUserStatus({
    required int userId,
    required int targetUserId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getChatUserStatusUrl);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {
            'user_id': userId.toString(),
            'blocked_user_id': targetUserId.toString(),
          },
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getChatUserStatus timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e) {
      print('[ApiManager] getChatUserStatus error: $e');
      return null;
    }
  }

  /// Block or unblock a user
  static Future<bool> blockUnblockUser({
    required int userId,
    required int targetUserId,
    required bool block,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.blockUnblockUserUrl);
      final headers = {'Accept': 'application/json'};
      final body = <String, String>{
        'user_id': userId.toString(),
        'blocked_user_id': targetUserId.toString(),
        // send both legacy numeric flag and explicit action string
        'block': block ? '1' : '0',
        'action': block ? 'block' : 'unblock',
      };
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] blockUnblockUser timeout or error: $e');
        return false;
      }
      if (response == null) return false;
      if (response.statusCode != 200) return false;
      if (response.body.trim().isEmpty) return false;
      final decoded = json.decode(response.body);
      if (decoded is Map &&
          (decoded['status'] == 'success' || decoded['ret_code'] == 0))
        return true;
      print('[ApiManager] blockUnblockUser failed: ${response.body}');
      return false;
    } catch (e) {
      print('[ApiManager] blockUnblockUser error: $e');
      return false;
    }
  }

  /// Get score (deprecated) (POST /games.php/get_score)
  static Future<Map<String, dynamic>?> getScore({required String uid}) async {
    try {
      final uri = Uri.parse(ApiConstants.sudGetScore);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: {'uid': uid},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] getScore timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['ret_code'] == 0) {
        final data = decoded['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('[ApiManager] getScore error: $e');
      return null;
    }
  }

  /// Update score (POST /games.php/update_score)
  static Future<Map<String, dynamic>?> updateScore({
    required String orderId,
    required String mgId,
    required String roundId,
    required String uid,
    required int score,
    required int type,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sudUpdateScore);
      final headers = {'Accept': 'application/json'};
      http.Response? response;
      try {
        final body = <String, String>{
          'order_id': orderId,
          'mg_id': mgId,
          'round_id': roundId,
          'uid': uid,
          'score': score.toString(),
          'type': type.toString(),
        };
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] updateScore timeout or error: $e');
        return null;
      }
      if (response == null) return null;
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['ret_code'] == 0) {
        final data = decoded['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('[ApiManager] updateScore error: $e');
      return null;
    }
  }

  // ✅ 5. MARK AS READ
  static Future<BaseResponseModel> markAsRead(int messageId) async {
    return await _makeApiCall({
      'action': 'mark_as_read',
      'message_id': messageId.toString(),
    });
  }

  /// Mark conversation messages as read via HTTP using user_id + other_user_id
  static Future<bool> markChatRead({
    required int userId,
    required int otherUserId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.markAsReadUrl);
      final headers = {'Accept': 'application/json'};
      final body = <String, String>{
        'user_id': userId.toString(),
        'other_user_id': otherUserId.toString(),
      };
      http.Response? response;
      try {
        response = await _postWithFallback(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        print('[ApiManager] markChatRead timeout or error: $e');
        return false;
      }
      if (response == null) return false;
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map &&
              (decoded['status'] == 'success' || decoded['ret_code'] == 0))
            return true;
        } catch (_) {}
      }
      // Fallback when mark_as_read.php returns 404: use User-to-User_Chat_API.php
      if (response.statusCode == 404 || response.statusCode != 200) {
        try {
          final res = await _makeApiCall({
            'action': 'mark_as_read',
            'user1_id': userId.toString(),
            'other_user_id': otherUserId.toString(),
          });
          if (res.success) return true;
        } catch (e) {
          print('[ApiManager] markChatRead fallback error: $e');
        }
      }
      return false;
    } catch (e) {
      print('[ApiManager] markChatRead error: $e');
      return false;
    }
  }

  // ✅ 6. DELETE MESSAGE
  static Future<BaseResponseModel> deleteMessage(int messageId) async {
    return await _makeApiCall({
      'action': 'delete_message',
      'message_id': messageId.toString(),
    });
  }

  /////////////////////////////////////////////////////
  ////////// Admin__Meassages///////////////////////////
  /////////////////////////////////////////////////////
  // ✅ ADMIN MESSAGES KE LIYE METHODS

  // 1️⃣ Get Admin Messages (User ke liye)
  static Future<List<AdminMessage>> getAdminMessages(int userId) async {
    try {
      final headers = {
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Cookie': 'PHPSESSID=6fb17d30923a695d88ee7094671fc732',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}Admin_Message_API.php'),
      );

      request.fields.addAll({
        'action': 'get_all', // ✅ Backend expects: send, get, delete, get_all
        'user_id': userId.toString(),
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('📩 Admin Messages Response: $responseBody');

        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        if (jsonResponse['status'] == 'success') {
          // ✅ data is a map with 'messages' array inside
          Map<String, dynamic>? dataMap = jsonResponse['data'];
          if (dataMap != null && dataMap['messages'] != null) {
            List<dynamic> messagesJson = dataMap['messages'] as List<dynamic>;
            return messagesJson
                .map((json) => AdminMessage.fromJson(json))
                .toList();
          }
          return [];
        } else {
          print('❌ Failed to get admin messages: ${jsonResponse['message']}');
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting admin messages: $e');
      return [];
    }
  }

  // 2️⃣ Send Admin Message (Admin panel ke liye - optional)
  static Future<BaseResponseModel> sendAdminMessage({
    required String messageType,
    required String title,
    required String content,
    required String country,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Cookie': 'PHPSESSID=6fb17d30923a695d88ee7094671fc732',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}Admin_Message_API.php'),
      );

      request.fields.addAll({
        'action': 'send',
        'message_type': messageType,
        'title': title,
        'content': content,
        'country': country,
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('📤 Admin Message Sent: $responseBody');

        Map<String, dynamic> jsonResponse = json.decode(responseBody);
        return BaseResponseModel.fromJson(jsonResponse);
      } else {
        return BaseResponseModel(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
          status: 'error',
        );
      }
    } catch (e) {
      print('❌ Exception sending admin message: $e');
      return BaseResponseModel(
        success: false,
        message: 'Exception: $e',
        status: 'error',
      );
    }
  }

  static Future<List<dynamic>> getAllRooms() async {
    print("🔄 [ApiManager.getAllRooms] ========== API CALL STARTED ==========");
    print("🔄 [ApiManager.getAllRooms] URL: ${ApiConstants.getAllRooms}");

    var headers = {
      'Authorization': 'Bearer mySuperSecretStaticToken123',
      'Cookie': 'PHPSESSID=511115a174825e3508bcd1a868eb513a',
    };

    try {
      print("🔄 [ApiManager.getAllRooms] Making HTTP GET request...");
      final response = await http.get(
        Uri.parse(ApiConstants.getAllRooms),
        headers: headers,
      );
      print(
        "🔄 [ApiManager.getAllRooms] HTTP request completed, status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        print("🔄 [getAllRooms] ========== API CALL SUCCESS ==========");
        print("🔄 [getAllRooms] Status Code: ${response.statusCode}");
        print("🔄 [getAllRooms] Response Body Length: ${response.body.length}");

        final decoded = json.decode(response.body);
        print("✅ [getAllRooms] Decoded Response Type: ${decoded.runtimeType}");
        print("✅ [getAllRooms] Full Response: $decoded");

        List<dynamic> roomsList = [];

        // Case 1: List directly
        if (decoded is List) {
          roomsList = decoded;
          print(
            "✅ [getAllRooms] Response is List, found ${roomsList.length} rooms",
          );
        }
        // Case 2: Response contains a 'rooms' array
        else if (decoded is Map && decoded["rooms"] is List) {
          roomsList = decoded["rooms"];
          print(
            "✅ [getAllRooms] Response is Map with 'rooms' key, found ${roomsList.length} rooms",
          );
        } else {
          print("⚠️ [getAllRooms] Unexpected format!");
          print("⚠️ [getAllRooms] Response body: ${response.body}");
          return [];
        }

        // Debug: Print first room to see available fields
        if (roomsList.isNotEmpty) {
          print("🔍 [getAllRooms] ========== FIRST ROOM ANALYSIS ==========");
          final firstRoom = roomsList[0] as Map;
          print("🔍 [getAllRooms] First Room Keys: ${firstRoom.keys.toList()}");
          print("🔍 [getAllRooms] First Room Full Data: $firstRoom");

          // Check for views field
          if (firstRoom.containsKey('views')) {
            print(
              "✅ [getAllRooms] 'views' field FOUND: ${firstRoom['views']} (type: ${firstRoom['views'].runtimeType})",
            );
          } else {
            print("⚠️ [getAllRooms] 'views' field NOT found!");
          }

          // Check for other possible view-related fields
          final possibleViewFields = [
            'view_count',
            'total_views',
            'viewers',
            'view_count',
            'total_viewers',
            'engagement',
            'popularity',
          ];
          for (var field in possibleViewFields) {
            if (firstRoom.containsKey(field)) {
              print(
                "🔍 [getAllRooms] Found alternative field '$field': ${firstRoom[field]}",
              );
            }
          }
          print("🔍 [getAllRooms] ========================================");
        } else {
          print("⚠️ [getAllRooms] No rooms found in response!");
        }

        print(
          "✅ [ApiManager.getAllRooms] ========== API CALL SUCCESS ==========",
        );
        return roomsList;
      } else {
        print(
          "❌ [ApiManager.getAllRooms] ========== API CALL FAILED ==========",
        );
        print("❌ [ApiManager.getAllRooms] Status Code: ${response.statusCode}");
        print("❌ [ApiManager.getAllRooms] Reason: ${response.reasonPhrase}");
        print("❌ [ApiManager.getAllRooms] Response Body: ${response.body}");
        return [];
      }
    } catch (e, stackTrace) {
      print(
        "❌ [ApiManager.getAllRooms] ========== EXCEPTION OCCURRED ==========",
      );
      print("❌ [ApiManager.getAllRooms] Exception: $e");
      print("❌ [ApiManager.getAllRooms] StackTrace: $stackTrace");
      return [];
    }
  }

  // ✅ Get All Users API - Returns all users, filter merchants in provider
  // Endpoint: https://shaheenstar.online/get_all_users.php
  // Method: POST (Multipart Form-Data)
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final uri = Uri.parse(ApiConstants.getAllUsers);

      print("📤 ========== GET ALL USERS API ==========");
      print("📤 Endpoint: $uri");
      print("📤 Method: POST (Multipart Form-Data)");

      // ✅ Use MultipartRequest (form-data) like other APIs
      var request = http.MultipartRequest('POST', uri);

      // Headers - same as other working APIs
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Response Status: ${response.statusCode}");
      print("📥 ========== GET ALL USERS API RESPONSE ==========");
      print("${responseBody.length}");
      print("📥 Response Body Length: ${responseBody.length}");
      print("📥 ========== GET ALL USERS API RESPONSE ==========");
      print("📥 Full Response Body:");
      print(responseBody);

      print("📥 ================================================");

      if (response.statusCode == 200) {
        try {
          // Clean response if it contains HTML comments
          String cleanedResponse = responseBody.trim();
          if (cleanedResponse.contains('<!--')) {
            print("🧹 Stripping HTML comments from response...");
            cleanedResponse = cleanedResponse
                .substring(0, cleanedResponse.indexOf('<!--'))
                .trim();
            print("🧹 Cleaned Response Length: ${cleanedResponse.length}");
          }

          final decoded = json.decode(cleanedResponse);
          print("✅ JSON Decoded Successfully for all users");
          print("✅ Decoded Type: ${decoded.runtimeType}");
          if (decoded is Map) {
            print("✅ Response Keys: ${decoded.keys.toList()}");
          }

          // Case 1: List directly
          if (decoded is List) {
            print("✅ Response is List with ${decoded.length} items");
            return decoded;
          }

          // Case 2: Response contains a 'users' array
          if (decoded is Map && decoded["users"] is List) {
            print(
              "✅ Response contains 'users' array with ${decoded["users"].length} items",
            );
            return decoded["users"];
          }

          // Case 3: Response contains a 'data' array
          if (decoded is Map && decoded["data"] is List) {
            print(
              "✅ Response contains 'data' array with ${decoded["data"].length} items",
            );
            return decoded["data"];
          }

          print("⚠️ Unexpected response format");
          return [];
        } catch (e) {
          print("❌ JSON Parse Error: $e");
          return [];
        }
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      print("❌ Exception getting all users: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAllCpUsers() async {
    try {
      final uri = Uri.parse(
        "https://shaheenstar.online/get_all_users.php?is_cp=true",
      );

      print("📤 GET ALL CP USERS API");
      print("📤 Endpoint: $uri");

      // Send GET request with Authorization header
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer mySuperSecretStaticToken123',
          'Accept': 'application/json',
        },
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body Length: ${response.body.length}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map && decoded['users'] is List) {
          print("✅ Fetched ${decoded['users'].length} CP users");
          return decoded['users'];
        }

        print("⚠️ Unexpected response format");
        return [];
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      print("❌ Exception getting CP users: $e");
      return [];
    }
  }

  static const String _baseUrl =
      '${ApiConstants.baseUrl}Room_Seats_Management_API.php';

  // ✅ Helper method to encode form data
  static String _encodeFormData(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  // ✅ Helper method to clean and parse response (PHP HTML cleanup)
  static Map<String, dynamic> _cleanAndParseResponse(String responseBody) {
    try {
      var bodyText = responseBody.trim();

      print("📄 Raw Response Length: ${bodyText.length}");
      print(
        "📄 First 200 chars: ${bodyText.substring(0, bodyText.length > 200 ? 200 : bodyText.length)}",
      );

      // JSON start dhundo
      final jsonStart = bodyText.indexOf('{');
      if (jsonStart == -1) {
        print("⚠️ No JSON found in response");
        return {'status': 'error', 'message': 'Invalid response format'};
      }

      // JSON end dhundo
      int jsonEnd = -1;
      int braceCount = 0;

      for (int i = jsonStart; i < bodyText.length; i++) {
        if (bodyText[i] == '{') {
          braceCount++;
        } else if (bodyText[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            jsonEnd = i + 1;
            break;
          }
        }
      }

      if (jsonEnd == -1) {
        print("⚠️ Incomplete JSON in response");
        return {'status': 'error', 'message': 'Malformed JSON'};
      }

      // Clean JSON extract karo
      final cleanJson = bodyText.substring(jsonStart, jsonEnd);
      print("✅ Clean JSON: $cleanJson");

      // Decode karo
      return json.decode(cleanJson);
    } catch (e) {
      print("❌ Parse Error: $e");
      return {'status': 'error', 'message': 'Parse error: $e'};
    }
  }

  // ✅ GET SEATS
  static Future<Map<String, dynamic>> getSeats(String roomId) async {
    try {
      final body = _encodeFormData({'action': 'get_seats', 'room_id': roomId});

      print("📡 Sending get_seats request: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=896c8b59d3f3f120ee266f9eac1e3205',
        },
        body: body,
      );

      print("📡 Get Seats Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = _cleanAndParseResponse(response.body);

        if (decoded['data'] != null && decoded['data']['seats'] != null) {
          print("🎯 Seats loaded: ${decoded['data']['seats'].length}");
        }

        return decoded;
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("❌ Get Seats Exception: $e");
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ✅ INITIALIZE SEATS
  static Future<Map<String, dynamic>> initializeSeats(String roomId) async {
    try {
      final body = _encodeFormData({'action': 'initialize', 'room_id': roomId});

      print("📡 Initializing room $roomId");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=896c8b59d3f3f120ee266f9eac1e3205',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return _cleanAndParseResponse(response.body);
      }
      return {'status': 'error', 'message': 'Network error'};
    } catch (e) {
      return {'status': 'error', 'message': 'Exception: $e'};
    }
  }

  // ✅ OCCUPY SEAT - FIXED
  static Future<Map<String, dynamic>> occupySeat({
    required String roomId,
    required String userId,
    required int seatNumber,
  }) async {
    try {
      final body = _encodeFormData({
        'action': 'occupy',
        'room_id': roomId,
        'user_id': userId,
        'seat_number': seatNumber.toString(),
      });

      print("📡 Occupy Seat Request: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=896c8b59d3f3f120ee266f9eac1e3205',
        },
        body: body,
      );

      print("📡 Occupy Seat Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = _cleanAndParseResponse(response.body);
        print("✅ Occupy Result: $result");
        return result;
      }
      return {'status': 'error', 'message': 'Network error'};
    } catch (e) {
      print("❌ Occupy Seat Exception: $e");
      return {'status': 'error', 'message': 'Exception: $e'};
    }
  }

  // ✅ VACATE SEAT - FIXED WITH PROPER PARSING
  static Future<Map<String, dynamic>> vacateSeat({
    required String roomId,
    required String userId,
  }) async {
    try {
      final body = _encodeFormData({
        'action': 'vacate',
        'room_id': roomId,
        'user_id': userId,
      });

      print("📡 Vacate Seat Request: $body");
      print("📡 Room ID: $roomId, User ID: $userId");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'PHPSESSID=896c8b59d3f3f120ee266f9eac1e3205',
        },
        body: body,
      );

      print("📡 Vacate Seat Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // ✅ FIX: Same parsing logic as getSeats
        final result = _cleanAndParseResponse(response.body);
        print("✅ Vacate Result: $result");
        return result;
      }

      return {
        'status': 'error',
        'message': 'Network error: ${response.statusCode}',
      };
    } catch (e) {
      print("❌ Vacate Seat Exception: $e");
      return {'status': 'error', 'message': 'Exception: $e'};
    }
  }

  // ⭐ DEBUG FUNCTION
  static Future<void> debugSeatsFlow(String roomId) async {
    print("\n🔥 ===== SEATS DEBUG TEST START ===== 🔥\n");

    print("TEST 1: Initializing room $roomId");
    var initResult = await initializeSeats(roomId);
    print("Init Response: $initResult\n");

    print("⏳ Waiting 2 seconds...\n");
    await Future.delayed(Duration(seconds: 2));

    print("TEST 2: Getting seats for room $roomId");
    var getResult = await getSeats(roomId);
    print("Get Response: $getResult");

    if (getResult['data'] != null) {
      var seatsData = getResult['data'];
      print("\n📊 SEATS DATA:");
      print("   Total Seats: ${seatsData['total_seats']}");
      print("   Occupied: ${seatsData['occupied_seats']}");
      print("   Available: ${seatsData['available_seats']}");
      print("   Seats Array Length: ${seatsData['seats']?.length ?? 0}");

      if (seatsData['seats'] != null && seatsData['seats'].length > 0) {
        print("   First Seat: ${seatsData['seats'][0]}");
      }
    }

    print("\n🔥 ===== DEBUG TEST END ===== 🔥\n");
  }

  // ============================================
  // MERCHANT & WITHDRAW APIs
  // ============================================

  /// Get user coins balance
  /// Returns UserBalanceResponse with user's current coin balance
  static Future<UserBalanceResponse?> getUserCoinsBalance({
    required String userId,
  }) async {
    try {
      final uid = userId.trim();
      if (uid.isEmpty || uid == '0') {
        print('💰 [ApiManager] getUserCoinsBalance skipped: invalid user_id');
        return null;
      }
      final uri = Uri.parse(ApiConstants.userCoinsBalance);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // Request fields
      request.fields['user_id'] = uid;

      print('💰 ========== GET USER COINS BALANCE ==========');
      print('   - User ID: ${request.fields['user_id']}');
      print('   - URL: ${uri.toString()}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          print('🔍 [ApiManager] Step 1: Cleaning response...');
          // Remove HTML comments from response (backend sometimes includes them)
          String cleanedResponse = responseBody;
          if (cleanedResponse.contains('<!--')) {
            cleanedResponse = cleanedResponse
                .substring(0, cleanedResponse.indexOf('<!--'))
                .trim();
            print('🔍 [ApiManager] Removed HTML comments from response');
          }

          print('🔍 [ApiManager] Step 2: Decoding JSON...');
          print(
            '🔍 [ApiManager] Cleaned response length: ${cleanedResponse.length}',
          );
          final data = json.decode(cleanedResponse) as Map<String, dynamic>;
          print('🔍 [ApiManager] JSON decoded successfully');
          print('🔍 [ApiManager] Data keys: ${data.keys.toList()}');
          print('🔍 [ApiManager] Data types:');
          data.forEach((key, value) {
            print('   - $key: ${value.runtimeType} = $value');
          });

          // Handle nested data structure: data.gold_coins
          Map<String, dynamic> responseData = data;
          print(
            '🔍 [ApiManager] Step 3: Processing response data structure...',
          );
          if (data.containsKey('data') && data['data'] is Map) {
            // ✅ Safely convert to Map<String, dynamic>
            Map<String, dynamic> dataObj;
            try {
              if (data['data'] is Map<String, dynamic>) {
                dataObj = data['data'] as Map<String, dynamic>;
              } else {
                dataObj = Map<String, dynamic>.from(data['data'] as Map);
              }
            } catch (e) {
              print('⚠️ [ApiManager] Error converting data to Map: $e');
              dataObj = <String, dynamic>{};
            }
            // ✅ Safely convert status and message to String (handle int types)
            print('🔍 [ApiManager] Step 5: Converting status and message...');
            String statusValue = 'error';
            if (data['status'] != null) {
              print(
                '🔍 [ApiManager] status type: ${data['status'].runtimeType}, value: ${data['status']}',
              );
              statusValue = data['status'].toString();
              print('🔍 [ApiManager] status converted to: $statusValue');
            }

            String? messageValue;
            if (data['message'] != null) {
              print(
                '🔍 [ApiManager] message type: ${data['message'].runtimeType}, value: ${data['message']}',
              );
              messageValue = data['message'].toString();
              print('🔍 [ApiManager] message converted to: $messageValue');
            }

            // ✅ Safely convert user_id to String (handle int types)
            print('🔍 [ApiManager] Step 6: Converting user_id...');
            String userIdValue = '';
            if (dataObj['user_id'] != null) {
              print(
                '🔍 [ApiManager] dataObj[\'user_id\'] type: ${dataObj['user_id'].runtimeType}, value: ${dataObj['user_id']}',
              );
              userIdValue = dataObj['user_id'].toString();
              print('🔍 [ApiManager] user_id converted to: $userIdValue');
            } else if (data['user_id'] != null) {
              print(
                '🔍 [ApiManager] data[\'user_id\'] type: ${data['user_id'].runtimeType}, value: ${data['user_id']}',
              );
              userIdValue = data['user_id'].toString();
              print('🔍 [ApiManager] user_id converted to: $userIdValue');
            }

            // Merge data object into main response for easier parsing
            print('🔍 [ApiManager] Step 7: Building responseData map...');
            print(
              '🔍 [ApiManager] gold_coins type: ${dataObj['gold_coins'].runtimeType}, value: ${dataObj['gold_coins']}',
            );
            print(
              '🔍 [ApiManager] diamond_coins type: ${dataObj['diamond_coins'].runtimeType}, value: ${dataObj['diamond_coins']}',
            );
            print(
              '🔍 [ApiManager] merchant_coins type: ${dataObj['merchant_coins'].runtimeType}, value: ${dataObj['merchant_coins']}',
            );
            responseData = {
              'status': statusValue,
              'message': messageValue,
              'user_id': userIdValue,
              'gold_coins': dataObj['gold_coins'],
              'diamond_coins': dataObj['diamond_coins'],
              'merchant_coins':
                  dataObj['merchant_coins'], // ✅ Include merchant_coins if available
              'balance': dataObj['gold_coins'], // Map gold_coins to balance
              'data': dataObj,
            };
            print('🔍 [ApiManager] responseData built successfully');
            print(
              '🔍 [ApiManager] responseData keys: ${responseData.keys.toList()}',
            );
            print(
              '💰 [ApiManager] Response data keys: ${dataObj.keys.toList()}',
            );
            print(
              '💰 [ApiManager] merchant_coins in response: ${dataObj['merchant_coins']}',
            );
          } else {
            print(
              '🔍 [ApiManager] Step 4: No nested data structure, processing root level...',
            );
            // ✅ Handle case where data is at root level - ensure status/message are strings
            if (responseData['status'] != null &&
                responseData['status'] is! String) {
              print(
                '🔍 [ApiManager] Converting root level status from ${responseData['status'].runtimeType} to String',
              );
              responseData['status'] = responseData['status'].toString();
            }
            if (responseData['message'] != null &&
                responseData['message'] is! String) {
              print(
                '🔍 [ApiManager] Converting root level message from ${responseData['message'].runtimeType} to String',
              );
              responseData['message'] = responseData['message'].toString();
            }
            if (responseData['user_id'] != null &&
                responseData['user_id'] is! String) {
              print(
                '🔍 [ApiManager] Converting root level user_id from ${responseData['user_id'].runtimeType} to String',
              );
              responseData['user_id'] = responseData['user_id'].toString();
            }
            print('🔍 [ApiManager] Root level processing complete');
            print(
              '🔍 [ApiManager] Final responseData keys: ${responseData.keys.toList()}',
            );
            print('🔍 [ApiManager] Final responseData types:');
            responseData.forEach((key, value) {
              print('   - $key: ${value.runtimeType} = $value');
            });
          }

          print(
            '🔍 [ApiManager] Step 8: Calling UserBalanceResponse.fromJson...',
          );
          UserBalanceResponse? balanceResponse;
          try {
            print(
              '🔍 [ApiManager] About to parse with UserBalanceResponse.fromJson',
            );
            print('🔍 [ApiManager] responseData being passed: $responseData');
            balanceResponse = UserBalanceResponse.fromJson(responseData);
            print(
              '🔍 [ApiManager] UserBalanceResponse.fromJson completed successfully',
            );
          } catch (e, stackTrace) {
            print('❌ [ApiManager] Error parsing UserBalanceResponse: $e');
            print('❌ [ApiManager] Error type: ${e.runtimeType}');
            print('❌ [ApiManager] Stack trace: $stackTrace');
            print('❌ [ApiManager] Response data that failed: $responseData');
            print('❌ [ApiManager] Response data types:');
            responseData.forEach((key, value) {
              print('   - $key: ${value.runtimeType} = $value');
            });
            return null;
          }

          if (balanceResponse.isSuccess) {
            print('✅ User Balance Retrieved Successfully');
            print(
              '   - Balance (legacy/gold_coins): ${balanceResponse.balance}',
            );
            print('   - Gold Coins: ${balanceResponse.goldCoins ?? 'N/A'}');
            print(
              '   - Diamond Coins: ${balanceResponse.diamondCoins ?? 'N/A'}',
            );
            print(
              '   - Merchant Coins: ${balanceResponse.merchantCoins ?? 'N/A'}',
            );
            return balanceResponse;
          } else {
            print('⚠️ API Error: ${balanceResponse.message}');
            return null;
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response: $responseBody');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Get User Balance Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  /// Transfer coins from Merchant to User
  /// Returns CoinTransferResponse with transaction details
  static Future<CoinTransferResponse?> transferCoinsMerchantToUser({
    required String merchantId,
    required String receiverId,
    required String amount,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.merchantCoinsDistribution);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // Request fields - Updated API format: admin_id, merchant_id, user_id, amount, action_type
      // Backend automatically adds to user's GOLD coins (not diamond coins)
      request.fields['admin_id'] = merchantId
          .trim(); // admin_id is same as merchant_id for merchant transfers
      request.fields['merchant_id'] = merchantId.trim();
      request.fields['user_id'] = receiverId
          .trim(); // user_id is the receiver (user receiving coins)
      request.fields['amount'] = amount.trim();
      request.fields['action_type'] =
          'merchant_to_user'; // Action type: merchant_to_user or admin_to_merchant

      print('💸 ========== MERCHANT TO USER TRANSFER API ==========');
      print('   - API Endpoint: ${ApiConstants.merchantCoinsDistribution}');
      print('   - API Method: POST');
      print('   - Headers:');
      print('     * Authorization: Bearer mySuperSecretStaticToken123');
      print('     * Accept: application/json');
      print('   - Request Fields:');
      print('     * admin_id: ${request.fields['admin_id']}');
      print('     * merchant_id: ${request.fields['merchant_id']}');
      print('     * user_id: ${request.fields['user_id']}');
      print('     * amount: ${request.fields['amount']}');
      print('     * action_type: ${request.fields['action_type']}');
      print(
        '   - Backend automatically adds to user\'s GOLD coins in user_coins table',
      );
      print(
        '   - Backend deducts from merchant\'s merchant_coins in users table',
      );
      print('   - Full URL: ${uri.toString()}');

      print('📤 Sending HTTP request...');
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 ========== MERCHANT TRANSFER API RESPONSE ==========');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Headers: ${response.headers}');
      print('   - Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          // Strip HTML comments from response (backend sometimes includes them)
          String cleanedResponse = responseBody;
          if (cleanedResponse.contains('<!--')) {
            cleanedResponse = cleanedResponse
                .substring(0, cleanedResponse.indexOf('<!--'))
                .trim();
            print('🧹 Stripped HTML comments from response');
          }

          print('📋 Parsing JSON response...');
          final data = json.decode(cleanedResponse) as Map<String, dynamic>;
          print('   - JSON Keys: ${data.keys.toList()}');
          print('   - Raw JSON Data: $data');

          print('📋 Creating CoinTransferResponse from JSON...');
          final transferResponse = CoinTransferResponse.fromJson(data);

          print('📋 Parsed Response:');
          print('   - Status: ${transferResponse.status}');
          print('   - Message: ${transferResponse.message}');
          print('   - Is Success: ${transferResponse.isSuccess}');
          print(
            '   - Transaction ID: ${transferResponse.transactionId ?? 'N/A'}',
          );
          print('   - New Balance: ${transferResponse.newBalance ?? 'N/A'}');
          print(
            '   - Merchant Balance: ${transferResponse.merchantBalance ?? 'N/A'}',
          );

          if (transferResponse.isSuccess) {
            print('✅ ========== TRANSFER SUCCESSFUL ==========');
            print(
              '   - Transaction ID: ${transferResponse.transactionId ?? 'N/A'}',
            );
            print('   - Message: ${transferResponse.message}');
            print('   - New Balance: ${transferResponse.newBalance ?? 'N/A'}');
            print(
              '   - Merchant Balance: ${transferResponse.merchantBalance ?? 'N/A'}',
            );
            return transferResponse;
          } else {
            print('⚠️ ========== TRANSFER FAILED ==========');
            print('   - Status: ${transferResponse.status}');
            print('   - Message: ${transferResponse.message}');
            return transferResponse; // Return response even on failure for error message
          }
        } catch (e, stackTrace) {
          print('❌ ========== JSON PARSE ERROR ==========');
          print('   - Error: $e');
          print('   - Stack Trace: $stackTrace');
          print('   - Response Body: $responseBody');
          return null;
        }
      } else {
        print('❌ ========== HTTP ERROR ==========');
        print('   - Status Code: ${response.statusCode}');
        print('   - Response Body: $responseBody');
        return null;
      }
    } catch (e, s) {
      print('❌ Transfer Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  /// Transfer coins from User to User (Gifting)
  /// Returns CoinTransferResponse with transaction details
  /// Note: This API requires room_id and gift_value (not amount)
  static Future<CoinTransferResponse?> transferCoinsUserToUser({
    required String senderId,
    required String receiverId,
    required String amount,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.userToUserGifting);

      // Ensure values are not empty
      final senderIdValue = senderId.trim();
      final receiverIdValue = receiverId.trim();
      final amountValue = amount.trim();
      final roomIdValue =
          '0'; // Default room_id for direct user-to-user transfer

      if (senderIdValue.isEmpty ||
          receiverIdValue.isEmpty ||
          amountValue.isEmpty) {
        print('❌ Missing required values');
        print('   - Sender ID: $senderIdValue');
        print('   - Receiver ID: $receiverIdValue');
        print('   - Amount: $amountValue');
        return null;
      }

      // ✅ Use MultipartRequest (form-data) - API expects multipart/form-data
      var request = http.MultipartRequest('POST', uri);

      // Headers - include Authorization like other working APIs
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // ✅ Add form fields - API requires: sender_id, receiver_id, room_id, gift_value
      request.fields['sender_id'] = senderIdValue;
      request.fields['receiver_id'] = receiverIdValue;
      request.fields['room_id'] = roomIdValue;
      request.fields['gift_value'] =
          amountValue; // API expects 'gift_value' not 'amount'

      print('🎁 ========== USER TO USER TRANSFER ==========');
      print('   - Sender ID: $senderIdValue');
      print('   - Receiver ID: $receiverIdValue');
      print('   - Room ID: $roomIdValue');
      print('   - Gift Value: $amountValue');
      print('   - URL: ${uri.toString()}');
      print('   - Request Type: POST (multipart/form-data)');
      print('   - Request Fields:');
      print('     * sender_id: ${request.fields['sender_id']}');
      print('     * receiver_id: ${request.fields['receiver_id']}');
      print('     * room_id: ${request.fields['room_id']}');
      print('     * gift_value: ${request.fields['gift_value']}');

      // Debug: Print the actual request being sent
      print('📤 Sending POST Request (Multipart Form-Data)...');
      print('   - Method: ${request.method}');
      print('   - URL: ${request.url}');
      print('   - Headers: ${request.headers}');
      print('   - Fields Count: ${request.fields.length}');
      print('   - All Fields: ${request.fields}');

      // Verify all required fields are present
      if (!request.fields.containsKey('sender_id') ||
          !request.fields.containsKey('receiver_id') ||
          !request.fields.containsKey('room_id') ||
          !request.fields.containsKey('gift_value')) {
        print('❌ ERROR: Missing fields in form data!');
        print('   - Has sender_id: ${request.fields.containsKey('sender_id')}');
        print(
          '   - Has receiver_id: ${request.fields.containsKey('receiver_id')}',
        );
        print('   - Has room_id: ${request.fields.containsKey('room_id')}');
        print(
          '   - Has gift_value: ${request.fields.containsKey('gift_value')}',
        );
        return null;
      }

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;
          final transferResponse = CoinTransferResponse.fromJson(data);

          if (transferResponse.isSuccess) {
            print('✅ Transfer Successful');
            print('   - Transaction ID: ${transferResponse.transactionId}');
            print('   - New Balance: ${transferResponse.newBalance ?? 'N/A'}');
            return transferResponse;
          } else {
            print('⚠️ Transfer Failed: ${transferResponse.message}');
            return transferResponse; // Return response even on failure for error message
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response: $responseBody');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Transfer Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  /// Transfer diamonds to merchant (agents redeem to merchant)
  static Future<CoinTransferResponse?> transferDiamondToMerchant({
    required String userId,
    required String merchantId,
    required String amount,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.transferDiamondToMerchant);
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
        'Accept': 'application/json',
      });

      // Backend expects form-data keys: sender_id, merchant_id, diamond_coins
      request.fields['sender_id'] = userId.trim();
      request.fields['merchant_id'] = merchantId.trim();
      request.fields['diamond_coins'] = amount.trim();

      print('💎 ========== TRANSFER DIAMOND TO MERCHANT =========');
      print('   - Endpoint: ${ApiConstants.transferDiamondToMerchant}');
      print(
        '   - Fields: sender_id=$userId, merchant_id=$merchantId, diamond_coins=$amount',
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Response Code: ${response.statusCode}');
      print('📥 Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          String cleaned = responseBody;
          if (cleaned.contains('<!--')) {
            cleaned = cleaned.substring(0, cleaned.indexOf('<!--')).trim();
          }
          final data = json.decode(cleaned) as Map<String, dynamic>;
          final transferResponse = CoinTransferResponse.fromJson(data);
          return transferResponse;
        } catch (e, s) {
          print('❌ Parse error: $e');
          print(s);
          return null;
        }
      }
      return null;
    } catch (e, s) {
      print('❌ transferDiamondToMerchant exception: $e');
      print(s);
      return null;
    }
  }

  /// Exchange diamonds to gold (user converts diamonds)
  /// Sends form-data: user_id, diamond_coins
  static Future<CoinTransferResponse?> exchangeDiamondToGold({
    required String userId,
    required String diamondCoins,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.exchangeDiamondToGold);
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
        'Accept': 'application/json',
      });

      request.fields['user_id'] = userId.trim();
      request.fields['diamond_coins'] = diamondCoins.trim();

      print('💱 ========== EXCHANGE DIAMOND TO GOLD =========');
      print('   - Endpoint: ${ApiConstants.exchangeDiamondToGold}');
      print('   - Fields: user_id=$userId, diamond_coins=$diamondCoins');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Response Code: ${response.statusCode}');
      print('📥 Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          String cleaned = responseBody;
          if (cleaned.contains('<!--')) {
            cleaned = cleaned.substring(0, cleaned.indexOf('<!--')).trim();
          }
          final data = json.decode(cleaned) as Map<String, dynamic>;
          final exchangeResponse = CoinTransferResponse.fromJson(data);
          return exchangeResponse;
        } catch (e, s) {
          print('❌ Parse error: $e');
          print(s);
          return null;
        }
      }
      return null;
    } catch (e, s) {
      print('❌ exchangeDiamondToGold exception: $e');
      print(s);
      return null;
    }
  }

  /// Get user messages from get_user_messages.php (coin transactions, admin messages e.g. welcome 5000 coins)
  static Future<GetUserMessagesResponse?> getUserMessagesApi({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.getUserMessagesApi).replace(
        queryParameters: <String, String>{
          'user_id': userId,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      print('📬 [ApiManager] getUserMessages: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.token}',
          'Accept': 'application/json',
        },
      );
      final responseBody = response.body;
      if (response.statusCode == 200) {
        try {
          String cleaned = responseBody;
          if (cleaned.contains('<!--')) {
            cleaned = cleaned.substring(0, cleaned.indexOf('<!--')).trim();
          }
          final data = json.decode(cleaned) as Map<String, dynamic>;
          return GetUserMessagesResponse.fromJson(data);
        } catch (e) {
          print('❌ [ApiManager] getUserMessages parse error: $e');
          return null;
        }
      }
      print('❌ [ApiManager] getUserMessages HTTP ${response.statusCode}');
      return null;
    } catch (e, s) {
      print('❌ [ApiManager] getUserMessages exception: $e');
      print(s);
      return null;
    }
  }

  /// Get transaction history for a user
  /// Returns TransactionHistoryResponse with list of transactions
  static Future<TransactionHistoryResponse?> getTransactionHistory({
    required String userId,
    String? type, // Optional: 'all', 'transfer', 'payout', 'received', 'sent'
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.transactionHistory);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // Request fields
      request.fields['user_id'] = userId.trim();
      if (type != null && type.isNotEmpty) {
        request.fields['type'] = type.trim();
      }

      print('📜 ========== GET TRANSACTION HISTORY ==========');
      print('   - User ID: ${request.fields['user_id']}');
      print('   - Type: ${request.fields['type'] ?? 'all'}');
      print('   - URL: ${uri.toString()}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          print('🔍 [ApiManager] Step 1: Cleaning transaction response...');
          // Remove HTML comments from response (backend sometimes includes them)
          String cleanedResponse = responseBody;
          if (cleanedResponse.contains('<!--')) {
            cleanedResponse = cleanedResponse
                .substring(0, cleanedResponse.indexOf('<!--'))
                .trim();
            print('🔍 [ApiManager] Removed HTML comments from response');
          }

          print('🔍 [ApiManager] Step 2: Decoding JSON...');
          print(
            '🔍 [ApiManager] Cleaned response length: ${cleanedResponse.length}',
          );
          final data = json.decode(cleanedResponse) as Map<String, dynamic>;
          print('🔍 [ApiManager] JSON decoded successfully');
          print('🔍 [ApiManager] Data keys: ${data.keys.toList()}');
          print('🔍 [ApiManager] Data types:');
          data.forEach((key, value) {
            print('   - $key: ${value.runtimeType} = $value');
          });

          // Handle nested data structure: data.transactions
          Map<String, dynamic> responseData = data;
          print(
            '🔍 [ApiManager] Step 3: Processing response data structure...',
          );
          if (data.containsKey('data') && data['data'] is Map) {
            print('🔍 [ApiManager] Step 4: Found nested data structure');
            // ✅ Safely convert to Map<String, dynamic>
            Map<String, dynamic> dataObj;
            try {
              print('🔍 [ApiManager] Converting data object...');
              print(
                '🔍 [ApiManager] data[\'data\'] type: ${data['data'].runtimeType}',
              );
              if (data['data'] is Map<String, dynamic>) {
                print(
                  '🔍 [ApiManager] data[\'data\'] is already Map<String, dynamic>',
                );
                dataObj = data['data'] as Map<String, dynamic>;
              } else {
                print(
                  '🔍 [ApiManager] Converting data[\'data\'] from Map to Map<String, dynamic>',
                );
                dataObj = Map<String, dynamic>.from(data['data'] as Map);
              }
              print('🔍 [ApiManager] Data object converted successfully');
              print('🔍 [ApiManager] DataObj keys: ${dataObj.keys.toList()}');
              print('🔍 [ApiManager] DataObj types:');
              dataObj.forEach((key, value) {
                print('   - $key: ${value.runtimeType} = $value');
              });
            } catch (e, stackTrace) {
              print('⚠️ [ApiManager] Error converting data to Map: $e');
              print('⚠️ [ApiManager] Stack trace: $stackTrace');
              dataObj = <String, dynamic>{};
            }

            // ✅ Safely convert status and message to String (handle int types)
            print('🔍 [ApiManager] Step 5: Converting status and message...');
            String statusValue = 'error';
            if (data['status'] != null) {
              print(
                '🔍 [ApiManager] status type: ${data['status'].runtimeType}, value: ${data['status']}',
              );
              statusValue = data['status'].toString();
              print('🔍 [ApiManager] status converted to: $statusValue');
            }

            String? messageValue;
            if (data['message'] != null) {
              print(
                '🔍 [ApiManager] message type: ${data['message'].runtimeType}, value: ${data['message']}',
              );
              messageValue = data['message'].toString();
              print('🔍 [ApiManager] message converted to: $messageValue');
            }

            // ✅ Safely handle transactions list - ensure all items are properly formatted
            print('🔍 [ApiManager] Step 6: Processing transactions list...');
            List<dynamic> transactionsList = [];
            if (dataObj['transactions'] != null &&
                dataObj['transactions'] is List) {
              print(
                '🔍 [ApiManager] Found transactions list, count: ${(dataObj['transactions'] as List).length}',
              );
              transactionsList = dataObj['transactions'] as List;
              print('🔍 [ApiManager] Transactions list extracted');
            } else {
              print('🔍 [ApiManager] No transactions list found or not a List');
              print(
                '🔍 [ApiManager] dataObj[\'transactions\'] type: ${dataObj['transactions']?.runtimeType}',
              );
            }

            print('🔍 [ApiManager] Step 7: Building responseData map...');
            responseData = {
              'status': statusValue,
              'message': messageValue,
              'transactions': transactionsList,
            };
            print('🔍 [ApiManager] responseData built successfully');
            print(
              '🔍 [ApiManager] responseData keys: ${responseData.keys.toList()}',
            );
            print(
              '🔍 [ApiManager] Transactions count in responseData: ${transactionsList.length}',
            );
          } else {
            print(
              '🔍 [ApiManager] Step 4: No nested data structure, processing root level...',
            );
            // ✅ Handle case where data is at root level - ensure status/message are strings
            if (responseData['status'] != null &&
                responseData['status'] is! String) {
              print(
                '🔍 [ApiManager] Converting root level status from ${responseData['status'].runtimeType} to String',
              );
              responseData['status'] = responseData['status'].toString();
            }
            if (responseData['message'] != null &&
                responseData['message'] is! String) {
              print(
                '🔍 [ApiManager] Converting root level message from ${responseData['message'].runtimeType} to String',
              );
              responseData['message'] = responseData['message'].toString();
            }
            print('🔍 [ApiManager] Root level processing complete');
            print(
              '🔍 [ApiManager] Final responseData keys: ${responseData.keys.toList()}',
            );
            print('🔍 [ApiManager] Final responseData types:');
            responseData.forEach((key, value) {
              if (value is List) {
                print(
                  '   - $key: ${value.runtimeType} = List(${value.length})',
                );
              } else {
                print('   - $key: ${value.runtimeType} = $value');
              }
            });
          }

          print(
            '🔍 [ApiManager] Step 8: Calling TransactionHistoryResponse.fromJson...',
          );
          TransactionHistoryResponse? historyResponse;
          try {
            print(
              '🔍 [ApiManager] About to parse with TransactionHistoryResponse.fromJson',
            );
            print('🔍 [ApiManager] responseData being passed: $responseData');
            historyResponse = TransactionHistoryResponse.fromJson(responseData);
            print(
              '🔍 [ApiManager] TransactionHistoryResponse.fromJson completed successfully',
            );
          } catch (e, stackTrace) {
            print(
              '❌ [ApiManager] Error parsing TransactionHistoryResponse: $e',
            );
            print('❌ [ApiManager] Error type: ${e.runtimeType}');
            print('❌ [ApiManager] Stack trace: $stackTrace');
            print('❌ [ApiManager] Response data that failed: $responseData');
            print('❌ [ApiManager] Response data types:');
            responseData.forEach((key, value) {
              print('   - $key: ${value.runtimeType} = $value');
            });
            return null;
          }

          if (historyResponse.status.toLowerCase() == 'success') {
            print('✅ Transaction History Retrieved');
            print(
              '   - Total Transactions: ${historyResponse.transactions.length}',
            );
            return historyResponse;
          } else {
            print(
              '⚠️ API Error: ${historyResponse.message ?? 'Unknown error'}',
            );
            return historyResponse; // Return response even on failure
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response: $responseBody');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Get Transaction History Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  static Future<PayoutResponse?> submitPayout({
    required String userId,
    required String amount,
    required String bankName, // 'Jazz Cash', 'Easy Paisa', 'Bank Transfer'
    required String accountNumber,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.transactionHistory);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // Request fields
      request.fields['user_id'] = userId.trim();
      request.fields['amount'] = amount.trim();
      request.fields['bank_name'] = bankName.trim();
      request.fields['account_number'] = accountNumber.trim();
      request.fields['action'] = 'payout'; // Indicate this is a payout request

      print('💳 ========== SUBMIT PAYOUT ==========');
      print('   - User ID: ${request.fields['user_id']}');
      print('   - Amount: ${request.fields['amount']}');
      print('   - Bank: ${request.fields['bank_name']}');
      print('   - Account: ${request.fields['account_number']}');
      print('   - URL: ${uri.toString()}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          // Extract JSON from response that may contain HTML comments
          String cleanResponse = responseBody;

          // Remove HTML comments if present
          if (cleanResponse.contains('<!--')) {
            int jsonStart = cleanResponse.indexOf('{');
            if (jsonStart != -1) {
              cleanResponse = cleanResponse.substring(jsonStart);
              // Find the last closing brace to get complete JSON
              int lastBrace = cleanResponse.lastIndexOf('}');
              if (lastBrace != -1) {
                cleanResponse = cleanResponse.substring(0, lastBrace + 1);
              }
            }
          }

          cleanResponse = cleanResponse.trim();

          print('🧹 Cleaned Response: $cleanResponse');

          final data = json.decode(cleanResponse) as Map<String, dynamic>;
          final payoutResponse = PayoutResponse.fromJson(data);

          if (payoutResponse.isSuccess) {
            print('✅ Payout Submitted Successfully');
            print('   - Transaction ID: ${payoutResponse.transactionId}');
            print('   - Status: ${payoutResponse.payoutStatus ?? 'pending'}');
            return payoutResponse;
          } else {
            print('⚠️ Payout Failed: ${payoutResponse.message}');
            return payoutResponse; // Return response even on failure for error message
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response: $responseBody');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Submit Payout Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  // ========== GIFT APIs ==========

  /// Get gifts from API
  /// Parameters: category (optional), limit (optional), offset (optional), coin_type (optional), is_active (optional)
  static Future<GiftResponse?> getGifts({
    String? category,
    int? limit,
    int? offset,
    String? coinType,
    bool? isActive,
  }) async {
    try {
      var uri = Uri.parse(ApiConstants.getGifts);

      // Build query parameters
      Map<String, String> queryParams = {};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category.toLowerCase();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }
      if (coinType != null && coinType.isNotEmpty) {
        queryParams['coin_type'] = coinType.toLowerCase();
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive ? '1' : '0';
      }

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('🎁 ========== GET GIFTS ==========');
      print('   - URL: ${uri.toString()}');

      final response = await http.get(uri);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          String responseBody = response.body;

          // ✅ Fix: Handle concatenated JSON objects from backend
          // Backend sometimes returns multiple JSON objects: {...}{...}
          // Extract the first valid JSON object
          if (responseBody.contains('}{')) {
            print(
              '⚠️ Detected concatenated JSON objects, extracting first valid JSON...',
            );
            // Find the first complete JSON object
            int firstBrace = responseBody.indexOf('{');
            int lastBrace = responseBody.lastIndexOf('}');

            if (firstBrace != -1 && lastBrace != -1) {
              // Try to find where the first JSON object ends
              int braceCount = 0;
              int endIndex = firstBrace;

              for (int i = firstBrace; i < responseBody.length; i++) {
                if (responseBody[i] == '{') {
                  braceCount++;
                } else if (responseBody[i] == '}') {
                  braceCount--;
                  if (braceCount == 0) {
                    endIndex = i + 1;
                    break;
                  }
                }
              }

              if (endIndex > firstBrace) {
                responseBody = responseBody.substring(firstBrace, endIndex);
                print(
                  '✅ Extracted first JSON object (${responseBody.length} chars)',
                );
              }
            }
          }

          final data = json.decode(responseBody) as Map<String, dynamic>;

          // ✅ Log raw gift data structure for analysis
          if (data['data'] != null && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap['gifts'] != null && dataMap['gifts'] is List) {
              final giftsList = dataMap['gifts'] as List;
              print('📦 ===== RAW GIFT DATA ANALYSIS =====');
              print('   Total gifts in response: ${giftsList.length}');
              for (var i = 0; i < giftsList.length && i < 5; i++) {
                final gift = giftsList[i] as Map<String, dynamic>;
                print(
                  '   --- Gift ${i + 1} (ID: ${gift['id']}, Name: ${gift['gift_name']}) ---',
                );
                print('      gift_image: ${gift['gift_image'] ?? 'null'}');
                print('      gift_video: ${gift['gift_video'] ?? 'null'}');
                print('      gift_svg: ${gift['gift_svg'] ?? 'null'}');
                print('      gift_file: ${gift['gift_file'] ?? 'null'}');
                print('      file_type: ${gift['file_type'] ?? 'null'}');
              }
              if (giftsList.length > 5) {
                print('   ... and ${giftsList.length - 5} more gifts');
              }
              print('   ====================================');
            }
          }

          final giftResponse = GiftResponse.fromJson(data);

          if (giftResponse.isSuccess) {
            print(
              '✅ Gifts Fetched Successfully: ${giftResponse.gifts.length} gifts',
            );
            return giftResponse;
          } else {
            print('⚠️ Get Gifts Failed: ${giftResponse.message}');
            return giftResponse;
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('   - Response body length: ${response.body.length}');
          print(
            '   - Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
          );
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Get Gifts Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  /// Add a new gift (Admin function)
  /// Parameters: gift_name, gift_price, coin_type, category, description, image (file), animation_file (file)
  static Future<GiftResponse?> addGift({
    required String giftName,
    required double giftPrice,
    required String coinType,
    required String category,
    String? description,
    File? image,
    File? animationFile,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.addGift);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConstants.token}',
        'Accept': 'application/json',
      });

      // Required fields
      request.fields['gift_name'] = giftName.trim();
      request.fields['gift_price'] = giftPrice.toString();
      request.fields['coin_type'] = coinType.toLowerCase().trim();
      request.fields['category'] = category.toLowerCase().trim();

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description.trim();
      }

      // Add image file if provided
      if (image != null && await image.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      // Add animation file if provided
      if (animationFile != null && await animationFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'animation_file',
            animationFile.path,
          ),
        );
      }

      print('🎁 ========== ADD GIFT ==========');
      print('   - Name: ${request.fields['gift_name']}');
      print('   - Price: ${request.fields['gift_price']}');
      print('   - Coin Type: ${request.fields['coin_type']}');
      print('   - Category: ${request.fields['category']}');
      print('   - Has Image: ${image != null}');
      print('   - Has Animation: ${animationFile != null}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;
          final giftResponse = GiftResponse.fromJson(data);

          if (giftResponse.isSuccess) {
            print('✅ Gift Added Successfully');
            return giftResponse;
          } else {
            print('⚠️ Add Gift Failed: ${giftResponse.message}');
            return giftResponse;
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Add Gift Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  /// Send a gift from one user to another
  /// Parameters: sender_id, receiver_id, room_id, gift_value, gift_id (optional)
  static Future<SendGiftResponse?> sendGift({
    required int senderId,
    required int receiverId,
    required int roomId,
    required double giftValue,
    int? giftId,
    int? senderSeatNumber, // ✅ Sender's seat number to verify they're seated
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.sendGift);
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConstants.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      // Required fields
      request.fields['sender_id'] = senderId.toString();
      request.fields['receiver_id'] = receiverId.toString();
      request.fields['room_id'] = roomId.toString();
      request.fields['gift_value'] = giftValue.toString();

      // Optional: Add gift_id if provided (some APIs might need it)
      if (giftId != null) {
        request.fields['gift_id'] = giftId.toString();
      }

      // ✅ Optional: Add sender's seat number to help backend verify sender is seated
      if (senderSeatNumber != null) {
        request.fields['sender_seat_number'] = senderSeatNumber.toString();
      }

      print('🎁 ========== SEND GIFT ==========');
      print('   - Sender ID: ${request.fields['sender_id']}');
      print('   - Receiver ID: ${request.fields['receiver_id']}');
      print('   - Room ID: ${request.fields['room_id']}');
      print('   - Gift Value: ${request.fields['gift_value']}');
      if (giftId != null) {
        print('   - Gift ID: ${request.fields['gift_id']}');
      }
      if (senderSeatNumber != null) {
        print(
          '   - Sender Seat Number: ${request.fields['sender_seat_number']}',
        );
      }
      print('   - Full URL: ${uri.toString()}');

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;
          final sendGiftResponse = SendGiftResponse.fromJson(data);

          if (sendGiftResponse.isSuccess) {
            print('✅ Gift Sent Successfully');
            return sendGiftResponse;
          } else {
            print('⚠️ Send Gift Failed: ${sendGiftResponse.message}');
            return sendGiftResponse;
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('❌ Send Gift Exception: $e');
      print('   - Stack: $s');
      return null;
    }
  }

  static Future<WithdrawalResponse?> requestWithdrawal({
    required int userId,
    required int paymentMethodId,
    required String userAccount,
    double? amount, // Optional amount
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.withdrawalSystem}?action=request_withdrawal',
      );

      print('💳 ========== REQUEST WITHDRAWAL ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST (Multipart Form-Data)');
      print('   📤 Request Fields:');
      print('      - user_id: $userId (type: ${userId.runtimeType})');
      print(
        '      - payment_method_id: $paymentMethodId (type: ${paymentMethodId.runtimeType})',
      );
      print(
        '      - user_account: "$userAccount" (type: ${userAccount.runtimeType})',
      );
      if (amount != null && amount > 0) {
        print('      - amount: $amount (type: ${amount.runtimeType})');
      } else {
        print('      - amount: Not provided (full balance will be withdrawn)');
      }

      // Use MultipartRequest (form-data) like other PHP APIs in this codebase
      var request = http.MultipartRequest('POST', uri);
      request.fields.addAll({
        'user_id': userId.toString(),
        'payment_method_id': paymentMethodId.toString(),
        'user_account': userAccount,
      });

      // Add amount only if provided (optional field)
      if (amount != null && amount > 0) {
        request.fields['amount'] = amount.toString();
      }

      http.StreamedResponse streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // Create a Response object from StreamedResponse for compatibility
      final response = http.Response(
        responseBody,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: http.Request('POST', uri),
      );

      print('   📥 Response Status Code: ${response.statusCode}');
      print('   📥 Response Headers: ${response.headers}');
      print('   📥 Response Body (Raw): ${response.body}');
      print('   📥 Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        try {
          // Clean response if it contains HTML comments or extra text
          String cleanResponse = response.body.trim();

          // Remove HTML comments if present
          if (cleanResponse.contains('<!--')) {
            int jsonStart = cleanResponse.indexOf('{');
            if (jsonStart != -1) {
              cleanResponse = cleanResponse.substring(jsonStart);
              int lastBrace = cleanResponse.lastIndexOf('}');
              if (lastBrace != -1) {
                cleanResponse = cleanResponse.substring(0, lastBrace + 1);
              }
            }
          }

          print('   🧹 Cleaned Response: $cleanResponse');

          final data = json.decode(cleanResponse) as Map<String, dynamic>;
          print('   📊 Parsed JSON Keys: ${data.keys.toList()}');
          print('   📊 Parsed JSON Values: $data');

          final withdrawalResponse = WithdrawalResponse.fromJson(data);

          if (withdrawalResponse.isSuccess) {
            print('   ✅ Withdrawal Request Submitted Successfully');
            print('   ✅ Status: ${withdrawalResponse.status}');
            print('   ✅ Message: ${withdrawalResponse.message}');
            if (withdrawalResponse.data != null) {
              print('   ✅ Response Data: ${withdrawalResponse.data}');
            }
            return withdrawalResponse;
          } else {
            print('   ⚠️ Withdrawal Request Failed');
            print('   ⚠️ Status: ${withdrawalResponse.status}');
            print('   ⚠️ Message: ${withdrawalResponse.message}');
            return withdrawalResponse;
          }
        } catch (e, stackTrace) {
          print('   ❌ JSON Parse Error: $e');
          print('   ❌ Stack Trace: $stackTrace');
          print('   ❌ Raw Response that failed to parse: ${response.body}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Request Withdrawal Exception: $e');
      print('   ❌ Exception Type: ${e.runtimeType}');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get payment methods
  /// API expects: GET/POST /withdrawal_system.php?action=get_payment_methods
  /// No parameters required
  static Future<PaymentMethodsResponse?> getPaymentMethods() async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.withdrawalSystem}?action=get_payment_methods',
      );

      print('💳 ========== GET PAYMENT METHODS ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print(
        '   📤 Headers: Content-Type: application/json, Accept: application/json',
      );
      print('   📤 Request Body: None (empty body)');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('   📥 Response Status Code: ${response.statusCode}');
      print('   📥 Response Headers: ${response.headers}');
      print('   📥 Response Body (Raw): ${response.body}');
      print('   📥 Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        try {
          // Clean response if it contains HTML comments or extra text
          String cleanResponse = response.body.trim();

          // Remove HTML comments if present
          if (cleanResponse.contains('<!--')) {
            int jsonStart = cleanResponse.indexOf('{');
            if (jsonStart != -1) {
              cleanResponse = cleanResponse.substring(jsonStart);
              int lastBrace = cleanResponse.lastIndexOf('}');
              if (lastBrace != -1) {
                cleanResponse = cleanResponse.substring(0, lastBrace + 1);
              }
            }
          }

          print('   🧹 Cleaned Response: $cleanResponse');

          final data = json.decode(cleanResponse) as Map<String, dynamic>;
          print('   📊 Parsed JSON Keys: ${data.keys.toList()}');
          print('   📊 Status: ${data['status']}');
          print('   📊 Data Type: ${data['data']?.runtimeType}');

          // ✅ ENHANCED ERROR LOGGING - Show ALL fields from backend response
          print('   🔍 ========== COMPLETE BACKEND RESPONSE ==========');
          print('   🔍 Full Response JSON: $data');
          data.forEach((key, value) {
            print('      - $key: $value (type: ${value.runtimeType})');
          });

          // Check for error_code or any error-related fields
          if (data.containsKey('error_code')) {
            print('   🔴 ERROR CODE FOUND: ${data['error_code']}');
          }
          if (data.containsKey('code')) {
            print('   🔴 CODE FOUND: ${data['code']}');
          }
          if (data.containsKey('error')) {
            print('   🔴 ERROR FIELD FOUND: ${data['error']}');
          }
          print('   🔍 ========== END COMPLETE RESPONSE ==========');

          if (data['data'] is List) {
            print('   📊 Data List Length: ${(data['data'] as List).length}');
            for (int i = 0; i < (data['data'] as List).length; i++) {
              print('      [$i] ${data['data'][i]}');
            }
          }

          final methodsResponse = PaymentMethodsResponse.fromJson(data);

          if (methodsResponse.isSuccess) {
            print('   ✅ Payment Methods Fetched Successfully');
            print(
              '   ✅ Total Methods: ${methodsResponse.paymentMethods.length}',
            );
            for (int i = 0; i < methodsResponse.paymentMethods.length; i++) {
              final method = methodsResponse.paymentMethods[i];
              print(
                '      [$i] ID: ${method.id}, Name: ${method.name}, Active: ${method.isActive}',
              );
            }
            return methodsResponse;
          } else {
            // ✅ ENHANCED ERROR DETAILS
            print('   ❌ ========== BACKEND ERROR DETAILS ==========');
            print(
              '   ❌ HTTP Status Code: 200 (Request successful, but API returned error)',
            );
            print('   ❌ Response Status: ${methodsResponse.status}');
            print(
              '   ❌ Error Message: ${methodsResponse.message ?? 'No message provided'}',
            );

            // Check for error code in response
            final errorCode =
                data['error_code'] ?? data['code'] ?? data['error'];
            if (errorCode != null) {
              print('   ❌ Error Code: $errorCode');
            } else {
              print('   ❌ Error Code: NOT PROVIDED BY BACKEND');
            }

            // Show all error-related fields
            print('   ❌ All Response Fields:');
            data.forEach((key, value) {
              if (key.toLowerCase().contains('error') ||
                  key.toLowerCase().contains('code') ||
                  key.toLowerCase().contains('status') ||
                  key.toLowerCase().contains('message')) {
                print('      - $key: $value');
              }
            });
            print('   ❌ ========== END ERROR DETAILS ==========');

            print('   ⚠️ Get Payment Methods Failed');
            print('   ⚠️ Status: ${methodsResponse.status}');
            print('   ⚠️ Message: ${methodsResponse.message}');
            return methodsResponse;
          }
        } catch (e, stackTrace) {
          print('   ❌ JSON Parse Error: $e');
          print('   ❌ Stack Trace: $stackTrace');
          print('   ❌ Raw Response that failed to parse: ${response.body}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Get Payment Methods Exception: $e');
      print('   ❌ Exception Type: ${e.runtimeType}');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get user withdrawals
  /// API expects: GET/POST /withdrawal_system.php?action=get_user_withdrawals
  /// Request body: {"user_id": 123}
  static Future<WithdrawalsListResponse?> getUserWithdrawals(int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.withdrawalSystem}?action=get_user_withdrawals',
      );

      // Prepare request body exactly as API expects
      final requestBody = {'user_id': userId};
      final requestBodyJson = jsonEncode(requestBody);

      print('💳 ========== GET USER WITHDRAWALS ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print(
        '   📤 Headers: Content-Type: application/json, Accept: application/json',
      );
      print('   📤 Request Body (JSON):');
      print('      - user_id: $userId (type: ${userId.runtimeType})');
      print('   📤 Full JSON String: $requestBodyJson');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBodyJson,
      );

      print('   📥 Response Status Code: ${response.statusCode}');
      print('   📥 Response Headers: ${response.headers}');
      print('   📥 Response Body (Raw): ${response.body}');
      print('   📥 Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        try {
          // Clean response if it contains HTML comments or extra text
          String cleanResponse = response.body.trim();

          // Remove HTML comments if present
          if (cleanResponse.contains('<!--')) {
            int jsonStart = cleanResponse.indexOf('{');
            if (jsonStart != -1) {
              cleanResponse = cleanResponse.substring(jsonStart);
              int lastBrace = cleanResponse.lastIndexOf('}');
              if (lastBrace != -1) {
                cleanResponse = cleanResponse.substring(0, lastBrace + 1);
              }
            }
          }

          print('   🧹 Cleaned Response: $cleanResponse');

          final data = json.decode(cleanResponse) as Map<String, dynamic>;
          print('   📊 Parsed JSON Keys: ${data.keys.toList()}');
          print('   📊 Status: ${data['status']}');
          print('   📊 Data Type: ${data['data']?.runtimeType}');

          if (data['data'] is List) {
            print(
              '   📊 Withdrawals List Length: ${(data['data'] as List).length}',
            );
          }

          final withdrawalsResponse = WithdrawalsListResponse.fromJson(data);

          if (withdrawalsResponse.isSuccess) {
            print('   ✅ User Withdrawals Fetched Successfully');
            print(
              '   ✅ Total Withdrawals: ${withdrawalsResponse.withdrawals.length}',
            );
            for (int i = 0; i < withdrawalsResponse.withdrawals.length; i++) {
              final withdrawal = withdrawalsResponse.withdrawals[i];
              print(
                '      [$i] ID: ${withdrawal.id}, Amount: ${withdrawal.amount}, Status: ${withdrawal.status}',
              );
            }
            return withdrawalsResponse;
          } else {
            print('   ⚠️ Get User Withdrawals Failed');
            print('   ⚠️ Status: ${withdrawalsResponse.status}');
            print('   ⚠️ Message: ${withdrawalsResponse.message}');
            return withdrawalsResponse;
          }
        } catch (e, stackTrace) {
          print('   ❌ JSON Parse Error: $e');
          print('   ❌ Stack Trace: $stackTrace');
          print('   ❌ Raw Response that failed to parse: ${response.body}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Get User Withdrawals Exception: $e');
      print('   ❌ Exception Type: ${e.runtimeType}');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get user balance from withdrawal system
  /// API expects: GET/POST /withdrawal_system.php?action=get_user_balance
  /// Request body: {"user_id": 123}
  /// Response: {"status": "success", "data": {"diamond_coins": 150.50, "user_name": "John Doe", "username": "johndoe"}}
  static Future<WithdrawalBalanceResponse?> getWithdrawalUserBalance(
    int userId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.withdrawalSystem}?action=get_user_balance',
      );

      // Prepare request body exactly as API expects
      final requestBody = {'user_id': userId};
      final requestBodyJson = jsonEncode(requestBody);

      print('💳 ========== GET WITHDRAWAL USER BALANCE ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print(
        '   📤 Headers: Content-Type: application/json, Accept: application/json',
      );
      print('   📤 Request Body (JSON):');
      print('      - user_id: $userId (type: ${userId.runtimeType})');
      print('   📤 Full JSON String: $requestBodyJson');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBodyJson,
      );

      print('   📥 Response Status Code: ${response.statusCode}');
      print('   📥 Response Headers: ${response.headers}');
      print('   📥 Response Body (Raw): ${response.body}');
      print('   📥 Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        try {
          // Clean response if it contains HTML comments or extra text
          String cleanResponse = response.body.trim();

          // Remove HTML comments if present
          if (cleanResponse.contains('<!--')) {
            int jsonStart = cleanResponse.indexOf('{');
            if (jsonStart != -1) {
              cleanResponse = cleanResponse.substring(jsonStart);
              int lastBrace = cleanResponse.lastIndexOf('}');
              if (lastBrace != -1) {
                cleanResponse = cleanResponse.substring(0, lastBrace + 1);
              }
            }
          }

          print('   🧹 Cleaned Response: $cleanResponse');

          final data = json.decode(cleanResponse) as Map<String, dynamic>;
          print('   📊 Parsed JSON Keys: ${data.keys.toList()}');
          print('   📊 Status: ${data['status']}');
          print('   📊 Data Type: ${data['data']?.runtimeType}');

          if (data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            print('   📊 Data Keys: ${dataMap.keys.toList()}');
            print('   📊 diamond_coins: ${dataMap['diamond_coins']}');
            print('   📊 user_name: ${dataMap['user_name']}');
            print('   📊 username: ${dataMap['username']}');
          }

          final balanceResponse = WithdrawalBalanceResponse.fromJson(data);

          if (balanceResponse.isSuccess) {
            print('   ✅ User Balance Fetched Successfully');
            if (balanceResponse.balance != null) {
              print(
                '   ✅ Diamond Coins: ${balanceResponse.balance!.diamondCoins}',
              );
              print('   ✅ User Name: ${balanceResponse.balance!.userName}');
              print('   ✅ Username: ${balanceResponse.balance!.username}');
            } else {
              print('   ⚠️ Balance data is null');
            }
            return balanceResponse;
          } else {
            print('   ⚠️ Get User Balance Failed');
            print('   ⚠️ Status: ${balanceResponse.status}');
            print('   ⚠️ Message: ${balanceResponse.message}');
            return balanceResponse;
          }
        } catch (e, stackTrace) {
          print('   ❌ JSON Parse Error: $e');
          print('   ❌ Stack Trace: $stackTrace');
          print('   ❌ Raw Response that failed to parse: ${response.body}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Get Withdrawal User Balance Exception: $e');
      print('   ❌ Exception Type: ${e.runtimeType}');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get user levels (sending and receiving)
  /// GET /level.php?action=get_user_levels&user_id=123
  static Future<UserLevelModel?> getUserLevels(int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.levelApi}?action=get_user_levels&user_id=$userId',
      );

      print('📊 ========== GET USER LEVELS ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: GET');
      print('   👤 User ID: $userId');

      final response = await http.get(uri);

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Strip HTML comments from response body (API sometimes includes <!-- ... -->)
        String cleanBody = response.body;
        final commentStart = cleanBody.indexOf('<!--');
        if (commentStart != -1) {
          cleanBody = cleanBody.substring(0, commentStart).trim();
        }

        final jsonData = jsonDecode(cleanBody) as Map<String, dynamic>;

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final data = jsonData['data'] as Map<String, dynamic>;

          // ✅ Debug: Check what format backend is sending
          final sendingType = data['sending']?.runtimeType.toString() ?? 'null';
          final receivingType =
              data['receiving']?.runtimeType.toString() ?? 'null';

          final levelModel = UserLevelModel.fromJson(jsonData);
          print('   ✅ User levels retrieved successfully');
          print('   📊 Sending Level: ${levelModel.sending.currentLevel}');
          print('   📊 Receiving Level: ${levelModel.receiving.currentLevel}');
          print(
            '   📊 Sending Type: $sendingType, Receiving Type: $receivingType',
          );

          // ✅ Show full level details if available
          if (levelModel.sending.currentLevel > 0) {
            print(
              '   📊 Sending Details: Level ${levelModel.sending.currentLevel}, EXP: ${levelModel.sending.currentExp}, Progress: ${levelModel.sending.progressPercentage}%',
            );
          }
          if (levelModel.receiving.currentLevel > 0) {
            print(
              '   📊 Receiving Details: Level ${levelModel.receiving.currentLevel}, EXP: ${levelModel.receiving.currentExp}, Progress: ${levelModel.receiving.progressPercentage}%',
            );
          }

          return levelModel;
        } else {
          print(
            '   ❌ API returned error or no data: ${jsonData['message'] ?? 'Unknown error'}',
          );
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get user tags
  /// POST /get_user_tags.php
  /// Request body: {"user_id": 15}
  /// Response: {"status": "success", "data": {"user_id": 15, "tags": ["Super VIP", "Official Host"]}}
  static Future<Map<String, dynamic>?> getUserTags(int userId) async {
    try {
      final uri = Uri.parse(ApiConstants.getUserTagsApi);

      // Prepare request body exactly as API expects
      final requestBody = {'user_id': userId};
      final requestBodyJson = jsonEncode(requestBody);

      print('🏷️ ========== GET USER TAGS ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print(
        '   📤 Headers: Content-Type: application/json, Accept: application/json',
      );
      print('   📤 Request Body (JSON):');
      print('      - user_id: $userId (type: ${userId.runtimeType})');
      print('   📤 Full JSON String: $requestBodyJson');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBodyJson,
      );

      print('   📥 Response Status Code: ${response.statusCode}');
      print('   📥 Response Headers: ${response.headers}');
      print('   📥 Response Body (Raw): ${response.body}');
      print('   📥 Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

          if (jsonData['status'] == 'success' && jsonData['data'] != null) {
            final data = jsonData['data'] as Map<String, dynamic>;
            final tags = data['tags'] as List<dynamic>? ?? [];

            print('   ✅ User tags retrieved successfully');
            print('   🏷️ User ID: ${data['user_id']}');
            print('   🏷️ Tags: $tags');
            print('   🏷️ Tags Count: ${tags.length}');

            return jsonData;
          } else {
            print(
              '   ⚠️ API returned error or no data: ${jsonData['message'] ?? 'Unknown error'}',
            );
            return null;
          }
        } catch (e, stackTrace) {
          print('   ❌ JSON Parse Error: $e');
          print('   ❌ Stack Trace: $stackTrace');
          print('   ❌ Raw Response that failed to parse: ${response.body}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        print('   ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Get User Tags Exception: $e');
      print('   ❌ Exception Type: ${e.runtimeType}');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Add gift EXP
  /// POST /level.php
  /// action=add_gift_exp&sender_id=123&receiver_id=456&gift_price=50.00&is_lucky_gift=true
  static Future<Map<String, dynamic>?> addGiftExp({
    required int senderId,
    required int receiverId,
    required double giftPrice,
    bool isLuckyGift = false,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.levelApi);

      print('🎁 ========== ADD GIFT EXP ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print('   👤 Sender ID: $senderId');
      print('   👤 Receiver ID: $receiverId');
      print('   💰 Gift Price: $giftPrice');
      print('   🍀 Is Lucky Gift: $isLuckyGift');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'add_gift_exp',
          'sender_id': senderId.toString(),
          'receiver_id': receiverId.toString(),
          'gift_price': giftPrice.toString(),
          'is_lucky_gift': isLuckyGift.toString(),
        },
      );

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Trigger lucky gift spinner API
  /// POST /lucky_gift_api.php
  static Future<Map<String, dynamic>?> triggerLuckyGift({
    required int senderId,
    required int receiverId,
    required int giftId,
    int quantity = 1,
    int? roomId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.luckyGiftApi);
      print('🍀 Triggering Lucky Gift API: ${uri.toString()}');
      print('   - senderId: $senderId');
      print('   - receiverId: $receiverId');
      print('   - giftId: $giftId');
      print('   - quantity: $quantity');
      if (roomId != null) print('   - roomId: $roomId');

      final body = <String, String>{
        'sender_id': senderId.toString(),
        'receiver_id': receiverId.toString(),
        'gift_id': giftId.toString(),
        'quantity': quantity.toString(),
      };
      if (roomId != null) body['room_id'] = roomId.toString();

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('   🍀 Response Status: ${response.statusCode}');
      print('   🍀 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('   ❌ LuckyGift HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ LuckyGift Exception: $e');
      print('   ❌ Stack: $s');
      return null;
    }
  }

  /// Get level configuration
  /// GET /level.php?action=get_level_config
  static Future<Map<String, dynamic>?> getLevelConfig() async {
    try {
      final uri = Uri.parse('${ApiConstants.levelApi}?action=get_level_config');

      print('⚙️ ========== GET LEVEL CONFIG ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: GET');

      final response = await http.get(uri);

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get top users
  /// GET /level.php?action=get_top_users&type=sending&limit=10
  static Future<Map<String, dynamic>?> getTopUsers({
    required String type, // 'sending' or 'receiving'
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.levelApi}?action=get_top_users&type=$type&limit=$limit',
      );

      print('🏆 ========== GET TOP USERS ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: GET');
      print('   📊 Type: $type');
      print('   📊 Limit: $limit');

      final response = await http.get(uri);

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Get all agencies via HTTP API
  /// GET /get_all_agencies.php?limit=50&offset=0
  static Future<Map<String, dynamic>?> getAllAgencies({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.getAllAgenciesApi}?limit=$limit&offset=$offset',
      );

      print('🏢 ========== GET ALL AGENCIES (HTTP API) ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: GET');
      print('   📊 Limit: $limit');
      print('   📊 Offset: $offset');

      final response = await http.get(uri);

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if response has success status
        if (jsonData['status'] == 'success') {
          print('   ✅ Successfully loaded agencies');
          return jsonData;
        } else {
          print('   ❌ API Error: ${jsonData['message'] ?? "Unknown error"}');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  /// Agency Management API - Unified endpoint for all agency operations
  /// POST /agency_manager.php
  static Future<Map<String, dynamic>?> agencyManager({
    required String action,
    int? agencyId,
    int? userId,
    String? agencyName,
    int? memberUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.agencyManagerApi);

      print('🏢 ========== AGENCY MANAGER API ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print('   📊 Action: $action');
      print('   📊 Agency ID: $agencyId');
      print('   📊 User ID: $userId');
      print('   📊 Agency Name: $agencyName');
      print('   📊 Member User ID: $memberUserId');
      print('   📊 Limit: $limit, Offset: $offset');

      // Build request body
      final body = <String, String>{'action': action};

      if (agencyId != null) body['agency_id'] = agencyId.toString();
      if (userId != null) body['user_id'] = userId.toString();
      if (agencyName != null && agencyName.isNotEmpty)
        body['agency_name'] = agencyName;
      if (memberUserId != null)
        body['member_user_id'] = memberUserId.toString();
      if (action == 'get_all' || action == 'get_all_users') {
        body['limit'] = limit.toString();
        body['offset'] = offset.toString();
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData['status'] == 'success') {
          print(
            '   ✅ Success: ${jsonData['message'] ?? "Operation successful"}',
          );
          return jsonData;
        } else {
          print('   ❌ API Error: ${jsonData['message'] ?? "Unknown error"}');
          return jsonData; // Return error response for handling
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  // Convenience methods for specific agency operations

  /// Create agency
  static Future<Map<String, dynamic>?> createAgency({
    required int userId,
    required String agencyName,
  }) async {
    return agencyManager(
      action: 'create',
      userId: userId,
      agencyName: agencyName,
    );
  }

  /// Update agency
  static Future<Map<String, dynamic>?> updateAgency({
    required int agencyId,
    required int userId,
    required String agencyName,
  }) async {
    return agencyManager(
      action: 'update',
      agencyId: agencyId,
      userId: userId,
      agencyName: agencyName,
    );
  }

  /// Delete agency
  static Future<Map<String, dynamic>?> deleteAgency({
    required int agencyId,
    required int userId,
  }) async {
    return agencyManager(action: 'delete', agencyId: agencyId, userId: userId);
  }

  /// Get specific agency
  static Future<Map<String, dynamic>?> getAgency({
    required int agencyId,
  }) async {
    return agencyManager(action: 'get', agencyId: agencyId);
  }

  /// Get all agencies (using agency_manager.php)
  static Future<Map<String, dynamic>?> getAllAgenciesViaManager({
    int limit = 50,
    int offset = 0,
  }) async {
    return agencyManager(action: 'get_all', limit: limit, offset: offset);
  }

  /// Add member to agency
  static Future<Map<String, dynamic>?> addAgencyMember({
    required int agencyId,
    required int userId,
    required int memberUserId,
  }) async {
    return agencyManager(
      action: 'add_member',
      agencyId: agencyId,
      userId: userId,
      memberUserId: memberUserId,
    );
  }

  /// Remove member from agency
  static Future<Map<String, dynamic>?> removeAgencyMember({
    required int agencyId,
    required int userId,
    required int memberUserId,
  }) async {
    return agencyManager(
      action: 'remove_member',
      agencyId: agencyId,
      userId: userId,
      memberUserId: memberUserId,
    );
  }

  /// Get agency members
  static Future<Map<String, dynamic>?> getAgencyMembers({
    required int agencyId,
  }) async {
    return agencyManager(action: 'get_members', agencyId: agencyId);
  }

  /// Get all users
  static Future<Map<String, dynamic>?> getAllUsersViaAgencyManager({
    int limit = 100,
    int offset = 0,
  }) async {
    return agencyManager(action: 'get_all_users', limit: limit, offset: offset);
  }

  /// Get specific user
  static Future<Map<String, dynamic>?> getUserViaAgencyManager({
    required int userId,
  }) async {
    return agencyManager(action: 'get_user', userId: userId);
  }

  /// Get agency statistics
  static Future<Map<String, dynamic>?> getAgencyStats() async {
    return agencyManager(action: 'get_stats');
  }

  // ========== AGENCY REQUESTS API ==========

  /// Agency Requests API - Unified endpoint for join/quit requests
  /// POST /agency_requests_api.php
  static Future<Map<String, dynamic>?> agencyRequests({
    required String action,
    int? userId,
    int? agencyId,
    int? requestId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.agencyRequestsApi);

      print('📋 ========== AGENCY REQUESTS API ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print('   📊 Action: $action');
      print('   📊 User ID: $userId');
      print('   📊 Agency ID: $agencyId');
      print('   📊 Request ID: $requestId');

      // Build request body
      final body = <String, String>{'action': action};

      if (userId != null) body['user_id'] = userId.toString();
      if (agencyId != null) body['agency_id'] = agencyId.toString();
      if (requestId != null) body['request_id'] = requestId.toString();

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData['status'] == 'success') {
          print(
            '   ✅ Success: ${jsonData['message'] ?? "Operation successful"}',
          );
          return jsonData;
        } else {
          print('   ❌ API Error: ${jsonData['message'] ?? "Unknown error"}');
          return jsonData; // Return error response for handling
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $s');
      return null;
    }
  }

  // Convenience methods for agency requests

  /// Create join request
  static Future<Map<String, dynamic>?> createJoinRequest({
    required int userId,
    required int agencyId,
  }) async {
    return agencyRequests(
      action: 'create_join_request',
      userId: userId,
      agencyId: agencyId,
    );
  }

  /// Get join requests (for agency owner)
  static Future<Map<String, dynamic>?> getJoinRequests({
    required int agencyId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'get_join_requests',
      agencyId: agencyId,
      userId: userId,
    );
  }

  /// Accept join request
  static Future<Map<String, dynamic>?> acceptJoinRequest({
    required int requestId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'accept_join_request',
      requestId: requestId,
      userId: userId,
    );
  }

  /// Decline join request
  static Future<Map<String, dynamic>?> declineJoinRequest({
    required int requestId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'decline_join_request',
      requestId: requestId,
      userId: userId,
    );
  }

  /// Create quit request
  static Future<Map<String, dynamic>?> createQuitRequest({
    required int userId,
    required int agencyId,
  }) async {
    return agencyRequests(
      action: 'create_quit_request',
      userId: userId,
      agencyId: agencyId,
    );
  }

  /// Get quit requests (for agency owner)
  static Future<Map<String, dynamic>?> getQuitRequests({
    required int agencyId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'get_quit_requests',
      agencyId: agencyId,
      userId: userId,
    );
  }

  /// Accept quit request
  static Future<Map<String, dynamic>?> acceptQuitRequest({
    required int requestId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'accept_quit_request',
      requestId: requestId,
      userId: userId,
    );
  }

  /// Decline quit request
  static Future<Map<String, dynamic>?> declineQuitRequest({
    required int requestId,
    required int userId,
  }) async {
    return agencyRequests(
      action: 'decline_quit_request',
      requestId: requestId,
      userId: userId,
    );
  }

  // ========== STORE APIs ==========

  /// Get mall data (categories and items)
  /// API: mall_api.php
  static Future<MallResponse?> getMallData() async {
    try {
      final uri = Uri.parse(ApiConstants.mallApi);

      print('🛒 ========== MALL API ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: GET');

      final response = await http.get(uri);

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final mallResponse = MallResponse.fromJson(jsonData);

          if (mallResponse.isSuccess) {
            print(
              '   ✅ Success: ${mallResponse.categories.length} categories, ${mallResponse.itemsByCategory.length} category groups',
            );
            return mallResponse;
          } else {
            print('   ❌ API Error: ${mallResponse.message}');
            return mallResponse;
          }
        } catch (jsonError) {
          print('   ❌ JSON Parse Error: $jsonError');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Purchase an item
  /// API: purchase_item.php
  /// Payload: { "user_id": 15, "item_id": 101, "days": 7 }
  static Future<PurchaseResponse?> purchaseItem({
    required int userId,
    required int itemId,
    required int days,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.purchaseItemApi);

      print('💰 ========== PURCHASE ITEM API ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print('   📊 User ID: $userId');
      print('   📊 Item ID: $itemId');
      print('   📊 Days: $days');

      final body = jsonEncode({
        'user_id': userId,
        'item_id': itemId,
        'days': days,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final purchaseResponse = PurchaseResponse.fromJson(jsonData);

          if (purchaseResponse.isSuccess) {
            print(
              '   ✅ Purchase successful! New balance: ${purchaseResponse.newBalance}',
            );
            return purchaseResponse;
          } else {
            print('   ❌ Purchase failed: ${purchaseResponse.message}');
            return purchaseResponse;
          }
        } catch (jsonError) {
          print('   ❌ JSON Parse Error: $jsonError');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Get user's backpack items
  /// API: get_backpack.php
  /// Payload: { "user_id": 15 }
  static Future<BackpackResponse?> getBackpack({required int userId}) async {
    try {
      if (userId == 0) {
        print('🎒 [ApiManager] getBackpack skipped: user_id 0 is invalid');
        return null;
      }
      final uri = Uri.parse(ApiConstants.getBackpackApi);

      print('🎒 ========== GET BACKPACK API ==========');
      print('   📍 Endpoint: ${uri.toString()}');
      print('   📤 Request Method: POST');
      print('   📊 User ID: $userId');

      final body = jsonEncode({'user_id': userId});

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('   📥 Response Status: ${response.statusCode}');
      print('   📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

          final backpackResponse = BackpackResponse.fromJson(jsonData);

          if (backpackResponse.isSuccess) {
            return backpackResponse;
          } else {
            print('   ❌ API Error: ${backpackResponse.message}');
            return backpackResponse;
          }
        } catch (jsonError) {
          print('   ❌ JSON Parse Error: $jsonError');
          return null;
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('   ❌ Exception: $e');
      print('   ❌ Stack Trace: $stackTrace');
      return null;
    }
  }

  // ========== GIFT TRANSACTIONS API ==========

  /// Get gift transactions with filtering and pagination
  /// API: gift_transactions_api.php

  static Future<GiftTransactionsResponse1> fetchTransactions({
    int page = 1,
    int limit = 50,
    int? senderId,
    int? receiverId,
    int? giftId,
    int? roomId,
    String? coinType,
    String? startDate,
    String? endDate,
    String sortBy = "gift_price",
    String sortOrder = "DESC",
  }) async {
    final queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      "sort_by": sortBy,
      "sort_order": sortOrder,
    };

    if (senderId != null) queryParams["sender_id"] = senderId.toString();
    if (receiverId != null) queryParams["receiver_id"] = receiverId.toString();
    if (giftId != null) queryParams["gift_id"] = giftId.toString();
    if (roomId != null) queryParams["room_id"] = roomId.toString();
    if (coinType != null) queryParams["coin_type"] = coinType;
    if (startDate != null) queryParams["start_date"] = startDate;
    if (endDate != null) queryParams["end_date"] = endDate;

    final uri = Uri.parse(
      "https://shaheenstar.online/gift_transactions_report.php",
    ).replace(queryParameters: queryParams);

    print("🎯 API URL: $uri");

    final response = await http.get(uri);

    print(response.statusCode);
    print(response);
    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print(jsonData["data"]["transactions"]);
      return GiftTransactionsResponse1.fromJson(jsonData);
    } else {
      throw Exception("❌ Failed to load gift transactions");
    }
  }

  // ================= FETCH ROOM STATS =================

  static Future<RoomGiftResponse> fetchRoomStats({
    int page = 1,
    int limit = 50,
    int? senderId,
    int? receiverId,
    int? giftId,
    int? roomId,
    String? coinType,
    String? startDate,
    String? endDate,
    String sortBy = "gift_price",
    String sortOrder = "DESC",
  }) async {
    final queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      "sort_by": sortBy,
      "sort_order": sortOrder,
    };

    if (senderId != null) queryParams["sender_id"] = senderId.toString();
    if (receiverId != null) queryParams["receiver_id"] = receiverId.toString();
    if (roomId != null) queryParams["room_id"] = roomId.toString();
    if (giftId != null) queryParams["gift_id"] = giftId.toString();
    if (startDate != null) queryParams["start_date"] = startDate;
    if (endDate != null) queryParams["end_date"] = endDate;
    if (coinType != null) queryParams["coin_type"] = coinType;

    final uri = Uri.parse(
      "https://shaheenstar.online/gift_102.php",
    ).replace(queryParameters: queryParams);

    print("🎯 Room Stats API URL: $uri");

    final response = await http.get(uri);
    print("🔹 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return RoomGiftResponse.fromJson(jsonData);
    } else {
      throw Exception("❌ Failed to load room stats: ${response.statusCode}");
    }
  }

  // ================= FETCH CpUser  STATS =================

  static Future<CpUserResponse> fetchCpUser() async {
    final uri = Uri.parse("https://shaheenstar.online/get_cp_wall.php");

    print("🎯 Cp Stats API URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
      },
    );

    print("🔹 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return CpUserResponse.fromJson(jsonData);
    } else {
      throw Exception("❌ Failed to load cp stats: ${response.statusCode}");
    }
  }

  // ================= FETCH CpRanking User  STATS =================

  static Future<CpUserResponse> fetchCpRankingUser() async {
    final uri = Uri.parse("https://shaheenstar.online/get_cp_ranking_live.php");

    print("🎯 Cp Stats API URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
      },
    );

    print("🔹 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return CpUserResponse.fromJson(jsonData);
    } else {
      throw Exception("❌ Failed to load cp stats: ${response.statusCode}");
    }
  }

  static Future<bool> removeSelfFromCp(String userId) async {
    try {
      final uri = Uri.parse(
        "https://shaheenstar.online/remove_self_from_cp.php",
      );

      print("📤 Removing self from CP API");
      print("📤 Endpoint: $uri");
      print("📤 User ID: $userId");

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer mySuperSecretStaticToken123',
        'Accept': 'application/json',
      });

      // Add fields
      request.fields['user_id'] = userId;

      // Send request
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: $responseBody");

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);

        // Check success flag
        if (decoded is Map && decoded['status'] == 'success') {
          print("✅ Successfully removed user from CP");
          return true;
        } else {
          print(
            "⚠️ Failed to remove user: ${decoded['message'] ?? 'Unknown error'}",
          );
          return false;
        }
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("❌ Exception removing user from CP: $e");
      return false;
    }
  }

  // ================= FETCH CpRanking User  STATS =================

  static Future<CpUserResponse> fetchCpRankingUserById(String userId) async {
    final uri = Uri.parse(
      "https://shaheenstar.online/get_cp_ranking_live.php?user_id=$userId",
    );

    print("🎯 Cp Stats API URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
      },
    );

    print("🔹 Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return CpUserResponse.fromJson(jsonData);
    } else {
      throw Exception("❌ Failed to load cp stats: ${response.statusCode}");
    }
  }

  // Remove CP partner (Postman: POST formdata user_id, Bearer auth)
  static Future<Map<String, dynamic>> removeCpPartner(String userId) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}remove_self_from_cp.php");

    print("🎯 Remove CP Partner API: POST $uri");
    print("🔹 User ID: $userId");

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${ApiConstants.bearertoken}',
      },
      body: 'user_id=${Uri.encodeQueryComponent(userId)}',
    );

    print("🔹 Status: ${response.statusCode}");
    print("🔹 Response: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData is! Map) throw Exception('Invalid response format');
      final map = Map<String, dynamic>.from(jsonData as Map);
      if (map['status'] == 'success') {
        return map;
      } else {
        throw Exception(
          map['message']?.toString() ?? 'Failed to remove CP partner',
        );
      }
    } else {
      throw Exception("❌ Failed to remove CP partner: ${response.statusCode}");
    }
  }

  //   static Future<RoomGiftResponse> fetchRoomStats({
  //       int page = 1,
  //     int limit = 50,
  //     int? senderId,
  //     int? receiverId,
  //     int? giftId,
  //     int? roomId,
  //     String? coinType,
  //     String? startDate,
  //     String? endDate,
  //     String sortBy = "gift_price",
  //     String sortOrder = "DESC",
  //     String? status,
  //     bool? isPrivate,
  //     String? timePeriod, // all, weekly, monthly
  //     String? filter,
  //   }) async {
  //     final queryParams = {
  //       "page": page.toString(),
  //       "limit": limit.toString(),
  //       "sort_by": sortBy ,
  //       "sort_order": sortOrder,

  //     };

  //     if (senderId != null) queryParams["sender_id"] = senderId.toString();
  //     if (receiverId != null) queryParams["receiver_id"] = receiverId.toString();
  //     if (roomId != null) queryParams["room_id"] = roomId.toString();
  //     if (status != null) queryParams["status"] = status;
  //     if (isPrivate != null) queryParams["is_private"] = isPrivate.toString();
  //     if (timePeriod != null) queryParams["time_period"] = timePeriod;
  //     if (startDate != null) queryParams["start_date"] = startDate;
  //     if (endDate != null) queryParams["end_date"] = endDate;
  //    if (coinType != null) queryParams["coin_type"] = coinType;

  //        final uri = Uri.parse("https://shaheenstar.online/gift_102.php").replace(queryParameters: queryParams);

  //     print("🎯 Room Stats API URL: $uri");

  //     final response = await http.get(uri);
  //     print("~~~~~~~~~~~~~~~~~~~~~~~");
  // print(response.statusCode);
  // print(response.body);
  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(response.body);
  //       print("✅ Room Stats API Response: ${jsonData.toString().substring(0, jsonData.toString().length > 200 ? 200 : jsonData.toString().length)}");
  //       return RoomGiftResponse.fromJson(jsonData);
  //     } else {
  //       throw Exception("❌ Failed to load room stats: ${response.statusCode}");
  //     }
  //   }

  // ================= FETCH ROOM TOTAL COINS =================
  /// Fetch total coins sent in a room
  ///
  /// Returns Map with room summary including total_sent_value
  /// Uses ApiService for consistent error handling and retry logic
  static Future<Map<String, dynamic>?> fetchTotalCoins({
    required String roomId,
  }) async {
    try {
      print('💰 [ApiManager] Fetching total coins for room: $roomId');

      final response = await ApiService.get<Map<String, dynamic>>(
        url: ApiConstants.fetchTotalCoinsApi,
        queryParameters: {'room_id': roomId, 'sort_by': 'total_sent_value'},
        headers: ApiService.getCommonHeaders(includeAuth: false),
        parser: (json) => json, // Return raw JSON
      );

      if (!response.isSuccess) {
        print(
          '❌ [ApiManager] Failed to fetch total coins: ${response.errorMessage}',
        );
        return null;
      }

      final data = response.data;
      if (data == null) {
        print('❌ [ApiManager] No data in response');
        return null;
      }

      // Validate response structure
      if (data['status'] != 'success') {
        print('❌ [ApiManager] API returned error status: ${data['message']}');
        return null;
      }

      print('✅ [ApiManager] Successfully fetched total coins');
      return data;
    } catch (e, stackTrace) {
      print('❌ [ApiManager] Exception fetching total coins: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }
}
