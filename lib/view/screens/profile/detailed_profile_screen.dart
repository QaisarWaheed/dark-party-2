import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/cp_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/follow_button.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/view/screens/user_chat/chat_screen.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/components/profile_with_frame.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shaheen_star_app/view/screens/store/store_screen.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_profile_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/all_agency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controller/api_manager/api_manager.dart';

class DetailedProfileScreen extends StatefulWidget {
  final String? userId, screen;
  const DetailedProfileScreen({super.key, this.userId, this.screen});

  @override
  State<DetailedProfileScreen> createState() => _DetailedProfileScreenState();
}

class _DetailedProfileScreenState extends State<DetailedProfileScreen>
    with SingleTickerProviderStateMixin {
  /// Logged-in user ID from SharedPreferences – used to decide Chat/Follow visibility.
  /// We do not use ProfileUpdateProvider.userId here because it gets overwritten with the viewed user's data.
  String? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
    // ✅ Load user data when screen opens
    print(
      "🎬 [DetailedProfile] initState called - widget.userId: ${widget.userId}",
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      );
      final followProvider = Provider.of<UserFollowProvider>(
        context,
        listen: false,
      );
      final cpProvider = Provider.of<CpProvider>(context, listen: false);

      // ✅ Get userId (either from widget or from provider)
      final userIdToUse = widget.userId ?? provider.userId;
      print(
        "🔍 [DetailedProfile] PostFrameCallback - Loading CP data for userId: $userIdToUse",
      );
      print(
        "🔍 [DetailedProfile] widget.userId: ${widget.userId}, provider.userId: ${provider.userId}",
      );

      // ✅ Always load CP data when profile screen opens
      if (userIdToUse != null && userIdToUse.isNotEmpty) {
        print(
          "✅ [DetailedProfile] Calling cpProvider.fetchCpRankingByUserId($userIdToUse)",
        );
        cpProvider.fetchCpRankingByUserId(userIdToUse);
      } else {
        print("⚠️ [DetailedProfile] No userId available to fetch CP data");
      }

      // Initialize follow provider
      followProvider.initialize();

      // ✅ If userId is provided, fetch that user's data, otherwise fetch current user's data
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        provider.fetchUserDataByUserId(widget.userId!);
        provider.fetchUserLevels(
          widget.userId!,
        ); // ✅ Fetch levels for selected user
        provider.fetchUserTags(
          widget.userId!,
        ); // ✅ Fetch tags for selected user

        // Check follow status for the viewed user
        final targetUserId = int.tryParse(widget.userId!);
        if (targetUserId != null) {
          followProvider.checkFollowStatus(targetUserId);
          // ✅ Load followers and following count for the viewed user
          // Note: Privacy - only show counts for own profile, but still fetch for consistency
          followProvider.getFollowers(targetUserId);
          followProvider.getFollowing(targetUserId);
        }
      } else {
        // ✅ For current user, fetch data and then immediately fetch counts
        provider.fetchUserData().then((_) {
          if (provider.userId != null) {
            provider.fetchUserLevels(
              provider.userId!,
            ); // ✅ Fetch levels for current user
            provider.fetchUserTags(
              provider.userId!,
            ); // ✅ Fetch tags for current user
            // ✅ Load followers and following count for current user IMMEDIATELY
            final currentUserId = int.tryParse(provider.userId!);
            if (currentUserId != null) {
              print(
                '📊 [DetailedProfileScreen] Fetching followers and following counts for user: $currentUserId',
              );
              followProvider.getFollowers(currentUserId);
              followProvider.getFollowing(currentUserId);
            }
          }
        });
      }

      // ✅ ALSO: Try to get counts immediately from SharedPreferences if available
      // This ensures counts are fetched even if fetchUserData hasn't completed yet
      Future.delayed(const Duration(milliseconds: 300), () {
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        final followProvider = Provider.of<UserFollowProvider>(
          context,
          listen: false,
        );

        // Try to get userId from provider (might be available from previous screen)
        String? userIdToUse = widget.userId;
        if (userIdToUse == null || userIdToUse.isEmpty) {
          userIdToUse = profileProvider.userId;
        }

        if (userIdToUse != null && userIdToUse.isNotEmpty) {
          final userId = int.tryParse(userIdToUse);
          if (userId != null) {
            print(
              '📊 [DetailedProfileScreen] Immediate fetch - Getting followers and following counts for user: $userId',
            );
            followProvider.getFollowers(userId);
            followProvider.getFollowing(userId);
          }
        }
      });
    });
  }

  Future<void> _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _loggedInUserId = prefs.get('user_id')?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Capture widget.userId at build level so it's accessible in nested builders
    final viewingUserId = widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,
        child: Consumer<ProfileUpdateProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C68FF)),
                ),
              );
            }

            return Column(
              children: [
                Builder(
                  builder: (context) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    return SizedBox(
                      height: screenHeight * 0.18,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: AppImage.asset(
                              'assets/images/image.bg.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Expanded(
                                    child: Builder(
                                      builder: (ctx) {
                                        final sh = MediaQuery.of(
                                          ctx,
                                        ).size.height;
                                        return Text(
                                          provider.username ?? 'Profile',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: sh * 0.025,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: _ProfileHeaderCard(
                            viewingUserId: viewingUserId,
                          ),
                        ),
                        const Expanded(child: ProfileTabView()),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          // Use logged-in user ID, NOT profileProvider.userId (provider holds viewed user's data on this screen)
          final viewingId = widget.userId;
          final isOwnProfile =
              viewingId == null ||
              viewingId.isEmpty ||
              (_loggedInUserId != null && viewingId == _loggedInUserId);
          if (isOwnProfile) return const SizedBox.shrink();
          return SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Target is the viewed user
                        String? targetIdStr = widget.userId;
                        if (targetIdStr == null || targetIdStr.isEmpty) {
                          final profileProvider =
                              Provider.of<ProfileUpdateProvider>(
                                context,
                                listen: false,
                              );
                          targetIdStr = profileProvider.userId;
                        }

                        final targetUserId = int.tryParse(targetIdStr ?? '');
                        if (targetUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to open chat: user id not found',
                              ),
                            ),
                          );
                          return;
                        }

                        final chatProvider = Provider.of<UserChatProvider>(
                          context,
                          listen: false,
                        );
                        // Ensure chat provider initialized (safe to call repeatedly)
                        try {
                          await chatProvider.initialize();
                        } catch (_) {}

                        // Try to find existing chatroom
                        UserChatRoom? existing = chatProvider
                            .getChatroomByUserId(targetUserId);
                        UserChatRoom? room = existing;
                        if (room == null) {
                          // Create a new chatroom (will fall back to HTTP inside provider)
                          room = await chatProvider.createChatroom(
                            targetUserId,
                          );
                        }

                        if (room != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(chatRoom: room!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open chat. Try again later.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF32A852),
                      ),
                      label: const Text(
                        'Chat',
                        style: TextStyle(color: Color(0xFF32A852)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF32A852)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        String? targetIdStr = widget.userId;
                        if (targetIdStr == null || targetIdStr.isEmpty) {
                          final profileProvider =
                              Provider.of<ProfileUpdateProvider>(
                                context,
                                listen: false,
                              );
                          targetIdStr = profileProvider.userId;
                        }

                        final targetUserId = int.tryParse(targetIdStr ?? '');
                        if (targetUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to follow: user id not found',
                              ),
                            ),
                          );
                          return;
                        }

                        final followProvider = Provider.of<UserFollowProvider>(
                          context,
                          listen: false,
                        );
                        // Ensure provider is initialized (no-op if already initialized)
                        try {
                          followProvider.initialize();
                        } catch (_) {}

                        final currentlyFollowing = followProvider.isFollowing(
                          targetUserId,
                        );
                        if (currentlyFollowing) {
                          await followProvider.unfollowUser(targetUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unfollow request sent'),
                            ),
                          );
                        } else {
                          await followProvider.followUser(targetUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Follow request sent'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9FFF5A), Color(0xFF2DD24F)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.favorite, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String? viewingUserId;
  const _ProfileHeaderCard({required this.viewingUserId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileUpdateProvider, UserFollowProvider>(
      builder: (context, provider, followProvider, _) {
        final username = provider.username ?? "Guest User";
        final currentUserId = provider.userId?.toString();
        final viewingUserIdStr =
            (viewingUserId ?? provider.userId?.toString()) ?? '';
        final isOwnProfile =
            viewingUserIdStr.isEmpty || viewingUserIdStr == currentUserId;
        final country = provider.country ?? '';
        final countryFlag = CountryFlagUtils.getFlagEmoji(country);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: ProfileWithFrame(
                size: 64,
                profileUrl: provider.profile_url,
                userId: viewingUserId ?? provider.userId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.height * 0.020,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "ID: ${provider.userId ?? ''}",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: MediaQuery.of(context).size.height * 0.015,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(countryFlag, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  // Wealth Level Badge
                  if (provider.wealthLevel != null)
                    Transform.translate(
                      offset: const Offset(
                        -28,
                        -8,
                      ), // ✅ Shifted left and slightly up
                      child: Container(
                        height: 65, // ✅ Reduced height to minimize space
                        width: 140,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Image.asset(
                              provider.wealthLevel! <= 20
                                  ? 'assets/images/level_1-to-20.png'
                                  : provider.wealthLevel! <= 50
                                  ? 'assets/images/level_21-to-50.png'
                                  : 'assets/images/level_51-to-100.png',
                              width: 140,
                              height: 65,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Lvl.${provider.wealthLevel}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Level Number Text
                            Positioned(
                              right: 25,
                              child: Text(
                                'Lv.${provider.wealthLevel}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniBadge('assets/icons/pfp1.png'),
                      const SizedBox(width: 6),
                      _miniBadge('assets/icons/pfp2.png'),
                    ],
                  ),
                ],
              ),
            ),
            if (!isOwnProfile && viewingUserIdStr.isNotEmpty)
              FollowButton(
                targetUserId: int.tryParse(viewingUserIdStr) ?? 0,
                initialIsFollowing: followProvider.isFollowing(
                  int.tryParse(viewingUserIdStr) ?? 0,
                ),
                width: MediaQuery.of(context).size.width * 0.23,
                height: MediaQuery.of(context).size.height * 0.042,
                fontSize: MediaQuery.of(context).size.height * 0.015,
              ),
          ],
        );
      },
    );
  }

  Widget _miniBadge(String assetPath) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(child: AppImage.asset(assetPath, fit: BoxFit.cover)),
    );
  }
}

// 🔹 Profile Tab
class ProfileTabView extends StatelessWidget {
  final String? userId;
  const ProfileTabView({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileUpdateProvider, UserFollowProvider>(
      builder: (context, provider, followProvider, _) {
        final followersCount = followProvider.followersCount;
        final followingCount = followProvider.followingCount;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // image72 full-width background (no horizontal padding) with "Say something..." on top
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/image72.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statItem('Visitor', 0),
                        _statItem('Follow', followersCount),
                        _statItem('Fans', followingCount),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // ✅ Use actual IntimacyTabView with Consumer instead of static image
                    IntimacyTabView(userId: userId ?? provider.userId),
                    const SizedBox(height: 14),
                    const Text(
                      'Supporter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage.asset(
                        'assets/images/supporterplaceholder.png',
                        width: double.infinity,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        _ProfileMiniTab(label: 'Gift', isSelected: true),
                        _ProfileMiniTab(label: 'Badge'),
                        _ProfileMiniTab(label: 'headwear'),
                        _ProfileMiniTab(label: 'Ride'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "Haven't received a gift yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dashboard shortcuts (moved from header)
                    if (provider.isMerchant || provider.hasAgencyAvailable)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (provider.isMerchant)
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreScreen(),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.storefront,
                                      color: Colors.orange,
                                      size: 28,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Merchant',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            if (provider.hasAgencyAvailable)
                              InkWell(
                                onTap: () {
                                  final agencyProvider =
                                      Provider.of<AgencyProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final userAgency = agencyProvider.userAgency;
                                  if (userAgency != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AgencyProfileCenterScreen(
                                              agency: userAgency,
                                            ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AllAgencyScreen(),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.business_center,
                                      color: Colors.orange,
                                      size: 28,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Agency',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMiniTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _ProfileMiniTab({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2ECC71) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 22,
            height: 2,
            color: isSelected ? const Color(0xFF2ECC71) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

Widget _statItem(String label, int value) {
  return Column(
    children: [
      Builder(
        builder: (ctx) {
          final sh = MediaQuery.of(ctx).size.height;
          return Text(
            value.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: sh * 0.018),
          );
        },
      ),
      const SizedBox(height: 4),
      Builder(
        builder: (ctx) {
          final sh = MediaQuery.of(ctx).size.height;
          return Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: sh * 0.014),
          );
        },
      ),
    ],
  );
}

// 🔹 Intimacy Tab
class IntimacyTabView extends StatelessWidget {
  final String? userId; // ✅ Accept userId parameter
  const IntimacyTabView({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    print("🎨 [IntimacyTabView] Building UI - userId: $userId");
    return Consumer<CpProvider>(
      builder: (context, cpProvider, child) {
        print(
          "🎨 [IntimacyTabView] Consumer rebuild - cpProvider.users.length: ${cpProvider.users.length}",
        );
        if (cpProvider.users.isNotEmpty) {
          print(
            "✅ [IntimacyTabView] CP Partner found: ${cpProvider.users[0].cpUser?.name}",
          );
        } else {
          print("⚠️ [IntimacyTabView] No CP partner data");
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.height * 0.020,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background image
                      AppImage.asset(
                        'assets/images/Group_341.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Consumer<ProfileUpdateProvider>(
                              builder: (context, provider, _) {
                                final username = provider.username ?? "Guest";
                                final displayName = username.length > 8
                                    ? "${username.substring(0, 8)}..."
                                    : username;

                                // ✅ Use userId passed from parent widget (IntimacyTabView's widget.userId field)
                                final userIdToUse = userId ?? provider.userId;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // ✅ Profile Avatar with Purchased Frame
                                    ProfileWithFrame(
                                      size: 55, // radius 30 * 2 = 60
                                      profileUrl: provider.profile_url,
                                      showPlaceholder: true,
                                      userId:
                                          userIdToUse, // ✅ Pass userId to load that user's backpack
                                    ),

                                    Text(
                                      displayName,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Pass userId to CpDetailsScreen
                                    final userIdToPass =
                                        userId ??
                                        Provider.of<ProfileUpdateProvider>(
                                          context,
                                          listen: false,
                                        ).userId;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CpDetailsScreen(
                                          userId: userIdToPass,
                                        ),
                                      ),
                                    );
                                  },
                                  child: AppImage.asset(
                                    'assets/icons/Screenshot_2026-01-26_124352-removebg-preview_1.png',
                                    width: 110,
                                    height: 72,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 4),
                                cpProvider.users.isEmpty
                                    ? Text(
                                        "LV 0",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        timeago.format(
                                          DateTime.parse(
                                            cpProvider.users[0].cpUser!.cpSince,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                cpProvider.users.isEmpty
                                    ? CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.white24,
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: cpProvider
                                              .normalizeRoomProfileUrl(
                                                cpProvider
                                                    .users[0]
                                                    .cpUser!
                                                    .profileUrl,
                                              ),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                SizedBox(height: 6),
                                cpProvider.users.isEmpty
                                    ? Text(
                                        "Invite",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : Text(
                                        cpProvider.users[0].cpUser!.name,
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showCpTerminationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Icon
                Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),

                // 🔹 Title
                Builder(
                  builder: (ctx) {
                    final sh = MediaQuery.of(ctx).size.height;
                    return Text(
                      "Terminate CP Relationship",
                      style: TextStyle(
                        fontSize: sh * 0.023,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 🔹 Description
                Builder(
                  builder: (ctx) {
                    final sh = MediaQuery.of(ctx).size.height;
                    return Text(
                      "After the CP relationship terminates, you will return to ordinary friends. "
                      "You cannot continue to complete CP tasks or have CP nests and other privileges.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sh * 0.018,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 🔹 Buttons
                Column(
                  children: [
                    // Yellow button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO: Handle "Apply to the other side" action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: const Text(
                            "Apply to the other side for termination (Free of charge)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Green button with gold icon and 70000
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final cpProvider = Provider.of<CpProvider>(
                            context,
                            listen: false,
                          );
                          bool removed = await ApiManager.removeSelfFromCp(
                            userId.toString(),
                          );
                          if (removed) {
                            print("User removed from CP successfully!");
                            cpProvider.fetchCpRankingByUserId(
                              cpProvider.users[0].cpUser!.id.toString(),
                            );
                          } else {
                            print("Failed to remove user from CP.");
                          }
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.monetization_on, // gold icon
                          color: Colors.amber,
                        ),
                        label: const Text(
                          "Resolutely terminate - 70000",
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🔹 Square Tab
class SquareTabView extends StatelessWidget {
  const SquareTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Square Content"));
  }
}

// 🔹 CP Details Screen
class CpDetailsScreen extends StatefulWidget {
  final String? userId;
  const CpDetailsScreen({super.key, this.userId});

  @override
  State<CpDetailsScreen> createState() => _CpDetailsScreenState();
}

class _CpDetailsScreenState extends State<CpDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch CP data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cpProvider = Provider.of<CpProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      );
      final userIdToFetch = widget.userId ?? profileProvider.userId;
      if (userIdToFetch != null) {
        cpProvider.fetchCpRankingByUserId(userIdToFetch);
      }
    });
  }

  // Helper to format numbers (e.g., 12300000 → "12.3M")
  String formatCount(double count) {
    if (count >= 1000000) {
      return "${(count / 1000000).toStringAsFixed(1)}M";
    } else if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}K";
    }
    return count.toInt().toString();
  }

  // Helper to calculate days together
  int calculateDaysTogether(String? cpSince) {
    if (cpSince == null || cpSince.isEmpty) return 0;
    try {
      final startDate = DateTime.parse(cpSince);
      return DateTime.now().difference(startDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Show confirmation dialog before removing CP partner
  void _showRemoveCpConfirmation(BuildContext context, CpProvider cpProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              const Text('Remove CP Partner?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (ctx) {
                  final sh = MediaQuery.of(ctx).size.height;
                  return Text(
                    'Are you sure you want to remove your CP partner?',
                    style: TextStyle(
                      fontSize: sh * 0.020,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(
                        builder: (ctx) {
                          final sh = MediaQuery.of(ctx).size.height;
                          return Text(
                            '70,000 coins will be deducted from your account',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: sh * 0.017,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Builder(
                builder: (ctx) {
                  final sh = MediaQuery.of(ctx).size.height;
                  return Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: sh * 0.020),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeCpPartner(context, cpProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm Remove',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Remove CP partner API call
  Future<void> _removeCpPartner(
    BuildContext context,
    CpProvider cpProvider,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );

      final profileProvider = Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      );
      // API remove_self_from_cp expects current (logged-in) user's id
      final currentUserId = profileProvider.userId;

      if (currentUserId == null || currentUserId.isEmpty) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call existing API to remove CP partner
      await cpProvider.removeCpPartner(currentUserId);

      Navigator.pop(context); // Close loading

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CP Partner removed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to previous screen
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove CP partner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CpProvider, ProfileUpdateProvider>(
      builder: (context, cpProvider, profileProvider, child) {
        // Get CP data
        final hasCpData = cpProvider.users.isNotEmpty;
        final cpUser = hasCpData ? cpProvider.users[0] : null;
        final cpPartner = cpUser?.cpUser;

        // Debug print
        print('🔍 CP Data Debug:');
        print('hasCpData: $hasCpData');
        print('cpProvider.users length: ${cpProvider.users.length}');
        if (cpUser != null) {
          print('cpUser.totalDiamond: ${cpUser.totalDiamond}');
          print('cpUser.cpSince: ${cpUser.cpSince}');
          print('cpUser.id: ${cpUser.id}');
        }

        // Calculate days together
        final daysTogether = calculateDaysTogether(cpUser?.cpSince);

        // Get current user data
        final currentUserName = profileProvider.username ?? "Guest";
        final currentUserProfile = profileProvider.profile_url ?? "";

        // Check if viewing own profile
        final isOwnProfile =
            widget.userId == null || widget.userId == profileProvider.userId;

        // Show "Remove CP Partner" only when both users are CP partners (use API data)
        // Either: viewing own profile and have a CP partner, OR: viewing the profile of our CP partner
        final viewingUserIdStr = widget.userId?.trim();
        final isViewingCpPartnerProfile =
            hasCpData &&
            cpPartner != null &&
            viewingUserIdStr != null &&
            viewingUserIdStr.isNotEmpty &&
            cpPartner.id.toString() == viewingUserIdStr;
        final canShowRemoveCpButton =
            hasCpData &&
            cpPartner != null &&
            (isOwnProfile || isViewingCpPartnerProfile);

        return Scaffold(
          body: Stack(
            children: [
              // Background image
              AppImage.asset(
                'assets/images/image_74.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),

              // Content overlay
              SafeArea(
                child: Column(
                  children: [
                    // Header with back button and title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Builder(
                                builder: (ctx) {
                                  final sh = MediaQuery.of(ctx).size.height;
                                  return Text(
                                    'Wealth',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: sh * 0.023,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Balance back button
                        ],
                      ),
                    ),

                    // Main CP design elements - scrollable for small screens
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;
                          final screenHeight = constraints.maxHeight;
                          final scale = (screenWidth / 375).clamp(0.85, 1.2);
                          final dpr = MediaQuery.of(context).devicePixelRatio;

                          // Crown → heart (profiles in eyes) → name tags below → value badge → bottom panel
                          final crownTop = screenHeight * 0.04;
                          final crownWidth = (screenWidth * 0.92).clamp(
                            260.0,
                            380.0,
                          );
                          final crownHeight =
                              crownWidth *
                              1.15; // Increased height ratio for better fit
                          final crownLeft = (screenWidth - crownWidth) / 2;
                          final avatarSize =
                              crownWidth * 0.23; // Larger avatars
                          final nameBarWidth = crownWidth * 0.34;
                          final nameBarHeight = crownHeight * 0.12;
                          final buttonTop =
                              8.0 + MediaQuery.of(context).padding.top;

                          return Stack(
                            children: [
                              // 2. Crown cluster (frame + avatars + name bars + value badge)
                              Positioned(
                                top: crownTop,
                                left: crownLeft,
                                child: SizedBox(
                                  width: crownWidth,
                                  height: crownHeight,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AppImage.asset(
                                        'assets/images/unnamed__19_-removebg-preview_1.png',
                                        width: crownWidth,
                                        height: crownHeight,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                      // Left avatar
                                      Positioned(
                                        top: crownHeight * 0.40,
                                        left: crownWidth * 0.22,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          child: currentUserProfile.isEmpty
                                              ? Container(
                                                  width: avatarSize,
                                                  height: avatarSize,
                                                  color: Colors.white24,
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: avatarSize * 0.55,
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: cpProvider
                                                      .normalizeRoomProfileUrl(
                                                        currentUserProfile,
                                                      ),
                                                  width: avatarSize,
                                                  height: avatarSize,
                                                  memCacheWidth:
                                                      (avatarSize * dpr)
                                                          .round(),
                                                  memCacheHeight:
                                                      (avatarSize * dpr)
                                                          .round(),
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        color: Colors.white24,
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        color: Colors.white24,
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                      // Right avatar
                                      Positioned(
                                        top: crownHeight * 0.40,
                                        right: crownWidth * 0.22,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          child: !hasCpData || cpPartner == null
                                              ? Container(
                                                  width: avatarSize,
                                                  height: avatarSize,
                                                  color: Colors.white24,
                                                  child: Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: avatarSize * 0.55,
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: cpProvider
                                                      .normalizeRoomProfileUrl(
                                                        cpPartner.profileUrl,
                                                      ),
                                                  width: avatarSize,
                                                  height: avatarSize,
                                                  memCacheWidth:
                                                      (avatarSize * dpr)
                                                          .round(),
                                                  memCacheHeight:
                                                      (avatarSize * dpr)
                                                          .round(),
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        color: Colors.white24,
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        color: Colors.white24,
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                      // Center heart
                                      Positioned(
                                        top: crownHeight * 0.44,
                                        child: AppImage.asset(
                                          'assets/images/unnamed__20_-removebg-preview_1.png',
                                          width: crownWidth * 0.12,
                                          height: crownWidth * 0.10,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // Left name bar
                                      Positioned(
                                        top: crownHeight * 0.60,
                                        left: crownWidth * 0.11,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AppImage.asset(
                                              'assets/images/unnamed__21_-removebg-preview_2.png',
                                              width: nameBarWidth,
                                              height: nameBarHeight,
                                              fit: BoxFit.fill,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10 * scale,
                                              ),
                                              child:
                                                  Consumer<
                                                    ProfileUpdateProvider
                                                  >(
                                                    builder:
                                                        (
                                                          _,
                                                          profileProvider,
                                                          __,
                                                        ) {
                                                          final userName =
                                                              profileProvider
                                                                  .username ??
                                                              'Mr.dark';
                                                          return FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              userName,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize:
                                                                    11 * scale,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          );
                                                        },
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Right name bar
                                      Positioned(
                                        top: crownHeight * 0.60,
                                        right: crownWidth * 0.11,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AppImage.asset(
                                              'assets/images/unnamed__21_-removebg-preview_2.png',
                                              width: nameBarWidth,
                                              height: nameBarHeight,
                                              fit: BoxFit.fill,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10 * scale,
                                              ),
                                              child: Consumer<CpProvider>(
                                                builder:
                                                    (
                                                      context,
                                                      cpProvider,
                                                      child,
                                                    ) {
                                                      final cpName =
                                                          cpProvider
                                                              .users
                                                              .isNotEmpty
                                                          ? cpProvider
                                                                    .users[0]
                                                                    .cpUser
                                                                    ?.name ??
                                                                "r'o♥"
                                                          : "r'o♥";
                                                      return FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          cpName,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                11 * scale,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Value badge inside crown - Styled like screenshot
                                      Positioned(
                                        top: crownHeight * 0.78,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16 * scale,
                                            vertical: 6 * scale,
                                          ),

                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppImage.asset(
                                                'assets/images/unnamed__20_-removebg-preview_1.png',
                                                width: 20 * scale,
                                                height: 14 * scale,
                                                fit: BoxFit.contain,
                                              ),
                                              SizedBox(width: 8 * scale),
                                              Text(
                                                hasCpData
                                                    ? formatCount(
                                                        cpUser!.totalDiamond,
                                                      )
                                                    : '0',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18 * scale,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    BoxShadow(
                                                      color: Colors.black38,
                                                      blurRadius: 2,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 5. Right badges - enough inset so they don't clip on the right edge
                              Positioned(
                                top: buttonTop,
                                right: (screenWidth * 0.04).clamp(16.0, 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppImage.asset(
                                      'assets/images/unnamed__24_-removebg-preview_2.png',
                                      width: 90 * scale,
                                      height: 32 * scale,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 6 * scale),
                                    AppImage.asset(
                                      'assets/images/unnamed__23_-removebg-preview_2.png',
                                      width: 90 * scale,
                                      height: 32 * scale,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),

                              // 4. Bottom Blue Panel – content centered in frame (reference: "22 days" lower in frame)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: (screenHeight * 0.42).clamp(
                                  270.0,
                                  360.0,
                                ),
                                child: ClipRect(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AppImage.asset(
                                        'assets/images/unnamed__22_-removebg-preview_1.png',
                                        fit: BoxFit.fill,
                                        width: screenWidth,
                                        filterQuality: FilterQuality.high,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          28 * scale,
                                          72 * scale,
                                          28 * scale,
                                          (10 * scale) +
                                              MediaQuery.of(
                                                context,
                                              ).padding.bottom,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            if (hasCpData) ...[
                                              Text(
                                                'We have been together for',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF001F5F,
                                                  ),
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.baseline,
                                                textBaseline:
                                                    TextBaseline.alphabetic,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '$daysTogether',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFFFFD700,
                                                      ),
                                                      fontSize: 42 * scale,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      height: 1.1,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors
                                                              .orange
                                                              .shade900,
                                                          offset: const Offset(
                                                            2,
                                                            2,
                                                          ),
                                                          blurRadius: 0,
                                                        ),
                                                        Shadow(
                                                          color: Colors
                                                              .yellow
                                                              .shade100,
                                                          offset: const Offset(
                                                            -1.5,
                                                            -1.5,
                                                          ),
                                                          blurRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8 * scale),
                                                  Text(
                                                    'days',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFFFFFF00,
                                                      ),
                                                      fontSize: 16 * scale,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.25,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black12,
                                                          offset: const Offset(
                                                            1,
                                                            1,
                                                          ),
                                                          blurRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8 * scale),
                                              Text(
                                                'CP monthly ranking',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF001F5F,
                                                  ),
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              SizedBox(height: 0),
                                              Text(
                                                '30',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFFFD700,
                                                  ),
                                                  fontSize: 42 * scale,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.0,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors
                                                          .orange
                                                          .shade900,
                                                      offset: const Offset(
                                                        2,
                                                        2,
                                                      ),
                                                      blurRadius: 0,
                                                    ),
                                                    Shadow(
                                                      color: Colors
                                                          .yellow
                                                          .shade100,
                                                      offset: const Offset(
                                                        -1.5,
                                                        -1.5,
                                                      ),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (canShowRemoveCpButton) ...[
                                              Spacer(),
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showRemoveCpConfirmation(
                                                      context,
                                                      cpProvider,
                                                    ),
                                                icon: Icon(
                                                  Icons.person_remove,
                                                  color: Colors.white,
                                                  size: 14 * scale,
                                                ),
                                                label: Text(
                                                  'Remove CP Partner',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12 * scale,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade600,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 14 * scale,
                                                    vertical: 8 * scale,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}
