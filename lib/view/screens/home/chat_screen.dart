import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final int messageId;
  final int senderId;
  final String senderName;
  final String message;
  final String? mediaUrl;
  final DateTime createdAt;
  final String messageType;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.mediaUrl,
    required this.messageType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      senderId: json['sender_id'],
      senderName: json['sender']['name'],
      message: json['message'] ?? '',
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      messageType: json['message_type'],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late IOWebSocketChannel _channel;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsUrl =
        'ws://localhost:8089?user_id=${widget.currentUserId}&username=user&name=User';
    _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((event) {
      final data = jsonDecode(event);
      final eventType = data['event'];

      if (eventType == 'chat:connected') {
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });
      } else if (eventType == 'chat:message') {
        final message = ChatMessage.fromJson(data['data']);
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      } else if (eventType == 'chat:user_status') {
        // handle user status if needed
      }
    }, onError: (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }, onDone: () {
      setState(() {
        _isConnected = false;
      });
      // reconnect after 3s
      Future.delayed(Duration(seconds: 3), _connectWebSocket);
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final response =
          await http.post(Uri.parse('https://shaheenstar.online/send_chat_message.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'sender_id': widget.currentUserId,
                'receiver_id': widget.otherUserId,
                'message': text,
              }));
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${data['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://shaheenstar.online/send_chat_message.php'));
      request.fields['sender_id'] = widget.currentUserId.toString();
      request.fields['receiver_id'] = widget.otherUserId.toString();
      request.files.add(await http.MultipartFile.fromPath('image', pickedFile.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      if (data['status'] != 'success') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${data['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName),
                Text(
                  _isConnected ? 'Online' : (_isLoading ? 'Connecting...' : 'Offline'),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) Text(msg.senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
            if (msg.messageType == 'text')
              Text(msg.message, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
            if (msg.messageType == 'image' && msg.mediaUrl != null)
              Image.network(msg.mediaUrl!, height: 150),
            SizedBox(height: 4),
            Text('${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.image, color: Colors.blue), onPressed: _sendImage),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendTextMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel.sink.close();
    super.dispose();
  }
}
