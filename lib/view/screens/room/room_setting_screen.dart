import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/view/screens/profile/theme_selection_screen.dart';

class RoomSettingsScreen extends StatefulWidget {
  final String? roomAvatarUrl; // Last time used room avatar
  final String roomName;
  final String announcement;
  final String? roomId;
  final String? userId;
  final void Function(String newName, String? newProfileUrl)? onRoomUpdated;

  const RoomSettingsScreen({
    super.key,
    this.roomAvatarUrl,
    this.roomName = "welcome",
    this.announcement = "",
    this.roomId,
    this.userId,
    this.onRoomUpdated,
  });

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late String _roomName;
  late String _announcement;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _roomName = widget.roomName;
    _announcement = widget.announcement;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Room Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRoomAvatarSection(),
            const SizedBox(height: 24),
            _buildSettingItem(
              title: "Room Name",
              value: _roomName,
              onTap: () => _editRoomName(context),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              title: "Announcement",
              value: _announcement.isEmpty ? ">" : _announcement,
              onTap: () => _editAnnouncement(context),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              title: "Theme Settings",
              value: ">",
              onTap: () => _openThemeSettings(context),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              title: "Black List",
              value: ">",
              onTap: () => _openBlackList(context),
            ),
            const SizedBox(height: 16),
            _buildAdditionalBox(),
          ],
        ),
      ),
    );
  }

  /// ✅ Room Avatar Section
  Widget _buildRoomAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _pickAndUploadAvatar();
          },
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[700],
            backgroundImage: _pickedImage != null
                ? FileImage(_pickedImage!) as ImageProvider
                : (widget.roomAvatarUrl != null
                    ? NetworkImage(widget.roomAvatarUrl!)
                    : null),
            child: (widget.roomAvatarUrl == null && _pickedImage == null)
                ? const Icon(Icons.camera_alt, color: Colors.white, size: 32)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Change Avatar",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  /// ✅ Common Setting Item
  Widget _buildSettingItem({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      tileColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.white54),
      ),
      onTap: onTap,
    );
  }

  /// ✅ Placeholder Methods
  void _editRoomName(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _roomName);
        return AlertDialog(
          title: const Text('Edit Room Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Room Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                Navigator.pop(context);
                if (newName.isEmpty) return;
                if (widget.userId == null || widget.roomId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing user or room id')));
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating room name...')));
                final res = await ApiManager.updateRoomName(
                  userId: widget.userId!,
                  roomId: widget.roomId!,
                  roomName: newName,
                );

                if (res['status'] == 'success' || res['code'] == 200 || res['status'] == 200) {
                  setState(() => _roomName = newName);
                  // Notify parent about the change so top bar can update
                  try {
                    widget.onRoomUpdated?.call(newName, null);
                  } catch (_) {}
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room name updated')));
                } else {
                  final msg = (res['message'] ?? res['msg'] ?? 'Update failed').toString();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $msg')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editAnnouncement(BuildContext context) {
    // Example: open dialog to edit announcement
  }

  void _openThemeSettings(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_)=>ThemeSelectionScreen()));
  }

  void _openBlackList(BuildContext context) {
    // Navigate to Blacklist screen
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() => _pickedImage = file);

      if (widget.userId == null || widget.roomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing user or room id')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading avatar...')));
      final res = await ApiManager.updateRoomProfile(
        userId: widget.userId!,
        roomId: widget.roomId!,
        imagePath: file.path,
        roomName: _roomName,
      );

      if (res['status'] == 'success' || res['code'] == 200) {
        final newProfile = res['room_profile'] ?? res['data']?['room_profile'] ?? res['profile'] ?? null;
        if (newProfile != null && newProfile is String) {
          setState(() {
            if (newProfile.startsWith('http')) {
              _pickedImage = null;
              try {
                widget.onRoomUpdated?.call(_roomName, newProfile);
              } catch (_) {}
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated')));
      } else {
        final msg = (res['message'] ?? res['msg'] ?? 'Upload failed').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $msg')));
      }
    } catch (e) {
      print('❌ Avatar upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar upload error')));
    }
  }

  Widget _buildAdditionalBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "Additional Settings Here",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
