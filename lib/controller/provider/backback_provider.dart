 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/model/backpack_item_model.dart';

class BackpackProvider with ChangeNotifier {
	List<BackpackItem> _items = [];
	bool _isLoading = false;
	String? _error;

	List<BackpackItem> get items => _items;
	bool get isLoading => _isLoading;
	String? get error => _error;

	Future<void> fetchBackpackByUserId(String userId) async {
		_isLoading = true;
		_error = null;
		notifyListeners();

		try {
			final url = Uri.parse('${ApiConstants.baseUrl}get_user_selected_backpack_simple.php?user_id=$userId');
print(url);
			final headers = {
				'Authorization': ApiConstants.token,
				'Accept': 'application/json',
			};

			final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
print(response);
print(response.statusCode);
print(response.body);
			if (response.statusCode == 200) {
				final body = response.body.trim();
				if (body.isEmpty) {
					_items = [];
				} else {
					final decoded = json.decode(body);

					// API may return a list or an object; handle both
					List<dynamic> listData = [];
					if (decoded is List) {
						listData = decoded;
					} else if (decoded is Map) {
						// try common keys
						if (decoded.containsKey('data') && decoded['data'] is List) {
							listData = decoded['data'];
						} else if (decoded.containsKey('items') && decoded['items'] is List) {
							listData = decoded['items'];
						} else if (decoded.containsKey('backpack') && decoded['backpack'] is List) {
							listData = decoded['backpack'];
						} else {
							// last resort: if the map itself looks like a single item, wrap it
							listData = [decoded];
						}
					}

					_items = listData.map((e) => BackpackItem.fromJson(Map<String, dynamic>.from(e))).toList();
				}
			} else {
				_error = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
				_items = [];
			}
		} catch (e) {
			_error = e.toString();
			_items = [];
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}
}