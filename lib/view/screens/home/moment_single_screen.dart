import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/moment_provider.dart';
import 'package:shaheen_star_app/model/comment_model.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../controller/api_manager/time_service.dart';
import '../profile/detailed_profile_screen.dart';

class MomentSingleScreen extends StatefulWidget {
  final dynamic post; // pass full post object from all posts
  final String userId; // current user id

  const MomentSingleScreen({
    super.key,
    required this.post,
    required this.userId,
  });

  @override
  State<MomentSingleScreen> createState() => _MomentSingleScreenState();
}

class _MomentSingleScreenState extends State<MomentSingleScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel>? comment;
  final String topBg = 'assets/images/bg_home.png';
  dynamic userId;
    dynamic userName;
       dynamic profileUrl;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = await _getUserIdFromPrefs();
       userName = await _getUserNameFromPrefs();
       profileUrl = await _getUserProfileUrlFromPrefs();
      // Fetch comments for this post
      final momentProvider = Provider.of<MomentProvider>(
        context,
        listen: false,
      );
      await momentProvider.getCommentsByPostId(postId: widget.post.id);

      if (momentProvider.postComments.containsKey(widget.post.id)) {
        comment = momentProvider.postComments[widget.post.id];
      }

      setState(() {});
    });
  }
void _sendComment() async {
  final text = _commentController.text.trim();
  if (text.isEmpty) return;

  _commentController.clear();

  final momentProvider =
      Provider.of<MomentProvider>(context, listen: false);

  await momentProvider.addComment(
    postId: widget.post.id,
    userId: userId,
    commentText: text,
    userName: userName,
    profileUrl:profileUrl
  );

}


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  ImageProvider _getSafeImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty||imagePath=="assets/images/person.png") {
      return const AssetImage('assets/images/person.png');
    }
    else if (imagePath.startsWith('https://') || imagePath.startsWith('http://')) {
      
      return CachedNetworkImageProvider(imagePath);
    }
    return CachedNetworkImageProvider('https://shaheenstar.online/$imagePath');
  }

  static Future<String> _getUserIdFromPrefs() async {
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
    return UserIdUtils.formatTo8Digits(rawUserId) ?? rawUserId;
  }

  static Future<String> _getUserNameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String rawUserName = '';
    if (prefs.containsKey('user_name')) {
      final v = prefs.get('user_name');
    rawUserName = v.toString();
     
    }
    if (prefs.containsKey('username')) {
      final v = prefs.get('username');
    rawUserName = v.toString();
     
    }
    if (rawUserName.isEmpty && prefs.containsKey('database_user_name')) {
      final v = prefs.get('database_user_name');
       rawUserName = v.toString();
    }
    if (rawUserName.isEmpty && prefs.containsKey('database_username')) {
      final v = prefs.get('database_username');
       rawUserName = v.toString();
    }
    return rawUserName;
  }

  static Future<String> _getUserProfileUrlFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String rawUserProfile = '';
    if (prefs.containsKey('profile_url')) {
      final v = prefs.get('profile_url');
    rawUserProfile = v.toString();
     
    }
    if (prefs.containsKey('profileUrl')) {
      final v = prefs.get('profileUrl');
    rawUserProfile = v.toString();
     
    }
    if (rawUserProfile.isEmpty && prefs.containsKey('database_profile_url')) {
      final v = prefs.get('database_profile_url');
       rawUserProfile = v.toString();
    }
    if (rawUserProfile.isEmpty && prefs.containsKey('database_profileUrl')) {
      final v = prefs.get('database_profileUrl');
       rawUserProfile = v.toString();
    }
    return rawUserProfile;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final momentProvider = Provider.of<MomentProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppImage.asset(
              topBg,
              width: size.width,
              fit: BoxFit.cover,
              height: size.height * 0.25,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back & Title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Post",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(child:
                            CircleAvatar(
                              backgroundImage: _getSafeImageProvider(
                                widget.post.profileUrl,
                              ),
                              radius: 25,
                            ),onTap:(){
                                              Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailedProfileScreen(
                userId: widget.post.userId.toString(),
              ),
            ),
          );
                            }),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.username,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                               timeago.format((widget.post.createdAt.toUtc()).toLocal()).toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: MediaQuery.of(context).size.height * 0.015,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Caption
                        if (widget.post.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            child: Text(
                              widget.post.caption,
                              maxLines: 100,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.height * 0.017,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Image
                        if (widget.post.isImage && widget.post.hasMedia)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image(
                                  image: _getSafeImageProvider(
                                    widget.post.mediaUrl,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),

                        // Footer: comments + likes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Likes
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    // 1️⃣ Optimistic update: toggle locally
                                    setState(() {
                                      widget.post.isLiked =
                                          !widget.post.isLiked;
                                      widget.post.likesCount +=
                                          widget.post.isLiked ? 1 : -1;
                                    });

                                    // 2️⃣ Send request to backend
                                    final success = await momentProvider
                                        .likePost(
                                          postId: widget.post.id,
                                          userId: userId,
                                        );

                                    // 3️⃣ Revert UI if backend failed
                                    if (!success) {
                                      setState(() {
                                        widget.post.isLiked =
                                            !widget.post.isLiked;
                                        widget.post.likesCount +=
                                            widget.post.isLiked ? 1 : -1;
                                      });
                                    }
                                  },
                                  child: Icon(
                                    widget.post.isLiked
                                        ? Icons.thumb_up_alt
                                        : Icons.thumb_up_off_alt,
                                    color: Colors.grey.shade600,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.post.likesCount.toString(),
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.height * 0.017,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (userId ==
                                UserIdUtils.formatTo8Digits(
                                  widget.post.userId.toString(),
                                ).toString())
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey.shade600,
                                  size: 25,
                                ),
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text('Delete Post?'),
                                        content: const Text(
                                          'Are you sure you want to delete this post?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
if (confirmed ?? false) {
  final success = await momentProvider.deletePost(
    postId: widget.post.id,
    userId: userId,
  );
   setState(() {
    
  });
  if (!mounted) return;
  if (success) {
    Navigator.pop(context); // go back after delete
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Post deleted successfully' : 'Failed to delete post',
      ),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
    ),
  );


}

                                  }
                                },

                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete),
                                        SizedBox(width: 5),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                  // Add more options here if needed
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        const Divider(),

                        const Text(
                          "All Comments",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),

                        (momentProvider.isLoadingComments)
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: const Color.fromARGB(
                                    255,
                                    188,
                                    145,
                                    16,
                                  ),
                                ),
                              )
                            : 
                            (comment!.isEmpty)?
                            SizedBox(height: size.width/3,child:Center(child:Text("No comments found",style: TextStyle(color:Colors.black),))):
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comment?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final comments = comment![index];

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        leading: GestureDetector(child:CircleAvatar(
                                          backgroundImage:_getSafeImageProvider(comments.profileUrl!,
                                                )
                                             ,
                                        ),onTap: (){
                                                          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailedProfileScreen(
                userId: comments.userId.toString(),
              ),
            ),
          );
                                        },),
                                        title: Text(
                                          comments.username,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          formatFromNow((comments.createdAt.toUtc()).toLocal().toString())
                                          ,

                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsetsGeometry.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          comments.comment,
                                          maxLines: 100,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      Divider(),
                                    ],
                                  );
                                },
                              ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(30),
          border: Border(
            top: BorderSide(color: Colors.grey.shade700, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: _sendComment,
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFd3902f),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Send",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
