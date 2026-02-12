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
  /// When true, hides the overlay's header (banner_pic) so only the top broadcasting_image banner shows.
  final bool hideHeader;

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
    this.hideHeader = false,
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
  bool get _isHeaderVisible => !widget.hideHeader;
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

    // Slide in from left (Offset(-1, 0) to Offset.zero)
    _headerSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(
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
          _videoController = VideoPlayerController.file(File(cachedPath))
            ..setLooping(false)
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

  // ================== SVGA PLAY ==================

  void _playNextSvga() {
    if (_isDisposed ||
        !mounted ||
        _svgaController == null ||
        _currentPlayCount >= widget.quantity) {
      // Only complete, do not animate header out or show another banner
      if (!_isDisposed && mounted) {
        widget.onComplete();
      }
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

    if (_videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.removeListener(_onVideoFinished);
      // Only complete, do not animate header out or show another banner
      if (!_isDisposed && mounted) {
        widget.onComplete();
      }
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
            // Only show the header banner animation and the video/SVGA animation
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
            if (_isAnimationVisible)
              RepaintBoundary(
                child: SizedBox.expand(
                  child: _isVideo
                      ? (_videoController != null &&
                                _videoController!.value.isInitialized
                            ? VideoPlayer(_videoController!)
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
          ],
        ),
      ),
    );
  }

  // ================== HEADER ==================

  Widget _buildGiftHeader() {
    return SafeArea(
      child: Builder(
        builder: (context) {
          final screenHeight = MediaQuery.of(context).size.height;
          final headerHeight =
              screenHeight * 0.10; // Responsive: 10% of screen height
          final dpr = MediaQuery.of(context).devicePixelRatio;

          return SizedBox(
            height: headerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background banner image
                AppImage.asset(
                  'assets/images/banner_pic.png',
                  fit: BoxFit.cover,
                ),

                // Foreground content: sender avatar, ribbon text, gift image + count
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: headerHeight * 0.15,
                  ),
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
                                vertical: headerHeight * 0.1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(
                                  headerHeight * 0.25,
                                ),
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
                            child: Builder(
                              builder: (context) {
                                final cacheWidth = (headerHeight * 0.5 * dpr)
                                    .round();
                                final imageUrl = widget.gift.image ?? '';
                                print(
                                  '🔍 [GiftImage] DPR=$dpr cacheWidth=$cacheWidth url=$imageUrl',
                                );

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
                              },
                            ),
                          ),
                          SizedBox(height: headerHeight * 0.08),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: headerHeight * 0.1,
                              vertical: headerHeight * 0.05,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                headerHeight * 0.15,
                              ),
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
        },
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Builder(
      builder: (context) {
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
            child: Builder(
              builder: (context) {
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
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppIcon() {
    return Builder(
      builder: (context) {
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
      },
    );
  }
}
