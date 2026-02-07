import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/components/profile_with_frame.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';

/// Full-screen overlay that displays SVGA store item animation
class StoreItemAnimationOverlay extends StatefulWidget {
  final StoreItem item;
  final VoidCallback onComplete;

  const StoreItemAnimationOverlay({
    super.key,
    required this.item,
    required this.onComplete,
  });

  @override
  State<StoreItemAnimationOverlay> createState() => _StoreItemAnimationOverlayState();
}

class _StoreItemAnimationOverlayState extends State<StoreItemAnimationOverlay>
    with TickerProviderStateMixin {
  SVGAAnimationController? _animationController;
  String? _currentAnimUrl;
  bool _isAnimationVisible = false;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    // Get animation URL - prioritize SVGA, then animation file
    String? rawUrl = widget.item.svgaFile ?? widget.item.animationFile;
    
    // ✅ Safety check: Normalize URL if it contains api.shaheenapp.com (fix certificate issues)
    if (rawUrl != null && rawUrl.contains('api.shaheenapp.com')) {
      _currentAnimUrl = rawUrl.replaceAll('api.shaheenapp.com', 'shaheenstar.online');
      print('🔄 [StoreItemAnimationOverlay] Normalized URL from api.shaheenapp.com to shaheenstar.online');
      print('   Original: $rawUrl');
      print('   Normalized: $_currentAnimUrl');
    } else {
      _currentAnimUrl = rawUrl;
    }
    
    print('🎬 [StoreItemAnimationOverlay] ========== INITIALIZING ==========');
    print('🎬 [StoreItemAnimationOverlay] Item: ${widget.item.itemName}');
    print('🎬 [StoreItemAnimationOverlay] Animation URL: $_currentAnimUrl');
    print('🎬 [StoreItemAnimationOverlay] Has SVGA: ${widget.item.hasSvgaAnimation}');
    print('🎬 [StoreItemAnimationOverlay] Has Animation: ${widget.item.hasAnimation}');

    if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
      print('⚠️ [StoreItemAnimationOverlay] No animation file available');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          widget.onComplete();
        }
      });
      return;
    }

    // Initialize SVGA animation controller
    _animationController = SVGAAnimationController(vsync: this);
    print('✅ [StoreItemAnimationOverlay] SVGA animation controller created');

    // Load and start animation
    _loadAndStartAnimation();
  }

Future<void> _loadAndStartAnimation() async {
  if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
    _isLoading = false;
    if (mounted) setState(() {});
    widget.onComplete();
    return;
  }

  try {
    final animUrl = _currentAnimUrl!;
    final isSvga = animUrl.toLowerCase().endsWith('.svga') ||
                   animUrl.contains('.svga?') ||
                   animUrl.contains('.svga&') ||
                   (animUrl.contains('svga') && !animUrl.contains('.svg') && !animUrl.endsWith('.svg'));

    if (!isSvga) {
      _isLoading = false;
      if (mounted) setState(() {});
      widget.onComplete();
      return;
    }

    // ✅ Use CacheManager to get file
    final fileInfo = await DefaultCacheManager().getSingleFile(animUrl);
    final videoItem = await SVGAParser.shared.decodeFromBuffer(await fileInfo.readAsBytes());

    if (_isDisposed || !mounted || _animationController == null) return;

    _animationController!.videoItem = videoItem;

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isAnimationVisible = true;
      });
      _animationController!.repeat();
    }
  } catch (e, stackTrace) {
    print('❌ Error loading SVGA animation: $e');
    print(stackTrace);
    _isLoading = false;
    if (mounted) setState(() {});
    widget.onComplete();
  }
}



  @override
  void dispose() {
    _isDisposed = true;
    _animationController?.stop();
    _animationController?.videoItem = null;
    _animationController?.dispose();
    print('🗑️ [StoreItemAnimationOverlay] Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAnimUrl == null || _currentAnimUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // Allow user to tap background to close
          widget.onComplete();
        },
        child: Stack(
          children: [
            // Black background with 0.6 opacity
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.7),
            ),
            
            // Centered content - Only show when SVGA is loaded
            if (_isAnimationVisible &&
                _animationController != null &&
                _animationController!.videoItem != null)
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when tapping the content area
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Item Name at the top
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          widget.item.itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Profile Picture with Purchased Frame + Preview Item Animation
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Profile Picture with Purchased Item Frame (from backpack)
                            ProfileWithFrame(
                              size: 120,
                              showPlaceholder: true,
                            ),
                            
                            // Preview Item's SVGA Animation Frame (overlay on top of purchased frame)
                            if (_isAnimationVisible && _animationController != null)
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: SVGAImage(
                                  _animationController!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

            // Close button
           
          ],
        ),
      ),
    );
  }
}

