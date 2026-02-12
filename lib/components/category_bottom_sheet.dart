import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/gift_provider.dart';
import 'package:shaheen_star_app/controller/provider/seat_provider.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/gift_web_socket_service.dart';
import 'package:shaheen_star_app/controller/provider/broadcast_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';

class CategoryBottomSheet extends StatefulWidget {
  final int? receiverId;
  final int? roomId;
  final int? senderId;
  final double? userBalance;

  const CategoryBottomSheet({
    super.key,
    this.receiverId,
    this.roomId,
    this.senderId,
    this.userBalance,
  });

  @override
  State<CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<CategoryBottomSheet>
    with TickerProviderStateMixin {
  int selectedCategoryIndex = 0; // Start with first API category selected
  late AnimationController _animationController;
  double _goldCoins = 0.0;
  bool _isLoadingBalance = false;
  final Set<int> _selectedReceiverIds =
      {}; // Track multiple selected receivers (always allow multiple)
  GiftProvider? _giftProvider; // Store provider reference for listener

  // Dynamic categories from API - will be populated after gifts are fetched
  List<Map<String, dynamic>> mainCategories = [];

  /// Build categories dynamically from API gifts
  List<Map<String, dynamic>> _buildCategoriesFromAPI(
    List<String> apiCategories,
  ) {
    final categories = <Map<String, dynamic>>[];
    print("~~~~~~~~~~~~~~~~Categories~~~~~~~~~~~~~~~~~~~~~~~");
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    print(categories);
    // NOTE: Removed 'All' category - only show API-provided categories
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    print(categories);
    // Add each category from API
    for (final category in apiCategories) {
      final displayName = _getCategoryDisplayName(category);
      categories.add({
        'name': displayName,
        'icon': _getCategoryIcon(category),
        'color': Colors.yellow,
        'category': category.toLowerCase(),
      });
    }
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    print(categories);

    return categories;
  }

  /// Convert category name to display name
  String _getCategoryDisplayName(String category) {
    final lowerCategory = category.toLowerCase();
    switch (lowerCategory) {
      case 'normal':
        return 'Normal';
      case 'lucky':
        return 'Lucky';
      case 'tiktok':
        return 'TikTok';
      case 'special':
        return 'Special';
      case 'vip':
        return 'VIP';
      case 'country':
        return 'Country';
      case 'unique':
        return 'Unique';
      default:
        // Capitalize first letter and return
        return category.isEmpty
            ? category
            : category[0].toUpperCase() + category.substring(1).toLowerCase();
    }
  }

  /// Get icon for category
  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    switch (lowerCategory) {
      case 'normal':
        return Icons.card_giftcard;
      case 'lucky':
        return Icons.stars;
      case 'tiktok':
        return Icons.video_library;
      case 'special':
        return Icons.celebration;
      case 'vip':
        return Icons.diamond;
      case 'country':
        return Icons.flag;
      case 'unique':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // Initialize selected receiver with widget receiverId
    if (widget.receiverId != null) {
      _selectedReceiverIds.add(widget.receiverId!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoldCoinsBalance();
      final giftProvider = Provider.of<GiftProvider>(context, listen: false);

      _giftProvider = giftProvider;

      // ✅ Fetch gifts via WebSocket when bottom sheet opens
      print("🎁 [CategoryBottomSheet] Requesting gifts via WebSocket...");
      giftProvider.fetchAllGifts().then((_) {
        print(
          "~~~~~~~~~~~~~~~~~~~~~~~~Fetch Gifts~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        );
        for (int i = 0; i < giftProvider.allGifts.length; i++) {
          print(giftProvider.allGifts[i].category);
        }
        // After gifts are fetched, build categories from API
        _updateCategoriesFromAPI(giftProvider);
      });

      // Do NOT set initial category here; we'll set it after categories are built
    });
  }

  /// Update categories from API after gifts are fetched
  void _updateCategoriesFromAPI(GiftProvider giftProvider) {
    if (mounted) {
      setState(() {
        final apiCategories = giftProvider.availableCategories;
        print(
          "📋 [CategoryBottomSheet] Available categories from API: $apiCategories",
        );
        print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        print(apiCategories);
        mainCategories = _buildCategoriesFromAPI(apiCategories);
        print(
          "📋 [CategoryBottomSheet] Built ${mainCategories.length} navigation tabs",
        );

        // Set initial selected category to the first API category (if available)
        if (mainCategories.isNotEmpty) {
          selectedCategoryIndex = 0;
          final initialCategory = mainCategories[0]['category'];
          giftProvider.setSelectedCategory(initialCategory);
        }
      });
    }
  }

  Future<void> _loadGoldCoinsBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Handle user_id as both int and String (it can be stored either way)
      String userId = '';
      if (prefs.containsKey('user_id')) {
        final userIdValue = prefs.get('user_id');
        if (userIdValue is int) {
          userId = userIdValue.toString();
        } else if (userIdValue is String) {
          userId = userIdValue;
        }
      }

      if (userId.isEmpty) {
        _goldCoins = 0.0;
        setState(() {
          _isLoadingBalance = false;
        });
        return;
      }

      // ✅ Fetch balance directly from WebSocket (no cached fallback)
      print("💰 [CategoryBottomSheet] Fetching user balance via WebSocket...");
      _giftProvider = Provider.of<GiftProvider>(context, listen: false);

      // ✅ Listen for balance updates from WebSocket
      if (_giftProvider != null) {
        _giftProvider!.addListener(_updateBalanceFromProvider);
      }

      // Wait for WebSocket balance response
      await _giftProvider!.fetchUserBalance();

      // ✅ Use WebSocket balance data only (always use WebSocket value, even if 0)
      final websocketBalance = _giftProvider!.userBalance;
      _goldCoins = websocketBalance;
      print("✅ [CategoryBottomSheet] Using WebSocket balance: $_goldCoins");

      _giftProvider!.setUserBalance(_goldCoins);

      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      print("❌ Error loading gold coins balance: $e");
      _goldCoins = 0.0;
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  void _updateBalanceFromProvider() {
    if (_giftProvider != null) {
      final newBalance = _giftProvider!.userBalance;
      if (newBalance != _goldCoins && mounted) {
        setState(() {
          _goldCoins = newBalance;
          print(
            "✅ [CategoryBottomSheet] Balance updated from WebSocket: $_goldCoins",
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Remove listener
    if (_giftProvider != null) {
      _giftProvider!.removeListener(_updateBalanceFromProvider);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 172, 155, 57),
            const Color(0xFF1A0B2E), // Darker purple
            Colors.grey[900]!,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Main Category Navigation Tabs
          _buildNavigationTabs(),

          const SizedBox(height: 5),

          // ✅ Users List - Show when gift is selected (if no receiver pre-selected)
          Consumer<GiftProvider>(
            builder: (context, giftProvider, child) {
              final shouldShowUserList =
                  giftProvider.selectedGift != null &&
                  widget.receiverId == null;
              //               return  GestureDetector(child:Text("ccec"),onTap: (){

              // //                 int normal=0,lucky=0,tiktok=0,vip=0;
              //                 for(int i=0;i<giftProvider.value.length;i++){
              //                   print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
              //                      print(giftProvider.value[i].category);
              //                       print(giftProvider.value[i].name);
              //                        print(giftProvider.value[i].description);
              //                   print(giftProvider.value[i].image);
              //                      print(giftProvider.value[i].animationFile);
              //                 }
              // //                   if(giftProvider.value[i].category=="normal"){
              // // normal+=1;
              // //                   }else if(giftProvider.value[i].category=="lucky"){
              // // lucky+=1;
              // //                   }
              // //                   else if(giftProvider.value[i].category=="tiktok"){
              // //                     tiktok+=1;
              // //                   }
              // //                   else if(giftProvider.value[i].category=="vip"){
              // //                     vip+=1;
              // //                   }

              // //                 }
              // //                   print("Normal"+ normal.toString());
              // //                   print("Lucky"+lucky.toString());
              // //                   print("Tiktok"+tiktok.toString());
              // //                   print("Vip"+vip.toString());

              //          },);
              if (shouldShowUserList) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedReceiverIds.isEmpty
                                  ? 'Select users to send gift'
                                  : 'Select users (${_selectedReceiverIds.length} selected)',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ✅ "Select All" Button
                          GestureDetector(
                            onTap: () {
                              final seatProvider = Provider.of<SeatProvider>(
                                context,
                                listen: false,
                              );
                              final allUserIds = seatProvider.seats
                                  .where(
                                    (seat) =>
                                        seat.isOccupied && seat.userId != null,
                                  )
                                  .map((seat) => int.tryParse(seat.userId!))
                                  .where((id) => id != null)
                                  .cast<int>()
                                  .toList();

                              setState(() {
                                // Toggle: If all relevant users are selected, deselect them. Otherwise, select all.
                                // We check if the set of selected IDs contains all available IDs.
                                bool allSelected =
                                    allUserIds.isNotEmpty &&
                                    allUserIds.every(
                                      (id) => _selectedReceiverIds.contains(id),
                                    );

                                if (allSelected) {
                                  _selectedReceiverIds.clear();
                                } else {
                                  _selectedReceiverIds.clear();
                                  _selectedReceiverIds.addAll(allUserIds);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFD700,
                                ).withOpacity(0.2), // Gold with opacity
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.select_all,
                                    color: Color(0xFFFFD700),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Gift to all users",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFFD700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildUsersList(),
                    const SizedBox(height: 8),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),

          // Content Area - All tabs show gifts filtered by category
          Expanded(child: _buildGiftContent()),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  // Navigation Tabs
  Widget _buildNavigationTabs() {
    return Consumer<GiftProvider>(
      builder: (context, giftProvider, child) {
        // Update categories if gifts are loaded and categories are empty
        if (mainCategories.isEmpty && giftProvider.allGifts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCategoriesFromAPI(giftProvider);
          });
        }

        // Show loading or empty state if no categories yet
        if (mainCategories.isEmpty) {
          return Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Center(
              child: Text(
                'Loading categories...',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ),
          );
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mainCategories.length,
            itemBuilder: (context, index) {
              return _buildMainCategoryTab(mainCategories[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildMainCategoryTab(Map<String, dynamic> category, int index) {
    bool isSelected = selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryIndex = index;
        });
        _animationController.reset();
        _animationController.forward();

        // Update gift provider category when main tab changes
        final giftProvider = Provider.of<GiftProvider>(context, listen: false);
        // null category means show all gifts (for "Gift" tab)
        giftProvider.setSelectedCategory(category['category']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category['name'],
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGiftContent() {
    return Consumer<GiftProvider>(
      builder: (context, giftProvider, child) {
        if (giftProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading gifts...',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (giftProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                const SizedBox(height: 16),
                Text(
                  giftProvider.errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allGifts = giftProvider.giftsForSelectedCategory;

        // // ✅ Filter to show only SVGA gifts
        // final gifts = allGifts.where((gift) {
        //   return _isSvgaGift(gift);
        // }).toList();

        print("🎁 [CategoryBottomSheet] ===== BUILDING GIFT CONTENT =====");
        print(
          "🎁 [CategoryBottomSheet] Selected category index: $selectedCategoryIndex",
        );
        print(
          "🎁 [CategoryBottomSheet] Total gifts in provider: ${giftProvider.allGifts.length}",
        );
        print(
          "🎁 [CategoryBottomSheet] Selected category: ${giftProvider.selectedCategory}",
        );
        print(
          "🎁 [CategoryBottomSheet] All gifts for selected category: ${allGifts.length}",
        );
        // print("🎁 [CategoryBottomSheet] SVGA gifts only: ${gifts.length}");
        // print("🎁 [CategoryBottomSheet] SVGA Gift IDs: ${gifts.map((g) => g.id).toList()}");

        // Get selected category from main categories
        final selectedMainCategory =
            mainCategories.isNotEmpty &&
                selectedCategoryIndex < mainCategories.length
            ? mainCategories[selectedCategoryIndex]
            : null;
        final mainCategoryValue = selectedMainCategory?['category'];
        print(
          "🎁 [CategoryBottomSheet] Main category value: $mainCategoryValue",
        );

        if (allGifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, color: Colors.grey[600], size: 64),
                const SizedBox(height: 16),
                Text(
                  'No gifts available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: RepaintBoundary(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.60,
              ),
              itemCount: allGifts.length,
              itemBuilder: (context, index) {
                final gift = allGifts[index];
                final isSelected = giftProvider.selectedGift?.id == gift.id;
                // Get category info from mainCategories or use default
                final categoryInfo =
                    mainCategories.isNotEmpty &&
                        selectedCategoryIndex < mainCategories.length
                    ? mainCategories[selectedCategoryIndex]
                    : {'name': 'All', 'category': null, 'color': Colors.yellow};
                return _buildGiftCard(gift, isSelected, categoryInfo);
              },
            ),
          ),
        );
      },
    );
  }

  /// Build gift media widget - shows actual gift content (static image or SVGA preview)
  /// ✅ Animations will only play on room screen AFTER gift is sent
  /// ✅ For SVGA gifts: Show static image if available, otherwise show SVGA file as static preview
  Widget _buildGiftMedia(GiftModel gift, Map<String, dynamic> category) {
    print("🎬 [CategoryBottomSheet] ===== BUILDING GIFT MEDIA =====");
    print("🎬 [CategoryBottomSheet] Gift: ${gift.name} (ID: ${gift.id})");
    print("🎬 [CategoryBottomSheet] Image URL: ${gift.image}");
    print("🎬 [CategoryBottomSheet] Animation URL: ${gift.animationFile}");

    // ✅ Priority 1: Show static gift image if available
    if (gift.image != null && gift.image!.isNotEmpty) {
      final imageUrl = gift.image!;

      // ✅ Check if it's a local file path (don't normalize local paths)
      bool isLocalPath =
          imageUrl.startsWith('/data/') ||
          imageUrl.startsWith('/storage/') ||
          imageUrl.startsWith('/private/') ||
          imageUrl.startsWith('/var/') ||
          imageUrl.startsWith('/tmp/') ||
          imageUrl.contains('/cache/') ||
          imageUrl.contains('cache/') ||
          imageUrl.contains('/com.example.') ||
          imageUrl.contains('/com.') ||
          imageUrl.startsWith('file://') ||
          imageUrl.contains('/data/user/');

      // Normalize image URL if needed (only for server paths, not local files)
      String normalizedImageUrl = imageUrl;
      if (!isLocalPath &&
          !imageUrl.startsWith('http://') &&
          !imageUrl.startsWith('https://')) {
        normalizedImageUrl = 'https://shaheenstar.online/$imageUrl';
      } else if (isLocalPath) {
        print(
          "⚠️ [CategoryBottomSheet] Gift image is local file path, cannot load as network URL: $imageUrl",
        );
        // Return placeholder for local paths
        return AppImage.asset('assets/images/person.png', fit: BoxFit.contain);
      }

      print(
        "🎨 [CategoryBottomSheet] Showing static gift image: $normalizedImageUrl",
      );

      try {
        return CachedNetworkImage(
          imageUrl: normalizedImageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          errorWidget: (context, url, error) {
            print("❌ [CategoryBottomSheet] Error loading gift image: $error");
            // If static image fails and it's SVGA, show SVGA preview
            if (_isSvgaGift(gift)) {
              print("image is svga");
              return _buildSvgaPreview(gift);
            }

            print("image is mp4");
            // Return empty container instead of fallback icon
            return const SizedBox.shrink();
          },
        );
      } catch (e) {
        print("❌ [CategoryBottomSheet] Error displaying gift image: $e");
        // If static image fails and it's SVGA, show SVGA preview
        if (_isSvgaGift(gift)) {
          print("image is svga");
          return _buildSvgaPreview(gift);
        }
        print("image is mp4");
        // Return empty container instead of fallback icon
        return const SizedBox.shrink();
      }
    }

    // ✅ Priority 2: For SVGA gifts without static image, show SVGA file as static preview
    if (_isSvgaGift(gift) &&
        gift.animationFile != null &&
        gift.animationFile!.isNotEmpty) {
      print("image is svga");
      return _buildSvgaPreview(gift);
    }
    print("image is mp4");

    // ✅ No fallback - return empty container if gift has no image or animation
    return const SizedBox.shrink();
  }

  /// Build SVGA preview - shows the actual SVGA file as a static preview (first frame)
  /// This shows the actual gift content, not a fallback icon
  Widget _buildSvgaPreview(GiftModel gift) {
    if (gift.animationFile == null || gift.animationFile!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Normalize SVGA URL
    String svgaUrl = gift.animationFile!;
    if (!svgaUrl.startsWith('http://') && !svgaUrl.startsWith('https://')) {
      svgaUrl = 'https://shaheenstar.online/$svgaUrl';
    }

    print("🎨 [CategoryBottomSheet] Showing SVGA preview: $svgaUrl");

    try {
      // Show SVGA file as a simple preview (auto-plays and loops)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SVGASimpleImage(
          resUrl: svgaUrl,
          // Note: SVGASimpleImage auto-plays and loops, which is fine for preview
          // The full animation will only play on room screen after gift is sent
        ),
      );
    } catch (e) {
      print("❌ [CategoryBottomSheet] Error displaying SVGA preview: $e");
      // Return empty container instead of fallback icon
      return const SizedBox.shrink();
    }
  }

  Widget _buildGiftCard(
    GiftModel gift,
    bool isSelected,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap: () {
        // ✅ Now gifts are selected directly - animation will play AFTER sending
        Provider.of<GiftProvider>(context, listen: false).selectGift(gift);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(
          isSelected ? 2 : 0,
        ), // Add padding when selected to show border
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.amber, width: 1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gift Image/Animation
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildGiftMedia(gift, category),
              ),
            ),
            const SizedBox(height: 4),
            // Gift Name
            Text(
              gift.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Price with Gold Coin Image
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppImage.asset(
                  'assets/images/coinsicon.png',
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 2),
                Text(
                  gift.formattedPrice,
                  style: GoogleFonts.poppins(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Consumer<GiftProvider>(
      builder: (context, giftProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.5),
            border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Currency + Recharge
              Row(
                children: [
                  // Gold Coins Display with Coin Image
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppImage.asset(
                        'assets/images/coinsicon.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      _isLoadingBalance
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.amber,
                                ),
                              ),
                            )
                          : Text(
                              _formatNumber(_goldCoins),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Recharge Button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Recharge functionality coming soon'),
                          backgroundColor: AppColors.primaryColor,
                        ),
                      );
                    },
                    child: Text(
                      'Recharge >',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              // Right side: Quantity Selector + Send Button
              Row(
                children: [
                  // Quantity Selector (only show when gift is selected)
                  if (giftProvider.selectedGift != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => giftProvider.decreaseQuantity(),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${giftProvider.giftQuantity}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => giftProvider.increaseQuantity(),
                            child: const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Send Button (yellow)
                  GestureDetector(
                    onTap: () async {
                      if (giftProvider.selectedGift == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select a gift'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (widget.senderId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please login to send gifts'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (widget.roomId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Room information missing'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ✅ Get receivers - always allow multiple selection
                      final receivers = _selectedReceiverIds.isNotEmpty
                          ? _selectedReceiverIds.toList()
                          : (widget.receiverId != null
                                ? [widget.receiverId!]
                                : []);

                      if (receivers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select at least one user from the list above to send gift to.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      final isMultipleReceivers = receivers.length > 1;

                      // ✅ Allow self-gifting - users can send gifts to themselves
                      if (receivers.contains(widget.senderId)) {
                        print(
                          '💝 Self-gift detected - allowing user to send gift to their own seat',
                        );
                        print('   - Sender ID: ${widget.senderId}');
                        print('   - Receiver IDs: $receivers');
                      }

                      print('🎁 ========== SENDING GIFT ==========');
                      print('   - Sender ID: ${widget.senderId}');
                      print(
                        '   - Receiver IDs: $receivers (${isMultipleReceivers ? 'Multiple' : 'Single'})',
                      );
                      print('   - Room ID: ${widget.roomId}');
                      print('   - Gift: ${giftProvider.selectedGift?.name}');
                      print('   - Gift ID: ${giftProvider.selectedGift?.id}');
                      print(
                        '   - Gift Price: ${giftProvider.selectedGift?.price}',
                      );
                      print('   - Quantity: ${giftProvider.giftQuantity}');
                      print(
                        '   - Total Value: ${giftProvider.selectedGift!.price * giftProvider.giftQuantity}',
                      );
                      print('🎁 ====================================');

                      // ✅ For multiple receivers, send gift to each receiver individually
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isMultipleReceivers
                                      ? 'Sending gift to ${receivers.length} users...'
                                      : 'Sending gift...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      // ✅ Send gift to each receiver
                      bool allSuccess = true;
                      int successCount = 0;

                      // Track seats for combo
                      Map<int, int?> comboReceiverSeats = {};
                      int? comboSenderSeat;

                      // ✅ Capture selected gift BEFORE sending, because sendGift clears it on success
                      final giftToSubmit = giftProvider.selectedGift;

                      for (int i = 0; i < receivers.length; i++) {
                        final currentReceiverId = receivers[i];
                        print(
                          '🎁 Sending gift ${i + 1}/${receivers.length} to receiver: $currentReceiverId',
                        );

                        // ✅ Find seat number for current receiver
                        int? seatNumber;
                        int? senderSeatNumber;
                        try {
                          final seatProvider = Provider.of<SeatProvider>(
                            context,
                            listen: false,
                          );

                          // Find receiver's seat
                          try {
                            final receiverSeat = seatProvider.seats.firstWhere(
                              (seat) =>
                                  seat.userId != null &&
                                  int.tryParse(seat.userId!) ==
                                      currentReceiverId &&
                                  seat.isOccupied,
                            );
                            seatNumber = receiverSeat.seatNumber;
                            comboReceiverSeats[currentReceiverId] =
                                seatNumber; // Store for combo
                            print(
                              '🎁 Found receiver $currentReceiverId on seat: $seatNumber',
                            );
                          } catch (e) {
                            print(
                              '⚠️ Could not find seat number for receiver $currentReceiverId: $e',
                            );
                            seatNumber = null;
                          }

                          // ✅ Find sender's seat number
                          try {
                            final senderSeat = seatProvider.seats.firstWhere(
                              (seat) =>
                                  seat.userId != null &&
                                  int.tryParse(seat.userId!) ==
                                      widget.senderId &&
                                  seat.isOccupied,
                            );
                            senderSeatNumber = senderSeat.seatNumber;
                            comboSenderSeat =
                                senderSeatNumber; // Store for combo
                            print('🎁 Found sender on seat: $senderSeatNumber');
                          } catch (e) {
                            print('⚠️ Could not find sender seat number: $e');
                            senderSeatNumber = null;
                          }
                        } catch (e) {
                          print('⚠️ Error finding seats: $e');
                        }

                        // ✅ Send gift to current receiver
                        final success = await giftProvider.sendGift(
                          senderId: widget.senderId!,
                          receiverId: currentReceiverId,
                          roomId: widget.roomId!,
                          seatNumber: seatNumber,
                          senderSeatNumber: senderSeatNumber,
                        );

                        if (success) {
                          successCount++;
                          print(
                            '✅ Gift sent successfully to receiver $currentReceiverId',
                          );
                          // If this gift is in the 'lucky' category, call the lucky addGiftExp API
                          try {
                            final selectedGift = giftProvider.selectedGift;
                            if (selectedGift != null &&
                                selectedGift.category == 'lucky') {
                              final double giftPrice =
                                  selectedGift.price *
                                  giftProvider.giftQuantity;
                              final resp = await ApiManager.addGiftExp(
                                senderId: widget.senderId!,
                                receiverId: currentReceiverId,
                                giftPrice: giftPrice,
                                isLuckyGift: true,
                              );
                              print(
                                '🍀 addGiftExp response for receiver $currentReceiverId: $resp',
                              );
                              // Note: Lucky spin/deduction is already done by sendGift (via lucky_gift_api).
                              // No need to call triggerLuckyGift again - would cause double deduction.
                            }
                          } catch (e) {
                            print(
                              '⚠️ addGiftExp API call failed for receiver $currentReceiverId: $e',
                            );
                          }
                        } else {
                          allSuccess = false;
                          print(
                            '❌ Failed to send gift to receiver $currentReceiverId',
                          );
                        }

                        // ✅ Small delay between sends to avoid overwhelming the server
                        if (i < receivers.length - 1) {
                          await Future.delayed(Duration(milliseconds: 300));
                        }
                      }

                      if (!context.mounted) return;

                      // Hide loading dialog
                      Navigator.of(context).pop();

                      if (allSuccess || successCount > 0) {
                        // ✅ At least some gifts were sent successfully
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isMultipleReceivers
                                        ? 'Gift sent to $successCount/${receivers.length} users successfully!'
                                        : 'Gift sent successfully!',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // ✅ Local Lucky banner to ensure immediate display; result event will update coins
                        if (mounted &&
                            context.mounted &&
                            giftToSubmit != null) {
                          final cat = giftToSubmit.category.toLowerCase();
                          final totalCoins =
                              giftToSubmit.price * giftProvider.giftQuantity;
                          if (cat.contains('lucky')) {
                            /* 
                            // 🔇 LOCAL BROADCAST DISABLED 
                            // Wait for the server response (with win details) to trigger the banner via WebSocket
                            // logic in room_screen.dart -> _handleGiftSentEvent
                            */
                          }
                        }

                        // ✅ Start Combo Mode if gift sent successfully
                        if (mounted && context.mounted) {
                          final giftProvider = Provider.of<GiftProvider>(
                            context,
                            listen: false,
                          );
                          // USE THE CAPTURED GIFT HERE
                          if (giftToSubmit != null) {
                            // ✅ Check if it's a Lucky gift before starting combo
                            // Check both the gift category and the currently selected tab to be robust
                            final giftCategory = giftToSubmit.category
                                .toLowerCase();
                            final tabCategory =
                                giftProvider.selectedCategory?.toLowerCase() ??
                                '';

                            // Relaxed check: if explicit category is 'lucky' OR user is on 'lucky' tab
                            // Also includes 'svga' as often lucky gifts are SVGA
                            final isLucky =
                                giftCategory.contains('lucky') ||
                                tabCategory.contains('lucky');

                            print(
                              '🔍 [CategoryBottomSheet] Combo Check - Gift Cat: "$giftCategory", Tab: "$tabCategory", IsLucky: $isLucky',
                            );

                            if (isLucky) {
                              print(
                                '🍀 [CategoryBottomSheet] Starting Combo for Lucky Gift: ${giftToSubmit.name}',
                              );
                              giftProvider.startCombo(
                                gift: giftToSubmit,
                                receiverIds: receivers.cast<int>().toList(),
                                roomId: widget.roomId ?? 0,
                                receiverSeats: comboReceiverSeats,
                                senderSeat: comboSenderSeat,
                              );
                            } else {
                              print(
                                'ℹ️ [CategoryBottomSheet] Combo skipped - Not a lucky gift',
                              );
                            }
                          }
                        }

                        // ✅ Close bottom sheet after short delay
                        Future.delayed(Duration(milliseconds: 300), () {
                          if (mounted && context.mounted) {
                            Navigator.of(context, rootNavigator: false).pop();
                            print('✅ CategoryBottomSheet closed');
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    giftProvider.errorMessage ??
                                        'Failed to send gift. Please try again.',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      return; // ✅ Exit early - we've handled sending to all receivers
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Send',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  /// Build horizontal list of users in the room
  Widget _buildUsersList() {
    return Consumer<SeatProvider>(
      builder: (context, seatProvider, child) {
        // Get all occupied seats (users in the room)
        final occupiedSeats = seatProvider.seats
            .where((seat) => seat.isOccupied && seat.userId != null)
            .toList();

        if (occupiedSeats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: occupiedSeats.length,
            itemBuilder: (context, index) {
              final seat = occupiedSeats[index];
              final userId = int.tryParse(seat.userId ?? '');
              final isSelected = _selectedReceiverIds.contains(userId);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    // ✅ Always allow multiple selection - toggle selection on tap
                    if (_selectedReceiverIds.contains(userId)) {
                      _selectedReceiverIds.remove(userId);
                    } else {
                      if (userId != null) {
                        _selectedReceiverIds.add(userId);
                      }
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Avatar with selection badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amber
                                    : Colors.grey[700]!,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  seat.profileUrl != null &&
                                      seat.profileUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: seat.profileUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryColor,
                                                ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[800],
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.grey[400],
                                              size: 30,
                                            ),
                                          ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      // User Name
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 45,
                        child: Text(
                          seat.userName ?? seat.username ?? 'User',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Check if gift is SVGA format
  bool _isSvgaGift(GiftModel gift) {
    if (!gift.hasAnimation ||
        gift.animationFile == null ||
        gift.animationFile!.isEmpty) {
      return false;
    }

    final animUrl = gift.animationFile!.toLowerCase();
    final isSvga =
        animUrl.endsWith('.svga') ||
        animUrl.contains('.svga?') ||
        animUrl.contains('.svga&') ||
        (animUrl.contains('svga') &&
            !animUrl.contains('.svg') &&
            !animUrl.endsWith('.svg'));

    print("🎨 [CategoryBottomSheet] Checking if gift is SVGA:");
    print("   - Gift: ${gift.name}");
    print("   - Animation URL: ${gift.animationFile}");
    print("   - Is SVGA: $isSvga");

    return isSvga;
  }
}

/// Video player widget for gift cards - auto-plays, loops, and is muted
class GiftVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final Map<String, dynamic> category;

  const GiftVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.category,
  });

  @override
  State<GiftVideoPlayerWidget> createState() => _GiftVideoPlayerWidgetState();
}

class _GiftVideoPlayerWidgetState extends State<GiftVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print("🎥 [GiftVideoPlayer] Initializing video: ${widget.videoUrl}");
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      // Set video to auto-play, loop, and be muted
      _controller!.setLooping(true);
      _controller!.setVolume(0.0); // Muted
      _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      print("✅ [GiftVideoPlayer] Video initialized and playing");
    } catch (e) {
      print("❌ [GiftVideoPlayer] Error initializing video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show video player if initialized, otherwise show empty container
    if (!_isInitialized || _controller == null || _hasError) {
      return const SizedBox.shrink();
    }

    // Show video player - fit to container
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
