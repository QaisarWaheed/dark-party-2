
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

// ✅ Safe image builder with error handling
Widget _buildSafeProfileImage(String imagePath) {
  // ✅ Check for empty or invalid values first
  if (imagePath.isEmpty || 
      imagePath == 'yyyy' || 
      imagePath == 'Profile Url' ||
      imagePath.trim().isEmpty) {
    return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
  }
  
  // ✅ Check if it's a network URL
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
  
  // ✅ Check if it's a local file path
  if (imagePath.startsWith('/data/') || 
      imagePath.startsWith('/storage/') || 
      imagePath.contains('cache')) {
    try {
      File file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // File doesn't exist or can't be loaded
            return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
          },
        );
      } else {
        // File doesn't exist
        return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
      }
    } catch (e) {
      // Error accessing file
      return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
    }
  }
  
  // ✅ If none of the above, use placeholder (don't try to load as asset)
  return AppImage.asset('assets/images/person.png', fit: BoxFit.cover);
}

class CustomProfileCard extends StatelessWidget {
  final String crownFrameImage; 
  final String profileImage;
  // final String id;
  final String name;
  final String views;
  final String flagEmoji;

  const CustomProfileCard({
    super.key,
    required this.crownFrameImage,
    required this.profileImage,
    // required this.id,
    required this.name,
    required this.views,
    required this.flagEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 🖼 Profile Image — fits perfectly inside frame
              Positioned(
                top: 18, // inner offset
                left: constraints.maxWidth * 0.06,
                right: constraints.maxWidth * 0.06,
                bottom: 0.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildSafeProfileImage(profileImage),
                ),
              ),

              // 👑 Frame Overlay (Top Layer)
              Positioned.fill(
                child: AppImage.asset(
                  crownFrameImage,
                  fit: BoxFit.fill,
                ),
              ),

              // 🔥 Views (top-right)
              Positioned(
                top: 30,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        views,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              
              Positioned(
                bottom: -26,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(flagEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
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
}

