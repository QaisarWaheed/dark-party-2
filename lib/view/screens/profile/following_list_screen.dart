import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/components/follow_button.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowingListScreen extends StatefulWidget {
  const FollowingListScreen({super.key});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final String topBg = 'assets/images/bg_home.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final followProvider = Provider.of<UserFollowProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
    
    // Initialize follow provider
    followProvider.initialize();
    
    // Get current user's ID
    final currentUserId = profileProvider.userId;
    
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final userId = int.tryParse(currentUserId);
      if (userId != null) {
        followProvider.getFollowing(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: size.height * 0.13,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(topBg),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 20,   
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),    
                      icon: const Icon(Icons.arrow_back, color: Colors.black87  ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Following',
                        style: TextStyle(
                              color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12), // Balance the back button
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15,  ),
              child: _buildFollowingList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    return Consumer2<UserFollowProvider, ProfileUpdateProvider>(
      builder: (context, followProvider, profileProvider, _) {
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
              padding: EdgeInsets.all(16.0),
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
            // ✅ Force isFollowing = true for all users in following list
            // Since they're in the following list, they must be followed
            return _buildUserCard(user, forceIsFollowing: true);
          },
        );
      },
    );
  }

  Widget _buildUserCard(SearchedUser user, {bool forceIsFollowing = false}) {
    // ✅ If forceIsFollowing is true, always show as following (for following list)
    final isFollowing = forceIsFollowing ? true : user.isFollowing;
    
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
          backgroundColor: AppColors.primaryColor.withOpacity(0.7),
          backgroundImage: user.profileUrl != null && 
                          user.profileUrl!.isNotEmpty && 
                          user.profileUrl!.startsWith('http')
              ? CachedNetworkImageProvider(user.profileUrl!)
              : null,
          child: user.profileUrl == null || 
                 user.profileUrl!.isEmpty || 
                 !user.profileUrl!.startsWith('http')
                  ? const Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('ID: ${user.id}'),
        trailing: FollowButton(
          targetUserId: user.id,
          initialIsFollowing: isFollowing, // ✅ Use forced value if provided
          width: MediaQuery.of(context).size.width * 0.24,
          height: MediaQuery.of(context).size.height * 0.045,
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

