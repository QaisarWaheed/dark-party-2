import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/components/follow_button.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';

import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initialize follow provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final followProvider = Provider.of<UserFollowProvider>(context, listen: false);
      followProvider.initialize();
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final provider = Provider.of<UserChatProvider>(context, listen: false);
      final text = _searchController.text.trim();

      // If user entered a full numeric user id (6+ digits to avoid partial IDs like 192), directly create/open chat
      if (RegExp(r'^\d{6,}$').hasMatch(text)) {
        try {
          final userId = int.parse(text);
          // Try to find existing chatroom first
          final existing = provider.getChatroomByUserId(userId);
          if (existing != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: existing),
              ),
            );
            return;
          }

          // Create new chatroom via provider and navigate immediately when available
          final created = await provider.createChatroom(userId);
          if (created != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoom: created),
              ),
            );
            return;
          }
        } catch (e) {
          // fallback to normal search if parsing/creation fails
          print('🔍 Numeric search failed: $e');
        }
      }

      // Default behavior: perform user search
      provider.searchUsers(_searchController.text);
    });
  }

  void _startChatWithUser(SearchedUser user) async {
    final provider = Provider.of<UserChatProvider>(context, listen: false);

    // Check if chatroom already exists
    final existingRoom = provider.getChatroomByUserId(user.id);

    if (existingRoom != null) {
      // Navigate to existing chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: existingRoom),
        ),
      );
    } else {
      // Create new chatroom and navigate immediately when the provider returns it
      final created = await provider.createChatroom(user.id);
      if (created != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: created),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final provider = Provider.of<UserChatProvider>(
              context,
              listen: false,
            );
            provider.clearSearch();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<UserChatProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by username or name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // Results
              Expanded(child: _buildResults(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(UserChatProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for users to start chatting',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.searchResults.isEmpty && provider.filteredChatRooms.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView(
      children: [
        // Existing conversations
        if (provider.filteredChatRooms.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Existing Conversations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...provider.filteredChatRooms.map(
            (room) => UserSearchTile(
              name: room.otherUserName,
              username: room.otherUserUsername,
              profileUrl: room.otherUserProfileUrl,
              isOnline: room.isOnline,
              isExisting: true,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatRoom: room),
                  ),
                );
              },
            ),
          ),
        ],

        // New users
        if (provider.searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Other Users',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...provider.searchResults.map(
            (user) => UserSearchTile(
              name: user.name,
              username: user.username,
              profileUrl: user.profileUrl,
              isOnline: user.isOnline,
              isExisting: false,
              userId: user.id,
              isFollowing: user.isFollowing,
              onTap: () => _startChatWithUser(user),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class UserSearchTile extends StatelessWidget {
  final String name;
  final String username;
  final String? profileUrl;
  final bool isOnline;
  final bool isExisting;
  final int? userId;
  final bool? isFollowing;
  final VoidCallback onTap;

  const UserSearchTile({
    super.key,
    required this.name,
    required this.username,
    this.profileUrl,
    this.isOnline = false,
    this.isExisting = false,
    this.userId,
    this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage:
                profileUrl != null
                    ? NetworkImage(profileUrl!)
                    : const AssetImage('assets/images/person.png')
                        as ImageProvider,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(name),
      subtitle: Text('@$username'),
      trailing: isExisting
          ? const Text('Chat', style: TextStyle(color: Colors.blue))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userId != null)
                  FollowButton(
                    targetUserId: userId!,
                    initialIsFollowing: isFollowing ?? false,
                    width: 90,
                    height: 32,
                    fontSize: 12,
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Message', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}
