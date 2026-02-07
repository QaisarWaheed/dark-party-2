import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';

// ✅ Build network image - no fallbacks, use original URL only
Widget _buildNetworkImage(String imagePath) {
  return cachedImage(
    imagePath,
    fit: BoxFit.cover,
  
   
  );
}

// ✅ Safe image builder with error handling
// ✅ FIXED: Better detection of local file paths to prevent 404 errors
Widget _buildSafeImage(String imagePath) {
  if (imagePath.isEmpty || 
      imagePath == 'yyyy' || 
      imagePath == 'Profile Url' ||
      imagePath.trim().isEmpty) {
    return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
  }
  
  // ✅ Priority 0: Check if it's an asset path (must be checked before network URLs)
  if (imagePath.startsWith('assets/')) {
    return AppImage.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
      },
    );
  }
  
  // ✅ Priority 1: Check if it's a network URL
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return _buildNetworkImage(imagePath);
  }
  
  // ✅ Priority 2: FIXED - Comprehensive check for local file paths
  // Check for absolute paths starting with /data/, /storage/, /private/, etc.
  if (imagePath.startsWith('/data/') || 
      imagePath.startsWith('/storage/') || 
      imagePath.startsWith('/private/') ||
      imagePath.startsWith('/var/') ||
      imagePath.startsWith('/tmp/') ||
      imagePath.startsWith('/cache/') ||
      // Check for paths containing cache directories
      imagePath.contains('/cache/') ||
      imagePath.contains('cache/') ||
      // Check for Android app-specific paths
      imagePath.contains('/com.example.') ||
      imagePath.contains('/com.') ||
      // Check for file:// protocol
      imagePath.startsWith('file://') ||
      // Check for data/user pattern (Android app data directory)
      imagePath.contains('/data/user/')) {
    try {
      final file = File(imagePath);
      // ✅ Check if file exists before trying to load
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("⚠️ [CustomCard] Failed to load local file: $imagePath");
            print("   Error: $error");
            return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
          },
        );
      } else {
        // ✅ File doesn't exist - show placeholder immediately
        print("⚠️ [CustomCard] Local file does not exist: $imagePath");
        return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
      }
    } catch (e) {
      print("❌ [CustomCard] Error accessing local file: $imagePath - $e");
      return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
    }
  }
  
  // ✅ Priority 3: If it looks like a server-relative path, try to construct network URL
  if (imagePath.startsWith('uploads/') ||
      imagePath.startsWith('images/') ||
      imagePath.startsWith('profiles/') ||
      imagePath.startsWith('room_profiles/') ||
      imagePath.startsWith('gifts/')) {
    String networkUrl = 'https://shaheenstar.online/$imagePath';
    return _buildNetworkImage(networkUrl);
  }
  
  // ✅ Priority 4: Unknown format - use placeholder (don't try to load as asset)
  print("⚠️ [CustomCard] Unknown image path format, using placeholder: $imagePath");
  return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
}

class CustomCard extends StatelessWidget {
  // final String bgImage;
  final String userProfile,profile;
  final String flag;
  final String name;
  final String? views;
  final bool showTopUp;

  const CustomCard({
    super.key,
    // required this.bgImage,
        required this.userProfile,
    required this.profile,
    required this.flag,
    required this.name,
    this.views,
    this.showTopUp = false,
  });

  @override
  Widget build(BuildContext context) {

    return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      
      Expanded(child:ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background Image
          SizedBox(
            width: double.infinity,
            height: 180,
            child: _buildSafeImage(profile),
          ),

          // Optional dark overlay for readability
          Container(
            width: double.infinity,
            height: 180,
            color: Colors.black.withOpacity(0.3),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Flag at top right
                Text(
                  flag,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),

                // Bottom row: profile + views
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _buildSafeImage(userProfile),
                      ),
                    ),

                    // Views
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          views ?? '0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // // Optional Top-Up Tag
          // if (showTopUp)
          //   Positioned(
          //     left: 10,
          //     top: 10,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: Colors.blue,
          //         borderRadius: BorderRadius.circular(6),
          //       ),
          //       child: const Text(
          //         'TOP UP',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 10,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ),

       
        ],
      ),
    )),
                               Text(
                              name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),]);
//     return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      
//       Expanded(child:ClipRRect(
//                                       borderRadius: BorderRadius.circular(10),
//                                       child:Container(
//                                               decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         image: DecorationImage(
//           image: NetworkImage(profile),
//           fit: BoxFit.cover,
//         ),),

//       alignment: Alignment.center,
//       padding: const EdgeInsets.all(10),
//       child:Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,crossAxisAlignment: CrossAxisAlignment.end,children: [
//                   Text(flag, style: const TextStyle(fontSize: 16)),    
              
              
     
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
      
//                 Container(
//                   width: 30,
//                   height: 30,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.white, width: 2),
//                     shape: BoxShape.circle,
//                   ),
//                   child: ClipOval(
//                     child: _buildSafeImage(userProfile),
//                   ),
//               ),
       
//                      Row(
//                   children: [
//                     Icon(
//   Icons.bar_chart,
//   color: Colors.white,
//   size: 15,
// ),
                   
            
//                     Text(
//                       views!,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ],
//                 ),
              
//       ])
//       ],)
     
//     )),),
//                            Text(
//                               name,
//                               style: const TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
                          
//     ]);
    
    // return Container(
    //   height: 85,
    //   margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(16),
    //     image: DecorationImage(
    //       image: AssetImage('assets/images/bg_bottom_nav.png'),
    //       fit: BoxFit.cover,
    //     ),
    //   ),
    //   child: Stack(
    //     children: [
    //       Row(
    //         children: [
    //           // Profile Image
    //           Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: Container(
    //               width: 56,
    //               height: 56,
    //               decoration: BoxDecoration(
    //                 border: Border.all(color: Colors.white, width: 2),
    //                 shape: BoxShape.circle,
    //               ),
    //               child: ClipOval(
    //                 child: _buildSafeImage(profile),
    //               ),
    //             ),

    //             // CircleAvatar(
    //             //   radius: 28,
    //             //   backgroundImage: AssetImage(profile),
    //             // ),
    //           ),

    //           // User Info
    //           Expanded(
    //             child: Padding(
    //               padding: const EdgeInsets.only(
    //                 left: 4.0,
    //                 top: 10,
    //                 bottom: 10,
    //               ),
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   // Flag + Name
    //                   Row(
    //                     children: [
    //                       Text(flag, style: const TextStyle(fontSize: 16)),
    //                       const SizedBox(width: 5),
    //                       Expanded(
    //                         child: Text(
    //                           name,
    //                           style: const TextStyle(
    //                             color: Colors.white,
    //                             fontWeight: FontWeight.bold,
    //                             fontSize: 14,
    //                           ),
    //                           overflow: TextOverflow.ellipsis,
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                   const SizedBox(height: 6),

    //                   // Badges Row
    //                   Row(
    //                     children: [
    //                       _badge('ID', '4'),
    //                       const SizedBox(width: 5),
    //                       _badge('💎', '30'),
    //                       const SizedBox(width: 5),
    //                       _smallAvatarsRow(),
    //                     ],
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),

    //           // 🔥 Views on right
    //           Padding(
    //             padding: const EdgeInsets.only(right: 10.0),
    //             child: Row(
    //               children: [
    //                 const Text('🔥', style: TextStyle(fontSize: 14)),
    //                 const SizedBox(width: 4),
    //                 Text(
    //                   views!,
    //                   style: const TextStyle(
    //                     color: Colors.white,
    //                     fontWeight: FontWeight.bold,
    //                     fontSize: 12,
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ],
    //       ),

    //       // 🏷️ Top-Up Tag (Optional)
    //       if (showTopUp)
    //         Positioned(
    //           left: 10,
    //           top: 6,
    //           child: Container(
    //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    //             decoration: BoxDecoration(
    //               color: Colors.blue,
    //               borderRadius: BorderRadius.circular(6),
    //             ),
    //             child: const Text(
    //               'TOP UP',
    //               style: TextStyle(
    //                 color: Colors.white,
    //                 fontSize: 10,
    //                 fontWeight: FontWeight.bold,
    //               ),
    //             ),
    //           ),
    //         ),
    //     ],
    //   ),
    // );
  }

  // Badge Widget
  Widget _badge(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 10, color: Colors.white)),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  // Small Avatars (like bottom mini images)
  Widget _smallAvatarsRow() {
    return Row(
      children: [
        _miniAvatar('assets/images/person.png'),
        _miniAvatar('assets/images/person.png'),
        _miniAvatar('assets/images/person.png'),
      ],
    );
  }

  Widget _miniAvatar(String img) {
    return Padding(
      padding: const EdgeInsets.only(right: 2.0),
      child: CircleAvatar(radius: 7, backgroundImage: AssetImage(img)),
    );
  }
}
