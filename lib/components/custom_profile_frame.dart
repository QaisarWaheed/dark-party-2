// import 'package:flutter/material.dart';

// class FrameWithProfile extends StatelessWidget {
//   final String frameImg;   // Frame background (jaise gold border)
//   final String profileImg; // Profile picture
//   final double size;       // Frame size

//   const FrameWithProfile({
//     Key? key,
//     required this.frameImg,
//     required this.profileImg,
//     this.size = 100,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Frame image (background)
//           AppImage.asset(
//             frameImg,
//             width: size,
//             height: size,
//             fit: BoxFit.contain,
//           ),

//           // Profile image (inside the frame)
//           ClipOval(
//             child: AppImage.asset(
//               profileImg,
//               width: size * 0.55,  // Adjust profile size relative to frame
//               height: size * 0.55,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

class FrameWithProfile extends StatelessWidget {
  final String frameImg;
  final String profileImg;
  final double size;

  const FrameWithProfile({
    super.key,
    required this.frameImg,
    required this.profileImg,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frame image
          AppImage.asset(
            frameImg,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),

          // Profile image
          ClipOval(
            child: AppImage.asset(
              profileImg,
              width: size * 0.5,
              height: size * 0.5,
              fit: BoxFit.cover,
            ),
          ),

          
        ],
      ),
    );
  }
}
