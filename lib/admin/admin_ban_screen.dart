// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';

// class AdminBanScreen extends StatefulWidget {
//   final int adminId;
//   final int roomId;

//   const AdminBanScreen({
//     super.key,
//     required this.adminId,
//     required this.roomId,
//   });

//   @override
//   State<AdminBanScreen> createState() => _AdminBanScreenState();
// }

// class _AdminBanScreenState extends State<AdminBanScreen> {
//   final TextEditingController _userIdController = TextEditingController();
//   String selectedDuration = "1day";

//   final List<String> durations = ["1day", "3days", "7days", "1month"];

//   @override
//   Widget build(BuildContext context) {
//     final banProvider = context.watch<BanUserProvider>();

//     return Scaffold(
//       appBar: AppBar(title: const Text("Ban User")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _userIdController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "Target User ID",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               initialValue: selectedDuration,
//               items: durations
//                   .map((d) => DropdownMenuItem(value: d, child: Text(d)))
//                   .toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   setState(() {
//                     selectedDuration = value;
//                   });
//                 }
//               },
//               decoration: const InputDecoration(
//                 labelText: "Ban Duration",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: banProvider.isLoading
//                     ? null
//                     : () async {
//                         final userId = int.tryParse(_userIdController.text);
//                         if (userId == null) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("Enter a valid User ID"),
//                             ),
//                           );
//                           return;
//                         }

//                         final success = await banProvider.banUser(
//                           adminId: widget.adminId,
//                           targetUserId: userId,
//                           roomId: widget.roomId,
//                           banDuration: selectedDuration,
//                         );

//                         if (success) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 banProvider.successMessage ??
//                                     "User banned successfully",
//                               ),
//                             ),
//                           );
//                           _userIdController.clear();
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 banProvider.errorMessage ??
//                                     "Failed to ban user",
//                               ),
//                             ),
//                           );
//                         }
//                       },
//                 child: banProvider.isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Ban User"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BanUserProvider with ChangeNotifier {
//   bool isLoading = false;
//   String? errorMessage;
//   String? successMessage;

//   Future<bool> banUser({
//     required int adminId,
//     required int targetUserId,
//     required int roomId,
//     required String banDuration,
//   }) async {
//     isLoading = true;
//     errorMessage = null;
//     successMessage = null;
//     notifyListeners();

//     try {
//       final response = await ApiManager.banUser(
//         adminId: adminId,
//         targetUserId: targetUserId,
//         roomId: roomId,
//         banDuration: banDuration,
//       );

//       if (response["status"] == "success") {
//         successMessage = response["message"] ?? "User banned successfully";
//         return true;
//       } else {
//         errorMessage = response["message"] ?? "Failed to ban user";
//         return false;
//       }
//     } catch (e) {
//       errorMessage = "Network error: $e";
//       return false;
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   void clearMessages() {
//     errorMessage = null;
//     successMessage = null;
//     notifyListeners();
//   }
// }

// class ApiManager {
//   static Future<Map<String, dynamic>> banUser({
//     required int adminId,
//     required int targetUserId,
//     required int roomId,
//     required String banDuration,
//   }) async {
//     final response = await http.post(
//       Uri.parse("https://yourdomain.com/ban_user.php"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "admin_user_id": adminId,
//         "target_user_id": targetUserId,
//         "room_id": roomId,
//         "ban_duration": banDuration,
//       }),
//     );
//     return jsonDecode(response.body);
//   }

//   static Future<Map<String, dynamic>> joinRoom({
//     required int userId,
//     required int roomId,
//   }) async {
//     final response = await http.post(
//       Uri.parse("https://yourdomain.com/join_room.php"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"user_id": userId, "room_id": roomId}),
//     );
//     return jsonDecode(response.body);
//   }
// }
// ✅ Flow Summary

// Admin bans user → ban_user.php

// Sirf specific room ban hota hai

// App ya login block nahi hota

// User taps room → join_room.php

// Backend check karta hai agar banned hai

// Agar banned → SnackBar message

// Agar allowed → navigate to RoomScreen

// Flutter side

// JoinRoomProvider handle karta hai API call aur ban message

// GetAllRoomProvider sirf room list provide karta hai


// ✅ Flow Summary

// Admin bans user → ban_user.php

// Sirf specific room ban hota hai

// App ya login block nahi hota

// User taps room → join_room.php

// Backend check karta hai agar banned hai

// Agar banned → SnackBar message

// Agar allowed → navigate to RoomScreen

// Flutter side

// JoinRoomProvider handle karta hai API call aur ban message

// GetAllRoomProvider sirf room list provide karta hai