import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/room_message_provider.dart';
import 'package:shaheen_star_app/view/screens/room/room_setting_screen.dart';
import 'package:shaheen_star_app/view/screens/store/store_screen.dart';
class ToolsBottomSheet extends StatelessWidget {
  final String? roomId;
  final String? userId;
  final String? roomName;
  final String? roomProfileUrl;
  final void Function(String newName, String? newProfileUrl)? onRoomUpdated;

  const ToolsBottomSheet({
    super.key,
    this.roomId,
    this.userId,
    this.roomName,
    this.roomProfileUrl,
    this.onRoomUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 254, 254),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Basic Tools Section
            _buildSectionHeader("Basic Tools"),
            const SizedBox(height: 10),
            _buildBasicToolsRow(),
            const SizedBox(height: 16),
            _buildSectionHeader("Other Tools"),
            const SizedBox(height: 10),
            _buildOtherToolsGrid(context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBasicToolsRow() {
    final partyTools = [
      {'icon': 'assets/icons/1.png', 'label': ''},
      {'icon': 'assets/icons/2.png', 'label': ''},
      {'icon': 'assets/icons/3.png', 'label': ''},
      {'icon': 'assets/icons/4.png', 'label': ''},
      {'icon': 'assets/icons/5.png', 'label': ''},
      {'icon': 'assets/icons/6.png', 'label': ''},
      {'icon': 'assets/icons/7.png', 'label': ''},
      {'icon': 'assets/icons/8.png', 'label': ''},
      {'icon': 'assets/icons/9.png', 'label': ''},
      {'icon': 'assets/icons/10.png', 'label': ''},
      {'icon': 'assets/icons/11.png', 'label': ''},
      {'icon': 'assets/icons/12.png', 'label': ''},
      {'icon': 'assets/icons/13.png', 'label': ''},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemCount: partyTools.length,
      itemBuilder: (context, index) {
        return _buildToolItem(
          icon: partyTools[index]['icon']!,
          label: partyTools[index]['label']!,
        );
      },
    );
  }

  // ✅ CONTEXT PARAMETER ADD KARO
  Widget _buildOtherToolsGrid(BuildContext context) {
    final otherTools = [
      {'icon': '⚙️', 'label': 'Setting'},
      {'icon': '🏪', 'label': 'Store'},
      {'icon': '🧹', 'label': 'Clear Mag'},
      {'icon': '✨', 'label': 'Effect Switch'},
      {'icon': '👑', 'label': 'Admin'},
      {'icon': '🎤', 'label': 'Number Of Mics'},
      {'icon': '💺', 'label': 'Seat Skin'},
      {'icon': '🔊', 'label': 'Lucky Sound'},
      {'icon': '📱', 'label': 'Pocket Banner'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: otherTools.length,
      itemBuilder: (context, index) {
        final tool = otherTools[index];
        
        // ✅ CLEAR MAG FUNCTIONALITY
        VoidCallback? onTap;

        if (tool['label'] == 'Setting') {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomSettingsScreen(
                  roomId: roomId,
                  userId: userId,
                  roomName: roomName ?? 'Room',
                  roomAvatarUrl: roomProfileUrl,
                  onRoomUpdated: onRoomUpdated,
                ),
              ),
            );
          };
        } else if (tool['label'] == 'Store') {
          onTap = () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreScreen(),
              ),
            );
          };
        } else if (tool['label'] == 'Clear Mag') {
          onTap = () {
            _showClearChatConfirmation(context);
          };
        }

        return _buildToolItem(
          icon: tool['icon']!,
          label: tool['label']!,
          onTap: onTap,
        );
      },
    );
  }

  // ✅ CLEAR CHAT CONFIRMATION DIALOG
  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Messages"),
        content: const Text("Are you sure you want to clear all messages in this room?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // ✅ CLEAR MESSAGES
              _clearAllMessages(context);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CLEAR ALL MESSAGES FUNCTION
  void _clearAllMessages(BuildContext context) {
    try {
      final messageProvider = context.read<RoomMessageProvider>();
      messageProvider.clearMessages();
      
      // ✅ SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All messages cleared successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      print("✅ All messages cleared from room");
    } catch (e) {
      print("❌ Error clearing messages: $e");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to clear messages"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildToolItem({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black,
    ),
    clipBehavior: Clip.antiAlias,
    child: Builder(builder: (context) {
      // If the icon string looks like an asset path, load it. Otherwise render as text (emoji or label).
      final looksLikeAsset = icon.startsWith('assets/') || icon.contains('.') && !icon.runes.any((r) => r > 0x1F600);
      if (looksLikeAsset) {
        return AppImage.asset(
          icon,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.error, color: Colors.redAccent));
          },
        );
      } else {
        return Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        );
      }
    }),
  ),
           
         
      
    );
  }
}
