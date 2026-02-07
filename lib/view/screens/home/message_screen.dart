import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/custom_bottom_nav.dart';
import 'package:shaheen_star_app/controller/provider/user_message_provider.dart';
import 'package:shaheen_star_app/view/screens/home/admin_chat.dart';
import 'package:shaheen_star_app/view/screens/user_chat/user_chat_list_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  int selectedTopIndex = 0;
  final String topBg = 'assets/images/bg_home.png';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAllMessages();
    });
  }

  Future<void> _initializeAllMessages() async {
    final provider = Provider.of<UserMessageProvider>(context, listen: false);

    print('🔄 Initializing all messages system...');
    await provider.initializeUser();

    // Donos types ki messages load karo
    await provider.loadAllMessages();

    // Agar koi chatroom nahi hai toh admin chat start karo
    if (provider.isInitialized && provider.chatRooms.isEmpty) {
      print('👤 Starting admin chat as fallback...');
      await _startAdminChat(provider);
    }

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _startAdminChat(UserMessageProvider provider) async {
    try {
      print('🔄 Starting admin chat...');
      bool success = await provider.startAdminChat();
      if (success) {
        print('✅ Admin chat started successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome! Chat with admin has been started.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Failed to start admin chat: ${provider.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start admin chat: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting admin chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      // backgroundColor: const Color(0xFFFDF6E8),
      body: Stack(
        children: [
          // Background top image
          Container(
            width: double.infinity,
            height: size.height * 0.30,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(topBg),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            height: size.height * 0.22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFA54F).withOpacity(0.6),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                //   child:
                //    Row(
                //     children: [

                //       SizedBox(width: 8),
                //       Text(
                //         'Messages',
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 20,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       Spacer(),
                //       IconButton(
                //         icon: Icon(Icons.search, color: Colors.white),
                //         onPressed: () {},
                //       ),
                //       IconButton(
                //         icon: Icon(Icons.more_vert, color: Colors.white),
                //         onPressed: () {},
                //       ),
                //     ],
                //   ),
                // ),

                // TopBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTopTab("Message", 0),
                      const SizedBox(width: 18),
                      _buildTopTab("Group", 1),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Main Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _isInitializing
                        ? _buildLoadingState()
                        : Consumer<UserMessageProvider>(
                            builder: (context, provider, child) {
                              return _buildMainContent(provider);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: CustomBottomNavBar(
          backgroundImage: 'assets/images/bg_bottom_nav.png',
          selectedIndex: 0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Setting up your chats...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(UserMessageProvider provider) {
    return Column(
      children: [
        // System Messages Section (Image jaisa design) - CLICKABLE
        _buildSystemMessagesSection(provider),

        // Event News Section
        _buildEventNewsSection(),

        // Applications Section
        _buildApplicationsSection(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatListScreen()),
            );
          },
        ),

        // User Chats Section
        // _buildUserChatsSection(provider),
      ],
    );
  }

  Widget _buildSystemMessagesSection(UserMessageProvider provider) {
    return GestureDetector(
      onTap: () {
        // System Message par click karein toh Admin Messages Screen par navigate karo
        _navigateToAdminMessagesScreen(provider);
      },
      child: Container(
        margin: EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(
                'assets/images/app_logo.jpeg',
              ), // ✅ AssetImage use karo
              // backgroundColor: Colors.grey[200], // optional fallback color
            ),
            title: Text(
              "Dark Party Admin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            // subtitle: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     SizedBox(height: 4),
            //     Text(
            //       "S H Q unfollowed you",
            //       style: TextStyle(
            //         fontWeight: FontWeight.w600,
            //         fontSize: 14,
            //         color: Colors.black87,
            //       ),
            //     ),
            //     SizedBox(height: 2),
            //     Text(
            //       "1d ago",
            //       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            //     ),
            //   ],
            // ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  // MessageScreen mein _navigateToAdminMessagesScreen method update karo
  void _navigateToAdminMessagesScreen(UserMessageProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminMessagesScreen()),
    );
  }

  Widget _buildEventNewsSection() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.event, color: Colors.white, size: 20),
        ),
        title: Text(
          "Event News",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "No Content Available",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          // Event news screen navigation
          print("Event News section tapped");
        },
      ),
    );
  }

  Widget _buildApplicationsSection({VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add, color: Colors.white, size: 20),
            ),
            title: Text(
              "Applications",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              "38398450 applied to be your friend",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "1",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: () {
              // Yahan aap applications screen par navigate kar sakte hain
              print("Applications tile tapped");
              if (onTap != null) onTap();
            },
          ),
        ),
      ),
    );
  }
  // Widget _buildUserChatsSection(UserMessageProvider provider) {
  //   return Expanded(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Section Header
  //         Padding(
  //           padding: EdgeInsets.all(16),
  //           child: Row(
  //             children: [
  //               Icon(Icons.chat, color: Colors.purple),
  //               SizedBox(width: 8),
  //               Text(
  //                 "Your Chats",
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //               SizedBox(width: 8),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //                 decoration: BoxDecoration(
  //                   color: Colors.purple,
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: Text(
  //                   provider.chatRooms.length.toString(),
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         // Chat List
  //         Expanded(
  //           child: _buildUserChatsList(provider),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ... (rest of the methods remain same as previous code)

  // void _navigateToChatScreen({
  //   required BuildContext context,
  //   required ChatRoom chatRoom,
  //   required int currentUserId,
  //   required UserMessageProvider provider,
  // }) async {
  //   provider.setCurrentChatroom(chatRoom.id);
  //   // Navigator.push(
  //   //   context,
  //   //   MaterialPageRoute(
  //   //     builder: (context) => ChatScreen(
  //   //       chatRoom: chatRoom,
  //   //       currentUserId: currentUserId,
  //   //     ),
  //   //   ),
  //   // );
  // }

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _buildTopTab(String title, int index) {
    final isSelected = selectedTopIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTopIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 20 : 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Dialog removed: FAB now opens ChatListScreen directly.
}
