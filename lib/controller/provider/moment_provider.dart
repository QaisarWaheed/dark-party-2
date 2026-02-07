import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/post_web_socket_service.dart';
import 'package:shaheen_star_app/model/post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';

import '../../model/comment_model.dart';

class MomentProvider with ChangeNotifier {
  final PostsWebSocketService _postWsService =
      PostsWebSocketService.instance;

  // ===================== STATE =====================
  List<PostModel> _allPosts = [];
  bool _isLoading = false;
    bool _isLoadingComments = false;
  String? _errorMessage;
    String? _errorMessageComments;
  dynamic value = [];
  PostModel? _singlePost;
PostModel? get singlePost => _singlePost;
final Map<int, List<CommentModel>> _postComments = {};
Map<int, List<CommentModel>> get postComments => _postComments;


  // ===================== GETTERS =====================
  List<PostModel> get allPosts => _allPosts;
  bool get isLoading => _isLoading;
    bool get isLoadingComments => _isLoadingComments;
  String? get errorMessage => _errorMessage;

  // ===================== USER ID =====================
  static Future<String> getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String rawUserId = '';

    if (prefs.containsKey('user_id')) {
      final v = prefs.get('user_id');
      if (v is int) rawUserId = v.toString();
      if (v is String) rawUserId = v;
    }

    if (rawUserId.isEmpty && prefs.containsKey('database_user_id')) {
      final v = prefs.get('database_user_id');
      if (v is int) rawUserId = v.toString();
      if (v is String) rawUserId = v;
    }

    return rawUserId;
  }

  // ===================== FETCH SINGLE POST =====================
Future<void> fetchSinglePost(String postId) async {
  try {
    print("🎁 [MomentProvider] ===== FETCH SINGLE POST =====");

    final completer = Completer<void>();
    bool handled = false;

    late void Function(Map<String, dynamic>) successHandler;
    late void Function(Map<String, dynamic>) errorHandler;

    successHandler = (data) {
      if (handled) return;
      handled = true;

      print("✅ [MomentProvider] Single post received");

      final payload = data['data'] ?? data;
      final postRaw = payload['post']; // assuming single post is in 'post'

      if (postRaw != null) {
        _singlePost = PostModel.fromJson(postRaw);
      } else {
        _singlePost = null;
      }

      notifyListeners();

      _postWsService.off('success', successHandler);
      _postWsService.off('error', errorHandler);

      completer.complete();
    };

    errorHandler = (data) {
      if (handled) return;
      handled = true;

      _errorMessage = data['message'] ?? 'Server error';
      _singlePost = null;

      notifyListeners();

      _postWsService.off('success', successHandler);
      _postWsService.off('error', errorHandler);

      completer.complete();
    };

    _postWsService.on('success', successHandler);
    _postWsService.on('error', errorHandler);

    final rawUserId = await getUserIdFromPrefs();
    final userId = int.tryParse(
          UserIdUtils.formatTo8Digits(rawUserId) ?? '0',
        ) ??
        0;

    _postWsService.sendAction('get_post', {
      'post_id': postId,
    });

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _errorMessage = 'Request timeout';
        _singlePost = null;
        notifyListeners();
      },
    );
  } catch (e) {
    _errorMessage = e.toString();
    _singlePost = null;
    notifyListeners();
  }
}


  // ===================== FETCH POSTS =====================
  Future<void> fetchAllPosts(limit,offset) async {
    try {
      print("🎁 [MomentProvider] ===== FETCH POSTS =====");
      _isLoading = true;
      notifyListeners();

      if (!_postWsService.isConnected) {
        final prefs = await SharedPreferences.getInstance();
        final rawUserId = await getUserIdFromPrefs();

        await _postWsService.connect(
          userId: UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId,
          username: prefs.getString('username') ?? '',
          name: prefs.getString('name') ?? '',
        );

        await Future.delayed(const Duration(milliseconds: 400));
      }

      final completer = Completer<void>();
      bool handled = false;

      late void Function(Map<String, dynamic>) successHandler;
      late void Function(Map<String, dynamic>) errorHandler;

      successHandler = (data) {
        if (handled) return;
        handled = true;

        print("✅ [MomentProvider] Feed received");

        final payload = data['data'] ?? data;
        final postsRaw = payload['posts'] ?? [];

        _allPosts = (postsRaw as List)
            .map((e) => PostModel.fromJson(e))
            .toList();

        value = _allPosts;

        _isLoading = false;
        _errorMessage = null;

        notifyListeners();

        _postWsService.off('success', successHandler);
        _postWsService.off('error', errorHandler);

        completer.complete();
      };

      errorHandler = (data) {
        if (handled) return;
        handled = true;

        _errorMessage = data['message'] ?? 'Server error';
        _allPosts = [];
        _isLoading = false;

        notifyListeners();

        _postWsService.off('success', successHandler);
        _postWsService.off('error', errorHandler);

        completer.complete();
      };

      _postWsService.on('success', successHandler);
      _postWsService.on('error', errorHandler);

      final rawUserId = await getUserIdFromPrefs();
      final userId = int.tryParse(
            UserIdUtils.formatTo8Digits(rawUserId) ?? '0',
          ) ??
          0;

      _postWsService.sendAction('get_feed', {
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      });
      notifyListeners();

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _errorMessage = 'Request timeout';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
// Convert File to Base64
String fileToBase64(File file) {
  final bytes = file.readAsBytesSync();
  return base64Encode(bytes);
}
  Future<bool> createPost({
  required String userId, // 8-digit formatted string
  required String caption,
  String? mediaUrl,
  String mediaType = 'text', // text | image | video
  String visibility = 'public',
  List<String> hashtags = const [],
}) async {
  if (!_postWsService.isConnected) {
    print("❌ [MomentProvider] WebSocket not connected");
    return false;
  }

  try {
    final completer = Completer<bool>();

   void postCreatedHandler(Map<String, dynamic> data) {
  try {
    final postData = data['post'] ?? data['data'];

    if (postData == null || postData is! Map<String, dynamic>) {
      print("❌ post:created payload is null or invalid, skipping");
      return;
    }

    final newPost = PostModel.fromJson(postData);

    _allPosts = List.from(_allPosts); // avoid concurrent modification
    _allPosts.insert(0, newPost);
    notifyListeners();
  } catch (e) {
    print("❌ [MomentProvider] Error parsing created post: $e");
  } finally {
    _postWsService.off('post:created', postCreatedHandler);
  }
}



    /// Listen for error
    void errorHandler(Map<String, dynamic> data) {
      print("❌ [MomentProvider] Create post error: ${data['message']}");
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      _postWsService.off('error', errorHandler);
    }

    _postWsService.on('post:created', postCreatedHandler);
    _postWsService.on('error', errorHandler);

    /// Send create_post action
    final request = {
      'action': 'create_post',
      'user_id': int.parse(userId),
      'caption': caption,
      'media_url': mediaUrl??"",
      'media_type': mediaType,
      'visibility': visibility,
      'hashtags': hashtags,
    };
print("!!!!!!!!!!!!!!!!!!!!!!!!");
    print(request);

    final sent = _postWsService.sendAction('create_post',request);



    if (!sent) {
      print("❌ [MomentProvider] Failed to send create_post");
      return false;
    }

    print("📤 [MomentProvider] create_post sent");

    return await completer.future.timeout(
       Duration(seconds: mediaType=="image"?20:5),
      onTimeout: () {
        print("⚠️ [MomentProvider] create_post timeout");
        return false;
      },
    );
  } catch (e) {
    print("❌ [MomentProvider] createPost exception: $e");
    return false;
  }
}

Future<bool> likePost({required int postId, required String userId}) async {
  if (!_postWsService.isConnected) {
    print("❌ WebSocket not connected for like_post");
    return false;
  }

  try {
    final completer = Completer<bool>();

    void successCallback(Map<String, dynamic> data) {
      if (!completer.isCompleted) completer.complete(true);
      _postWsService.off('success', successCallback);
    }

    void errorCallback(Map<String, dynamic> data) {
      if (!completer.isCompleted) completer.complete(false);
      _postWsService.off('error', errorCallback);
    }

    _postWsService.on('success', successCallback);
    _postWsService.on('error', errorCallback);

    final sent = _postWsService.sendAction('like_post', {
      'user_id': int.tryParse(userId) ?? 0,
      'post_id': postId,
    });

    if (!sent) {
      _postWsService.off('success', successCallback);
      _postWsService.off('error', errorCallback);
      return false;
    }

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _postWsService.off('success', successCallback);
        _postWsService.off('error', errorCallback);
        return false;
      },
    );
  } catch (e) {
    print("❌ Error liking post: $e");
    return false;
  }
}
Future<bool> deletePost({required int postId, required String userId}) async {
  if (!_postWsService.isConnected) {
    print("❌ WebSocket not connected for delete_post");
    return false;
  }

  try {
    // ------------------------
    // 1. Remove post locally immediately
    // ------------------------
    final removedPostIndex = _allPosts.indexWhere((post) => post.id == postId);
    if (removedPostIndex == -1) return false; // not found

    final removedPost = _allPosts.removeAt(removedPostIndex);
    notifyListeners(); // immediately update UI

    // ------------------------
    // 2. Send delete action to WebSocket
    // ------------------------
    final completer = Completer<bool>();

    void successCallback(Map<String, dynamic> data) {
      if (!completer.isCompleted) completer.complete(true);
      _postWsService.off('success', successCallback);
    }

    void errorCallback(Map<String, dynamic> data) {
      // ------------------------
      // 3. Revert if deletion fails
      // ------------------------
      _allPosts.insert(removedPostIndex, removedPost);
      notifyListeners();

      if (!completer.isCompleted) completer.complete(false);
      _postWsService.off('error', errorCallback);
    }

    _postWsService.on('success', successCallback);
    _postWsService.on('error', errorCallback);

    final sent = _postWsService.sendAction('delete_post', {
      'post_id': postId,
      'user_id':userId
    });

    if (!sent) {
      _allPosts.insert(removedPostIndex, removedPost);
      notifyListeners();
      _postWsService.off('success', successCallback);
      _postWsService.off('error', errorCallback);
      return false;
    }

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _allPosts.insert(removedPostIndex, removedPost);
        notifyListeners();
        _postWsService.off('success', successCallback);
        _postWsService.off('error', errorCallback);
        return false;
      },
    );
  } catch (e) {
    print("❌ Error deleting post: $e");
    return false;
  }
}
Future<void> getCommentsByPostId({
  required int postId,
  int page = 1,
  int limit = 200,
}) async {
  try {
    print("🎁 [MomentProvider] ===== FETCH COMMENTS FOR POST $postId =====");
    _isLoadingComments = true;
    _errorMessageComments = null;
    notifyListeners();

    if (!_postWsService.isConnected) {
      final prefs = await SharedPreferences.getInstance();
      final rawUserId = await getUserIdFromPrefs();

      await _postWsService.connect(
        userId: UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId,
        username: prefs.getString('username') ?? '',
        name: prefs.getString('name') ?? '',
      );

      await Future.delayed(const Duration(milliseconds: 400));
    }

    final completer = Completer<void>();
    bool handled = false;

    late void Function(Map<String, dynamic>) successHandler;
    late void Function(Map<String, dynamic>) errorHandler;

    // ------------------------
    // Success Handler
    // ------------------------
    successHandler = (data) {
      if (handled) return;
      handled = true;

      print("✅ [MomentProvider] Comments received for post $postId");

      final payload = data['data'] ?? data;
      final commentsRaw = payload['comments'] ?? [];

      _postComments[postId] = (commentsRaw as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();

      _isLoadingComments = false;
      _errorMessageComments = null;
      notifyListeners();

      _postWsService.off('success', successHandler);
      _postWsService.off('error', errorHandler);

      completer.complete();
    };

    // ------------------------
    // Error Handler
    // ------------------------
    errorHandler = (data) {
      if (handled) return;
      handled = true;

      _errorMessageComments = data['message'] ?? 'Server error';
      _postComments[postId] = [];
      _isLoadingComments = false;

      notifyListeners();

      _postWsService.off('success', successHandler);
      _postWsService.off('error', errorHandler);

      completer.complete();
    };

    _postWsService.on('success', successHandler);
    _postWsService.on('error', errorHandler);

    // ------------------------
    // Send WebSocket action
    // ------------------------
    _postWsService.sendAction('get_comments', {
      'post_id': postId,
      'page': page,
      'limit': limit,
    });

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _errorMessageComments = 'Request timeout';
        _isLoadingComments = false;
        _postComments[postId] = [];
        notifyListeners();
      },
    );
  } catch (e) {
    print("❌ [MomentProvider] getCommentsByPostId exception: $e");
    _errorMessageComments = e.toString();
    _isLoadingComments = false;
    _postComments[postId] = [];
    notifyListeners();
  }
}

Future<bool> addComment({
  required int postId,
  required String userId,
    required String userName,
  required String commentText,
    required String profileUrl,
}) async {
  if (!_postWsService.isConnected) {
    print("❌ WebSocket not connected for add_comment");
    return false;
  }

  try {
    final completer = Completer<bool>();

    // ---------------------------
    // 1️⃣ Optimistic comment model
    // ---------------------------
    final optimisticComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch, // temp id
      
      postId: postId,
      userId: int.parse(userId),
      username: userName,
      comment: commentText,
      createdAt: DateTime.now(),
      profileUrl: profileUrl,
      formattedDate: DateTime.now().toString()
    );


    _postComments.putIfAbsent(postId, () => []);
    _postComments[postId]!.insert(0, optimisticComment);
    notifyListeners();

    // ---------------------------
    // 2️⃣ Success handler
    // ---------------------------
    void commentCreatedHandler(Map<String, dynamic> data) {
      print("✅ [MomentProvider] post:commented received");

      try {
        final payload = data['comment'] ?? data['data'];
        final serverComment = CommentModel.fromJson(payload);

        // Replace optimistic comment
        _postComments[postId]!.removeWhere(
          (c) => c.id == optimisticComment.id,
        );
        _postComments[postId]!.insert(0, serverComment);

        notifyListeners();

        if (!completer.isCompleted) completer.complete(true);
      } catch (e) {
        print("❌ Comment parse error: $e");
        if (!completer.isCompleted) completer.complete(false);
      }

      _postWsService.off('post:commented', commentCreatedHandler);
    }

    // ---------------------------
    // 3️⃣ Error handler (rollback)
    // ---------------------------
    void errorHandler(Map<String, dynamic> data) {
      print("❌ add_comment failed: ${data['message']}");

      _postComments[postId]!
          .removeWhere((c) => c.id == optimisticComment.id);

      notifyListeners();

      if (!completer.isCompleted) completer.complete(false);
      _postWsService.off('error', errorHandler);
    }

    _postWsService.on('post:commented', commentCreatedHandler);
    _postWsService.on('error', errorHandler);

    // ---------------------------
    // 4️⃣ Send WS action
    // ---------------------------
    final sent = _postWsService.sendAction('add_comment', {
      'user_id': int.parse(userId),
      'post_id': postId,
      'comment': commentText,
    });

    if (!sent) {
      _postComments[postId]!
          .removeWhere((c) => c.id == optimisticComment.id);
      notifyListeners();
      return false;
    }

    return await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _postComments[postId]!
            .removeWhere((c) => c.id == optimisticComment.id);
        notifyListeners();
        return false;
      },
    );
  } catch (e) {
    print("❌ addComment exception: $e");
    return false;
  }
}



  // ===================== UTILS =====================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _errorMessage = null;
    notifyListeners();
  }
}




// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shaheen_star_app/controller/api_manager/post_web_socket_service.dart';
// import 'package:shaheen_star_app/model/gift_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shaheen_star_app/utils/user_id_utils.dart';

// class MomentProvider with ChangeNotifier {
//   final PostsWebSocketService _postWsService = PostsWebSocketService.instance; // ✅ Post WebSocket (port 8084)

//   // State variables
//   List<GiftModel> _allPosts = [];
//   bool _isLoading = false;
//   String? _errorMessage;
//     dynamic value=[];

//   // Getters
//   List<GiftModel> get allPosts => _allPosts;
  
  
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   // Helper function to get user_id from SharedPreferences (handles both int and String)
//   static Future<String> _getUserIdFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     String rawUserId = '';
    
//     if (prefs.containsKey('user_id')) {
//       final user_id_value = prefs.get('user_id');
//       if (user_id_value is int) {
//         rawUserId = user_id_value.toString();
//       } else if (user_id_value is String) {
//         rawUserId = user_id_value;
//       }
//     }
    
//     if (rawUserId.isEmpty && prefs.containsKey('database_user_id')) {
//       final db_user_id_value = prefs.get('database_user_id');
//       if (db_user_id_value is int) {
//         rawUserId = db_user_id_value.toString();
//       } else if (db_user_id_value is String) {
//         rawUserId = db_user_id_value;
//       }
//     }
    
//     return rawUserId;
//   }

//   /// Fetch all posts - uses Posts WebSocket (port 8085) only
//   Future<void> fetchAllPosts() async {
//     try {
//       print("🎁 [PostsProvider] ===== FETCHING Posts =====");
//       print("🎁 [PostsProvider] Post WebSocket Connected: ${_postWsService.isConnected}");
//       print("🎁 [PostsProvider] Current posts count: ${_allPosts.length}");
//       print("🎁 [PostsProvider] Current isLoading: $_isLoading");
      
//       // ✅ If posts are already loaded and we're not currently loading, skip fetch
//       // This prevents unnecessary re-fetching when sheet opens multiple times
//       if (_allPosts.isNotEmpty && !_isLoading) {
//         print("✅ [PostProvider] Posts already loaded (${_allPosts.length} posts) - skipping fetch");
//         // Ensure loading is false (safety check) and notify listeners to update UI
//         _isLoading = false;
//         _errorMessage = null;
//         notifyListeners();
//         return;
//       }
      
//       _isLoading = true;
//       _errorMessage = null;
//       print("🔄 [PostProvider] Setting isLoading = true and notifying listeners");
//         notifyListeners();

//       // ✅ Connect to Posts WebSocket if not connected
//       bool useWebSocket = false;
      
//       if (!_postWsService.isConnected) {
//         print("🔄 [PostProvider] Connecting to Post WebSocket (port 8084)...");
//         try {
//           final prefs = await SharedPreferences.getInstance();
//           final rawUserId = await _getUserIdFromPrefs();
//           // ✅ Format user_id to 8 digits before connecting
//           final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
//           final username = prefs.getString('username') ?? prefs.getString('userName') ?? '';
//           final name = prefs.getString('name') ?? username;
          
//           final connected = await _postWsService.connect(
//             userId: userId,
//             username: username,
//             name: name,
//           );
            
//           // ✅ Wait a bit for connection to stabilize
//           await Future.delayed(Duration(milliseconds: 500));
//           useWebSocket = _postWsService.isConnected;
          
//           if (!connected || !useWebSocket) {
//             print("❌ [PostProvider] Failed to connect to Posts WebSocket");
//             print("   - Connected return value: $connected");
//             print("   - isConnected status: ${_postWsService.isConnected}");
//             _errorMessage = 'Failed to connect to server. Please check your connection.';
//             _allPosts = [];
//             _isLoading = false;
//             notifyListeners();
//             return;
//           } else {
//             print("✅ [PostProvider] Post WebSocket connection verified and stable");
//           }
//         } catch (e) {
//           print("❌ [PostProvider] Error connecting to Posts WebSocket: $e");
//           _errorMessage = 'Error connecting to server: $e';
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//           return;
//         }
//       } else {
//         // ✅ Already connected - verify it's still valid
//         useWebSocket = _postWsService.isConnected;
//         if (!useWebSocket) {
//           print("⚠️ [PostProvider] Previously connected WebSocket is now disconnected");
//           _errorMessage = 'Connection lost. Please try again.';
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//           return;
//         } else {
//           print("✅ [PostProvider] Reusing existing Posts WebSocket connection");
//         }
//       }
      
//       if (useWebSocket) {
//         print("✅ [PostProvider] Post WebSocket is available and connected");
//         print("🎁 [PostProvider] Attempting to fetch posts via Post WebSocket (port 8084)...");
        
//         // Use Completer to wait for WebSocket response
//         final completer = Completer<void>();
//         bool responseReceived = false;
        
//         // Set up callback to receive gifts:list event
//         _postWsService.on('posts:list', (data) {
//           if (responseReceived) return; // Prevent multiple calls
//           responseReceived = true;
          
//           print("🎁 [PostProvider] posts:list event received from Post WebSocket");
//           print("🎁 [PostProvider] Data keys: ${data.keys.toList()}");
          
//           try {
//           // Parse posts from response
//           List<GiftModel> postsList = [];
          
//           // Handle different response formats
//           if (data['posts'] != null && data['posts'] is List) {
//             postsList = (data['posts'] as List)
//                 .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                 .toList();
//           } else if (data['data'] != null) {
//             if (data['data'] is List) {
//               postsList = (data['data'] as List)
//                   .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                   .toList();
//             } else if (data['data'] is Map) {
//               final dataMap = data['data'] as Map<String, dynamic>;
//               if (dataMap['posts'] != null && dataMap['posts'] is List) {
//                 postsList = (dataMap['posts'] as List)
//                     .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                     .toList();
//               }
//             }
//           }
          
//           if (postsList.isNotEmpty) {
//      _allPosts = postsList;
//             print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Start!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
//           print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
//             print(_allPosts[0]);
         
//             value=_allPosts;
        

//         notifyListeners();
//            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!End!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
//           print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
       
     
//             _errorMessage = null;
//             _isLoading = false;
            
//             print("✅ [GiftProvider] ===== Posts FETCHED SUCCESSFULLY =====");
//             print("✅ [GiftProvider] Total gifts: ${_allPosts.length}");
//             print("✅ [GiftProvider] Status: Success");
//             print("✅ [GiftProvider] ======================================");
            
//             // Log detailed gift information
//             for (var post in _allPosts) {
//               print("📦 [PostProvider] Post: ${post.name} (ID: ${post.id})");
            
//             }
            
//             notifyListeners();
//             if (!completer.isCompleted) {
//               completer.complete();
//             }
//           } else {
//             print("⚠️ [PostProvider] No posts found in WebSocket response");
//             _errorMessage = 'No posts found in server response';
//             _allPosts = [];
//             _isLoading = false;
//             notifyListeners();
//             if (!completer.isCompleted) {
//               completer.complete();
//             }
//           }
//         } catch (e) {
//           print("❌ [PostProvider] Error parsing WebSocket posts: $e");
//           _errorMessage = 'Error parsing gifts: $e';
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//           if (!completer.isCompleted) {
//             completer.complete();
//           }
//         }
//         });
      
//         // Set up success callback (status: success) - might contain gifts
//         _postWsService.on('success', (data) {
//           if (responseReceived) return;
          
//           // Check if this is a gifts response
//           if (data.containsKey('posts') || 
//               (data.containsKey('data') && data['data'] is List) ||
//               (data.containsKey('data') && data['data'] is Map && (data['data'] as Map).containsKey('posts'))) {
//             responseReceived = true;
            
//             print("🎁 [PostProvider] Success response with posts received from Post WebSocket");
//             print("🎁 [PostProvider] Data keys: ${data.keys.toList()}");
            
//             try {
//               // Parse posts from response
//               List<GiftModel> postsList = [];
              
//               // Handle different response formats
//               if (data['posts'] != null && data['posts'] is List) {
//                 postsList = (data['posts'] as List)
//                     .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                     .toList();
//               } else if (data['data'] != null) {
//                 if (data['data'] is List) {
//                   postsList = (data['data'] as List)
//                       .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                       .toList();
//                 } else if (data['data'] is Map) {
//                   final dataMap = data['data'] as Map<String, dynamic>;
//                   if (dataMap['posts'] != null && dataMap['posts'] is List) {
//                     postsList = (dataMap['posts'] as List)
//                         .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//                         .toList();
//                   }
//                 }
//               }
              
//               if (postsList.isNotEmpty) {
//                 _allPosts = postsList;
              
//                 _errorMessage = null;
//                 _isLoading = false;
//                 print("✅ [PostProvider] Posts fetched via Post WebSocket (success response): ${_allPosts.length} posts");
//                 notifyListeners();
//                 if (!completer.isCompleted) {
//                   completer.complete();
//                 }
//               } else {
//                 print("⚠️ [PostProvider] No posts found in success response");
//                 _errorMessage = 'No posts found in server response';
//                 _allPosts = [];
//                 _isLoading = false;
//                 notifyListeners();
//                 if (!completer.isCompleted) {
//                   completer.complete();
//                 }
//               }
//             } catch (e) {
//               print("❌ [PostProvider] Error parsing success response posts: $e");
//               _errorMessage = 'Error parsing posts: $e';
//               _allPosts = [];
//               _isLoading = false;
//               notifyListeners();
//               if (!completer.isCompleted) {
//                 completer.complete();
//               }
//             }
//           }
//         });
        
//         // Set up error callback - no retry logic
//         _postWsService.on('error', (data) {
//           if (responseReceived) return;
//           responseReceived = true;
          
//           final errorMsg = data['message'] as String? ?? 'Server error';
//           print("❌ [PostProvider] ===== Posts WEBSOCKET ERROR RESPONSE =====");
//           print("❌ [PostProvider] Error Message: $errorMsg");
          
//           _errorMessage = errorMsg;
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//           if (!completer.isCompleted) {
//             completer.complete();
//           }
//         });
        
//         // Get user_id for the request
//         final rawUserId = await _getUserIdFromPrefs();
//         // ✅ Format user_id to 8 digits before sending to backend
//         final userId = UserIdUtils.formatTo8Digits(rawUserId) ?? (rawUserId.isEmpty ? '0' : rawUserId);
//         final userIdInt = int.tryParse(userId) ?? 0;
        
//         // Request gifts via Gifts WebSocket
//         print("📤 [PostProvider] Sending get_feed request to Posts WebSocket (port 8084)...");
//         final requestData = <String, dynamic>{
         
//           'user_id': userIdInt, // Backend may expect int, but we format the source to 8 digits
//           'limit': 200,
//           'offset': 0,
//         };
        
     
      
        
//         // ✅ Wait a bit more to ensure connection is fully ready
//         await Future.delayed(Duration(milliseconds: 300));
        
//         // ✅ Double-check connection before sending
//         if (!_postWsService.isConnected) {
//           print("❌ [PostProvider] Connection lost before sending request");
//           _errorMessage = 'Connection lost. Please try again.';
//         _allPosts = [];
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
      
//         final success = _postWsService.sendAction('get_feed', requestData);
        
//         if (!success) {
//           print("❌ [PostProvider] Posts WebSocket request failed");
//           _errorMessage = 'Failed to send request to server';
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//         } else {
//           print("✅ [PostProvider] get_feed request sent successfully to Post WebSocket");
//           print("⏳ [PostProvider] Waiting for server response (timeout: 5 seconds)...");

//           // Wait for WebSocket response
//       try {
//         await completer.future.timeout(
//               Duration(seconds: 5),
//           onTimeout: () {
//             if (!responseReceived) {
//                   print("⚠️ [PostProvider] ===== Posts WEBSOCKET RESPONSE TIMEOUT =====");
//                   print("⚠️ [PostProvider] Server did not respond within 5 seconds");
//                   _errorMessage = 'Server did not respond. Please try again.';
//               _allPosts = [];
//               _isLoading = false;
//               notifyListeners();
//             }
//           },
//         );
//       } catch (e) {
//             print("❌ [PostProvider] Error waiting for Posts WebSocket response: $e");
//           _errorMessage = 'Error waiting for server response: $e';
//           _allPosts = [];
//           _isLoading = false;
//           notifyListeners();
//         }
//         }
//       } else {
//         print("❌ [PostProvider] Posts WebSocket not available");
//         _errorMessage = 'Unable to connect to server. Please check your connection.';
//         _allPosts = [];
//         _isLoading = false;
//         notifyListeners();
//       }
//     } catch (e) {
//       print("❌ [PostProvider] Error fetching posts: $e");
//       _errorMessage = 'Error loading posts: $e';
//       _allPosts = [];
//       _isLoading = false;
//       print("✅ [PostProvider] Exception handler: Setting isLoading = false and notifying listeners");
//       notifyListeners();
//     } finally {
//       // ✅ Final safeguard: Ensure loading is always cleared
//       if (_isLoading) {
//         print("⚠️ [PostProvider] FINAL SAFEGUARD: isLoading was still true - forcing it to false");
//         _isLoading = false;
//         notifyListeners();
//       }
//       print("✅ [PostProvider] fecthAllPosts completed. Final state: isLoading=$_isLoading, posts=${_allPosts.length}");
//     }
//   }

//   /// Fetch posts feed via Posts WebSocket
// Future<List<GiftModel>> getFeed({
//   required String userId,   // 8-digit formatted string
//   int page = 1,
//   int limit = 10,
//   Function(String)? onError,       // Optional error callback
//   Function(List<GiftModel>)? onSuccess, // Optional success callback
// }) async {
//   final completer = Completer<List<GiftModel>>();

//   // Ensure WebSocket is connected
//   if (!_postWsService.isConnected) {
//     final msg = "❌ [PostWebSocketService] Cannot fetch feed: WebSocket not connected";
//     print(msg);
//     if (onError != null) onError(msg);
//     return [];
//   }

//   // Temporary listener for success response
//   void successCallback(Map<String, dynamic> data) {
//     List<GiftModel> posts = [];

//     try {
//       // Server may send 'posts' or 'data.posts'
//       if (data['posts'] != null && data['posts'] is List) {
//         posts = (data['posts'] as List)
//             .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//             .toList();
//       } else if (data['data'] != null) {
//         final dataMap = data['data'];
//         if (dataMap is List) {
//           posts = dataMap.map((item) => GiftModel.fromJson(item as Map<String, dynamic>)).toList();
//         } else if (dataMap is Map && dataMap['posts'] != null && dataMap['posts'] is List) {
//           posts = (dataMap['posts'] as List)
//               .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
//               .toList();
//         }
//       }

//       print("✅ [PostWebSocketService] Feed received: ${posts.length} posts");

//       if (onSuccess != null) onSuccess(posts);
//       if (!completer.isCompleted) completer.complete(posts);
//     } catch (e) {
//       print("❌ [PostWebSocketService] Error parsing feed: $e");
//       if (onError != null) onError(e.toString());
//       if (!completer.isCompleted) completer.complete([]);
//     }

//     // Remove listener after first response
//     _postWsService.off('success', successCallback);
   
//   }

//   // Temporary listener for error response
//   void errorCallback(Map<String, dynamic> data) {
//     final msg = data['message']?.toString() ?? "Unknown server error";
//     print("❌ [PostWebSocketService] Feed error: $msg");
//     if (onError != null) onError(msg);
//     if (!completer.isCompleted) completer.complete([]);
   
//     _postWsService.off('error', errorCallback);
//   }

//   // Register temporary callbacks
//   _postWsService.on('success', successCallback);
//   _postWsService.on('error', errorCallback);

//   // Send get_feed action
//   final requestData = {
//     'user_id': userId,
//     'page': page,
//     'limit': limit,
//   };

//   final sent = _postWsService.sendAction('get_feed', requestData);
//   if (!sent) {
//     final msg = "❌ [PostWebSocketService] Failed to send get_feed request";
//     print(msg);
//     _postWsService.off('success', successCallback);
//     _postWsService.off('error', errorCallback);
//     if (onError != null) onError(msg);
//     return [];
//   } else {
//     print("📤 [PostWebSocketService] get_feed request sent successfully");
//   }

//   // Wait for response or timeout
//   try {
//     return await completer.future.timeout(Duration(seconds: 5), onTimeout: () {
//       final msg = "⚠️ [PostWebSocketService] get_feed response timeout";
//       print(msg);
//       _postWsService.off('success', successCallback);
//       _postWsService.off('error', errorCallback);
//       if (onError != null) onError(msg);
//       return <GiftModel>[];
//     });
//   } catch (e) {
//     final msg = "❌ [PostWebSocketService] Exception waiting for feed: $e";
//     print(msg);
//    _postWsService. off('success', successCallback);
//     _postWsService.off('error', errorCallback);
//     if (onError != null) onError(msg);
//     return [];
//   }
// }



//   /// Create a new post via Posts WebSocket
// Future<bool> createPost({
//   required String userId,               // Must be 8-digit formatted string
//   required String caption,
//   String? mediaUrl,
//   String? mediaType,                    // "image", "video", etc.
//   String visibility = 'public',         // "public", "friends", "private"
//   List<String>? hashtags,
//   Function(Map<String, dynamic>)? onSuccess,  // Optional success callback
//   Function(Map<String, dynamic>)? onError,    // Optional error callback
// }) async {
//   // Ensure WebSocket is connected
//   if (!_postWsService.isConnected ) {
//     print("❌ [PostWebSocketService] Cannot create post: WebSocket not connected");
//     return false;
//   }

//   try {
//     final requestData = {
//       'action': 'create_post',
//       'user_id': userId,
//       'caption': caption,
//       'media_url': mediaUrl ?? '',
//       'media_type': mediaType ?? 'text',
//       'visibility': visibility,
//       'hashtags': hashtags ?? [],
//     };

//     // Register temporary listeners if callbacks are provided
//     void successCallback(Map<String, dynamic> data) {
//       if (onSuccess != null) onSuccess(data);
//       _postWsService.off('success', successCallback); // Unregister after one call
//     }

//     void errorCallback(Map<String, dynamic> data) {
//       if (onError != null) onError(data);
//       _postWsService.off('error', errorCallback); // Unregister after one call
//     }

//     if (onSuccess != null) _postWsService.on('success', successCallback);
//     if (onError != null) _postWsService.on('error', errorCallback);

//     // Send action
//     final sent = _postWsService.sendAction('create_post', requestData);
//     if (sent) {
//       print("📤 [PostWebSocketService] create_post request sent successfully");
//       return true;
//     } else {
//       print("❌ [PostWebSocketService] Failed to send create_post request");
//       return false;
//     }
//   } catch (e) {
//     print("❌ [PostWebSocketService] Error creating post: $e");
//     return false;
//   }
// }


//   /// Clear error message
//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }

//   /// Reset state
//   void reset() {
//     _errorMessage = null;
//     notifyListeners();
//   }
// }


