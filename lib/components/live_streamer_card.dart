import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';
import 'package:shaheen_star_app/components/animated_name_text.dart';

class LiveStreamerCard extends StatelessWidget {
  final String profileImage;
  final String userName;
  final String countryFlag;
  final String viewers;
  final String popularity; // e.g., "5.5K"
  final bool isSelected;
  final Color? nameColor;
  final bool animateName;
  final List<String>? secondaryAvatars;
  final String? frameImage; // Ornate frame image path

  const LiveStreamerCard({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.countryFlag,
    required this.viewers,
    required this.popularity,
    this.isSelected = false,
    this.nameColor,
    this.animateName = false,
    this.secondaryAvatars,
    this.frameImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          // Profile Picture with Frame
          Stack(
            alignment: Alignment.center,
            children: [
              // Frame (if provided)
              if (frameImage != null)
                SizedBox(
                  width: 70,
                  height: 70,
                  child: AppImage.asset(
                    frameImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              // Profile Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: cachedImage(
                    profileImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Name
                Row(
                  children: [
                    if (userName.contains('🔥'))
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                    Flexible(
                      child: animateName
                          ? AnimatedNameText(
                              text: userName.replaceAll('🔥', '').trim(),
                              fontSize: 16,
                            )
                          : Text(
                              userName.replaceAll('🔥', '').trim(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: nameColor ?? Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (userName.contains('🔥'))
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Country Flag and Secondary Avatars
                Row(
                  children: [
                    // Country Flag
                    Text(
                      countryFlag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    // Secondary Avatars (overlapping)
                    if (secondaryAvatars != null && secondaryAvatars!.isNotEmpty)
                      SizedBox(
                        width: 24 + (secondaryAvatars!.take(3).toList().length - 1) * 16.0,
                        height: 24,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: secondaryAvatars!.take(3).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final avatar = entry.value;
                            return Positioned(
                              left: index * 16.0, // Overlap by 8px (24 - 16 = 8)
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  color: Colors.grey.shade300,
                                ),
                                child: ClipOval(
                                  child: cachedImage(
                                    avatar,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Arabic Text and Icons
                Row(
                  children: [
                    const Text(
                      'تعال اشحن واخد مزه',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Icons
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.bolt,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const Icon(
                          Icons.local_fire_department,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Metrics (Right-aligned)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Viewers
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    viewers,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Popularity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    popularity,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
