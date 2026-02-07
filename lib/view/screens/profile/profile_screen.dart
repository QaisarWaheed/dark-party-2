// ignore_for_file: public_member_api_docs, sort_constructors_first, unused_element, unused_local_variable, unused_field, unused_import, unused_parameter
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/profile_with_frame.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/controller/provider/banner_provider.dart';
import 'package:shaheen_star_app/controller/provider/bottom_nav_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/view/screens/VIP/vip_reward_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_profile_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/all_agency_screen.dart';
// Removed unused imports
import 'package:shaheen_star_app/view/screens/level/level_description_screen.dart';
// removed unused merchant profile import
import 'package:shaheen_star_app/view/screens/merchant/wallet_screen.dart';
import 'package:shaheen_star_app/view/screens/merchant/withdraw_screen.dart';
// removed unused profile/merchant/agency dashboard imports
import 'package:shaheen_star_app/view/screens/profile/followers_list_screen.dart';
import 'package:shaheen_star_app/view/screens/profile/following_list_screen.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';
// removed unused invite import
import 'package:shaheen_star_app/view/screens/profile/personal_info_screen.dart';
// removed unused backpack import
import 'package:shaheen_star_app/view/screens/store/store_screen.dart';
import 'package:shaheen_star_app/view/screens/widget/robust_animated_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// removed unused withdraw provider import
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

// Format large numbers into compact strings like 2.6K or 1.2M
String _formatCompactNumber(dynamic value) {
  double v;
  if (value is num) {
    v = value.toDouble();
  } else {
    v = double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
  if (v >= 1000000) {
    final m = v / 1000000.0;
    return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
  }
  if (v >= 1000) {
    final k = v / 1000.0;
    return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
  }
  return v.toInt().toString();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final PageController _rechargeBannerPageController = PageController();
  Timer? _rechargeBannerTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _rechargeBannerTimer?.cancel();
    _rechargeBannerPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Reload current user's data when screen becomes visible
    // This ensures we always show the current user's profile, not a previously viewed user's profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      );
      final prefs = await SharedPreferences.getInstance();
      final currentLoggedInUserId = prefs.get('user_id')?.toString();

      // ✅ CRITICAL: Always reload if provider has different user ID or if we're returning to this screen
      if (currentLoggedInUserId != null) {
        if (profileProvider.userId == null ||
            profileProvider.userId != currentLoggedInUserId) {
          print('🔄 [ProfileScreen] Detected different user ID in provider!');
          print('   - Provider User ID: ${profileProvider.userId}');
          print('   - Current Logged-in User ID: $currentLoggedInUserId');
          print('   - Reloading current user\'s data...');
          _loadProfileData();
        }
      } else {
        // If no user_id in SharedPreferences, still try to load (might be first time)
        _loadProfileData();
      }
    });
  }

  void _loadProfileData() async {
    // Acquire providers
    final provider = Provider.of<ProfileUpdateProvider>(context, listen: false);
    final followProvider = Provider.of<UserFollowProvider>(
      context,
      listen: false,
    );
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // Get current logged-in user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final currentLoggedInUserId = prefs.get('user_id')?.toString();

    if (currentLoggedInUserId == null) {
      print("❌ [ProfileScreen] No user_id found in SharedPreferences!");
      return;
    }

    print("🔄 [ProfileScreen] Loading current user's profile data...");
    print("   - Current Logged-in User ID: $currentLoggedInUserId");

    // Fetch profile data using provider
    await provider.fetchUserData();

    print("📥 [ProfileScreen] Profile data loaded: ${provider.profile_url}");
    print("📥 [ProfileScreen] User ID (after fetch): ${provider.userId}");

    // Fetch additional user data if available
    if (provider.userId != null) {
      provider.fetchUserLevels(provider.userId!);
      provider.fetchUserTags(provider.userId!);

      final currentUserId = int.tryParse(provider.userId!);
      if (currentUserId != null) {
        followProvider.getFollowers(currentUserId);
        followProvider.getFollowing(currentUserId);
      }
    }

    // Load store/backpack
    storeProvider.loadBackpack(currentLoggedInUserId);
  }

  @override
  Widget build(BuildContext context) {
    // When "Me" tab is visible, ensure we have current user's data (e.g. after viewing another user's profile)
    final bottomProvider = Provider.of<BottomNavProvider>(
      context,
      listen: true,
    );
    final isMeTabVisible = bottomProvider.currentIndex == 4;
    if (isMeTabVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileProvider = Provider.of<ProfileUpdateProvider>(
          context,
          listen: false,
        );
        final bannerProvider = Provider.of<BannerProvider>(
          context,
          listen: false,
        );
        final prefs = SharedPreferences.getInstance();
        prefs.then((p) async {
          final currentId = p.get('user_id')?.toString();
          if (currentId != null && profileProvider.userId != currentId) {
            _loadProfileData();
          }
          if (bannerProvider.banners.isEmpty) {
            await bannerProvider.fetchBanners(currentId ?? '');
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ProfileUpdateProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final username = provider.username ?? "Guest User";
            final userId = provider.userId ?? "00000000";

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section with White Background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile Picture and User Info Row – both on left: avatar first, then user data
                        Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // ✅ Top align to prevent shifting
                          children: [
                            // Profile Picture with Frame (left side)
                            Consumer<ProfileUpdateProvider>(
                              builder: (context, provider, child) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailedProfileScreen(
                                          userId: provider.userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ProfileWithFrame(
                                    userId: userId,
                                    size: 80,
                                    profileUrl: provider.profile_url,
                                    showPlaceholder: true,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            // User Information (right of avatar, left-aligned)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username in Orange
                                  Text(
                                    username,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // ID with Copy Icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ID: $userId",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          // Copy ID to clipboard
                                        },
                                        child: const Icon(
                                          Icons.copy_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Badges Row – left aligned
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      AppImage.asset(
                                        'assets/images/profile_picture_badge_one.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 4),
                                      AppImage.asset(
                                        'assets/images/profile_picture_badge_two.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 4),
                                      AppImage.asset(
                                        'assets/images/profile_picture_badge_three.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                  // Wealth Level Badge
                                  if (provider.wealthLevel != null)
                                    Transform.translate(
                                      offset: const Offset(
                                        -28,
                                        -12,
                                      ), // ✅ Shifted more to the left
                                      child: Container(
                                        height: 75,
                                        width: 130,
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            Image.asset(
                                              provider.wealthLevel! <= 20
                                                  ? 'assets/images/level_1-to-20.png'
                                                  : provider.wealthLevel! <= 50
                                                  ? 'assets/images/level_21-to-50.png'
                                                  : 'assets/images/level_51-to-100.png',
                                              width: 130,
                                              height: 75,
                                              fit: BoxFit.fill,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "Lvl.${provider.wealthLevel}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // Level Number Text
                                            Positioned(
                                              right:
                                                  20, // ✅ Moved text to the right (smaller right padding)
                                              child: Text(
                                                'Lvl.${provider.wealthLevel}',
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // User Statistics Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Consumer<UserFollowProvider>(
                      builder: (context, followProvider, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: "Visitors",
                              value: "70", // You can get this from provider
                            ),
                            _StatItem(
                              label: "Follow",
                              value: "${followProvider.followersCount}",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FollowersListScreen(),
                                  ),
                                );
                              },
                            ),
                            _StatItem(
                              label: "Fans",
                              value: "${followProvider.followingCount}",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FollowingListScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Recharge Weekly – same backend banners as Home screen
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Consumer<BannerProvider>(
                          builder: (context, bannerProvider, _) {
                            if (bannerProvider.isLoading) {
                              return SizedBox(
                                height: 130,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                              );
                            }
                            final banners = bannerProvider.banners;
                            if (banners.isEmpty) {
                              return SizedBox(
                                height: 100,
                                child: Material(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final userId =
                                          prefs.get('user_id')?.toString() ??
                                          prefs.getInt('user_id')?.toString() ??
                                          '';
                                      await bannerProvider.fetchBanners(
                                        userId.isEmpty ? '' : userId,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.white54,
                                            size: 28,
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Tap to load banners',
                                            style: TextStyle(
                                              color: Colors.white70,
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
                            return SizedBox(
                              height: 130,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CarouselSlider.builder(
                                  itemCount: banners.length,
                                  options: CarouselOptions(
                                    height: 130,
                                    viewportFraction: 1.0,
                                    padEnds: false,
                                    enableInfiniteScroll: banners.length > 1,
                                    autoPlay: banners.length > 1,
                                    autoPlayInterval: const Duration(
                                      seconds: 4,
                                    ),
                                    autoPlayAnimationDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    autoPlayCurve: Curves.linear,
                                    enlargeCenterPage: false,
                                  ),
                                  itemBuilder: (context, index, realIndex) {
                                    final banner = banners[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        if (banner.redirectUrl.isNotEmpty) {
                                          final uri = Uri.parse(
                                            banner.redirectUrl,
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        }
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final width = constraints.maxWidth;
                                          return SizedBox(
                                            width: width,
                                            height: 130,
                                            child: RobustAnimatedImage(
                                              imageUrl: banner.fullImageUrl,
                                              width: width,
                                              height: 130,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wallet Section - Two Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Coin Wallet (tappable)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WalletScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/icons/coin_wallet_background.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // textual content
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Coin wallet",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FutureBuilder(
                                        future: ApiManager.getUserCoinsBalance(
                                          userId: userId,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState !=
                                              ConnectionState.done) {
                                            return const Text(
                                              '...',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          if (!snapshot.hasData ||
                                              snapshot.data == null) {
                                            return const Text(
                                              '0',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          final resp = snapshot.data as dynamic;
                                          final gold =
                                              resp.goldCoins ??
                                              resp.balance ??
                                              0;
                                          return Text(
                                            _formatCompactNumber(gold),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  // wallet image placed inside background on the right
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: AppImage.asset(
                                      'assets/icons/coin_wallet.png',
                                      width: 56,
                                      height: 56,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Diamonds Wallet (tappable -> WithdrawScreen)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WithdrawScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/icons/diamonds_wallet_background.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Diamonds wallet",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.diamond,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          FutureBuilder(
                                            future:
                                                ApiManager.getUserCoinsBalance(
                                                  userId: userId,
                                                ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState !=
                                                  ConnectionState.done) {
                                                return const Text(
                                                  '...',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data == null) {
                                                return const Text(
                                                  '0',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }
                                              final resp =
                                                  snapshot.data as dynamic;
                                              final diamonds =
                                                  resp.diamondCoins ??
                                                  resp.balance ??
                                                  0;
                                              return Text(
                                                _formatCompactNumber(diamonds),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  Positioned(
                                    right: -2,
                                    top: 8,
                                    child: AppImage.asset(
                                      'assets/icons/diamonds_wallet.png',
                                      width: 56,
                                      height: 56,
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

                  const SizedBox(height: 16),

                  // First Icon Grid - Room, Level, Medal, Store (Green Outline Icons)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: [
                        _GridItem(
                          image: 'assets/images/RoomIcon.png',
                          label: "Room",
                          onTap: () {},
                        ),
                        _GridItem(
                          image: 'assets/images/levelIcon.png',
                          label: "Level",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LevelDescriptionScreen(),
                            ),
                          ),
                        ),
                        _GridItem(
                          image: 'assets/images/medlaIcon.png',
                          label: "Medal",
                          onTap: () {},
                        ),
                        _GridItem(
                          image: 'assets/images/storeIcon.png',
                          label: "Store",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StoreScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Mine" Section 1 Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          "Mine",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Mine" Section 1 - 2x3 Grid (VIP, My Agency, Task Center, Edit Profile, Setting, Go Live)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 3, // 3 columns for 2x3 grid
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        _GridItem(
                          image: 'assets/icons/Group_55.svg',
                          label: "VIP",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VipRewardScreen(),
                              ),
                            );
                          },
                        ),
                        _GridItem(
                          image: 'assets/icons/Group_56.svg',
                          label: "My Agency",
                          onTap: () {
                            final agencyProvider = Provider.of<AgencyProvider>(
                              context,
                              listen: false,
                            );
                            final userAgency = agencyProvider.userAgency;
                            if (userAgency != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AgencyProfileCenterScreen(
                                    agency: Map<String, dynamic>.from(
                                      userAgency,
                                    ),
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
                        ),
                        _GridItem(
                          image: 'assets/icons/Group_53.svg',
                          label: "Task Center",
                          onTap: () {},
                        ),
                        _GridItem(
                          image: 'assets/icons/Group_54.png',
                          label: "Edit Profile",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PersonalInfoScreen(),
                              ),
                            );
                          },
                        ),
                        _GridItem(
                          image: 'assets/icons/Group_82.svg',
                          label: "Setting",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PersonalInfoScreen(),
                              ),
                            );
                          },
                        ),
                        _GridItem(
                          image: 'assets/icons/Group_83.svg',
                          label: "Go Live",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Mine" Section 2 Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          "Mine",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Mine" Section 2 - List Items
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ListItem(
                          image: 'assets/icons/Group_59.svg',
                          label: "Check -In",
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _ListItem(
                          image: 'assets/icons/Group_61.svg',
                          label: "Feedback",
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _ListItem(
                          image: 'assets/icons/Group_62.svg',
                          label: "About Dark Party",
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _ListItem(
                          image: 'assets/icons/Group_63.svg',
                          label: "Privacy Policy",
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _ListItem(
                          image: 'assets/icons/Group_64.svg',
                          label: "Switch",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dashboard shortcuts (moved from header)
                  if (provider.isMerchant || provider.hasAgencyAvailable)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                                  Text('Store', style: TextStyle(fontSize: 12)),
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
                                      builder: (_) => AgencyProfileCenterScreen(
                                        agency: Map<String, dynamic>.from(
                                          userAgency,
                                        ),
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

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            );
          },
        ),
      ),
      // Chat & Follow buttons only on other user's profile (search result), not on "Me"
    );
  }

  Widget _buildProfileAvatar(String? profileUrl) {
    print("🖼️ Profile Avatar:");
    print("   - Path (raw): $profileUrl");

    // ✅ Check if profileUrl is empty or invalid
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url') {
      print("   - Using placeholder (empty/invalid)");
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: _buildPlaceholderImage(),
      );
    }

    // ✅ Normalize profile URL (convert relative path to full URL if needed)
    // ✅ FIXED: Better detection of local file paths to prevent 404 errors
    String normalizedUrl = profileUrl;

    // Check if it's already a network URL
    bool isNetworkUrl =
        profileUrl.startsWith('http://') || profileUrl.startsWith('https://');

    // Check if it's a local file path (more comprehensive check)
    bool isLocalPath =
        profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.startsWith('/private/') ||
        profileUrl.startsWith('/var/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.contains('cache/') ||
        profileUrl.contains('/com.example.') ||
        profileUrl.contains('/com.') ||
        profileUrl.startsWith('file://');

    // Only normalize if it's neither a network URL nor a local path
    if (!isNetworkUrl && !isLocalPath) {
      // Check if it looks like a server-relative path
      if (profileUrl.startsWith('uploads/') ||
          profileUrl.startsWith('images/') ||
          profileUrl.startsWith('profiles/') ||
          profileUrl.startsWith('room_profiles/') ||
          profileUrl.startsWith('gifts/')) {
        // It's a relative server path, construct full URL
        String cleanPath = profileUrl.startsWith('/')
            ? profileUrl.substring(1)
            : profileUrl;
        normalizedUrl = 'https://shaheenstar.online/$cleanPath';
        print("   - Normalized URL: $normalizedUrl");
      } else {
        // Unknown format, don't try to normalize (will use local file check below)
        print("   ⚠️ Unknown path format, skipping normalization: $profileUrl");
      }
    }

    // ✅ Check if it's a network URL
    if (normalizedUrl.startsWith('http://') ||
        normalizedUrl.startsWith('https://')) {
      print("   - Is Network URL: true");
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            normalizedUrl,
            fit: BoxFit.cover,
            width: 70,
            height: 70,
            errorBuilder: (context, error, stackTrace) {
              print("❌ Network image error: $error");
              return _buildPlaceholderImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        ),
      );
    }

    // ✅ Check if it's a local file path
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.contains('cache')) {
      print("   - Is Local File: true");
      try {
        File file = File(profileUrl);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: 70,
                height: 70,
                errorBuilder: (context, error, stackTrace) {
                  print("❌ File error: $error");
                  return _buildPlaceholderImage();
                },
              ),
            ),
          );
        } else {
          print("   - File does not exist: $profileUrl");
          return CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: _buildPlaceholderImage(),
          );
        }
      } catch (e) {
        print("❌ Error loading file: $e");
        return CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          child: _buildPlaceholderImage(),
        );
      }
    }

    // ✅ Default to placeholder
    print("   - Using placeholder (unknown format)");
    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.white,
      child: _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return AppImage.asset(
      'assets/images/person.png',
      width: 70,
      height: 70,
      fit: BoxFit.cover,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }

    return content;
  }
}

class _GridItem extends StatelessWidget {
  final String? image;
  final String label;
  final VoidCallback? onTap;

  const _GridItem({this.image, required this.label, this.onTap});

  ImageProvider _getSafeImageProvider(String? imagePath) {
    // ✅ Check for invalid values
    if (imagePath == null ||
        imagePath.isEmpty ||
        imagePath == 'yyyy' ||
        imagePath == 'Profile Url' ||
        imagePath == 'upload' ||
        imagePath == 'jgh' ||
        !imagePath.startsWith('assets/')) {
      return const AssetImage('assets/images/person.png');
    }

    // ✅ Only use AssetImage for valid asset paths
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }

    // ✅ Default to placeholder
    return const AssetImage('assets/images/person.png');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    // Responsive icon size: 4% of screen height (smaller, crisp DPR-aware)
    final iconSize = screenHeight * 0.04;
    final cacheWidth = (iconSize * dpr).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null)
            SizedBox(
              height: iconSize,
              width: iconSize,
              child: image!.toLowerCase().endsWith('.svg')
                  ? SvgPicture.asset(image!, fit: BoxFit.contain)
                  : Image(
                      image: image!.startsWith('assets/')
                          ? ResizeImage(
                              AssetImage(image!),
                              width: cacheWidth,
                              height: cacheWidth,
                            )
                          : _getSafeImageProvider(image),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
            )
          else
            Icon(Icons.help_outline, size: iconSize * 0.8, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: screenHeight * 0.018,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Rank Badge Widget
class _RankBadge extends StatelessWidget {
  final String rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rank,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Mine List Item Widget
class _MineListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MineListItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  const _ListItem({
    required this.image,
    required this.label,
    required this.onTap,
  });

  ImageProvider _getSafeImageProvider(String imagePath) {
    // ✅ Check for invalid values
    if (imagePath.isEmpty ||
        imagePath == 'yyyy' ||
        imagePath == 'Profile Url' ||
        imagePath == 'upload' ||
        imagePath == 'jgh' ||
        !imagePath.startsWith('assets/')) {
      return const AssetImage('assets/images/person.png');
    }

    // ✅ Only use AssetImage for valid asset paths
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }

    // ✅ Default to placeholder
    return const AssetImage('assets/images/person.png');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: SizedBox(
        height: 32,
        width: 32,
        child: image.toLowerCase().endsWith('.svg')
            ? SvgPicture.asset(image, fit: BoxFit.contain)
            : Image(
                image: _getSafeImageProvider(image),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}
