import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

// Shared theme colors used by chat screens
const Color _primaryGreen = Color(0xFF00C853);
const Color _sentBlue = Color(0xFF2F80ED);
const Color _bubbleGrey = Color(0xFFF5F6F8);

class ChatScreen extends StatefulWidget {
  final UserChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Top-level helper so widgets in this file can validate image URLs
bool isValidNetworkUrl(String? url) {
  if (url == null) return false;
  final s = url.trim();
  return s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'));
}

// Normalize profile URLs coming from backend (relative paths -> absolute)
String? _normalizeProfileUrl(String? profileUrl) {
  if (profileUrl == null || profileUrl.isEmpty) return null;
  final s = profileUrl.trim();

  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('assets/')) return s;

  // local file paths
  if (s.startsWith('/data/') || s.startsWith('/storage/') || s.contains('cache')) return s;

  // common relative server paths -> prefix with canonical base
  final clean = s.startsWith('/') ? s.substring(1) : s;
  return 'https://shaheenstar.online/$clean';
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    
    // ✅ CORRECT: Set current chatroom and load messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserChatProvider>(context, listen: false);
      
      // Set this chatroom as active
      provider.setCurrentChatroom(widget.chatRoom.id);
      
      // Mark as read
      provider.markAsRead(widget.chatRoom.id);
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final provider = Provider.of<UserChatProvider>(context, listen: false);
    provider.sendChatMessage(message);
    
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startVoiceNote() async {
    if (_isRecording) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission needed for voice messages')),
        );
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100), path: path);
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _currentRecordingPath = path;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start recording: $e')));
      }
    }
  }

  Future<void> _stopAndSendVoiceNote() async {
    if (!_isRecording || _currentRecordingPath == null) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      await _audioRecorder.stop();
      final path = _currentRecordingPath!;
      final duration = _recordingSeconds;
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
        _recordingSeconds = 0;
      });
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording file not found')));
        return;
      }
      final chatProvider = Provider.of<UserChatProvider>(context, listen: false);
      final ok = await chatProvider.sendVoiceMessage(file, durationSeconds: duration > 0 ? duration : null);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send voice message')));
      } else {
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _currentRecordingPath = null;
          _recordingSeconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showOfficial = (widget.chatRoom.otherUserName.toLowerCase().contains('official') ||
        widget.chatRoom.otherUserUsername.toLowerCase().contains('official'));
    // Use top-level `isValidNetworkUrl`

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  // Normalize profile URL first so relative server paths are handled
                  backgroundImage: () {
                    final normalized = _normalizeProfileUrl(widget.chatRoom.otherUserProfileUrl);
                    if (normalized != null && normalized.startsWith('assets/')) {
                      return AssetImage(normalized) as ImageProvider;
                    }
                    if (normalized != null && normalized.startsWith('http')) {
                      return NetworkImage(normalized);
                    }
                    return null;
                  }(),
                  child: () {
                    final normalized = _normalizeProfileUrl(widget.chatRoom.otherUserProfileUrl);
                    if (normalized == null || (!normalized.startsWith('http') && !normalized.startsWith('assets/'))) {
                      return Text(
                        widget.chatRoom.otherUserName.isNotEmpty ? widget.chatRoom.otherUserName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    }
                    return null;
                  }(),
                ),
                if (widget.chatRoom.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.chatRoom.otherUserName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showOfficial) const SizedBox(width: 6),
                            if (showOfficial) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.chatRoom.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.chatRoom.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!showOfficial)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openChatOptionsPage(context, widget.chatRoom),
            ),
        ],
      ),
      body: Consumer<UserChatProvider>(
        builder: (context, provider, child) {
          // ✅ Safe access to provider properties
          final messages = provider.messages;
          final currentUserId = provider.currentUserId;
          
          return Column(
            children: [
              // ✅ Show error if exists
              if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),
              
              // ✅ Messages List
              Expanded(
                child: provider.isLoading && messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(color: Colors.grey, fontSize: 18),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUserId;
                              
                              return MessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
              ),
              
              // ✅ Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Image picker
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.grey),
                      onPressed: () async {
                        try {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (picked == null) return;
                          final file = File(picked.path);
                          final chatProvider = Provider.of<UserChatProvider>(context, listen: false);
                          final ok = await chatProvider.sendImageMessage(file);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send image')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image error: $e')));
                        }
                      },
                    ),
                    // Voice note: tap to start, tap again to stop & send (no Zego)
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic_none,
                        color: _isRecording ? Colors.red : Colors.grey[700],
                      ),
                      onPressed: _isRecording ? _stopAndSendVoiceNote : _startVoiceNote,
                    ),
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                    // When recording: Send = stop & send voice. When not: Send = send text.
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _isRecording ? _stopAndSendVoiceNote : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openChatOptionsPage(BuildContext context, UserChatRoom chatRoom) async {
    final provider = Provider.of<UserChatProvider>(context, listen: false);
    final currentUserId = provider.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    Map<String, dynamic>? status;
    try {
      status = await ApiManager.getChatUserStatus(userId: currentUserId, targetUserId: chatRoom.otherUserId);
    } catch (e) {
      status = null;
    }

    bool parseBlocked(Map<String, dynamic>? m) {
      if (m == null) return false;
      final v = m['blocked'] ?? m['is_blocked'] ?? m['blocked_by'] ?? m['isBlocked'];
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    bool blocked = parseBlocked(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chat Settings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (chatRoom.otherUserProfileUrl != null && chatRoom.otherUserProfileUrl!.startsWith('assets/'))
                              ? AssetImage(chatRoom.otherUserProfileUrl!) as ImageProvider
                              : isValidNetworkUrl(chatRoom.otherUserProfileUrl)
                                  ? NetworkImage(chatRoom.otherUserProfileUrl!)
                                  : null,
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          ListTile(
                            title: const Text('Clear chat history'),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clear chat history (placeholder)')));
                            },
                          ),
                          ListTile(
                            title: const Text('Report'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report (placeholder)')));
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setStateLocal) {
                              bool isUpdating = false;
                              return SwitchListTile(
                                title: const Text('Block'),
                                value: blocked,
                                onChanged: isUpdating
                                    ? null
                                    : (val) async {
                                        setStateLocal(() => isUpdating = true);
                                        print('[ChatOptions] Toggling block -> $val for ${chatRoom.otherUserId}');
                                        final ok = await ApiManager.blockUnblockUser(userId: currentUserId, targetUserId: chatRoom.otherUserId, block: val);
                                        print('[ChatOptions] blockUnblockUser returned: $ok');
                                        if (!ok) {
                                          setStateLocal(() {
                                            isUpdating = false;
                                            // keep previous value
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update block status')));
                                          return;
                                        }

                                        // Re-fetch status to confirm server state
                                        Map<String, dynamic>? newStatus;
                                        try {
                                          newStatus = await ApiManager.getChatUserStatus(userId: currentUserId, targetUserId: chatRoom.otherUserId);
                                        } catch (e) {
                                          newStatus = null;
                                        }
                                        print('[ChatOptions] getChatUserStatus after toggle: $newStatus');

                                        bool parseBlockedLocal(Map<String, dynamic>? m) {
                                          if (m == null) return val; // fallback to optimistic
                                          final v = m['blocked'] ?? m['is_blocked'] ?? m['blocked_by'] ?? m['isBlocked'] ?? m['blocked_user'];
                                          if (v == null) return val;
                                          if (v is bool) return v;
                                          if (v is int) return v == 1;
                                          if (v is String) return v == '1' || v.toLowerCase() == 'true';
                                          return val;
                                        }

                                        final confirmed = parseBlockedLocal(newStatus);
                                        setStateLocal(() {
                                          blocked = confirmed;
                                          isUpdating = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmed ? 'User blocked' : 'User unblocked')));
                                      },
                              );
                            },
                          ),
                          ListTile(
                            title: const Text('Set current chat background'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set background (placeholder)')));
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete conversation (placeholder)')));
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}

// ✅ FIXED: Using correct UserChatMessage model
class MessageBubble extends StatelessWidget {
  final  message; // ✅ Changed from SearchedUser
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,2))],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: isValidNetworkUrl(message.senderProfileUrl)
                  ? NetworkImage(message.senderProfileUrl!.trim())
                  : const AssetImage('assets/images/person.png') as ImageProvider,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0,1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  // Render by message type: image, voice, or text
                  if (message.attachmentType == 'image' && message.attachmentUrl != null)
                    ImageMessageBubble(imageUrl: message.attachmentUrl!, isMe: isMe)
                  else if (message.attachmentType == 'voice' && message.attachmentUrl != null)
                    VoiceMessageBubble(audioUrl: message.attachmentUrl!, isMe: isMe)
                  else
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black45,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ImageMessageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;

  const ImageMessageBubble({super.key, required this.imageUrl, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isMe ? _primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image)),
                  );
                },
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                width: 220,
                height: 180,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
              ),
      ),
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const VoiceMessageBubble({super.key, required this.audioUrl, this.isMe = false});

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final isRemote = widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://');
      if (isRemote) {
        await _player.play(UrlSource(widget.audioUrl));
      } else {
        await _player.play(DeviceFileSource(widget.audioUrl));
      }
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    return InkWell(
      onTap: _togglePlay,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              _isPlaying ? 'Playing...' : 'Voice message',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}