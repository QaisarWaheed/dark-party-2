


import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/bottom_nav_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String backgroundImage;
  final int selectedIndex;
  final int? unreadMessageCount; // Optional unread message count

  const CustomBottomNavBar({
    super.key,
    required this.backgroundImage,
    required this.selectedIndex,
    this.unreadMessageCount,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BottomNavProvider>(context, listen: false);
    
    return Container(
      height: 70,
      color: Colors.white, // White background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home,
            label: 'Home',
            index: 0,
            currentIndex: selectedIndex,
            onTap: () {
              print("🖱️ [BottomNav] Home tab tapped");
              provider.changeTab(0);
            },
            showBadge: false,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.explore_outlined,
            label: 'Discover',
            index: 1,
            currentIndex: selectedIndex,
            onTap: () {
              print("🖱️ [BottomNav] Discover tab tapped");
              provider.changeTab(1);
            },
            showBadge: false,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.message_outlined,
            label: 'Message',
            index: 3, // Message is at index 3
            currentIndex: selectedIndex,
            onTap: () {
              print("🖱️ [BottomNav] Message tab tapped");
              provider.changeTab(3);
            },
            showBadge: true,
            badgeCount: unreadMessageCount ?? 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Me',
            index: 4, // Me is at index 4
            currentIndex: selectedIndex,
            onTap: () {
              print("🖱️ [BottomNav] Me tab tapped");
              provider.changeTab(4);
              // Reload current user's profile so "Me" always shows own data (not a previously viewed user)
              final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
              profileProvider.fetchUserData();
            },
            showBadge: false,
          ),
        ],
      ),
    );
  }

  // Helper method to get custom icon path
  // Using SVG icons from assets/icons/ for crisp rendering
  // Home: home.svg
  // Discover: Group_28.svg
  // Message: Group_31.svg
  // Me: Group_29.svg
  String _getCustomIconPath(String label, bool isSelected) {
    switch (label.toLowerCase()) {
      case 'home':
        return 'assets/icons/home.svg';
      case 'discover':
        return 'assets/icons/Group_28.svg';
      case 'message':
        return 'assets/icons/Group_31.svg';
      case 'me':
        return 'assets/icons/Group_29.svg';
      default:
        return 'assets/icons/home.svg';
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
    required bool showBadge,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = Colors.green; // Green for active
    final inactiveColor = Colors.black; // Black for inactive
    final homeActiveColor = const Color(0xFF6AEA1A);
    final iconColor = label.toLowerCase() == 'home'
        ? (isSelected ? homeActiveColor : inactiveColor)
        : (isSelected ? activeColor : inactiveColor);
    
    // Get custom icon path
    final iconPath = _getCustomIconPath(label, isSelected);
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print("🖱️ [BottomNav] Tab tapped: $label (index: $index)");
            onTap();
          },
          splashColor: Colors.green.withOpacity(0.2),
          highlightColor: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    iconColor,
                    BlendMode.srcIn,
                  ),
                ),
                // Notification Badge
                // Show custom badge for Message tab if there are unread messages
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: label.toLowerCase() == 'home'
                        ? (isSelected ? homeActiveColor : inactiveColor)
                        : (isSelected ? activeColor : inactiveColor),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
