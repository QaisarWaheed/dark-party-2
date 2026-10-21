import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';

import '../controller/api_manager/svg_cache_manager.dart';

/// Widget that displays a profile picture with SVGA frames from active backpack items
class ProfileWithFrame extends StatefulWidget {
  final double size;
  final String? profileUrl;
  final bool showPlaceholder;
  final String? userId; // ✅ Optional: If provided, load this user's backpack instead of current user's
  final bool fitToSize; // ✅ If true, frame fits within exact size (no 1.3 multiplier)

  const ProfileWithFrame({
    super.key,
    this.size = 70,
    this.profileUrl,
    this.showPlaceholder = true,
    this.userId,
    this.fitToSize = false, // ✅ Default to false for backward compatibility
  });

  @override
  State<ProfileWithFrame> createState() => _ProfileWithFrameState();
}

class _ProfileWithFrameState extends State<ProfileWithFrame>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _animationController;
  String? _currentAnimUrl;
  bool _isAnimationVisible = false;
  final bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    print('🎬 [ProfileWithFrame] ========== INIT STATE ==========');
    print('🎬 [ProfileWithFrame] Size: ${widget.size}');
    print('🎬 [ProfileWithFrame] Profile URL: ${widget.profileUrl}');
    print('🎬 [ProfileWithFrame] User ID: ${widget.userId}');
    print('🎬 [ProfileWithFrame] =================================');
    // Load backpack items and find active SVGA frames
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🎬 [ProfileWithFrame] PostFrameCallback - Starting to load frame...');
      _loadActiveFrame();
    });
  }

  @override
void didUpdateWidget(covariant ProfileWithFrame oldWidget) {
  super.didUpdateWidget(oldWidget);

  print('🎬 [ProfileWithFrame] ========== INIT STATE ==========');
    print('🎬 [ProfileWithFrame] Size: ${widget.size}');
    print('🎬 [ProfileWithFrame] Profile URL: ${widget.profileUrl}');
    print('🎬 [ProfileWithFrame] User ID: ${widget.userId}');
    print('🎬 [ProfileWithFrame] =================================');
    // Load backpack items and find active SVGA frames
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🎬 [ProfileWithFrame] PostFrameCallback - Starting to load frame...');
      _loadActiveFrame();
    });
  
}

  Future<void> _loadActiveFrame() async {
    if (_isDisposed || !mounted) {
      print('⚠️ [ProfileWithFrame] Widget disposed or not mounted, skipping frame load');
      return;
    }

    print('📦 [ProfileWithFrame] ========== LOADING ACTIVE FRAME ==========');
    print('📦 [ProfileWithFrame] User ID: ${widget.userId}');
    
    try {
      List<BackpackItem> activeItems = [];
      
      // ✅ If userId is provided and valid (not 0), load that user's backpack directly
      final uid = widget.userId?.trim();
      if (uid != null && uid.isNotEmpty && uid != '0') {
        final userIdInt = int.tryParse(uid);
        if (userIdInt != null && userIdInt != 0) {
          print('📦 [ProfileWithFrame] Loading backpack for user: $userIdInt');
          final response = await ApiManager.getBackpack(userId: userIdInt);
          if (response != null && response.isSuccess) {
            print('📦 [ProfileWithFrame] Backpack response: ${response.totalItems} total, ${response.activeItems} active');
            activeItems = response.items
                .where((item) => item.isActive && item.svgaUrl != null && item.svgaUrl!.isNotEmpty)
                .toList();
            print('✅ [ProfileWithFrame] Found ${activeItems.length} active items with SVGA for user $userIdInt');
            for (var item in activeItems) {
              print('   - Item: ${item.itemName}, Category: ${item.itemCategory}, SVGA: ${item.svgaUrl}');
            }
          } else {
            print('❌ [ProfileWithFrame] Failed to load backpack for user $userIdInt: ${response?.message}');
          }
        } else {
          print('❌ [ProfileWithFrame] Invalid user ID format: ${widget.userId}');
        }
      } else {
        // ✅ Otherwise, use current user's backpack from StoreProvider
        print('📦 [ProfileWithFrame] Loading current user\'s backpack from StoreProvider');
        final storeProvider = Provider.of<StoreProvider>(context, listen: false);
        
        // Load backpack if not already loaded
        if (storeProvider.backpackItems.isEmpty && !storeProvider.isLoadingBackpack) {
          print('📦 [ProfileWithFrame] Backpack empty, loading...');
          final uidForStore = (uid == null || uid.isEmpty || uid == '0') ? null : uid;
          await storeProvider.loadBackpack(uidForStore);
          // Wait a bit for the state to update
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Get active backpack items with SVGA animations
        activeItems = storeProvider.activeBackpackItems
            .where((item) => item.svgaUrl != null && item.svgaUrl!.isNotEmpty)
            .toList();
        print('✅ [ProfileWithFrame] Found ${activeItems.length} active items with SVGA from StoreProvider');
      }

      if (activeItems.isEmpty) {
        print('📦 [ProfileWithFrame] No active items with SVGA frames');
        if (mounted) {
          setState(() {
            _isAnimationVisible = false;
          });
        }
        return;
      }

      // Use the first active item's SVGA (prioritize headwear, then others)
      // You can customize this logic to prioritize certain categories
      var activeItem = activeItems.first;
      
      // Try to find headwear first
      final headwear = activeItems.where((item) => 
        item.itemCategory.toLowerCase() == 'headwear'
      ).toList();
      
      if (headwear.isEmpty) {
         print('📦 [ProfileWithFrame] No active items with SVGA frames');
        if (mounted) {
          setState(() {
            _isAnimationVisible = false;
          });
        }
        return;
      }else{
activeItem = headwear.first;
      }

   
      
      String? rawUrl = activeItem.svgaUrl;

      // Normalize URL if needed
      if (rawUrl != null && rawUrl.contains('api.shaheenapp.com')) {
        _currentAnimUrl = rawUrl.replaceAll('api.shaheenapp.com', 'shaheenstar.online');
      } else if (rawUrl != null && rawUrl.contains('your-domain.com')) {
        _currentAnimUrl = rawUrl.replaceAll('your-domain.com', 'shaheenstar.online');
      } else {
        _currentAnimUrl = rawUrl;
      }

           // ✅ Preload SVGA in background
if (_currentAnimUrl != null) {
  SvgaCacheManager.load(_currentAnimUrl!);
}

      if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
        return;
      }
 

      print('🎬 [ProfileWithFrame] Loading SVGA frame: $_currentAnimUrl');
      
      // Initialize animation controller
      _animationController = SVGAAnimationController(vsync: this);
      
      if (mounted) {
        setState(() {});
      }

      // Load SVGA animation
      await _loadAndStartAnimation();
    } catch (e) {
      print('❌ [ProfileWithFrame] Error loading frame: $e');
    }
  }

  // Future<void> _loadAndStartAnimation() async {
  //   if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty || _isDisposed) {
  //     return;
  //   }

  //   try {
  //     print('📥 [ProfileWithFrame] Loading animation from: $_currentAnimUrl');
      
  //     final animUrl = _currentAnimUrl!.toLowerCase();
  //     final isSvga = animUrl.endsWith('.svga') || 
  //                    animUrl.contains('.svga?') || 
  //                    animUrl.contains('.svga&') ||
  //                    (animUrl.contains('svga') && !animUrl.contains('.svg') && !animUrl.endsWith('.svg'));

  //     if (!isSvga) {
  //       print('⚠️ [ProfileWithFrame] Animation is not SVGA format: $animUrl');
  //       return;
  //     }

  //     final videoItem = await SVGAParser.shared.decodeFromURL(_currentAnimUrl!);
      
  //     if (_isDisposed || !mounted || _animationController == null) {
  //       return;
  //     }

  //     print('✅ [ProfileWithFrame] SVGA file loaded successfully');
  //     _animationController!.videoItem = videoItem;

  //     if (mounted && !_isDisposed) {
  //       // Start playing animation in loop FIRST
  //       _animationController!.repeat();
  //       print('🎬 [ProfileWithFrame] Animation repeat() called');
        
  //       // Then update state to show the frame
  //       setState(() {
  //         _isAnimationVisible = true;
  //       });
  //       print('🎬 [ProfileWithFrame] State updated, isVisible: $_isAnimationVisible, controller: ${_animationController != null}');
  //     }
  //   } catch (e, stackTrace) {
  //     print('❌ [ProfileWithFrame] Error loading animation: $e');
  //     print('❌ [ProfileWithFrame] Stack trace: $stackTrace');
      
  //     if (mounted && !_isDisposed) {
  //       setState(() {
  //         _isAnimationVisible = false;
  //       });
  //     }
  //   }
  // }

Future<void> _loadAndStartAnimation() async {
  if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty || _isDisposed) {
    return;
  }

  try {
    print('📥 [ProfileWithFrame] Loading animation from (cached) $_currentAnimUrl');

    final animUrl = _currentAnimUrl!.toLowerCase();
    final isSvga = animUrl.endsWith('.svga') || 
                   animUrl.contains('.svga?') || 
                   animUrl.contains('.svga&') ||
                   (animUrl.contains('svga') && !animUrl.contains('.svg') && !animUrl.endsWith('.svg'));

    if (!isSvga) {
      print('⚠️ [ProfileWithFrame] Animation is not SVGA format: $animUrl');
      return;
    }

    // ✅ Load from cache (memory + disk)
    final movie = await SvgaCacheManager.load(_currentAnimUrl!);
    if (movie == null || _isDisposed || !mounted || _animationController == null) return;

    _animationController!.videoItem = movie;
    _animationController!.repeat(); // Loop animation

    setState(() {
      _isAnimationVisible = true;
    });

    print('✅ [ProfileWithFrame] SVGA Loaded & Playing');

  } catch (e, stackTrace) {
    print('❌ [ProfileWithFrame] Error loading SVGA animation: $e');
    print(stackTrace);

    if (mounted && !_isDisposed) {
      setState(() {
        _isAnimationVisible = false;
      });
    }
  }
}

  @override
  void dispose() {
        _animationController?.dispose();
  

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
      String cleanPath = profileUrl.startsWith('/') ? profileUrl.substring(1) : profileUrl;
      return 'https://shaheenstar.online/$cleanPath';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileUrl = widget.profileUrl ?? 
        Provider.of<ProfileUpdateProvider>(context, listen: false).profile_url;
    final normalizedUrl = _normalizeProfileUrl(profileUrl);

    print('🎨 [ProfileWithFrame] Building widget - isVisible: $_isAnimationVisible, hasController: ${_animationController != null}');
    
    // ✅ Use exact size if fitToSize is true, otherwise use 1.3 multiplier for frame visibility
    final containerSize = widget.fitToSize ? widget.size : widget.size * 1.3;
    
    return SizedBox(
      width: containerSize*1.1,
      height: containerSize*1.1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: widget.fitToSize ? Clip.hardEdge : Clip.none, // ✅ Clip if fitting to size
        children: [
          // Profile Picture (centered, original size) - Bottom layer
          Positioned(
            left: (_isAnimationVisible && _animationController != null)?05:05,
              top:  (_isAnimationVisible && _animationController != null)?05:05,
              right:  (_isAnimationVisible && _animationController != null)?05:05,
              bottom:  (_isAnimationVisible && _animationController != null)?05:05,
            child: CircleAvatar(
              radius: widget.size / 2,
              backgroundColor: Colors.transparent,
              backgroundImage:  null,
              child:ClipRRect(
                
      borderRadius: BorderRadius.circular(100),
      child: normalizedUrl != null && normalizedUrl.startsWith('http')
          ?SizedBox.expand(
            child:cachedImage(
              normalizedUrl,
          fit: BoxFit.cover
        

            ))
          : (widget.showPlaceholder
              ? Icon(
                  Icons.person,
                  size: widget.size * 0.4,
                )
              : null),
            ),
          ),),

          // SVGA Animation Frame (overlay on top, larger size) - Top layer
          // ✅ Must be after profile picture in Stack to appear on top
          if (_isAnimationVisible && _animationController != null)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: true, // ✅ Allow touches to pass through
                child: SVGAImage(
                  _animationController!,
                  fit: BoxFit.contain,
                ),
              ),
             ),
        ],
      ),
    );
  }
}

