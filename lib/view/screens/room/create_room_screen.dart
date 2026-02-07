import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/create_room_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    // ✅ Reset provider to clear any previous room data (including old images)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CreateRoomProvider>(context, listen: false);
      provider.reset();
      print(
        "🔄 [CreateRoomScreen] Reset provider - cleared previous room data",
      );
    });
    _getUserId();
  }

  // 👇 GET USER ID FROM SHARED PREFERENCES - FIXED
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Safely get user_id (handles both int and String types)
    try {
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        _userId = userIdInt.toString();
      } else {
        _userId = prefs.getString('user_id');
      }
    } catch (e) {
      // Fallback: try dynamic retrieval
      final dynamic userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        _userId = userIdValue.toString();
      }
    }
    print("🔍 User ID from SharedPreferences: $_userId");

    // Agar user ID mil gaya toh check karo existing room
    if (_userId != null && _userId!.isNotEmpty) {
      final provider = Provider.of<CreateRoomProvider>(context, listen: false);
      await provider.checkExistingRoom(_userId!);

      // ✅ Agar editing mode hai toh existing data load karo
      if (provider.editingMode) {
        _loadExistingRoomData(provider);
      }
    }
  }

  // 👇 LOAD EXISTING ROOM DATA
  void _loadExistingRoomData(CreateRoomProvider provider) {
    // ✅ Yahan aap existing room ka data load kar sakte hain
    // Temporary - manually set karo ya API se fetch karo
    print("🔄 Loading existing room data for editing");

    // Example: Agar aapke paas existing data hai toh
    // _roomNameController.text = existingRoomData['room_name'];
    // _topicController.text = existingRoomData['topic'];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = Provider.of<CreateRoomProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        title: Text(
          provider.editingMode ? "Edit Your Room" : "Create Room",
        ), // ✅ Dynamic title
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          /// 🟣 Main UI
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              size.width * 0.05,
              16,
              size.width * 0.05,
              size.height * 0.15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 INFO MESSAGE AGAR EDITING MODE HAI
                if (provider.editingMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You already have a room. You can update your room details here.",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Text(
                      "Room Avatar",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (!provider.editingMode) ...[
                      const SizedBox(width: 4),
                      const Text(
                        "*",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async => await provider.pickRoomAvatar(context),
                  child: Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.02),
                    ),
                    child: provider.avatarImage == null
                        ? const Center(
                            child: Icon(
                              Icons.add,
                              size: 40,
                              color: Colors.white54,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(provider.avatarImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔹 Room Name
                const Text(
                  "Room Name",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: provider.editingMode
                        ? "Name"
                        : "Please enter room name",
                    hintStyle: const TextStyle(color: Colors.white54),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF141416),
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔹 Room Announcement
                const Text(
                  "Room Announcement",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _topicController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: provider.editingMode
                        ? "Update room announcement"
                        : "Welcome everyone! Let's enjoy Dark Party and have fun together!",
                    hintStyle: const TextStyle(color: Colors.white54),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    counterText: "${_topicController.text.length}/300",
                    filled: true,
                    fillColor: const Color(0xFF141416),
                    counterStyle: const TextStyle(color: Colors.white70),
                  ),
                  onChanged: (text) => setState(() {}),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 16),

                /// 🔒 Private Room Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: provider.isPrivate,
                      activeColor: Colors.purpleAccent,
                      onChanged: (value) =>
                          provider.togglePrivate(value ?? false),
                    ),
                    const Text(
                      "Private Room",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (provider.isPrivate) ...[
                  const SizedBox(height: 8),
                  TextField(
                    obscureText: true,
                    onChanged: provider.setPassword,
                    decoration: InputDecoration(
                      hintText: "Enter room password",
                      hintStyle: const TextStyle(color: Colors.white54),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF141416),
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// 🔹 Fixed Bottom Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Consumer<CreateRoomProvider>(
              builder: (context, provider, _) {
                // ✅ AGAR EDITING MODE HAI TOH UPDATE BUTTON, NAHI TOH CREATE
                final buttonText = provider.editingMode
                    ? "Update Room"
                    : "Let's Play 🎮";
                final isDisabled =
                    provider.errorMessage != null &&
                    provider.errorMessage!.contains("already created") &&
                    !provider.editingMode;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled
                        ? Colors.grey
                        : Colors.purpleAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      (provider.isLoading ||
                          provider.checkingRoom ||
                          isDisabled)
                      ? null
                      : () async {
                          // ✅ User ID get karo agar nahi hai
                          if (_userId == null) {
                            await _getUserId();
                          }

                          if (_userId != null && _userId!.isNotEmpty) {
                            if (provider.editingMode) {
                              // ✅ UPDATE ROOM
                              provider.createOrUpdateRoom(
                                context: context,
                                roomName: _roomNameController.text.trim(),
                                topic: _topicController.text.trim(),
                                userId: _userId!,
                              );
                            } else {
                              // ✅ CREATE ROOM
                              provider.createOrUpdateRoom(
                                context: context,
                                roomName: _roomNameController.text.trim(),
                                topic: _topicController.text.trim(),
                                userId: _userId!,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "User not found. Please login again.",
                                ),
                              ),
                            );
                          }
                        },
                  child: provider.checkingRoom
                      ? const CircularProgressIndicator(color: Colors.white)
                      : provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}















// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shaheen_star_app/controller/provider/create_room_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CreateRoomScreen extends StatefulWidget {
//   const CreateRoomScreen({super.key});

//   @override
//   State<CreateRoomScreen> createState() => _CreateRoomScreenState();
// }

// class _CreateRoomScreenState extends State<CreateRoomScreen> {
//   final TextEditingController _roomNameController = TextEditingController();
//   final TextEditingController _topicController = TextEditingController();
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     _getUserId();
//   }

//   // 👇 GET USER ID FROM SHARED PREFERENCES
//   Future<void> _getUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     _userId = prefs.getString('user_id');
//     print("🔍 User ID from SharedPreferences: $_userId");
    
//     // Agar user ID mil gaya toh check karo existing room
//     if (_userId != null && _userId!.isNotEmpty) {
//       final provider = Provider.of<CreateRoomProvider>(context, listen: false);
//       await provider.checkExistingRoom(_userId!);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final provider = Provider.of<CreateRoomProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(provider.editingMode ? "Edit Your Room" : "Create Room"),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Stack(
//         children: [
//           /// 🟣 Main UI
//           SingleChildScrollView(
//             padding: EdgeInsets.fromLTRB(
//               size.width * 0.05,
//               16,
//               size.width * 0.05,
//               size.height * 0.15,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 👇 INFO MESSAGE AGAR EDITING MODE HAI
//                 if (provider.editingMode)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.blue),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.info, color: Colors.blue),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             "You already have a room. You can update your room details here.",
//                             style: TextStyle(color: Colors.blue[800]),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                
//                 if (provider.editingMode) const SizedBox(height: 16),

//                 /// 🔹 Room Avatar
//                 const Text(
//                   "Room Avatar",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: () async => await provider.pickRoomAvatar(context),
//                   child: Container(
//                     width: size.width * 0.3,
//                     height: size.width * 0.3,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade400, width: 1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: provider.avatarImage != null
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.file(
//                               File(provider.avatarImage!.path),
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         : const Center(
//                             child: Icon(Icons.add, size: 40, color: Colors.grey),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 /// 🔹 Room Name
//                 const Text(
//                   "Room Name",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _roomNameController,
//                   decoration: InputDecoration(
//                     hintText: "Enter your room name",
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 /// 🔹 Room Announcement
//                 const Text(
//                   "Room Announcement",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _topicController,
//                   maxLines: 4,
//                   maxLength: 300,
//                   decoration: InputDecoration(
//                     hintText: "Welcome everyone! Let's enjoy together!",
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     ),
//                     counterText: "${_topicController.text.length}/300",
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 /// 🔒 Private Room Checkbox
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: provider.isPrivate,
//                       onChanged: (value) => provider.togglePrivate(value ?? false),
//                     ),
//                     const Text(
//                       "Private Room",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (provider.isPrivate) ...[
//                   const SizedBox(height: 8),
//                   TextField(
//                     obscureText: true,
//                     onChanged: provider.setPassword,
//                     decoration: InputDecoration(
//                       hintText: "Enter room password",
//                       hintStyle: const TextStyle(color: Colors.grey),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 10,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           /// 🔹 Fixed Bottom Button
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Consumer<CreateRoomProvider>(
//               builder: (context, provider, _) {
//                 return ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.purpleAccent,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 14,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: (provider.isLoading || provider.checkingRoom)
//                       ? null
//                       : () async {
//                           if (_userId == null) {
//                             await _getUserId();
//                           }
                          
//                           if (_userId != null && _userId!.isNotEmpty) {
//                             provider.createOrUpdateRoom(
//                               context: context,
//                               roomName: _roomNameController.text.trim(),
//                               topic: _topicController.text.trim(),
//                               userId: _userId!,
//                             );
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text("User not found. Please login again.")),
//                             );
//                           }
//                         },
//                   child: provider.checkingRoom
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : provider.isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Text(
//                               provider.editingMode ? "Update Room" : "Create Room",
//                               style: const TextStyle(fontSize: 18, color: Colors.white),
//                             ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }