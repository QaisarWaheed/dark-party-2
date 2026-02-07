import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/view/screens/user_chat/chat_screen.dart';
import 'package:shaheen_star_app/components/animated_name_text.dart';
import 'package:shaheen_star_app/view/screens/user_chat/user_search_screen.dart';

bool isValidNetworkUrl(String? url) {
  if (url == null) return false;
  final s = url.trim();
  return s.startsWith('http://') || s.startsWith('https://');
}

// Theme colors (from Figma)
const Color _primaryGreen = Color(0xFF00C853);
const Color _officialOrange = Color(0xFFFFC107);
const Color _unreadRed = Color(0xFFFF3B30);
const Color _sentBlue = Color(0xFF2F80ED);
const Color _bubbleGrey = Color(0xFFF5F6F8);
const Color _dividerColor = Color(0xFFF0F0F0);

Color _colorForName(String name) {
  final palette = [
    Color(0xFF00C853), // green
    Color(0xFF9B27FF), // purple
    Color(0xFFFF3B30), // red
    Color(0xFF00BCD4), // cyan
    Color(0xFFFFEB3B), // yellow
    Color(0xFFFF6B81), // pink
    Color(0xFF2F80ED), // blue
  ];
  if (name.isEmpty) return Colors.black;
  final idx = name.codeUnits.fold(0, (p, c) => p + c) % palette.length;
  return palette[idx];
}
class ChatListScreen extends StatefulWidget {
  final int? preselectUserId;
  const ChatListScreen({super.key, this.preselectUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserChatRoom> _filteredRooms = [];
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    
    // ✅ Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserChatProvider>(context, listen: false);
      
      // Check if already initialized
      if (!provider.isConnected && !provider.isLoading) {
        print('🔄 Initializing chat provider from screen...');
        provider.initialize();
      } else if (provider.isConnected) {
        // If already connected, just fetch chat rooms
        print('🔄 Already connected, fetching chat rooms...');
        provider.getChatRooms();
      }

      // If this screen was opened to start/locate a conversation for a specific user
      final targetUserId = widget.preselectUserId;
      if (targetUserId != null) {
        // Show UI feedback that we're opening/creating the conversation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening conversation...'), duration: Duration(seconds: 5)),
        );
        // If a chatroom already exists, open it immediately
        final existing = provider.getChatroomByUserId(targetUserId);
        if (existing != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: existing)),
          );
          return;
        }

        // Otherwise, request creation and navigate when the provider returns the room
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final created = await provider.createChatroom(targetUserId);
          if (created != null && context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: created)),
            );
          } else {
            print('⚠️ No chatroom created yet for user $targetUserId');
            // Keep the snackbar briefly to indicate pending state
          }
        });
      }
    });

    // ✅ Local search listener
    _searchController.addListener(_filterChatRooms);
  }

  void _filterChatRooms() {
    final provider = Provider.of<UserChatProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredRooms = provider.chatRooms;
      });
    } else {
      setState(() {
        _filteredRooms = provider.chatRooms.where((room) {
          return room.otherUserName.toLowerCase().contains(query) ||
                 room.otherUserUsername.toLowerCase().contains(query) ||
                 (room.lastMessage?.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isValidNetworkUrl(String? url) {
      if (url == null) return false;
      final s = url.trim();
      return s.startsWith('http://') || s.startsWith('https://');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // placeholder action
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_chat_unread, color: Colors.green, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // placeholder action
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.green, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<UserChatProvider>(
        builder: (context, provider, child) {
          print('🔄 ChatListScreen rebuild - isLoading: ${provider.isLoading}, isConnected: ${provider.isConnected}, error: ${provider.error}');
          print('📊 Current chat rooms count: ${provider.chatRooms.length}');
          
          // ✅ Handle loading state - only show for initial load
          if (provider.isLoading && _isFirstLoad) {
            print('⏳ Showing loading indicator (first load)...');
            // Don't set _isFirstLoad to false here yet, wait for data
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading conversations...'),
                ],
              ),
            );
          }

          // ✅ Mark first load as complete if we have data OR an error
          if (_isFirstLoad && (!provider.isLoading || provider.error != null)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _isFirstLoad = false;
            });
          }

          // ✅ Handle connection error
          if (!provider.isConnected && provider.error != null) {
            print('❌ Connection error: ${provider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Not connected to server',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error ?? 'Connection lost',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                    onPressed: () {
                      print('🔁 Manual reconnect pressed');
                      provider.reconnect();
                    },
                  ),
                ],
              ),
            );
          }

          // ✅ Handle other errors (but still show data if available)
          if (provider.error != null && provider.chatRooms.isEmpty) {
            print('⚠️ General error with no data: ${provider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.getChatRooms();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // ✅ Update filtered rooms when chatRooms change
          if (_searchController.text.isEmpty && _filteredRooms.length != provider.chatRooms.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _filteredRooms = provider.chatRooms;
              });
            });
          }

          // ✅ Handle empty state after loading (connected but no rooms)
          if (provider.chatRooms.isEmpty && !provider.isLoading && provider.isConnected) {
            print('📭 Chat rooms are empty (connected, no rooms)');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a new conversation by\nsearching for users',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Search Users'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSearchScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () {
                      print('🔄 Manual refresh - fetching chat rooms...');
                      provider.getChatRooms();
                    },
                  ),
                ],
              ),
            );
          }

          final displayedRooms = _searchController.text.isEmpty 
              ? provider.chatRooms 
              : _filteredRooms;

          print('📊 Displaying ${displayedRooms.length} chat rooms');

          return Column(
            children: [
              // Search bar removed as per design request
              
              // ✅ Show error banner if there's an error but we have data
              if (provider.error != null && provider.chatRooms.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),
              
              // unread banner removed per design
              
              // ✅ Connection Status Bar (only when disconnected)
              if (!provider.isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.isLoading ? 'Connecting to server...' : 'Disconnected',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (provider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton(
                          onPressed: () => provider.reconnect(),
                          child: const Text('Reconnect', style: TextStyle(color: Colors.orange)),
                        ),
                    ],
                  ),
                ),
              
              // ✅ Chat List
              Expanded(
                child: displayedRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Placeholder image removed per design
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty 
                                ? 'No conversations yet' 
                                : 'No conversations found',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                onPressed: () => provider.getChatRooms(),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          print('🔄 Pull to refresh triggered');
                          provider.getChatRooms();
                          // Wait for loading to complete
                          await Future.delayed(const Duration(milliseconds: 500));
                          while (provider.isLoading) {
                            await Future.delayed(const Duration(milliseconds: 100));
                          }
                        },
                        child: ListView.builder(
                          itemCount: displayedRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = displayedRooms[index];
                            return ChatRoomTile(
                              key: ValueKey(chatRoom.id),
                              chatRoom: chatRoom,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final provider = Provider.of<UserChatProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(context);
                  provider.getChatRooms();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_chat_read),
                title: const Text('Mark all as read'),
                onTap: () {
                  Navigator.pop(context);
                  for (var room in provider.chatRooms) {
                    if (room.unreadCount > 0) {
                      provider.markAsRead(room.id);
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All messages marked as read')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  provider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
                title: Text(provider.isConnected ? 'Connected' : 'Disconnected'),
                subtitle: Text(provider.isConnected ? 'Real-time updates active' : 'Tap to reconnect'),
                onTap: () {
                  Navigator.pop(context);
                  if (!provider.isConnected) {
                    provider.reconnect();
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Debug Info'),
                subtitle: Text(
                  'Rooms: ${provider.chatRooms.length}\n'
                  'Connected: ${provider.isConnected}\n'
                  'Loading: ${provider.isLoading}'
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ChatRoomTile extends StatelessWidget {
  final UserChatRoom chatRoom;

  const ChatRoomTile({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    final bool showOfficial = chatRoom.otherUserName.toLowerCase().contains('admin') || chatRoom.otherUserUsername.toLowerCase().contains('official');

    return InkWell(
      onTap: () {
        final provider = Provider.of<UserChatProvider>(context, listen: false);
        provider.markAsRead(chatRoom.id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                // Avatar with colored ring, white inner border and soft shadow
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _colorForName(chatRoom.otherUserName).withOpacity(0.9), width: 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (chatRoom.otherUserProfileUrl != null && chatRoom.otherUserProfileUrl!.startsWith('assets/'))
                          ? AssetImage(chatRoom.otherUserProfileUrl!) as ImageProvider
                          : isValidNetworkUrl(chatRoom.otherUserProfileUrl)
                              ? NetworkImage(chatRoom.otherUserProfileUrl!)
                              : null,
                      child: (chatRoom.otherUserProfileUrl == null ||
                              (!isValidNetworkUrl(chatRoom.otherUserProfileUrl) && !(chatRoom.otherUserProfileUrl?.startsWith('assets/') ?? false)))
                          ? Text(
                              chatRoom.otherUserName.isNotEmpty ? chatRoom.otherUserName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            )
                          : null,
                    ),
                  ),
                ),
                if (chatRoom.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(const BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: chatRoom.unreadCount > 0
                            ? Row(
                                children: [
                                  Expanded(
                                    child: AnimatedNameText(
                                      text: chatRoom.otherUserName.isNotEmpty ? chatRoom.otherUserName : 'Unknown User',
                                      fontSize: 16,
                                      color: showOfficial ? Colors.black : null,
                                    ),
                                  ),
                                  if (showOfficial) const SizedBox(width: 6),
                                  if (showOfficial) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chatRoom.otherUserName.isNotEmpty ? chatRoom.otherUserName : 'Unknown User',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontFamily: 'Kablammo',
                                        fontSize: 16,
                                        height: 30 / 16,
                                        fontWeight: FontWeight.w600,
                                        color: showOfficial ? Colors.black : _colorForName(chatRoom.otherUserName),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (showOfficial) const SizedBox(width: 6),
                                  if (showOfficial) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
                                ],
                              ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Show date of last message under the name
                  if (chatRoom.lastMessageTime != null)
                    Text(
                      _formatDate(chatRoom.lastMessageTime!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  const SizedBox(height: 6),
                  if (chatRoom.lastMessage != null && chatRoom.lastMessage!.isNotEmpty)
                    Text(
                      chatRoom.lastMessage!,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: chatRoom.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        color: chatRoom.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Time + unread
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                
                if (chatRoom.lastMessageTime != null)
                  Text(
                    _formatTime(chatRoom.lastMessageTime!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 8),
                if (chatRoom.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B81),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      chatRoom.unreadCount > 99 ? '99+' : chatRoom.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDay).inDays < 7) {
      return _getWeekday(time.weekday);
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatDate(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  
}