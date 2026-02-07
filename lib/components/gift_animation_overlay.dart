// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shaheen_star_app/components/category_bottom_sheet.dart';
// import 'package:shaheen_star_app/model/gift_model.dart';
// import 'package:svgaplayer_plus/svgaplayer_flutter.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// /// Full-screen transparent overlay that displays SVGA gift animation
// /// Plays animation based on quantity count - duration is determined by actual animation length
// class GiftAnimationOverlay extends StatefulWidget {
//   final GiftModel gift;
//   final int quantity;
//   final VoidCallback onComplete;
//   final String? senderName;
//   final String? senderAvatar;
//   final String? receiverName;
//   final String? receiverAvatar;
//   final bool
//   isMultipleReceivers; // If true, show app icon instead of receiver avatar

//   const GiftAnimationOverlay({
//     Key? key,
//     required this.gift,
//     required this.quantity,
//     required this.onComplete,
//     this.senderName,
//     this.senderAvatar,
//     this.receiverName,
//     this.receiverAvatar,
//     this.isMultipleReceivers = false,
//   }) : super(key: key);

//   @override
//   State<GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
// }

// class _GiftAnimationOverlayState extends State<GiftAnimationOverlay>
//     with TickerProviderStateMixin {
//   SVGAAnimationController? _animationController;
//   int _currentPlayCount = 0;
//   String? _currentAnimUrl;
//     String? _currentVideoUrl;
//   late AnimationController _headerAnimationController;
//   late Animation<Offset> _headerSlideAnimation;
//   bool _isHeaderVisible = true;
//   bool _isAnimationVisible = false; // Control whether animation widget is shown
//   bool _isLoading = true;
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();

   
//        _currentVideoUrl="";
//     _currentAnimUrl = widget.gift.animationFile ?? '';

//     print(
//       "🎬 [GiftAnimationOverlay] ========== INITIALIZING OVERLAY ==========",
//     );
//     print("🎬 [GiftAnimationOverlay] Gift: ${widget.gift.name}");
//     print("🎬 [GiftAnimationOverlay] Quantity: ${widget.quantity}");
//     print("🎬 [GiftAnimationOverlay] Animation URL: $_currentAnimUrl");
//     print(
//       "🎬 [GiftAnimationOverlay] Sender: ${widget.senderName} (${widget.senderAvatar})",
//     );
//     print(
//       "🎬 [GiftAnimationOverlay] Receiver: ${widget.receiverName} (${widget.receiverAvatar})",
//     );
//     print(
//       "🎬 [GiftAnimationOverlay] Multiple Receivers: ${widget.isMultipleReceivers}",
//     );

//     // Initialize header animation
//     _headerAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     _headerSlideAnimation = Tween<Offset>(
//       begin: const Offset(0, -1), // Start from top (hidden)
//       end: Offset.zero, // End at center
//     ).animate(
//       CurvedAnimation(
//         parent: _headerAnimationController,
//         curve: Curves.easeOut,
//       ),
//     );

//     // Start header animation
//     _headerAnimationController.forward();
//     print("✅ [GiftAnimationOverlay] Header animation started");

//     // Initialize SVGA animation controller
//     _animationController = SVGAAnimationController(vsync: this);
//     print("✅ [GiftAnimationOverlay] SVGA animation controller created");

//     // Load and start animation sequence
//     _loadAndStartAnimation();
//     print("✅ [GiftAnimationOverlay] Animation loading started");
//     print(
//       "🎬 [GiftAnimationOverlay] ===========================================",
//     );
    
//   }

//   Future<void> _loadAndStartAnimation() async {
//     if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
//       print("❌ [GiftAnimationOverlay] No animation URL - closing overlay");
//       widget.onComplete();
//       return;
//     }

//     if (widget.quantity <= 0) {
//       print(
//         "❌ [GiftAnimationOverlay] Invalid quantity (${widget.quantity}) - closing overlay",
//       );
//       widget.onComplete();
//       return;
//     }

//     try {
//       print(
//         "📥 [GiftAnimationOverlay] Loading SVGA file from: $_currentAnimUrl",
//       );
//       final videoItem = await SVGAParser.shared.decodeFromURL(_currentAnimUrl!);

//       if (_isDisposed || !mounted) {
//         print(
//           "⚠️ [GiftAnimationOverlay] Widget disposed during loading - aborting",
//         );
//         return;
//       }

//       if (_animationController == null) {
//         print(
//           "❌ [GiftAnimationOverlay] Animation controller is null - aborting",
//         );
//         return;
//       }

//       print("✅ [GiftAnimationOverlay] SVGA file loaded successfully");
//       _animationController!.videoItem = videoItem;

//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _isAnimationVisible = true;
//         });
//       }

//       print(
//         "🎬 [GiftAnimationOverlay] Starting animation sequence (quantity: ${widget.quantity})",
//       );
//       _playNextAnimation();
//     } catch (e, stackTrace) {
//       print("❌ [GiftAnimationOverlay] Error loading SVGA file: $e");
//       print("❌ [GiftAnimationOverlay] Stack trace: $stackTrace");
//       if (mounted && !_isDisposed) {
//         widget.onComplete();
//       }
//     }
//   }

//   void _playNextAnimation() {
//     print("🎬 [GiftAnimationOverlay] ===== _playNextAnimation CALLED =====");
//     print("🎬 [GiftAnimationOverlay] Current play count: $_currentPlayCount");
//     print("🎬 [GiftAnimationOverlay] Target quantity: ${widget.quantity}");

//     // ✅ Check if we've already played all required animations BEFORE incrementing
//     if (_currentPlayCount >= widget.quantity) {
//       print(
//         "✅ [GiftAnimationOverlay] All animations completed ($_currentPlayCount >= ${widget.quantity}) - closing overlay",
//       );
//       _animateHeaderOut();
//       return;
//     }

//     if (_isDisposed || !mounted || _animationController == null) {
//       print(
//         "⚠️ [GiftAnimationOverlay] Widget disposed or controller null - aborting",
//       );
//       return;
//     }

//     _currentPlayCount++;
//     print(
//       "🎬 [GiftAnimationOverlay] ===== STARTING ANIMATION PLAY #$_currentPlayCount =====",
//     );
//     print(
//       "🎬 [GiftAnimationOverlay] Playing animation $_currentPlayCount of ${widget.quantity}",
//     );

//     // ✅ Immediately check if we've reached the limit after incrementing
//     if (_currentPlayCount > widget.quantity) {
//       print(
//         "✅ [GiftAnimationOverlay] Reached quantity limit ($_currentPlayCount > ${widget.quantity}) - stopping animation",
//       );
//       _animateHeaderOut();
//       return;
//     }

//     // Play animation once (forward) - NOT repeat
//     print(
//       "▶️ [GiftAnimationOverlay] Starting animation playback (forward, no repeat)",
//     );
//     _animationController!.forward().whenComplete(() {
//       // Check if disposed before doing anything
//       if (_isDisposed || !mounted) {
//         print(
//           "⚠️ [GiftAnimationOverlay] Widget disposed during animation completion - aborting",
//         );
//         return;
//       }

//       print(
//         "✅ [GiftAnimationOverlay] ===== ANIMATION #$_currentPlayCount COMPLETED =====",
//       );
//       print(
//         "✅ [GiftAnimationOverlay] Animation $_currentPlayCount finished playing",
//       );
//       print("✅ [GiftAnimationOverlay] Current play count: $_currentPlayCount");
//       print("✅ [GiftAnimationOverlay] Target quantity: ${widget.quantity}");

//       // Check if we should play next animation or complete
//       if (_currentPlayCount >= widget.quantity) {
//         print(
//           "✅ [GiftAnimationOverlay] All animations completed ($_currentPlayCount >= ${widget.quantity}) - closing overlay",
//         );
//         _animateHeaderOut();
//       } else {
//         print(
//           "🔄 [GiftAnimationOverlay] More animations to play - waiting 300ms before next animation",
//         );
//         // Small delay before playing next animation
//         Future.delayed(const Duration(milliseconds: 300), () {
//           if (mounted && !_isDisposed) {
//             print(
//               "🔄 [GiftAnimationOverlay] Starting next animation after delay",
//             );
//             _playNextAnimation();
//           } else {
//             print(
//               "⚠️ [GiftAnimationOverlay] Widget disposed during delay - aborting",
//             );
//           }
//         });
//       }
//     });
//   }

//   void _animateHeaderOut() {
//     print("🎬 [GiftAnimationOverlay] ===== _animateHeaderOut CALLED =====");
//     print("🎬 [GiftAnimationOverlay] Final play count: $_currentPlayCount");
//     print("🎬 [GiftAnimationOverlay] Target quantity: ${widget.quantity}");

//     // Stop and clear animation safely
//     if (_animationController != null && !_isDisposed) {
//       try {
//         print("🛑 [GiftAnimationOverlay] Stopping animation controller");
//         _animationController!.stop();
//         _animationController!.videoItem = null;
//       } catch (e) {
//         print("⚠️ [GiftAnimationOverlay] Error stopping animation: $e");
//       }
//     }

//     // Hide animation widget immediately
//     if (mounted) {
//       setState(() {
//         _isAnimationVisible = false;
//       });
//     }

//     // Animate header to the right and hide
//     _headerSlideAnimation = Tween<Offset>(
//       begin: Offset.zero,
//       end: const Offset(1.5, 0), // Move to right and off screen
//     ).animate(
//       CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeIn),
//     );

//     print("🎬 [GiftAnimationOverlay] Starting header exit animation");
//     _headerAnimationController.reverse().then((_) {
//       print("✅ [GiftAnimationOverlay] Header exit animation completed");
//       if (mounted && !_isDisposed) {
//         setState(() {
//           _isHeaderVisible = false;
//         });
//         // Call onComplete after header animation
//         Future.delayed(const Duration(milliseconds: 300), () {
//           if (mounted && !_isDisposed) {
//             print("✅ [GiftAnimationOverlay] Calling onComplete callback");
//             widget.onComplete();
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     print("🗑️ [GiftAnimationOverlay] ===== DISPOSING OVERLAY =====");
//     print("🗑️ [GiftAnimationOverlay] Final play count: $_currentPlayCount");
//     print("🗑️ [GiftAnimationOverlay] Target quantity: ${widget.quantity}");

//     _isDisposed = true;

//     // Safely dispose animation controller
//     if (_animationController != null) {
//       try {
//         print("🗑️ [GiftAnimationOverlay] Disposing animation controller");
//         _animationController!.stop();
//         _animationController!.videoItem = null;
//       } catch (e) {
//         print("⚠️ [GiftAnimationOverlay] Error stopping animation controller: $e");
//       }
      
//       try {
//         _animationController!.dispose();
//       } catch (e) {
//         print("⚠️ [GiftAnimationOverlay] Error disposing animation controller: $e");
//       }
      
//       _animationController = null;
//     }

//     // Safely dispose header animation controller
//     try {
//       _headerAnimationController.dispose();
//     } catch (e) {
//       print("⚠️ [GiftAnimationOverlay] Error disposing header animation controller: $e");
//     }
    
//     print(
//       "🗑️ [GiftAnimationOverlay] ===========================================",
//     );
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if ((_currentAnimUrl == null || _currentAnimUrl!.isEmpty)) {
//       // No animation file - close immediately
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!_isDisposed) {
//           widget.onComplete();
//         }
//       });
//       return const SizedBox.shrink();
//     }

   

//     return Material(
//       // ✅ TRANSPARENT BACKGROUND - No white/black overlay
//       color: Colors.transparent,
//       child: IgnorePointer(
//         // Allow touches to pass through
//         ignoring: true,
//         child: Stack(
//           children: [
//             // ✅ FULL SCREEN SVGA ANIMATION - Centered and scaled to fit
//             // ✅ Only show animation when actively playing and within quantity limit (prevents looping)
//             if (_isAnimationVisible &&
//                 _animationController != null &&
//                 _currentPlayCount > 0 &&
//                 _currentPlayCount <= widget.quantity)
               
//               Center(
//                 child: Container(
//                   width: double.infinity,
//                   height: double.infinity,
//                   child: SVGAImage(
//                     _animationController!,
//                     fit:
//                         BoxFit
//                             .cover, // ✅ Full screen - fills entire screen (may crop edges to maintain aspect ratio)
//                   ),
//                 ),
//               ),

//             // Loading indicator
//             if (_isLoading)
//               Center(
//                 child: Container(
//                   color: Colors.black.withOpacity(0.3),
//                   child: const CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 ),
//               ),

//             // ✅ SENDER/RECEIVER HEADER OVERLAY (Animated)
//             if (_isHeaderVisible)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: SlideTransition(
//                   position: _headerSlideAnimation,
//                   child: _buildGiftHeader(),
//                 ),
//               ),

//             // Optional: Show count indicator (can be removed if not needed)
//             if (widget.quantity > 1)
//               Positioned(
//                 top: 60,
//                 right: 20,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '$_currentPlayCount / ${widget.quantity}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build gift header with sender avatar, gift name, and receiver avatar
//   /// Uses image as Stack background instead of separate cards
//   Widget _buildGiftHeader() {
//     return SafeArea(
//       child: Container(
//         height: 100, // Fixed height for the banner
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // ✅ BACKGROUND IMAGE (Purple banner with gold ornate design)
//          
//             Positioned(
//               top: 42,
//               left: 36,

//               child: _buildAvatar(
//                 widget.senderAvatar,
//                 widget.senderName ?? 'Sender',
//                 Colors.red,
//               ),
//             ),
//             Positioned(
//             top: 60,
//               right: 0,
//               left: 0,
//               child: Text(
//                 widget.gift.name,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 42,
//               right: 36,
//               child:
//                   widget.isMultipleReceivers
//                       ? _buildAppIcon()
//                       : _buildAvatar(
//                         widget.receiverAvatar,
//                         widget.receiverName ?? 'Receiver',
//                         Colors.red,
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Build avatar widget with red circle border
//   Widget _buildAvatar(String? avatarUrl, String name, Color borderColor) {
//     return Container(
//       width: 55,
//       height: 55,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(color: borderColor, width: 3),
//         boxShadow: [
//           BoxShadow(
//             color: borderColor.withOpacity(0.5),
//             blurRadius: 8,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: ClipOval(
//         child:
//             avatarUrl != null && avatarUrl.isNotEmpty
//                 ? CachedNetworkImage(
//                   imageUrl: avatarUrl,
//                   fit: BoxFit.cover,
//                   placeholder:
//                       (context, url) => Container(
//                         color: Colors.grey[800],
//                         child: const Center(
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                   errorWidget:
//                       (context, url, error) => Container(
//                         color: Colors.grey[800],
//                         child: const Icon(
//                           Icons.person,
//                           color: Colors.white,
//                           size: 30,
//                         ),
//                       ),
//                 )
//                 : Container(
//                   color: Colors.grey[800],
//                   child: const Icon(
//                     Icons.person,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                 ),
//       ),
//     );
//   }

//   /// Build app icon widget for multiple receivers
//   Widget _buildAppIcon() {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.red, width: 3),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.red.withOpacity(0.5),
//             blurRadius: 8,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: ClipOval(
//         child: Image.asset(
//           'assets/images/app_logo.jpeg',
//           fit: BoxFit.cover,
//           errorBuilder:
//               (context, error, stackTrace) => Container(
//                 color: Colors.grey[800],
//                 child: const Icon(Icons.people, color: Colors.white, size: 30),
//               ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import 'package:shaheen_star_app/components/app_image.dart';
import '../controller/api_manager/cached_file_service.dart';
import '../controller/api_manager/svg_cache_manager.dart';

class GiftAnimationOverlay extends StatefulWidget {
  final GiftModel gift;
  final int quantity;
  final VoidCallback onComplete;
  final String? senderName;
  final String? senderAvatar;
  final String? receiverName;
  final String? receiverAvatar;
  final bool isMultipleReceivers;

  const GiftAnimationOverlay({
    super.key,
    required this.gift,
    required this.quantity,
    required this.onComplete,
    this.senderName,
    this.senderAvatar,
    this.receiverName,
    this.receiverAvatar,
    this.isMultipleReceivers = false,
  });

  @override
  State<GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
}

class _GiftAnimationOverlayState extends State<GiftAnimationOverlay>
    with TickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  VideoPlayerController? _videoController;

  int _currentPlayCount = 0;
  String? _currentAnimUrl;

  late AnimationController _headerController;
  late Animation<Offset> _headerSlide;

  bool _isLoading = true;
  bool _isAnimationVisible = false;
  final bool _isHeaderVisible = true;
  bool _isDisposed = false;

  bool get _isVideo =>
      _currentAnimUrl != null &&
      _currentAnimUrl!.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();

    _currentAnimUrl = widget.gift.animationFile ?? '';

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerController.forward();

    _svgaController = SVGAAnimationController(vsync: this);

    _loadAndStartAnimation();
  }

  // ================== LOAD & START ==================
Future<void> _loadAndStartAnimation() async {
  if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
    widget.onComplete();
    return;
  }

  try {
    final cachedPath = await getCachedFile(_currentAnimUrl!);

    if (!mounted || _isDisposed) return;

    if (_isVideo) {
      // 🎥 Use cached MP4 file
      if (cachedPath != null) {
        _videoController = VideoPlayerController.file(
          File(cachedPath),
        )..setLooping(false)
         ..addListener(_onVideoFinished);

        await _videoController!.initialize();
        setState(() {
          _isLoading = false;
          _isAnimationVisible = true;
          _currentPlayCount = 1;
        });

        _videoController!.play();
      } else {
        widget.onComplete();
      }
    } else {
      // 🎬 SVGA – load from cache (disk or memory)
      final movie = await SvgaCacheManager.load(_currentAnimUrl!); 
      if (movie == null) {
        widget.onComplete();
        return;
      }

      _svgaController!.videoItem = movie;

      setState(() {
        _isLoading = false;
        _isAnimationVisible = true;
      });

      _playNextSvga();
    }
  } catch (e) {
    print("❌ Error loading animation: $e");
    widget.onComplete();
  }
}

  // Future<void> _loadAndStartAnimation() async {
  //   if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
  //     widget.onComplete();
  //     return;
  //   }

  //   try {
  //     if (_isVideo) {
     
  //       // 🎥 MP4 VIDEO
  //       _videoController = VideoPlayerController.network(_currentAnimUrl!)
  //         ..setLooping(false)
  //         ..addListener(_onVideoFinished);

  //       await _videoController!.initialize();

  //       if (!mounted || _isDisposed) return;

  //       setState(() {
  //         _isLoading = false;
  //         _isAnimationVisible = true;
  //         _currentPlayCount = 1;
  //       });

  //       _videoController!.play();
  //     } else {
  //       // 🎬 SVGA
  //       final videoItem =
  //           await SVGAParser.shared.decodeFromURL(_currentAnimUrl!);

  //       if (!mounted || _isDisposed) return;

  //       _svgaController!.videoItem = videoItem;

  //       setState(() {
  //         _isLoading = false;
  //         _isAnimationVisible = true;
  //       });

  //       _playNextSvga();
  //     }
  //   } catch (e) {
  //     widget.onComplete();
  //   }
  // }

  // ================== SVGA PLAY ==================

  void _playNextSvga() {
    if (_isDisposed ||
        !mounted ||
        _svgaController == null ||
        _currentPlayCount >= widget.quantity) {
      _animateHeaderOut();
      return;
    }

    _currentPlayCount++;

    _svgaController!.forward().whenComplete(() {
      if (_isDisposed || !mounted) return;

      if (_currentPlayCount >= widget.quantity) {
        _animateHeaderOut();
      } else {
        Future.delayed(const Duration(milliseconds: 300), _playNextSvga);
      }
    });
  }

  // ================== VIDEO COMPLETE ==================

  void _onVideoFinished() {
    if (_videoController == null) return;

    if (_videoController!.value.position >=
        _videoController!.value.duration) {
      _videoController!.removeListener(_onVideoFinished);
      _animateHeaderOut();
    }
  }

  // ================== EXIT ==================

  void _animateHeaderOut() {
    if (_isDisposed) return;

    _svgaController?.stop();
    _videoController?.pause();

    setState(() {
      _isAnimationVisible = false;
    });

    _headerSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _headerController.reverse().then((_) {
      if (!_isDisposed && mounted) {
        widget.onComplete();
      }
    });
  }

  // ================== DISPOSE ==================

  @override
  void dispose() {
    _isDisposed = true;

    _svgaController?.dispose();
    _videoController?.removeListener(_onVideoFinished);
    _videoController?.dispose();
    _headerController.dispose();

    super.dispose();
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          children: [
            if (_isAnimationVisible)
              RepaintBoundary(
                child: SizedBox.expand(
                  child: _isVideo
                      ? 
                      
                      (_videoController != null &&
                              _videoController!.value.isInitialized
                          ? 
                       
                          VideoPlayer(_videoController!)
                          : const SizedBox())
                      : (_svgaController != null
                          ? RepaintBoundary(
                            child: SVGAImage(
                              _svgaController!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const SizedBox()),
                ),
              ),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            if (_isHeaderVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildGiftHeader(),
                  ),
                ),
              ),

            if (widget.quantity > 1 && !_isVideo)
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPlayCount / ${widget.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================== HEADER ==================

  Widget _buildGiftHeader() {
    return SafeArea(
      child: Builder(builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final headerHeight = screenHeight * 0.10; // Responsive: 10% of screen height
        final dpr = MediaQuery.of(context).devicePixelRatio;
        
        return SizedBox(
          height: headerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background banner image
              AppImage.asset('assets/images/banner_pic.png', fit: BoxFit.cover),

              // Foreground content: sender avatar, ribbon text, gift image + count
              Container(
                padding: EdgeInsets.symmetric(horizontal: headerHeight * 0.15),
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sender avatar
                    SizedBox(
                      width: headerHeight * 0.55,
                      height: headerHeight * 0.55,
                      child: _buildAvatar(widget.senderAvatar),
                    ),
                    SizedBox(width: headerHeight * 0.1),

                    // Ribbon / text area
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: headerHeight * 0.15,
                                vertical: headerHeight * 0.1),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius:
                                  BorderRadius.circular(headerHeight * 0.25),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${widget.senderName ?? 'Sender'} send ${widget.receiverName ?? 'Receiver'}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: headerHeight * 0.18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: headerHeight * 0.1),

                    // Gift image and quantity
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gift image (network or asset) - decode at device DPR to avoid upscaling blur
                        SizedBox(
                          width: headerHeight * 0.5,
                          height: headerHeight * 0.5,
                          child: Builder(builder: (context) {
                            final cacheWidth =
                                (headerHeight * 0.5 * dpr).round();
                            final imageUrl = widget.gift.image ?? '';
                            print('🔍 [GiftImage] DPR=$dpr cacheWidth=$cacheWidth url=$imageUrl');

                            if (imageUrl.isNotEmpty) {
                              return Image(
                                image: ResizeImage(
                                  CachedNetworkImageProvider(imageUrl),
                                  width: cacheWidth,
                                ),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (c, e, s) => AppImage.asset(
                                  'assets/images/image_9.png',
                                  fit: BoxFit.contain,
                                ),
                              );
                            }

                            return AppImage.asset(
                              'assets/images/image_9.png',
                              fit: BoxFit.contain,
                            );
                          }),
                        ),
                        SizedBox(height: headerHeight * 0.08),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: headerHeight * 0.1,
                              vertical: headerHeight * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius:
                                BorderRadius.circular(headerHeight * 0.15),
                          ),
                          child: Text(
                            '${widget.quantity}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: headerHeight * 0.14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(String? url) {
    return Builder(builder: (context) {
      final screenHeight = MediaQuery.of(context).size.height;
      final avatarSize = screenHeight * 0.055; // Responsive avatar size
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final cacheWidth = (avatarSize * dpr).round();
      
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: avatarSize * 0.055),
        ),
        child: ClipOval(
          child: Builder(builder: (context) {
            print('🔍 [Avatar] DPR=$dpr cacheWidth=$cacheWidth url=$url');

            if (url != null && url.isNotEmpty) {
              return Image(
                image: ResizeImage(
                  CachedNetworkImageProvider(url),
                  width: cacheWidth,
                ),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              );
            }

            return Icon(
              Icons.person,
              color: Colors.white,
              size: avatarSize * 0.5,
            );
          }),
        ),
      );
    });
  }

  Widget _buildAppIcon() {
    return Builder(builder: (context) {
      final screenHeight = MediaQuery.of(context).size.height;
      final iconSize = screenHeight * 0.05; // Responsive icon size
      
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: iconSize * 0.06),
        ),
        child: ClipOval(
          child: AppImage.asset(
            'assets/images/app_logo.jpeg',
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }
}
