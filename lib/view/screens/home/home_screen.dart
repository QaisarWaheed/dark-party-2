import 'dart:io';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/custom_card.dart';
import 'package:shaheen_star_app/components/custom_profile_card.dart';
import 'package:shaheen_star_app/components/custom_profile_frame.dart';
import 'package:shaheen_star_app/components/filter_card.dart';
import 'package:shaheen_star_app/components/live_streamer_card.dart';
import 'package:shaheen_star_app/controller/provider/banner_provider.dart';
import 'package:shaheen_star_app/controller/provider/create_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/model/banner_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:shaheen_star_app/view/screens/home/events_screen.dart';
import 'package:shaheen_star_app/view/screens/home/mine_screen.dart';
import 'package:shaheen_star_app/view/screens/home/search_screen.dart';
import 'package:shaheen_star_app/view/screens/ranking/ranking_screen.dart';
import 'package:shaheen_star_app/view/screens/room/create_room_screen.dart';
import 'package:shaheen_star_app/view/screens/room/room_screen.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';
import 'package:shaheen_star_app/view/screens/widget/robust_animated_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controller/provider/bottom_nav_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String topBg = 'assets/images/bg_home.png';

  final String bottomBg = 'assets/images/bg_bottom_nav.png';

  // ✅ Banner is now dynamic from API (removed static banner)
  // final String banner = 'assets/images/wel.jpeg';

  final String userImg1 = 'assets/images/bg_home_rank1.png';

  final String userImg2 = 'assets/images/bg_home_rank2.png';

  final String userImg3 = 'assets/images/bg_home_rank3.png';

  final String profile = 'assets/images/person.png';

  DateTime? _lastRefreshTime;

  // ✅ CarouselSlider Controller for banner
  final CarouselSliderController _bannerCarouselController =
      CarouselSliderController();

  // Scroll controller for top user profiles
  final ScrollController _topProfilesScrollController = ScrollController();

  // Banner fade carousel state
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  bool _bannerFetchAttempted = false; // ✅ Prevent repeated banner fetches

  // Tab state for Hot/Mine/MIDDLE_EAST
  int selectedTopTab = 0; // 0: Hot, 1: Mine, 2: MIDDLE_EAST
  // Live tab state for Hot tab (Offical Live / Popular Live)
  int _selectedLiveTab = 0; // 0: Offical Live, 1: Popular Live

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<ProfileUpdateProvider>(
        context,
        listen: false,
      ).fetchUserData();
      final prefs = await SharedPreferences.getInstance();
      var userId =
          prefs.get('user_id')?.toString() ??
          prefs.getInt('user_id')?.toString() ??
          '';
      if (userId.isEmpty || userId == '0') userId = '';
      await Provider.of<BannerProvider>(
        context,
        listen: false,
      ).fetchBanners(userId);
      final banners = Provider.of<BannerProvider>(
        context,
        listen: false,
      ).banners;
      _refreshRooms();
    });
  }

  void _startBannerTimer(int count) {
    _bannerTimer?.cancel();
    if (count <= 1) {
      if (mounted) {
        setState(() {
          _currentBannerIndex = 0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _currentBannerIndex = 0;
      });
    }
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _currentBannerIndex = (_currentBannerIndex + 1) % count;
      });
    });
  }

  @override
  void dispose() {
    _topProfilesScrollController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Do NOT fetch here – didChangeDependencies runs often (e.g. on every Provider/theme update)
    // and caused repeated API calls. Initial load is done once in initState only.
  }

  /// ✅ Refresh rooms list with throttling
  void _refreshRooms() {
    _lastRefreshTime = DateTime.now();
    Provider.of<GetAllRoomProvider>(context, listen: false).fetchRooms();
  }

  /// ✅ Refresh rooms if enough time has passed (avoid too frequent refreshes)
  void _refreshRoomsIfNeeded() {
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!).inSeconds > 3) {
      _refreshRooms();
    }
  }

  Future<void> openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // ✅ Do NOT schedule API calls from build() – build runs on every rebuild and caused a loop.
    // Rooms and banners are fetched once in initState.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<BannerProvider>(
          builder: (context, bannerProvider, _) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // ✅ Better scroll physics
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar - Hot/Mine/MIDDLE_EAST Tabs
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Tabs
                        Flexible(
                          flex: selectedTopTab == 1 ? 1 : 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Hot Tab
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTopTab = 0;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Hot',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: selectedTopTab == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (selectedTopTab == 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        height: 3,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Mine Tab
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTopTab = 1;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Mine',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: selectedTopTab == 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (selectedTopTab == 1)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        height: 3,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // MIDDLE_EAST Tab (hide when Mine tab is selected to save space)
                              if (selectedTopTab != 1)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedTopTab = 2;
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'MIDDLE_EAST',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: selectedTopTab == 2
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                      if (selectedTopTab == 2)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          height: 3,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Middle Dropdown (only show when Mine tab is selected)
                        if (selectedTopTab == 1)
                          Flexible(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                // Show MIDDLE_EAST dropdown
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'MIDDLE_EAST',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Right Icons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Trophy Icon (Group_33.svg)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RankingScreen(),
                                  ),
                                );
                              },
                              child: SvgPicture.asset(
                                'assets/icons/Group_33.svg',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Search Icon (Group_32.svg)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(),
                                  ),
                                );
                              },
                              child: SvgPicture.asset(
                                'assets/icons/Group_32.svg',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content based on selected tab
                  if (selectedTopTab == 0)
                    // Hot Tab - Live Streaming View
                    _buildHotTabContent(bannerProvider)
                  else if (selectedTopTab == 1)
                    // Mine Tab - Mine Screen Content
                    _buildMineTabContent()
                  else if (selectedTopTab == 2)
                    // MIDDLE_EAST Tab - Same design as Popular
                    _buildMiddleEastTabContent(bannerProvider)
                  else
                    // Popular Tab - Original View
                    _buildPopularTabContent(bannerProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// ✅ Get room profile as network URL (for RoomScreen) - only for network URLs
  /// Returns normalized network URL if it's a network/relative path, null for local files
  String? _getRoomProfileNetworkUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'jgh' ||
        profileUrl == 'null' ||
        profileUrl.trim().isEmpty) {
      return null;
    }

    // ✅ If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }

    // ✅ FIXED: Comprehensive check for local file paths (must come BEFORE generic / check)
    // Check for absolute paths starting with /data/, /storage/, /private/, etc.
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.startsWith('/private/') ||
        profileUrl.startsWith('/var/') ||
        profileUrl.startsWith('/tmp/') ||
        // Check for paths containing cache directories
        profileUrl.contains('/cache/') ||
        profileUrl.contains('cache/') ||
        // Check for Android app-specific paths
        profileUrl.contains('/com.example.') ||
        profileUrl.contains('/com.') ||
        // Check for file:// protocol
        profileUrl.startsWith('file://') ||
        // Check for data/user pattern (Android app data directory)
        profileUrl.contains('/data/user/')) {
      print(
        "⚠️ [HomeScreen] Detected local file path, returning null: $profileUrl",
      );
      return null; // Use File for local paths, don't convert to network URL
    }

    // ✅ If it starts with 'uploads/', 'images/', 'profiles/', etc., it's a relative server path
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/') ||
        profileUrl.startsWith('gifts/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }

    // ✅ If it's a relative path (starts with /), check if it's a server path
    // Only normalize if it looks like a server-relative path, not a local file path
    if (profileUrl.startsWith('/')) {
      // Double-check it's not a local path (should have been caught above, but be safe)
      if (!profileUrl.contains('/data/') &&
          !profileUrl.contains('/storage/') &&
          !profileUrl.contains('/cache/') &&
          !profileUrl.contains('/com.')) {
        String cleanPath = profileUrl.substring(1); // Remove leading slash
        return 'https://shaheenstar.online/$cleanPath';
      } else {
        print(
          "⚠️ [HomeScreen] Path starts with / but looks like local path: $profileUrl",
        );
        return null;
      }
    }

    // ✅ If it's just a filename or unknown format, don't try to normalize
    // Return null to avoid creating invalid URLs
    print("⚠️ [HomeScreen] Unknown path format, returning null: $profileUrl");
    return null;
  }

  /// ✅ Get room avatar as File (for RoomScreen) - only for local file paths
  /// Returns File if it's a local path, null for network URLs or assets
  File? _getRoomAvatarFile(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'jgh' ||
        profileUrl == 'null' ||
        profileUrl.trim().isEmpty) {
      return null;
    }

    // ✅ Only return File for local file paths
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.startsWith('/cache/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.contains('/data/user/')) {
      try {
        final file = File(profileUrl);
        // Check if file exists before returning
        if (file.existsSync()) {
          return file;
        } else {
          print("⚠️ [HomeScreen] Room avatar file does not exist: $profileUrl");
          return null;
        }
      } catch (e) {
        print("❌ [HomeScreen] Error creating File from path: $profileUrl - $e");
        return null;
      }
    }

    // ✅ For network URLs or asset paths, return null (RoomScreen will handle differently)
    return null;
  }

  String normalizeRoomProfileUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'jgh' ||
        profileUrl == 'null' ||
        profileUrl.trim().isEmpty) {
      return 'assets/images/person.png';
    }

    // ✅ If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }

    // ✅ FIXED: Detect local file paths and return placeholder (don't try to load as network URL)
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.startsWith('/private/') ||
        profileUrl.startsWith('/var/') ||
        profileUrl.startsWith('/tmp/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.contains('cache/') ||
        profileUrl.contains('/com.example.') ||
        profileUrl.contains('/com.') ||
        profileUrl.startsWith('file://') ||
        profileUrl.contains('/data/user/')) {
      print(
        "⚠️ [HomeScreen] Room profile is local file path, using placeholder: $profileUrl",
      );
      return 'assets/images/person.png'; // Use placeholder for local paths
    }

    // ✅ If it starts with 'uploads/', 'room_profiles/', etc., it's a relative server path
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/') ||
        profileUrl.startsWith('gifts/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }

    // ✅ If it's a relative path (starts with /), check if it's a server path
    if (profileUrl.startsWith('/')) {
      // Double-check it's not a local path
      if (!profileUrl.contains('/data/') &&
          !profileUrl.contains('/storage/') &&
          !profileUrl.contains('/cache/') &&
          !profileUrl.contains('/com.')) {
        String cleanPath = profileUrl.substring(1); // Remove leading slash
        return 'https://shaheenstar.online/$cleanPath';
      } else {
        print(
          "⚠️ [HomeScreen] Path starts with / but looks like local path: $profileUrl",
        );
        return 'assets/images/person.png';
      }
    }

    // ✅ Unknown format - use placeholder
    print(
      "⚠️ [HomeScreen] Unknown room profile format, using placeholder: $profileUrl",
    );
    return 'assets/images/person.png';
  }

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

  Widget bannerCard(String img) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: _getSafeImageProvider(img),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget bannerWithCard(String backgroundImg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(backgroundImg),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔸 Room Ranking Text at Top Center
          Positioned(
            top: 5,
            child: Text(
              'Room Ranking',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ).createShader(Rect.fromLTWH(0, 0, 100, 0)),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),

          // 🔸 Frames Row in the center
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FrameWithProfile(
                  frameImg: 'assets/images/room_1.png',
                  profileImg: 'assets/images/person.png',
                  size: 30,
                ),
                const SizedBox(width: 15),
                FrameWithProfile(
                  frameImg: 'assets/images/room.png',
                  profileImg: 'assets/images/person.png',
                  size: 25, // middle one slightly larger
                ),
                const SizedBox(width: 15),
                FrameWithProfile(
                  frameImg: 'assets/images/room_2.png',
                  profileImg: 'assets/images/person.png',
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget topUpCard(String img, String title, String views) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.2),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: _getSafeImageProvider(img)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text('🔥 $views'),
        ],
      ),
    );
  }

  // ✅ Build Banner Section from Real API Data (banners loaded once in initState)
  Widget _buildBannerSection(BannerProvider bannerProvider) {
    final banners = bannerProvider.banners;

    if (bannerProvider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SizedBox(
          height: 118,
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
            child: InkWell(
              onTap: () async {
                _bannerFetchAttempted = false;
                final prefs = await SharedPreferences.getInstance();
                var userId =
                    prefs.get('user_id')?.toString() ??
                    prefs.getInt('user_id')?.toString() ??
                    '';
                if (userId.isEmpty || userId == '0') userId = '';
                await bannerProvider.fetchBanners(userId);
                if (mounted) setState(() {});
              },
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 28,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Banner load nahi hua',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        _bannerFetchAttempted = false;
                        final prefs = await SharedPreferences.getInstance();
                        var userId =
                            prefs.get('user_id')?.toString() ??
                            prefs.getInt('user_id')?.toString() ??
                            '';
                        if (userId.isEmpty || userId == '0') userId = '';
                        await bannerProvider.fetchBanners(userId);
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CarouselSlider.builder(
            itemCount: banners.length,
            options: CarouselOptions(
              height: 150,
              viewportFraction: 1.0,
              padEnds: false,
              enableInfiniteScroll: banners.length > 1,
              autoPlay: banners.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 500),
              autoPlayCurve: Curves.linear,
              enlargeCenterPage: false,
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () async {
                  if (banner.redirectUrl.isNotEmpty) {
                    final uri = Uri.parse(banner.redirectUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      print(
                        "❌ [HomeScreen] Could not launch URL: ${banner.redirectUrl}",
                      );
                    }
                  }
                },
                child: SizedBox.expand(
                  child: _buildBannerImage(banner.fullImageUrl),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ Build Banner Image Widget (no static fallback)
  Widget _buildBannerImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 150,
          width: width,
          child: RobustAnimatedImage(
            imageUrl: imageUrl,
            width: width,
            height: 150,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  // Hot Tab Content - Live Streaming View (Original Design)
  Widget _buildHotTabContent(BannerProvider bannerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // ✅ Real Banner from API
        _buildBannerSection(bannerProvider),
        const SizedBox(height: 20),
        // Live streaming Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live streaming',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.grid_view, color: Colors.black87),
                onPressed: () {
                  // Toggle grid/list view
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Live Streamers List
        Consumer<GetAllRoomProvider>(
          builder: (context, roomProvider, _) {
            if (roomProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roomProvider.rooms.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No live streamers found",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            }

            // Use real backend data for live streamers - Show ALL rooms
            final sampleStreamers = List.generate(roomProvider.rooms.length, (
              index,
            ) {
              final room = roomProvider.rooms[index];
              // ✅ Use participantCount (total members) instead of views
              final totalMembers = room.participantCount ?? 0;
              // Format total members: if >= 1000, show "XK", else show actual number
              final formattedMembers = totalMembers >= 1000
                  ? '${(totalMembers / 1000).toStringAsFixed(1)}K'.replaceAll(
                      '.0K',
                      'K',
                    )
                  : totalMembers.toString();
              // Format popularity: use views for popularity
              final views = room.views ?? 0;
              final formattedPopularity = views >= 1000
                  ? '${(views / 1000).toStringAsFixed(1)}K'.replaceAll(
                      '.0K',
                      'K',
                    )
                  : views.toString();

              return {
                'room': room, // ✅ Store room object for navigation
                'profileImage': normalizeRoomProfileUrl(room.roomProfile),
                'userName': room.name,
                'countryFlag': room.countryFlag?.isNotEmpty == true
                    ? room.countryFlag!
                    : CountryFlagUtils.getFlagEmoji(null),
                'viewers': formattedMembers, // ✅ Real total members data
                'popularity': formattedPopularity,
                'isSelected': index == 3, // 4th item selected
                'nameColor': index == 3 ? Colors.pink : Colors.black87,
              };
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sampleStreamers.length,
              itemBuilder: (context, index) {
                final streamer = sampleStreamers[index];
                final room = streamer['room'] as dynamic; // Room object
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomScreen(
                          roomName: room.name,
                          roomCreatorId: room.creatorId!,
                          roomId: room.id,
                          topic: room.topic,
                          avatarUrl: _getRoomAvatarFile(room.roomProfile),
                          roomProfileUrl: _getRoomProfileNetworkUrl(
                            room.roomProfile,
                          ),
                        ),
                      ),
                    );

                    if (mounted) {
                      _refreshRooms();
                    }
                  },
                  child: LiveStreamerCard(
                    profileImage: streamer['profileImage'] as String,
                    userName: streamer['userName'] as String,
                    countryFlag: streamer['countryFlag'] as String,
                    viewers: streamer['viewers'] as String,
                    popularity: streamer['popularity'] as String,
                    isSelected: streamer['isSelected'] as bool,
                    animateName: true,
                    nameColor: streamer['nameColor'] as Color?,
                    frameImage:
                        'assets/images/bg_home_rank1.png', // Ornate frame
                    secondaryAvatars: (room.participantAvatars != null &&
                            room.participantAvatars!.isNotEmpty)
                        ? room.participantAvatars!
                        : [
                            'assets/images/person.png',
                            'assets/images/person.png',
                            'assets/images/person.png',
                          ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFeaturedSection({required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Using the actual image for horizontal scrollable cards
        SizedBox(
          height: 140,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage.asset(
                'assets/images/Mine_Page_Photo_Second.png',
                fit: BoxFit.contain,
                height: 140,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 140,
                    width: 300,
                    color: Colors.grey,
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondFeaturedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Using the actual image for the second featured section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage.asset(
              'assets/images/Mine_Page_photo_Top.png',
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey,
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLiveTab('Offical Live', 0),
              const SizedBox(width: 20),
              _buildLiveTab('Popular Live', 1),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.black87),
            onPressed: () {
              // Toggle grid/list view
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab(String title, int index) {
    final isSelected = _selectedLiveTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLiveTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfficalLiveContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          'Offical Live Content',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildPopularLiveContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          'Popular Live Content',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  // Popular Tab Content - Original View
  Widget _buildPopularTabContent(BannerProvider bannerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Hall of Fame (Left) and Family Button (Right)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              // Hall of Fame Card (Left - Large)
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RankingScreen()),
                    );
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/home.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Family Button (Right - Smaller)
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to family screen or perform action
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/home_family.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Room Ranking Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RankingScreen()),
              );
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/image1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Room Ranking Text at Top
                  const Positioned(
                    top: 5,
                    child: Text(
                      'Room Ranking',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Frames Row in the center
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FrameWithProfile(
                          frameImg: 'assets/images/room_1.png',
                          profileImg: 'assets/images/person.png',
                          size: 30,
                        ),
                        const SizedBox(width: 15),
                        FrameWithProfile(
                          frameImg: 'assets/images/room.png',
                          profileImg: 'assets/images/person.png',
                          size: 35, // middle one slightly larger
                        ),
                        const SizedBox(width: 15),
                        FrameWithProfile(
                          frameImg: 'assets/images/room_2.png',
                          profileImg: 'assets/images/person.png',
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Top User Profiles Row (Scrollable with arrows)
        SizedBox(
          height: 140,
          child: Row(
            children: [
              // Left Arrow
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  _topProfilesScrollController.animateTo(
                    (_topProfilesScrollController.offset - 120).clamp(
                      0.0,
                      _topProfilesScrollController.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
              // Scrollable Profile Cards
              Expanded(
                child: ListView.builder(
                  controller: _topProfilesScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: 3, // You can make this dynamic from API
                  itemBuilder: (context, index) {
                    final crownImages = [
                      'assets/images/bg_home_rank1.png',
                      'assets/images/bg_home_rank2.png',
                      'assets/images/bg_home_rank3.png',
                    ];
                    final names = ['داستان', 'Empire🔥', 'داستان'];
                    final views = ['25.48M', '19.8M', '25.48M'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: CustomProfileCard(
                        crownFrameImage: crownImages[index],
                        profileImage: 'assets/images/app_logo.jpeg',
                        name: names[index],
                        views: views[index],
                        flagEmoji: '🇵🇰',
                      ),
                    );
                  },
                ),
              ),
              // Right Arrow
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  _topProfilesScrollController.animateTo(
                    (_topProfilesScrollController.offset + 120).clamp(
                      0.0,
                      _topProfilesScrollController.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Country Filter Bar
        FilterCard(),
        const SizedBox(height: 20),
        // Main Content Grid
        Consumer<GetAllRoomProvider>(
          builder: (context, roomProvider, _) {
            if (roomProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roomProvider.rooms.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No rooms found 😕",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1,
              ),
              itemCount: roomProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = roomProvider.rooms[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomScreen(
                          roomName: room.name,
                          roomCreatorId: room.creatorId!,
                          roomId: room.id,
                          topic: room.topic,
                          avatarUrl: _getRoomAvatarFile(room.roomProfile),
                          roomProfileUrl: _getRoomProfileNetworkUrl(
                            room.roomProfile,
                          ),
                        ),
                      ),
                    );

                    if (mounted) {
                      print(
                        "🔄 [HomeScreen] Refreshing rooms after returning from RoomScreen",
                      );
                      _refreshRooms();
                    }
                  },
                  child: CustomCard(
                    userProfile: normalizeRoomProfileUrl(
                      room.creatorProfileUrl,
                    ),
                    profile: normalizeRoomProfileUrl(room.roomProfile),
                    flag: room.countryFlag?.isNotEmpty == true
                        ? room.countryFlag!
                        : CountryFlagUtils.getFlagEmoji(null),
                    name: room.name,
                    views: room.views?.toString() ?? room.id,
                    showTopUp: index % 2 == 0,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMiddleEastTabContent(BannerProvider bannerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // ✅ Real Banner from API
        _buildBannerSection(bannerProvider),
        const SizedBox(height: 20),
        // Live streaming Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live streaming',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.grid_view, color: Colors.black87),
                onPressed: () {
                  // Toggle grid/list view
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Live Streamers List
        Consumer<GetAllRoomProvider>(
          builder: (context, roomProvider, _) {
            if (roomProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roomProvider.rooms.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No live streamers found",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            }

            // Use real backend data for live streamers - Show ALL rooms
            final sampleStreamers = List.generate(roomProvider.rooms.length, (
              index,
            ) {
              final room = roomProvider.rooms[index];
              // ✅ Use participantCount (total members) instead of views
              final totalMembers = room.participantCount ?? 0;
              // Format total members: if >= 1000, show "XK", else show actual number
              final formattedMembers = totalMembers >= 1000
                  ? '${(totalMembers / 1000).toStringAsFixed(1)}K'.replaceAll(
                      '.0K',
                      'K',
                    )
                  : totalMembers.toString();
              // Format popularity: use views for popularity
              final views = room.views ?? 0;
              final formattedPopularity = views >= 1000
                  ? '${(views / 1000).toStringAsFixed(1)}K'.replaceAll(
                      '.0K',
                      'K',
                    )
                  : views.toString();

              return {
                'room': room, // ✅ Store room object for navigation
                'profileImage': normalizeRoomProfileUrl(room.roomProfile),
                'userName': room.name,
                'countryFlag': room.countryFlag?.isNotEmpty == true
                    ? room.countryFlag!
                    : CountryFlagUtils.getFlagEmoji(null),
                'viewers': formattedMembers, // ✅ Real total members data
                'popularity': formattedPopularity,
                'isSelected': index == 3, // 4th item selected
                'nameColor': index == 3 ? Colors.pink : Colors.black87,
              };
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sampleStreamers.length,
              itemBuilder: (context, index) {
                final streamer = sampleStreamers[index];
                final room = streamer['room'] as dynamic; // Room object
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomScreen(
                          roomName: room.name,
                          roomCreatorId: room.creatorId!,
                          roomId: room.id,
                          topic: room.topic,
                          avatarUrl: _getRoomAvatarFile(room.roomProfile),
                          roomProfileUrl: _getRoomProfileNetworkUrl(
                            room.roomProfile,
                          ),
                        ),
                      ),
                    );

                    if (mounted) {
                      _refreshRooms();
                    }
                  },
                  child: LiveStreamerCard(
                    profileImage: streamer['profileImage'] as String,
                    userName: streamer['userName'] as String,
                    countryFlag: streamer['countryFlag'] as String,
                    viewers: streamer['viewers'] as String,
                    popularity: streamer['popularity'] as String,
                    isSelected: streamer['isSelected'] as bool,
                    animateName: true,
                    nameColor: streamer['nameColor'] as Color?,
                    frameImage:
                        'assets/images/bg_home_rank1.png', // Ornate frame
                    secondaryAvatars: (room.participantAvatars != null &&
                            room.participantAvatars!.isNotEmpty)
                        ? room.participantAvatars!
                        : [
                            'assets/images/person.png',
                            'assets/images/person.png',
                            'assets/images/person.png',
                          ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  // Mine Tab Content
  Widget _buildMineTabContent() {
    return _MineTabContent();
  }
}

// Mine Tab Content Widget
class _MineTabContent extends StatefulWidget {
  @override
  State<_MineTabContent> createState() => _MineTabContentState();
}

class _MineTabContentState extends State<_MineTabContent> {
  int selectedContentTab = 0; // 0: My room, 1: Recently, 2: Following
  String? _currentUserId;
  bool _roomCheckDone = false;

  @override
  void initState() {
    super.initState();
    _checkUserRoom();
  }

  Future<void> _checkUserRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.get('user_id')?.toString() ??
        prefs.getInt('user_id')?.toString() ??
        '';
    if (userId.isEmpty || !mounted) return;
    _currentUserId = userId;
    final provider = Provider.of<CreateRoomProvider>(context, listen: false);
    await provider.checkExistingRoom(userId);
    if (mounted) {
      setState(() => _roomCheckDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateRoomProvider>(
      builder: (context, createRoomProvider, _) {
        final hasRoom =
            createRoomProvider.editingMode &&
            createRoomProvider.existingRoomData != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Create my room Button - disabled when user already has a room
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: IgnorePointer(
                ignoring: hasRoom,
                child: Opacity(
                  opacity: hasRoom ? 0.5 : 1.0,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateRoomScreen(),
                        ),
                      );
                      if (mounted && _currentUserId != null) {
                        await _checkUserRoom();
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasRoom
                                ? 'Create my room (one room only)'
                                : 'Create my room',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Content Tabs: My room, Recently, Following
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildContentTab('My room', 0),
                      const SizedBox(width: 20),
                      _buildContentTab('Recently', 1),
                      const SizedBox(width: 20),
                      _buildContentTab('Following', 2),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildContentArea(createRoomProvider),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildContentTab(String title, int index) {
    final isSelected = selectedContentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedContentTab = index;
        });
        if (index == 0 && _currentUserId != null) {
          _checkUserRoom();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentArea(CreateRoomProvider createRoomProvider) {
    if (selectedContentTab == 0) {
      return _buildMyRoomContent(createRoomProvider);
    }
    if (selectedContentTab == 1) {
      return _buildNoDataPlaceholder();
    }
    return _buildNoDataPlaceholder();
  }

  Widget _buildMyRoomContent(CreateRoomProvider createRoomProvider) {
    final room = createRoomProvider.existingRoomData;
    if (!_roomCheckDone || room == null) {
      return Center(
        child: createRoomProvider.checkingRoom
            ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )
            : _buildNoRoomPlaceholder(),
      );
    }
    // Support backend keys: room_id/id, room_name/name, topic, room_profile
    final roomId = (room['room_id'] ?? room['id'])?.toString() ?? '';
    final roomName =
        (room['room_name'] ?? room['name'])?.toString() ?? 'My Room';
    final topic = room['topic']?.toString() ?? '';
    final roomProfile =
        (room['room_profile'] ?? room['profile'] ?? room['room_profile_url'])
            ?.toString() ??
        '';
    const baseUrl = 'https://shaheenstar.online/';
    final profileUrl = roomProfile.isEmpty
        ? null
        : (roomProfile.startsWith('http')
              ? roomProfile
              : '$baseUrl$roomProfile');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          if (_currentUserId == null || roomId.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomScreen(
                roomId: roomId,
                roomName: roomName,
                roomCreatorId: _currentUserId!,
                topic: topic,
                roomProfileUrl: profileUrl,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: profileUrl != null && profileUrl.isNotEmpty
                    ? SizedBox(
                        width: 80,
                        height: 80,
                        child: cachedImage(
                          profileUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.green.shade100,
                        child: Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.green.shade700,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (topic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Tap to enter room',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRoomPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'You haven\'t created a room yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Create my room" above to create one',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppImage.asset(
            'assets/images/image_16.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.green.shade100, Colors.green.shade300],
                  ),
                ),
                child: const Icon(Icons.public, size: 100, color: Colors.green),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No data',
            style: TextStyle(color: Colors.grey, fontSize: 16),
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
