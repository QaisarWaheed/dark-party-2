import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/utils/colors.dart';

import '../../../controller/provider/bottom_nav_provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String topBg = 'assets/images/bg_home.png';
    final String bottomBg = 'assets/images/bg_bottom_nav.png';
    final List<String> bannerImages = [
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
      'assets/images/banner_pic.png',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
          // 🔸 Scrollable Body
          SafeArea(
            child: Column(
              children: [
                // 🔹 Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       GestureDetector(
                              onTap: () {

                                   final provider = Provider.of<BottomNavProvider>(context, listen: false);
                                  Navigator.pop(context);
                                   provider.changeTab(1);
                                   
                              },
                              child: Text(
                        'Mine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),),
                      GestureDetector(
                              onTap: () {

                                   final provider = Provider.of<BottomNavProvider>(context, listen: false);
                                  Navigator.pop(context);
                                   provider.changeTab(0);
                                   
                              },
                              child:Text(
                        'Popular',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),),
                      const Text(
                        'Event',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.search, color: AppColors.bgColor, size: 28),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: AppColors.bgColor),
                      ),
                    ],
                  ),
                ),

                // 🔹 Banners List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    itemCount: bannerImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(bannerImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: Stack(
        children: [
          Image.asset(
            bottomBg,
            width: double.infinity,
            fit: BoxFit.cover,
            height: 70,
          ),
          Container(
            height: 70,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                BottomNavItem(icon: Icons.celebration, label: 'Party'),
                BottomNavItem(icon: Icons.search, label: 'Discover'),
                BottomNavItem(icon: Icons.message, label: 'Msg'),
                BottomNavItem(icon: Icons.person, label: 'Mine'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const BottomNavItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
