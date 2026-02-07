import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/components/follow_button.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/view/screens/home/events_screen.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controller/provider/bottom_nav_provider.dart';

class FollowerScreen extends StatefulWidget {
  final String? userId; // ✅ Optional: If provided, show this user's followers/following instead of current user
  final int initialTab; // ✅ Optional: 0 for Followers, 1 for Following
  
  const FollowerScreen({super.key, this.userId, this.initialTab = 0});

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  final String topBg = 'assets/images/bg_home.png';
  final String bottomBg = 'assets/images/bg_bottom_nav.png';

  int selectedTopIndex = 0;
  late int selectedInnerTab;

  final List<String> topTabs = ["Mine", "Popular", "Event"];
  final List<String> innerTabs = ["Followers", "Following"]; // ✅ Changed to show only Followers and Following tabs

  @override
  void initState() {
    super.initState();
    // Set initial tab from widget parameter
    selectedInnerTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final followProvider = Provider.of<UserFollowProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
    
    // Initialize follow provider
    followProvider.initialize();
    
    // ✅ Privacy: Only allow viewing own followers/following
    // Always use current user's ID, ignore widget.userId if it's different
    final currentUserId = profileProvider.userId;
    
    // Check if trying to view another user's followers/following
    if (widget.userId != null && 
        widget.userId!.isNotEmpty && 
        widget.userId != currentUserId) {
      // Privacy: Don't load data for other users
      return;
    }
    
    // ✅ Always use current user's ID, not widget.userId
    // This ensures we always show the current user's own followers/following
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final userId = int.tryParse(currentUserId);
      if (userId != null) {
        // Load followers (for "Followers" tab - index 0)
        if (selectedInnerTab == 0) {
          followProvider.getFollowers(userId);
        }
        // Load following (for "Following" tab - index 1)
        if (selectedInnerTab == 1) {
          followProvider.getFollowing(userId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      extendBody: true,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: size.height * 0.20,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(topBg),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: topTabs.length,
                          itemBuilder: (context, index) {
                            final isSelected = selectedTopIndex == index;
                            return GestureDetector(
                              onTap: () => setState(() {
                              
                                selectedTopIndex = index;
 final provider = Provider.of<BottomNavProvider>(context, listen: false);
                                   

                                   if(topTabs[index]=="Mine"){
provider.changeTab(1);
                                   }
                                    else if(topTabs[index]=="Popular"){
provider.changeTab(0);
                                   }
                                    else if(topTabs[index]=="Event"){
Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EventsScreen(),
                                  ),
                                );
                                   }

                              },),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  topTabs[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: isSelected ? 22 : 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.search, color: Colors.white, size: 26),
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background + main scroll
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 70),
                  child: Column(
                    children: [
                      // Tabs
                      SizedBox(
                        height: 35,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: innerTabs.length,
                          itemBuilder: (context, index) {
                            final isSelected = selectedInnerTab == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedInnerTab = index;
                                });
                                // Reload data when tab changes
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _loadData();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFd3902f) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  innerTabs[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Content based on selected tab
                      _buildTabContent(),
                    ],
                  ),
                ),
                // Profile Card Overlap effect
                Positioned(
                  top: -40,
                  left: 15,
                  right: 15,
                  child: Consumer<ProfileUpdateProvider>(
                    builder: (context, profileProvider, _) {
                      // ✅ Privacy: Only show current user's profile data
                      final currentUserId = profileProvider.userId;
                      
                      // If trying to view another user's profile, show privacy message
                      if (widget.userId != null && 
                          widget.userId!.isNotEmpty && 
                          widget.userId != currentUserId) {
                        // Show current user's profile instead (privacy protection)
                        return Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                backgroundImage: profileProvider.profile_url != null &&
                                        profileProvider.profile_url!.isNotEmpty &&
                                        profileProvider.profile_url!.startsWith('http')
                                    ? CachedNetworkImageProvider(profileProvider.profile_url!)
                                    : null,
                                child: profileProvider.profile_url == null ||
                                        profileProvider.profile_url!.isEmpty ||
                                        !profileProvider.profile_url!.startsWith('http')
                                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      profileProvider.username ?? "Guest",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: ${profileProvider.userId ?? "00000000"}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer<UserFollowProvider>(
                                builder: (context, followProvider, _) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${followProvider.followersCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Followers',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Viewing own profile - use current user's data
                      final username = profileProvider.username ?? "Guest";
                      final userId = profileProvider.userId ?? "00000000";
                      final profileUrl = profileProvider.profile_url;
                      
                      return Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: profileUrl != null &&
                                      profileUrl.isNotEmpty &&
                                      profileUrl.startsWith('http')
                                  ? CachedNetworkImageProvider(profileUrl)
                                  : null,
                              child: profileUrl == null ||
                                      profileUrl.isEmpty ||
                                      !profileUrl.startsWith('http')
                                  ? const Icon(Icons.person, color: Colors.grey, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: $userId",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Consumer<UserFollowProvider>(
                              builder: (context, followProvider, _) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${followProvider.followersCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Followers',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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
    );
  }

  Widget _buildTabContent() {
    switch (selectedInnerTab) {
      case 0: // Followers
        return _buildFollowersTab();
      case 1: // Following
        return _buildFollowingTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFollowersTab() {
    return Consumer2<UserFollowProvider, ProfileUpdateProvider>(
      builder: (context, followProvider, profileProvider, _) {
        // ✅ Privacy Check: Only show data for current user
        final currentUserId = profileProvider.userId;
        if (widget.userId != null && 
            widget.userId!.isNotEmpty && 
            widget.userId != currentUserId) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'This information is private',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You can only view your own followers',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (followProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (followProvider.followers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No followers yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: followProvider.followers.length,
          itemBuilder: (context, index) {
            final user = followProvider.followers[index];
            return _buildUserCard(user, isFollower: true);
          },
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return Consumer2<UserFollowProvider, ProfileUpdateProvider>(
      builder: (context, followProvider, profileProvider, _) {
        // ✅ Privacy Check: Only show data for current user
        final currentUserId = profileProvider.userId;
        if (widget.userId != null && 
            widget.userId!.isNotEmpty && 
            widget.userId != currentUserId) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'This information is private',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You can only view your own following list',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (followProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (followProvider.following.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Not following anyone yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: followProvider.following.length,
          itemBuilder: (context, index) {
            final user = followProvider.following[index];
            return _buildUserCard(user, isFollower: false);
          },
        );
      },
    );
  }

  Widget _buildUserCard(SearchedUser user, {required bool isFollower}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: user.profileUrl != null && user.profileUrl!.isNotEmpty && user.profileUrl!.startsWith('http')
              ? CachedNetworkImageProvider(user.profileUrl!)
              : null,
          child: user.profileUrl == null || user.profileUrl!.isEmpty || !user.profileUrl!.startsWith('http')
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            
          ],
        ),
        trailing: FollowButton(
          targetUserId: user.id,
          initialIsFollowing: user.isFollowing,
          width: 100,
          height: 36,
          fontSize: 14,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailedProfileScreen(
                userId: user.id.toString(),
              ),
            ),
          );
        },
      ),
    );
  }
}
