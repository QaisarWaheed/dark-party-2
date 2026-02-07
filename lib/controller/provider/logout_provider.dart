// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

// class LogoutProvider with ChangeNotifier {
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   Future<void> logout(BuildContext context) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId') ?? '';

//       if (userId.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("User not logged in")),
//         );
//         return;
//       }

//       final response = await ApiManager.logoutUser(userId: userId);

//       if (response != null && response['status'] == 'success') {
//         // ✅ clear local storage
//         await prefs.clear();

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Logout successful')),
//         );

//         // ✅ Navigate to login screen
//         Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(response?['message'] ?? 'Logout failed')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Something went wrong: $e")),
//       );
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
