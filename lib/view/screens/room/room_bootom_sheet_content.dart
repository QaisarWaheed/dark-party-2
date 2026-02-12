// ignore_for_file: must_be_immutable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../components/app_image.dart';
import '../../../components/follow_button.dart';
import '../../../controller/api_manager/api_manager.dart';
import '../../../controller/api_manager/svg_cache_manager.dart';
import '../../../controller/provider/profile_update_provider.dart';
import '../../../controller/provider/store_provider.dart';
import '../../../controller/provider/cp_provider.dart';
import '../../../controller/provider/user_follow_provider.dart';
import '../../../model/room_gift_response.dart';
import '../../../model/seat_model.dart';
import '../../../model/store_model.dart';
import '../../../utils/country_utils.dart';
import '../profile/detailed_profile_screen.dart';
import '../../widgets/user_id_display.dart';

class RoomBottomSheetContent extends StatefulWidget {
  final dynamic profileProvider;
  final String? databaseId,
      currentDatabaseUserId,
      userId,
      userName,
      profileUrl,
      roomId;
  final bool? isCurrentUser;

  const RoomBottomSheetContent({
    super.key,
    this.profileProvider,
    this.databaseId,
    this.currentDatabaseUserId,
    this.userId,
    this.userName,
    this.isCurrentUser,
    this.profileUrl,
    this.roomId,
  });

  @override
  State<RoomBottomSheetContent> createState() => RoomBottomSheetContentState();
}

class RoomBottomSheetContentState extends State<RoomBottomSheetContent>
    with TickerProviderStateMixin {
  String displayName = "";
  String displayUserId = "";
  String currentDatabaseUserId = "";
  bool isCurrentUser = false;
  Seat? _selectedSeatForGift;
  String? userCountry = "";
  SVGAAnimationController? _animationRoomHeadwearController;
  String? _currentRoomHeadwearAnimUrl;
  bool _isRoomHeadwearAnimationVisible = false;
  bool _isRoomHeadwearDisposed = false;

  int _selectedTopTab = 0; // 0: Contribut, 1: Charm
  int _selectedPeriod = 0; // 0: Daily, 1: Weekly, 2: Monthly
  bool _statsLoading = false;
  String? _statsError;
  User? _statsUser;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        currentDatabaseUserId = widget.databaseId!;
        isCurrentUser = widget.userId == currentDatabaseUserId.toString();

        print("👤 ===== SHOW PROFILE BOTTOM SHEET =====");
        print("👤 User Name: ${widget.userName}");
        print("👤 User ID: ${widget.userId}");
        print("👤 Current User ID: ${widget.currentDatabaseUserId}");
        print("👤 Is Current User: ${widget.isCurrentUser}");
        print("👤 Profile URL: ${widget.profileUrl}");

        // ✅ Handle null values
        displayName = widget.userName ?? 'Unknown User';
        displayUserId = widget.userId ?? 'Unknown ID';
      });
      setState(() {
        userCountry =
            widget.profileProvider.country; // Directly updated country

        print("🎯 ========== BOTTOM SHEET BUILDER ==========");
        print("🎯 Profile Provider Country: '$userCountry'");
        print("🎯 =========================================");

        // ✅ Fetch user levels and tags when bottom sheet opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.userId != null) {
            widget.profileProvider.fetchUserLevels(widget.userId!);
            widget.profileProvider.fetchUserTags(widget.userId!);
            print(
              "📊 [ProfileBottomSheet] Fetching levels and tags for user: ${widget.userId}",
            );
          }
        });
      });

      print('🎬 [ProfileWithFrame] ========== INIT STATE ==========');
      print('🎬 [ProfileWithFrame] Size: 70');
      print('🎬 [ProfileWithFrame] Profile URL: ${widget.profileUrl}');
      print('🎬 [ProfileWithFrame] User ID: ${widget.userId}');
      print('🎬 [ProfileWithFrame] =================================');
      // Load backpack items and find active SVGA frames
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎯 [BottomSheet] Fetching CP data for user: ${widget.userId}');
        if (widget.userId != null && widget.userId!.isNotEmpty) {
          // ✅ Fetch CP data using CpProvider instead of ProfileUpdateProvider
          final cpProvider = Provider.of<CpProvider>(context, listen: false);
          cpProvider.fetchCpRankingByUserId(widget.userId!);
          print('🎯 [BottomSheet] fetchCpRankingByUserId called successfully');
        } else {
          print(
            '❌ [BottomSheet] User ID is null or empty, skipping CP data fetch',
          );
        }
        print(
          '🎬 [ProfileWithFrame] PostFrameCallback - Starting to load frame...',
        );
        _loadActiveFrame();

        // ✅ Fetch contribution/charm stats for sender profile
        _fetchContributionStats();
      });
    });
  }

  Map<String, String> _getDateRange(int periodIndex) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    switch (periodIndex) {
      case 0: // Daily
        final today = formatter.format(now);
        return {"start": today, "end": today};
      case 1: // Weekly
        final startOfWeek = now.subtract(const Duration(days: 6));
        return {
          "start": formatter.format(startOfWeek),
          "end": formatter.format(now),
        };
      case 2: // Monthly
        final startOfMonth = DateTime(now.year, now.month - 1, now.day);
        return {
          "start": formatter.format(startOfMonth),
          "end": formatter.format(now),
        };
      default:
        final today = formatter.format(now);
        return {"start": today, "end": today};
    }
  }

  User? _findUserStats(RoomGiftResponse response, int userId) {
    final isSender = _selectedTopTab == 0;
    final room = response.data.room;
    if (room != null) {
      final list = isSender ? room.allSenders.list : room.allReceivers.list;
      for (final user in list) {
        if (user.userId == userId) return user;
      }
    }

    final rooms = response.data.rooms ?? [];
    for (final r in rooms) {
      final list = isSender ? r.allSenders.list : r.allReceivers.list;
      for (final user in list) {
        if (user.userId == userId) return user;
      }
    }

    return null;
  }

  Future<void> _fetchContributionStats() async {
    final userIdStr = widget.userId;
    final userId = int.tryParse(userIdStr ?? '');
    if (userId == null) {
      return;
    }

    setState(() {
      _statsLoading = true;
      _statsError = null;
      _statsUser = null;
    });

    final dateRange = _getDateRange(_selectedPeriod);

    try {
      final response = await ApiManager.fetchRoomStats(
        senderId: _selectedTopTab == 0 ? userId : null,
        receiverId: _selectedTopTab == 1 ? userId : null,
        roomId: int.tryParse(widget.roomId ?? ''),
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );

      final statsUser = _findUserStats(response, userId);

      if (!mounted) return;
      setState(() {
        _statsUser = statsUser;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _statsLoading = false;
      });
    }
  }

  Future<void> _loadActiveFrame() async {
    if (!mounted || _isRoomHeadwearDisposed) {
      print(
        '⚠️ [ProfileWithFrame] Widget disposed or not mounted, skipping frame load',
      );
      return;
    }

    print('📦 [ProfileWithFrame] ========== LOADING ACTIVE FRAME ==========');
    print('📦 [ProfileWithFrame] User ID: ${widget.userId}');

    try {
      List<BackpackItem> activeItems = [];

      // ✅ If userId is provided and valid (not 0), load that user's backpack
      final uid = widget.userId?.trim();
      if (uid != null && uid.isNotEmpty && uid != '0') {
        final userIdInt = int.tryParse(uid);
        if (userIdInt != null && userIdInt != 0) {
          print('📦 [ProfileWithFrame] Loading backpack for user: $userIdInt');
          final response = await ApiManager.getBackpack(userId: userIdInt);

          if (response != null && response.isSuccess) {
            print(
              '📦 [ProfileWithFrame] Backpack response: ${response.totalItems} total, ${response.activeItems} active',
            );
            activeItems = response.items
                .where(
                  (item) =>
                      item.isActive &&
                      item.svgaUrl != null &&
                      item.svgaUrl!.isNotEmpty,
                )
                .toList();
            print(
              '✅ [ProfileWithFrame] Found ${activeItems.length} active items with SVGA for user $userIdInt',
            );
            for (var item in activeItems) {
              print(
                '   - Item: ${item.itemName}, Category: ${item.itemCategory}, SVGA: ${item.svgaUrl}',
              );
            }
          } else {
            print(
              '❌ [ProfileWithFrame] Failed to load backpack for user $userIdInt: ${response?.message}',
            );
          }
        } else {
          print(
            '❌ [ProfileWithFrame] Invalid user ID format: ${widget.userId}',
          );
        }
      } else {
        // ✅ Otherwise, use current user's backpack from StoreProvider
        print(
          '📦 [ProfileWithFrame] Loading current user\'s backpack from StoreProvider',
        );
        final storeProvider = Provider.of<StoreProvider>(
          context,
          listen: false,
        );

        // Load backpack if not already loaded
        if (storeProvider.backpackItems.isEmpty &&
            !storeProvider.isLoadingBackpack) {
          print('📦 [ProfileWithFrame] Backpack empty, loading...');
          final uidForStore = (uid == null || uid.isEmpty || uid == '0')
              ? null
              : uid;
          await storeProvider.loadBackpack(uidForStore);
          // Wait a bit for the state to update
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Get active backpack items with SVGA animations
        activeItems = storeProvider.activeBackpackItems
            .where((item) => item.svgaUrl != null && item.svgaUrl!.isNotEmpty)
            .toList();
        print(
          '✅ [ProfileWithFrame] Found ${activeItems.length} active items with SVGA from StoreProvider',
        );
      }

      if (activeItems.isEmpty) {
        print('📦 [ProfileWithFrame] No active items with SVGA frames');
        if (mounted) {
          setState(() {
            _isRoomHeadwearAnimationVisible = false;
          });
        }
        return;
      }

      // Use the first active item's SVGA (prioritize headwear, then others)
      // You can customize this logic to prioritize certain categories

      var roomHeadWearActiveItem = activeItems.first;

      // Try to find room headwear first
      final roomHeadwear = activeItems
          .where((item) => item.itemCategory.toLowerCase() == 'room_headwear')
          .toList();

      if (roomHeadwear.isEmpty) {
        print('📦 [ProfileWithFrame] No headwaer items with SVGA frames');
        if (mounted) {
          setState(() {
            _isRoomHeadwearAnimationVisible = false;
          });
        }
        return;
      } else {
        roomHeadWearActiveItem = roomHeadwear.first;
      }

      String? roomHeadwearRawUrl = roomHeadWearActiveItem.svgaUrl;

      // Normalize room headwear URL if needed
      if (roomHeadwearRawUrl != null &&
          roomHeadwearRawUrl.contains('api.shaheenapp.com')) {
        _currentRoomHeadwearAnimUrl = roomHeadwearRawUrl.replaceAll(
          'api.shaheenapp.com',
          'shaheenstar.online',
        );
      } else if (roomHeadwearRawUrl != null &&
          roomHeadwearRawUrl.contains('your-domain.com')) {
        _currentRoomHeadwearAnimUrl = roomHeadwearRawUrl.replaceAll(
          'your-domain.com',
          'shaheenstar.online',
        );
      } else {
        _currentRoomHeadwearAnimUrl = roomHeadwearRawUrl;
      }

      // ✅ Preload SVGA in background
      if (_currentRoomHeadwearAnimUrl != null) {
        SvgaCacheManager.load(_currentRoomHeadwearAnimUrl!);
      }
      if (_currentRoomHeadwearAnimUrl == null ||
          _currentRoomHeadwearAnimUrl!.isEmpty) {
        return;
      }

      print(
        '🎬 [ProfileWithFrame] Loading SVGA frame: $_currentRoomHeadwearAnimUrl',
      );

      // Initialize room headwear animation controller
      _animationRoomHeadwearController = SVGAAnimationController(vsync: this);

      if (mounted) {
        setState(() {});
      }

      // Load SVGA animation

      await _loadAndStartRoomHeadwearAnimation();
    } catch (e) {
      print('❌ [ProfileWithFrame] Error loading frame: $e');
    }
  }

  //  Future<void> _loadAndStartRoomHeadwearAnimation() async {
  //   if (_currentRoomHeadwearAnimUrl == null || _currentRoomHeadwearAnimUrl!.isEmpty || _isRoomHeadwearDisposed) {
  //     return;
  //   }

  //   try {
  //     print('📥 [ProfileWithFrame] Loading animation from: $_currentRoomHeadwearAnimUrl');

  //     final animUrl = _currentRoomHeadwearAnimUrl!.toLowerCase();
  //     final isSvga = animUrl.endsWith('.svga') ||
  //                    animUrl.contains('.svga?') ||
  //                    animUrl.contains('.svga&') ||
  //                    (animUrl.contains('svga') && !animUrl.contains('.svg') && !animUrl.endsWith('.svg'));

  //     if (!isSvga) {
  //       print('⚠️ [ProfileWithFrame] Animation is not SVGA format: $animUrl');
  //       return;
  //     }

  //     final videoItem = await SVGAParser.shared.decodeFromURL(_currentRoomHeadwearAnimUrl!);

  //     if (_isRoomHeadwearDisposed || !mounted || _animationRoomHeadwearController == null) {
  //       return;
  //     }

  //     print('✅ [ProfileWithFrame] SVGA file loaded successfully');
  //     _animationRoomHeadwearController!.videoItem = videoItem;

  //     if (mounted && !_isRoomHeadwearDisposed) {
  //       // Start playing animation in loop FIRST

  //       _animationRoomHeadwearController!.repeat();

  //       print('🎬 [ProfileWithFrame] Animation repeat() called');

  //       // Then update state to show the frame
  //       setState(() {
  //         _isRoomHeadwearAnimationVisible = true;
  //       });
  //       print('🎬 [ProfileWithFrame] State updated, isVisible: $_isRoomHeadwearAnimationVisible, controller: ${_animationRoomHeadwearController != null}');
  //     }
  //   } catch (e, stackTrace) {
  //     print('❌ [ProfileWithFrame] Error loading animation: $e');
  //     print('❌ [ProfileWithFrame] Stack trace: $stackTrace');

  //     if (mounted && !_isRoomHeadwearDisposed) {
  //       setState(() {
  //         _isRoomHeadwearAnimationVisible = false;
  //       });
  //     }
  //   }
  //   setState(() {

  //   });
  // }
  Future<void> _loadAndStartRoomHeadwearAnimation() async {
    if (_currentRoomHeadwearAnimUrl == null ||
        _currentRoomHeadwearAnimUrl!.isEmpty ||
        _isRoomHeadwearDisposed ||
        _animationRoomHeadwearController == null) {
      return;
    }

    try {
      print('📥 Loading (cached) SVGA: $_currentRoomHeadwearAnimUrl');

      final movie = await SvgaCacheManager.load(_currentRoomHeadwearAnimUrl!);
      if (movie == null || !mounted || _isRoomHeadwearDisposed) {
        return;
      }

      _animationRoomHeadwearController!.videoItem = movie;
      _animationRoomHeadwearController!.repeat();

      setState(() {
        _isRoomHeadwearAnimationVisible = true;
      });

      print('✅ SVGA Loaded & Playing');
    } catch (e, stack) {
      print('❌ Error decoding SVGA: $e');
      print(stack);

      if (mounted) {
        setState(() {
          _isRoomHeadwearAnimationVisible = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isRoomHeadwearDisposed = true;

    _animationRoomHeadwearController?.dispose();
    super.dispose();
  }

  String? _normalizeProfileUrl(String? profileUrl) {
    if (profileUrl == null || profileUrl.isEmpty) {
      return null;
    }

    // If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }

    // Check for local file paths
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.contains('cache')) {
      return profileUrl; // Return local path as-is
    }

    // Check if it's a relative server path
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/')) {
      String cleanPath = profileUrl.startsWith('/')
          ? profileUrl.substring(1)
          : profileUrl;
      return 'https://shaheenstar.online/$cleanPath';
    }

    return null;
  }

  ImageProvider _resolveProfileImage(String? profileUrl) {
    final normalized = _normalizeProfileUrl(profileUrl);
    if (normalized == null || normalized.isEmpty) {
      return const AssetImage('assets/images/person.png');
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }

    if (normalized.startsWith('/data/') ||
        normalized.startsWith('/storage/') ||
        normalized.contains('cache')) {
      return FileImage(File(normalized));
    }

    return const AssetImage('assets/images/person.png');
  }

  Widget _buildTagBadge(String tag) {
    return SizedBox(
      width: 70,
      height: 28,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AppImage.asset(
            'assets/images/tag.png',
            width: 70,
            height: 28,
            fit: BoxFit.contain,
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                tag,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Check if user is CP user from CpProvider
    return Consumer<CpProvider>(
      builder: (context, cpProvider, _) {
        final isCpUser =
            cpProvider.users.isNotEmpty && cpProvider.users[0].cpUser != null;

        print('🔍 [Build] isCpUser: $isCpUser');
        print('🔍 [Build] cpProvider.users.length: ${cpProvider.users.length}');

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              // ✅ CP User: Use gradient background, Normal User: White background
              color: isCpUser ? null : Colors.white,
              gradient: isCpUser
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF2E0249), // Dark Purple
                        Color(0xFF570A57), // Purple
                      ],
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 150),
                // ✅ Profile Picture Section - Different layout for CP users
                isCpUser
                    ? Consumer<CpProvider>(
                        builder: (context, cpProvider, _) {
                          final hasCp =
                              cpProvider.users.isNotEmpty &&
                              cpProvider.users[0].cpUser != null;
                          final cpPartner = hasCp
                              ? cpProvider.users[0].cpUser
                              : null;

                          print('🔍 [BottomSheet] CP Data Debug:');
                          print(
                            '   cpProvider.users.length: ${cpProvider.users.length}',
                          );
                          print('   hasCp: $hasCp');
                          if (hasCp) {
                            print('   CP Partner: ${cpPartner!.name}');
                            print(
                              '   CP Partner Profile: ${cpPartner.profileUrl}',
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Left Profile Picture
                                  GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DetailedProfileScreen(
                                            userId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: Builder(
                                          builder: (context) {
                                            final normalized =
                                                _normalizeProfileUrl(
                                                  widget.profileUrl,
                                                );
                                            if (normalized == null ||
                                                normalized.isEmpty) {
                                              return AppImage.asset(
                                                'assets/images/person.png',
                                                width: 88,
                                                height: 88,
                                                fit: BoxFit.cover,
                                              );
                                            }

                                            if (normalized.startsWith('http')) {
                                              return CachedNetworkImage(
                                                imageUrl: normalized,
                                                width: 88,
                                                height: 88,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      width: 88,
                                                      height: 88,
                                                      color: Colors.grey[200],
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => AppImage.asset(
                                                      'assets/images/person.png',
                                                      width: 88,
                                                      height: 88,
                                                      fit: BoxFit.cover,
                                                    ),
                                              );
                                            }

                                            return Image.file(
                                              File(normalized),
                                              width: 88,
                                              height: 88,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Icon Between Users
                                  AppImage.asset(
                                    'assets/icons/icon_between_users.png',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 12),
                                  // Right Profile Picture (CP Partner)
                                  GestureDetector(
                                    onTap: () async {
                                      if (hasCp && cpPartner != null) {
                                        final partnerId = cpPartner.id
                                            .toString();
                                        Navigator.pop(context);
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetailedProfileScreen(
                                                  userId: partnerId,
                                                  screen: 'cp',
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: Builder(
                                          builder: (context) {
                                            if (!hasCp || cpPartner == null) {
                                              return AppImage.asset(
                                                'assets/images/person.png',
                                                width: 88,
                                                height: 88,
                                                fit: BoxFit.cover,
                                              );
                                            }

                                            final partnerProfile =
                                                cpPartner.profileUrl;
                                            print(
                                              '🔍 [BottomSheet] Partner Profile URL: $partnerProfile',
                                            );

                                            final normalized = cpProvider
                                                .normalizeRoomProfileUrl(
                                                  partnerProfile,
                                                );
                                            print(
                                              '🔍 [BottomSheet] Normalized URL: $normalized',
                                            );

                                            if (normalized ==
                                                'assets/images/person.png') {
                                              return AppImage.asset(
                                                'assets/images/person.png',
                                                width: 88,
                                                height: 88,
                                                fit: BoxFit.cover,
                                              );
                                            }

                                            return CachedNetworkImage(
                                              imageUrl: normalized,
                                              width: 88,
                                              height: 88,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    width: 88,
                                                    height: 88,
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                              errorWidget: (context, url, error) {
                                                print(
                                                  '❌ [BottomSheet] Error loading partner image: $error',
                                                );
                                                return AppImage.asset(
                                                  'assets/images/person.png',
                                                  width: 88,
                                                  height: 88,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      )
                    : GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailedProfileScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: Builder(
                            builder: (context) {
                              final normalized = _normalizeProfileUrl(
                                widget.profileUrl,
                              );
                              if (normalized == null || normalized.isEmpty) {
                                return AppImage.asset(
                                  'assets/images/person.png',
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                );
                              }

                              if (normalized.startsWith('http')) {
                                return CachedNetworkImage(
                                  imageUrl: normalized,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey[200],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      AppImage.asset(
                                        'assets/images/person.png',
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                      ),
                                );
                              }

                              return Image.file(
                                File(normalized),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailedProfileScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.mic, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    const Icon(Icons.cake, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4FA0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Q 21',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CountryUtils.getCountryFlag(
                      userCountry,
                      width: 18,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Consumer<ProfileUpdateProvider>(
                      builder: (context, provider, _) {
                        final tags = provider.tags;
                        final leftTag = tags.isNotEmpty ? tags.first : null;
                        final rightTag = tags.length > 1 ? tags[1] : null;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leftTag != null) ...[
                              _buildTagBadge(leftTag.toString()),
                              const SizedBox(width: 6),
                            ],
                            UserIdDisplay(
                              userId: displayUserId,
                              isIdChanged: provider.isIdChanged,
                            ),
                            if (rightTag != null) ...[
                              const SizedBox(width: 6),
                              _buildTagBadge(rightTag.toString()),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                // Wealth Level Badge
                Consumer<ProfileUpdateProvider>(
                  builder: (context, provider, _) {
                    if (provider.wealthLevel == null)
                      return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Container(
                          height: 65,
                          width: 140,
                          child: Stack(
                            alignment: Alignment.center,
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
                    );
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.emoji_events, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('0', style: TextStyle(color: Colors.black54)),
                      SizedBox(width: 10),
                      Icon(Icons.shield, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('0', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<UserFollowProvider>(
                        builder: (context, followProvider, _) {
                          final targetUserId = int.tryParse(
                            widget.userId ?? '',
                          );
                          if (targetUserId == null || isCurrentUser) {
                            return const SizedBox(width: 90);
                          }

                          return FollowButton(
                            targetUserId: targetUserId,
                            initialIsFollowing: followProvider.isFollowing(
                              targetUserId,
                            ),
                            width: 90,
                            height: 32,
                            fontSize: 11,
                          );
                        },
                      ),
                      _buildProfileActionAsset(
                        assetPath:
                            'assets/icons/Screenshot_2026-01-27_123551-removebg-preview_2.png',
                        label: '@',
                      ),
                      _buildProfileActionAsset(
                        assetPath:
                            'assets/icons/Screenshot_2026-01-27_123551-removebg-preview_3.png',
                        label: 'Say hi',
                      ),
                      _buildProfileActionAsset(
                        assetPath:
                            'assets/icons/Screenshot_2026-01-27_123551-removebg-preview_4.png',
                        label: 'Gift',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ); // Consumer<CpProvider>
  }

  Widget _buildProfileActionAsset({
    required String assetPath,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F3F3),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AppImage.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTopTab(String title, int index) {
    final isSelected = _selectedTopTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTopTab = index);
        _fetchContributionStats();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD54F) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = index);
        _fetchContributionStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD54F)
              : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
