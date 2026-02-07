
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/animated_name_text.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';

class RankCards extends StatelessWidget {
  // final String bgImage;
  final String? profile;
  final String name;
  final String? coins;
  final String country;
  final int? userId;
  const RankCards({
    super.key,
    // required this.bgImage,
     this.profile,
    required this.name,
    required this.coins,
    required this.country,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage('assets/images/bg_bottom_nav.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Profile Image
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                        child: profile=="assets/images/person.png"?AppImage.asset(profile!, fit: BoxFit.cover):Image.network(profile!, fit: BoxFit.cover)
                    ),
                  ),
                ),
              ),

              // User Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(country),
                          SizedBox(width: 5),
                          AnimatedNameText( text: name, fontSize: 13,),
                        ],
                      ),
                    //  Text(
                    //           name,
                    //           style: const TextStyle(
                    //             color: Colors.white,
                    //             fontWeight: FontWeight.bold,
                    //             fontSize: 14,
                    //           ),
                    //           overflow: TextOverflow.ellipsis,
                    //         ),
                      SizedBox(height: 10,),
                      // Badges Row
                       Row(
                        children: [
                          AppImage.asset(
                            "assets/images/gold_coin.png",
                            height: 25,
                            width: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            coins.toString(),
                            style: TextStyle(
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
        ],
      ),
    );
  }
  
}
