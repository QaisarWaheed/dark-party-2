import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/animated_name_text.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';

class RankUserCard extends StatelessWidget {
  final String name;
  final String coins;
  final String? avatarPath;
  final String country;
  final String backgroundPath;
  final double avatarRadius;
  final double textOffset;
  final int? userId;

  const RankUserCard({
    super.key,
    required this.name,
    required this.coins,
    this.avatarPath,
    required this.backgroundPath,
    required this.country,
    this.avatarRadius = 40,
    this.textOffset = 20,
    this.userId,
  });
  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarPath ?? '';
    final ImageProvider avatarImage = (imageUrl.isEmpty || !imageUrl.startsWith('http'))
        ? const AssetImage('assets/images/person.png')
        : NetworkImage(imageUrl) as ImageProvider;

    return Flexible(
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AppImage.asset(
                backgroundPath,
                fit: BoxFit.contain,
              ),
            ),

            // Avatar aligned inside the decorative circle
            Align(
              alignment: const Alignment(0, -0.25),
              child: GestureDetector(
                onTap: userId != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailedProfileScreen(userId: userId.toString()),
                          ),
                        );
                      }
                    : null,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: avatarImage,
                ),
              ),
            ),

            // User info at bottom
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, textOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(country),
                      const SizedBox(width: 5),
                      AnimatedNameText(text: name, fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppImage.asset(
                        "assets/images/gold_coin.png",
                        height: 25,
                        width: 25,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        coins,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
