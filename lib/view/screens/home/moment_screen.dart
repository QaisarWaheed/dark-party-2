import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/moment_provider.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:shaheen_star_app/view/screens/home/moment_create_screen.dart';
import 'package:shaheen_star_app/view/screens/home/moment_single_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../controller/api_manager/post_web_socket_service.dart';
import '../../../controller/provider/bottom_nav_provider.dart';
import '../profile/detailed_profile_screen.dart';
class MomentScreen extends StatefulWidget {
  const MomentScreen({super.key});

  @override
  State<MomentScreen> createState() => _MomentScreenState();
}

class _MomentScreenState extends State<MomentScreen> {
  final String topBg = 'assets/images/bg_home.png';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final int _limit = 10; // fetch 10 posts at a time
  dynamic userId;
   


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async{
     userId = await _getUserIdFromPrefs();
     
      final momentProvider = Provider.of<MomentProvider>(context, listen: false);
      _fetchInitialPosts(momentProvider);

     
    });

    _scrollController.addListener(() async {
      final momentProvider = Provider.of<MomentProvider>(context, listen: false);

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore) {
        // Fetch more posts when reaching near bottom
        _isLoadingMore = true;
        await momentProvider.fetchAllPosts(
          _limit,
           momentProvider.allPosts.length,
        );
        _isLoadingMore = false;
      }
    });
  }

  Future<void> _fetchInitialPosts(MomentProvider provider) async {
    await provider.fetchAllPosts(10, 0);
     setState(() {
        
      });
    
  }

  @override
  void dispose() {
    _scrollController.dispose();
    PostsWebSocketService.instance.disconnect();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
 final momentProvider = Provider.of<MomentProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              topBg,
              width: size.width,
              fit: BoxFit.cover,
              height: size.height * 0.25,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _fetchInitialPosts(momentProvider),
              child:  (momentProvider.allPosts.isEmpty)?
              SingleChildScrollView(
  controller: _scrollController,
  physics: const AlwaysScrollableScrollPhysics(), // 👈 allows pull-to-refresh
  child:
              Column(children: [
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _fetchInitialPosts(momentProvider),
                            child: const Text(
                              'Moment',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              final provider =
                                  Provider.of<BottomNavProvider>(context, listen: false);
                              provider.changeTab(1);
                            },
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                            SizedBox(height: size.width,child:Center(child:Text("No post found",style: TextStyle(color:Colors.black),)))])):


                ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                 // top: size.height * 0.15,
                  left: size.width * 0.04,
                  right: size.width * 0.04,
                  bottom: size.height * 0.12,
                ),
                itemCount: momentProvider.allPosts.length + 1,
                itemBuilder: (context, index) {
                 
                  if (index == 0) {
                    // Top bar
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _fetchInitialPosts(momentProvider),
                            child: const Text(
                              'Moment',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              final provider =
                                  Provider.of<BottomNavProvider>(context, listen: false);
                              provider.changeTab(1);
                            },
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (index > momentProvider.allPosts.length) {
                    return _isLoadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox();
                  }

                  final post = momentProvider.allPosts[index - 1];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(height:10),
                        // Header
                        Row(
                          children: [

                            GestureDetector(child:
                            CircleAvatar(
                              backgroundImage: _getSafeImageProvider(post.profileUrl),
                              radius: 25,
                            ),onTap: (){
                               Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailedProfileScreen(
                userId: post.userId.toString(),
              ),
            ),
          ).whenComplete(() {

      _fetchInitialPosts(momentProvider);
});
                            },),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.username,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                               
                                timeago.format((post.createdAt.toUtc()).toLocal()).toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Caption
                        if (post.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Text(
                              post.caption,
                              maxLines: 100,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Image
                        if (post.isImage && post.hasMedia)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: 
                           
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image(
                                  image: _getSafeImageProvider(post.mediaUrl),
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
                            // Comments
                            
                            GestureDetector(onTap: (){

                            
                        Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomentSingleScreen(
          post: post,          // pass the full post object
          userId: userId,      // pass the current user id
        ),
      )).whenComplete(() {

      _fetchInitialPosts(momentProvider);
});
                            },child:
                            Row(
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  color: Colors.grey.shade600,
                                  size: 22,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  post.commentsCount.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),),
                            // Likes
                           Row(
  children: [
    GestureDetector(
      onTap: () async {

        // 1️⃣ Optimistic update: toggle locally
        setState(() {
          post.isLiked = !post.isLiked;
          post.likesCount += post.isLiked ? 1 : -1;
        });

        // 2️⃣ Send request to backend
        final success = await momentProvider.likePost(
          postId: post.id,
          userId: userId,
        );

        // 3️⃣ Revert UI if backend failed
        if (!success) {
          setState(() {
            post.isLiked = !post.isLiked;
            post.likesCount += post.isLiked ? 1 : -1;
          });
        }
      },
      child: Icon(
        post.isLiked ? Icons.thumb_up_alt : Icons.thumb_up_off_alt,
        color:  Colors.grey.shade600,
        size: 25,
      ),
    ),
    const SizedBox(width: 2),
    Text(
      post.likesCount.toString(),
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),
                     if(userId==UserIdUtils.formatTo8Digits(post.userId.toString()).toString())PopupMenuButton<String>(
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
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',),
            ),
          ],
        ),
      );

     if (confirmed ?? false) {
  final success = await momentProvider.deletePost(
    postId: post.id,
    userId: userId,
  );
  setState(() {
    
  });

  if (!mounted) return;
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
      child: Row(children: [Icon(Icons.delete),SizedBox(width: 5,),Text('Delete'),])
    ),
    // Add more options here if needed
  ],
)

                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70, right: 5),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MomentCreateScreen()),
            ).whenComplete(() {
  
      _fetchInitialPosts(momentProvider);

});
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFd3902f),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFd3902f).withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/create_post.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// // import 'package:flutter/material.dart';

// // class MomentScreen extends StatefulWidget {
// //   const MomentScreen({super.key});

// //   @override
// //   State<MomentScreen> createState() => _MomentScreenState();
// // }

// // class _MomentScreenState extends State<MomentScreen> {
// //   int selectedTab = 1; // 0 = Follow, 1 = Moment

// //   final String topBg = 'assets/images/f9.jpeg';
// //   final String bottomBg = 'assets/images/bg_bottom_nav.png';

// //   ImageProvider _getSafeImageProvider(dynamic imagePath) {
// //     // ✅ Convert to string and check for invalid values
// //     String? img = imagePath?.toString();
// //     if (img == null || 
// //         img.isEmpty || 
// //         img == 'yyyy' || 
// //         img == 'Profile Url' ||
// //         img == 'upload' ||
// //         img == 'jgh' ||
// //         !img.startsWith('assets/')) {
// //       return const AssetImage('assets/images/person.png');
// //     }
    
// //     // ✅ Only use AssetImage for valid asset paths
// //     if (img.startsWith('assets/')) {
// //       return AssetImage(img);
// //     }
    
// //     // ✅ Default to placeholder
// //     return const AssetImage('assets/images/person.png');
// //   }

// //   final List<Map<String, dynamic>> moments = [
// //     {
// //       "name": "MR.Kharoos",
// //       "time": "1h ago",
// //       "gender": "male",
// //       "avatar": "assets/images/person.png",
// //       "comments": "5",
// //       "likes": "1",
// //       "liked":"1",
// //       "content":
// //           "اگے تجھے یاد میں بلانے کے لئے بیٹھا ہوا۔\nتھک گیا دل اپنی نگاہ کے سامنے بیٹھا ہوا۔",
// //       "type": "text",
// //     },
// //     {
// //       "name": "☆Happy☆",
// //       "time": "1h ago",
// //       "gender": "female",
// //       "avatar": "assets/images/person.png",
// //       "image": "assets/images/person.png",
// //       "likes": "5",
// //       "liked":"0",
// //       "comments": "15",
// //       "type": "image",
// //     },
// //     {
// //       "name": "MALIK",
// //       "time": "2h ago",
// //       "gender": "male",
// //       "avatar": "assets/images/person.png",
// //       "image": "assets/images/person.png",
// //       "likes": "10",
// //       "liked":"1",
// //       "content":"اگے تجھے یاد میں بلانے کے لئے بیٹھا ہوا۔\nتھک گیا دل اپنی نگاہ کے سامنے بیٹھا ہوا۔",
// //       "comments": "20",
// //       "type": "textimage",
// //     },
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     final size = MediaQuery.of(context).size;
// //     final bool isSmall = size.width < 380;

// //     return Scaffold(
   
// //       backgroundColor: Colors.white,
// //       body: Stack(
// //         children: [
// //            // Top Background
// //           Positioned(
// //             top: 0,
// //             left: 0,
// //             right: 0,
// //             bottom: 0,
// //             child: Image.asset(
// //               topBg,
// //               width: size.width,
// //               fit: BoxFit.cover,
// //               height: size.height,
// //             ),
// //           ),

// //   // Main content scroll
// //           SafeArea(
// //             child:  SingleChildScrollView(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //  // Top Bar
// //                       Padding(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 20,
// //                           vertical: 10,
// //                         ),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               'Moment',
// //                               style: TextStyle(
// //                                 color: Colors.yellow,
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                             ),
// //                            SizedBox(width: size.width * 0.07),
// //                             const Text(
// //                               'Follow',
// //                               style: TextStyle(
// //                                 color: Colors.white,
// //                                 fontSize: 18,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
                           
// //                     ])),
// //                     SizedBox(height:5),
                    
// //                   // 🔸 Moments List
// //                  ListView.builder(
// //                     padding: EdgeInsets.only(
// //                       left: size.width * 0.04,
// //                       right: size.width * 0.04,
// //                       bottom: size.height * 0.12,
// //                     ),
// //                     itemCount: moments.length,
// //                      shrinkWrap: true,
// //   physics: const NeverScrollableScrollPhysics(),
// //                     itemBuilder: (context, index) {
// //                       final moment = moments[index];
// //                       return Container(
// //                         margin: const EdgeInsets.symmetric(vertical: 5),
// //                         decoration: BoxDecoration(
// //                            color: Colors.transparent,
                        
// //                         ),
// //                         child:  Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               // 🔹 Header Row
// //                               Row(
// //                                 children: [
// //                                   CircleAvatar(
// //                                     backgroundImage: AssetImage(
// //                                       moment["avatar"],
// //                                     ),
// //                                     radius: 25,
// //                                   ),
// //                                   const SizedBox(width: 10),
// //                                   Column(
// //                                     crossAxisAlignment:
// //                                         CrossAxisAlignment.start,
// //                                     children: [
// //                                       Row(
// //                                         children: [
// //                                           Text(
// //                                             moment["name"],
// //                                             style: const TextStyle(
// //                                               color: Colors.white,
// //                                               fontWeight: FontWeight.w900,
// //                                               fontSize: 15,
// //                                             ),
// //                                           ),
// //                                           const SizedBox(width: 10),
// //                                           Container(
// //                                             padding: const EdgeInsets.symmetric(
// //                                               horizontal: 2,
// //                                               vertical: 2,
// //                                             ),
// //                                             decoration: BoxDecoration(
// //                                               color:moment["gender"]=="male"? Colors.lightBlueAccent:const Color.fromARGB(255, 237, 122, 160),
// //                                               borderRadius:
// //                                                   BorderRadius.circular(100),
// //                                             ),
// //                                             child: Icon(moment["gender"]=="male"?Icons.male:Icons.female,color: Colors.white,size: 14,)
// //                                           ),
// //                                         ],
// //                                       ),
// //                                       Text(
// //                                         moment["time"],
// //                                         style: TextStyle(
// //                                           color: Colors.grey.shade100,
// //                                           fontSize: 12,
// //                                           fontWeight: FontWeight.w600
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ],
// //                               ),
                            

// //                               // 🔹 Post Content (text/image)
// //                               if ((moment["type"] == "text"||moment["type"] == "textimage") &&
// //                                   moment["content"] != "")
// //                                 Padding(
                              
// //                                   padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 2),
                                
// //                                   child: Text(
// //                                     moment["content"],
// //                                     textAlign: TextAlign.start,
// //                                     maxLines: 100,
// //                                     style: const TextStyle(
// //                                       fontSize: 14,
// //                                   color: Colors.white,
// //                                   fontWeight: FontWeight.bold
// //                                     ),
// //                                   ),
// //                                 ),
// //                               if ((moment["type"] == "image"||moment["type"] == "textimage")&&
// //                                   moment["iamge"] != "")

// //            Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 12,vertical: 12),child:AspectRatio(
// //     aspectRatio:1,
// //     child:
// //          ClipRRect(borderRadius:BorderRadius.circular(15) ,child:Image(
// //       image: _getSafeImageProvider(moment["image"]),
// //       fit: BoxFit.contain,
// //     ),)
// //   )),


// // SizedBox(height: 10,),
                

// //                               // 🔹 Footer Row (comment + say hi)
// //                               Row(
// //                                 mainAxisAlignment:
// //                                     MainAxisAlignment.spaceAround,
// //                                     crossAxisAlignment: CrossAxisAlignment.center,
// //                                 children: [
                                 
// //                                       Row(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,children: [Icon(
// //                                         Icons.message_outlined,
// //                                         color: Colors.grey.shade100,
// //                                         size: 22,
// //                                           fontWeight: FontWeight.bold,
// //                                       ),
// //                                       SizedBox(width:2),
                                      
// //                                       Text(moment["comments"],
// //                                     textAlign: TextAlign.start,
                                   
// //                                     style:  TextStyle(
// //                                       fontSize: 14,
// //                                     fontWeight: FontWeight.w600,
// //                                      color: Colors.grey.shade100,
// //                                     ),
// //                                   ),]),
// //                                       Row(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,children: [  Icon(
                                       
                                       
// //                                        moment["liked"]=="0"?Icons.thumb_up_off_alt:Icons.thumb_up_alt,
// //                                    color: Colors.grey.shade100,
// //                                         size: 25,
// //                                           fontWeight: FontWeight.bold,
// //                                       ),
// //  SizedBox(width:2),
                                      
// //                                       Text(moment["likes"],
// //                                     textAlign: TextAlign.start,
                                   
// //                                     style:  TextStyle(
// //                                       fontSize: 14,
// //                                     fontWeight: FontWeight.w600,
// //                                      color: Colors.grey.shade100,
// //                                     ),
// //                                   ),
// //                                       ]),
                                     
// //                                       Icon(
// //                                         Icons.more_horiz,
// //                                          color: Colors.grey.shade100,
// //                                          fontWeight: FontWeight.bold,
// //                                         size: 25,
// //                                       ),
                                   
                                  
                                
// //                                 ],
// //                               ),

// //                               SizedBox(height: 8,),

// //                               Divider()
// //                             ],
// //                           ),
                        
// //                       );
// //                     },
// //                   ),
                 
                    
                    
                    
                    
                    
                    
// //                     ])))

// //           // SafeArea(
// //           //   child: Column(
// //           //     children: [
// //           //       // 🔸 Top Tabs Bar (Follow | Moment)
// //           //       Padding(
// //           //         padding: EdgeInsets.symmetric(
// //           //           horizontal: size.width * 0.08,
// //           //           vertical: size.height * 0.015,
// //           //         ),
// //           //         child: Row(
// //           //           mainAxisAlignment: MainAxisAlignment.center,
// //           //           children: [
// //           //             _buildTopTab("Follow", 0),
// //           //             SizedBox(width: size.width * 0.07),
// //           //             _buildTopTab("Moment", 1),
// //           //           ],
// //           //         ),
// //           //       ),

// //           //       // 🔸 Moments List
// //           //       Expanded(
// //           //         child: ListView.builder(
// //           //           padding: EdgeInsets.only(
// //           //             left: size.width * 0.04,
// //           //             right: size.width * 0.04,
// //           //             bottom: size.height * 0.12,
// //           //           ),
// //           //           itemCount: moments.length,
// //           //           physics: const BouncingScrollPhysics(),
// //           //           itemBuilder: (context, index) {
// //           //             final moment = moments[index];
// //           //             return Container(
// //           //               margin: const EdgeInsets.symmetric(vertical: 10),
// //           //               decoration: BoxDecoration(
// //           //                 // color: Colors.white,
// //           //                 borderRadius: BorderRadius.circular(10),
// //           //                 // boxShadow: [
// //           //                 //   BoxShadow(
// //           //                 //     color: Colors.black12.withOpacity(0.05),
// //           //                 //     blurRadius: 5,
// //           //                 //     offset: const Offset(0, 2),
// //           //                 //   ),
// //           //                 // ],
// //           //               ),
// //           //               child: Padding(
// //           //                 padding: const EdgeInsets.symmetric(
// //           //                   horizontal: 5,
// //           //                   vertical: 10,
// //           //                 ),
// //           //                 child: Column(
// //           //                   crossAxisAlignment: CrossAxisAlignment.start,
// //           //                   children: [
// //           //                     // 🔹 Header Row
// //           //                     Row(
// //           //                       children: [
// //           //                         CircleAvatar(
// //           //                           backgroundImage: AssetImage(
// //           //                             moment["avatar"],
// //           //                           ),
// //           //                           radius: 25,
// //           //                         ),
// //           //                         const SizedBox(width: 10),
// //           //                         Column(
// //           //                           crossAxisAlignment:
// //           //                               CrossAxisAlignment.start,
// //           //                           children: [
// //           //                             Row(
// //           //                               children: [
// //           //                                 Text(
// //           //                                   moment["name"],
// //           //                                   style: const TextStyle(
// //           //                                     fontWeight: FontWeight.bold,
// //           //                                     fontSize: 15,
// //           //                                   ),
// //           //                                 ),
// //           //                                 const SizedBox(width: 6),
// //           //                                 Container(
// //           //                                   padding: const EdgeInsets.symmetric(
// //           //                                     horizontal: 6,
// //           //                                     vertical: 2,
// //           //                                   ),
// //           //                                   decoration: BoxDecoration(
// //           //                                     color: Colors.blueAccent,
// //           //                                     borderRadius:
// //           //                                         BorderRadius.circular(10),
// //           //                                   ),
// //           //                                   child: const Text(
// //           //                                     "41",
// //           //                                     style: TextStyle(
// //           //                                       color: Colors.white,
// //           //                                       fontSize: 11,
// //           //                                     ),
// //           //                                   ),
// //           //                                 ),
// //           //                               ],
// //           //                             ),
// //           //                             Text(
// //           //                               moment["time"],
// //           //                               style: TextStyle(
// //           //                                 color: Colors.grey.shade600,
// //           //                                 fontSize: 12,
// //           //                               ),
// //           //                             ),
// //           //                           ],
// //           //                         ),
// //           //                       ],
// //           //                     ),
// //           //                     const SizedBox(height: 10),

// //           //                     // 🔹 Post Content (text/image)
// //           //                     if (moment["type"] == "text" &&
// //           //                         moment["content"] != "")
// //           //                       Container(
// //           //                         width: 160,
// //           //                         height: 120,
// //           //                         padding: const EdgeInsets.all(12),
// //           //                         decoration: BoxDecoration(
// //           //                           color: Colors.green.shade50,
// //           //                           borderRadius: BorderRadius.circular(8),
// //           //                         ),
// //           //                         child: Text(
// //           //                           moment["content"],
// //           //                           textAlign: TextAlign.center,
// //           //                           style: const TextStyle(
// //           //                             fontSize: 14,
// //           //                             height: 1.5,
// //           //                           ),
// //           //                         ),
// //           //                       ),
// //           //                     if (moment["type"] == "image")
// //           //                       Container(
// //           //                         width: 160,
// //           //                         height: 120,
// //           //                         decoration: BoxDecoration(
// //           //                         borderRadius: BorderRadius.circular(8),
// //           //                        image: DecorationImage(
// //           //                           fit: BoxFit.cover,
// //           //                           image: _getSafeImageProvider(moment["image"]),
// //           //                         ),
                                 
// //           //                       ),),

// //           //                     const SizedBox(height: 10),

// //           //                     // 🔹 Footer Row (comment + say hi)
// //           //                     Row(
// //           //                       mainAxisAlignment:
// //           //                           MainAxisAlignment.spaceBetween,
// //           //                       children: [
// //           //                         Row(
// //           //                           children: [
// //           //                             Icon(
// //           //                               Icons.message,
// //           //                               color: Colors.grey.shade600,
// //           //                               size: 20,
// //           //                             ),
// //           //                             const SizedBox(width: 4),
// //           //                             Text(
// //           //                               "1",
// //           //                               style: TextStyle(
// //           //                                 color: Colors.grey.shade700,
// //           //                                 fontSize: 13,
// //           //                               ),
// //           //                             ),
// //           //                             const SizedBox(width: 4),
// //           //                             Icon(
// //           //                               Icons.favorite_border,
// //           //                               color: Colors.grey.shade600,
// //           //                               size: 20,
// //           //                             ),
// //           //                           ],
// //           //                         ),
                                  
// //           //                         Container(
// //           //                           height: 50,
// //           //                           width: 100,
// //           //                           decoration: BoxDecoration(
// //           //                             image: DecorationImage(
// //           //                               image: AssetImage(
// //           //                                 'assets/images/say_hi.png',
// //           //                               ),
// //           //                             ),
// //           //                           ),
// //           //                         ),
// //           //                       ],
// //           //                     ),
// //           //                   ],
// //           //                 ),
// //           //               ),
// //           //             );
// //           //           },
// //           //         ),
// //           //       ),
// //           //     ],
// //           //   ),
// //           // ),

// //           // // 🔹 Floating Button (Edit)
// //           // Positioned(
// //           //   right: 20,
// //           //   bottom: 90,
// //           //   child: Container(
// //           //     height: 60,
// //           //     width: 80,
// //           //     decoration: BoxDecoration(
// //           //       borderRadius: BorderRadius.circular(10),
// //           //       image: DecorationImage(
// //           //         image: AssetImage(
// //           //         'assets/images/ic_edit.png',
// //           //         ),
// //           //       ),
// //           //     ),
          
             
              
// //           //     ),
// //           //   )
          
// //         ],
// //       ),

// //       // 🔹 Bottom Navigation
// //       // bottomNavigationBar: SizedBox(
// //       //   height: 70,
// //       //   child: CustomBottomNavBar(backgroundImage: bottomBg),
// //       // ),
// //     );
// //   }

// //   Widget _buildTopTab(String title, int index) {
// //     final bool isSelected = selectedTab == index;
// //     return GestureDetector(
// //       onTap: () => setState(() => selectedTab = index),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Text(
// //             title,
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: isSelected ? 20 : 18,
// //               fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
// //             ),
// //           ),
// //           if (isSelected)
// //             Container(
// //               margin: const EdgeInsets.only(top: 3),
// //               height: 2,
// //               width: 35,
// //               color: Colors.white,
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }
