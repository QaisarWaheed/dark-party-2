// admin_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/user_message_provider.dart';
import 'package:shaheen_star_app/model/admin_message_model.dart';
import 'package:shaheen_star_app/model/user_system_message_model.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserMessageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 15),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 15),
            onPressed: provider.loadAdminMessages,
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(UserMessageProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error loading messages',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.loadAdminMessages,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Combine both lists
    final allMessages = <dynamic>[];
    allMessages.addAll(provider.adminMessages);
    allMessages.addAll(provider.systemMessages);

    if (allMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No messages',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will see admin & system notifications here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort by date (descending)
    allMessages.sort((a, b) {
      DateTime dateA = DateTime(1970);
      DateTime dateB = DateTime(1970);

      if (a is AdminMessage) {
        dateA = a.createdAt;
      } else if (a is UserSystemMessage) {
        dateA = a.createdAtDate ?? DateTime(1970);
      }

      if (b is AdminMessage) {
        dateB = b.createdAt;
      } else if (b is UserSystemMessage) {
        dateB = b.createdAtDate ?? DateTime(1970);
      }

      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allMessages.length,
      itemBuilder: (context, index) {
        final message = allMessages[index];
        if (message is AdminMessage) {
          return _buildAdminMessageCard(message);
        } else if (message is UserSystemMessage) {
          return _buildUserSystemMessageCard(message);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildAdminMessageCard(AdminMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/images/app_logo.jpeg'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(message.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSystemMessageCard(UserSystemMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE3F2FD), // Light Blue
            child: Icon(
              Icons.notifications_active,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (message.amount != null && message.amount! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Amount: ${message.amount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    message.createdAtDate != null
                        ? _formatDate(message.createdAtDate!)
                        : (message.createdAt ?? ''),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
