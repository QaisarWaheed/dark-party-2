import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/gift_display_provider.dart';
import 'package:shaheen_star_app/model/gift_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Overlay widget that displays active gifts on the room screen
class GiftDisplayOverlay extends StatelessWidget {
  const GiftDisplayOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GiftDisplayProvider>(
      builder: (context, giftDisplayProvider, child) {
        final activeGifts = giftDisplayProvider.activeGifts;

        if (activeGifts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: IgnorePointer(
            // Allow touches to pass through to underlying widgets
            ignoring: true,
            child: Container(
              // ✅ TRANSPARENT BACKGROUND - No white/black overlay
              color: Colors.transparent,
              child: Stack(
                children: activeGifts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final gift = entry.value;
                  return _buildGiftItem(context, gift, index);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftItem(
    BuildContext context,
    ActiveGift activeGift,
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate position - spread gifts across the screen
    // Position from left side, starting from top
    final leftOffset = 20.0 + (index % 3) * (screenWidth * 0.3);
    final topOffset = 100.0 + (index ~/ 3) * 120.0;

    return Positioned(
      left: leftOffset,
      top: topOffset,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: _buildGiftCard(context, activeGift),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftCard(BuildContext context, ActiveGift activeGift) {
    // Special lucky gift presentation
    if (activeGift.gift.category.toLowerCase() == 'lucky') {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.9),
            Colors.pink.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                backgroundImage:
                    activeGift.senderAvatar != null &&
                        activeGift.senderAvatar!.isNotEmpty &&
                        (activeGift.senderAvatar!.startsWith('http://') ||
                            activeGift.senderAvatar!.startsWith('https://'))
                    ? NetworkImage(activeGift.senderAvatar!)
                    : null,
                child:
                    activeGift.senderAvatar == null ||
                        activeGift.senderAvatar!.isEmpty ||
                        (!activeGift.senderAvatar!.startsWith('http://') &&
                            !activeGift.senderAvatar!.startsWith('https://'))
                    ? const Icon(Icons.person, size: 16, color: Colors.purple)
                    : null,
              ),
              const SizedBox(width: 8),
              // Sender name
              Flexible(
                child: Text(
                  activeGift.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Gift image and info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gift image/animation - prioritize animation file over static image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildGiftMedia(activeGift.gift),
                ),
              ),
              const SizedBox(width: 8),
              // Gift name and quantity
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeGift.gift.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activeGift.quantity > 1) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${activeGift.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Receiver info (optional)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'to ${activeGift.receiverName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyGiftCard(BuildContext context, ActiveGift activeGift) {
    // Small centered animation card for lucky gifts
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.deepPurple.shade700],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: sender avatar, central image, receiver avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sender Circle
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage:
                    activeGift.senderAvatar != null &&
                        activeGift.senderAvatar!.isNotEmpty &&
                        (activeGift.senderAvatar!.startsWith('http') ||
                            activeGift.senderAvatar!.startsWith('https'))
                    ? NetworkImage(activeGift.senderAvatar!) as ImageProvider
                    : null,
                child:
                    activeGift.senderAvatar == null ||
                        activeGift.senderAvatar!.isEmpty
                    ? const Icon(Icons.person, color: Colors.deepPurple)
                    : null,
              ),
              const SizedBox(width: 8),
              // Center image (okkkkk... png)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 2),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/images/okkkkkkkkkkkkkkkk3.png'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Receiver Circle
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage:
                    activeGift.receiverAvatar != null &&
                        activeGift.receiverAvatar!.isNotEmpty &&
                        (activeGift.receiverAvatar!.startsWith('http') ||
                            activeGift.receiverAvatar!.startsWith('https'))
                    ? NetworkImage(activeGift.receiverAvatar!) as ImageProvider
                    : null,
                child:
                    activeGift.receiverAvatar == null ||
                        activeGift.receiverAvatar!.isEmpty
                    ? const Icon(Icons.person, color: Colors.deepPurple)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${activeGift.senderName} → ${activeGift.receiverName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (activeGift.quantity > 1) const SizedBox(height: 6),
          if (activeGift.quantity > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${activeGift.quantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Helper: Build gift image widget with local path detection
  Widget _buildGiftImageWidget(String imageUrl) {
    // ✅ Check if it's a local file path (don't load as network URL)
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

    if (isLocalPath) {
      print(
        "⚠️ [GiftDisplayOverlay] Gift image is local file path, cannot load as network URL: $imageUrl",
      );
      return Container(
        color: Colors.purple.withOpacity(0.5),
        child: const Icon(
          Icons.play_circle_filled,
          color: Colors.white,
          size: 30,
        ),
      );
    }

    // ✅ Normalize URL if needed (only for server paths)
    String normalizedImageUrl = imageUrl;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      normalizedImageUrl = 'https://shaheenstar.online/$imageUrl';
    }

    return CachedNetworkImage(
      imageUrl: normalizedImageUrl,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(
        color: Colors.purple.withOpacity(0.5),
        child: const Icon(
          Icons.play_circle_filled,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  /// Build gift media widget - shows animation/video if available, otherwise shows static image
  Widget _buildGiftMedia(GiftModel gift) {
    // ✅ Priority 1: Check if gift has animation file (video/GIF/animation)
    if (gift.hasAnimation &&
        gift.animationFile != null &&
        gift.animationFile!.isNotEmpty) {
      final animUrl = gift.animationFile!;
      final lowerUrl = animUrl.toLowerCase();

      print("🎬 [GiftDisplayOverlay] Displaying animation file: $animUrl");

      // Check file type
      if (lowerUrl.contains('.gif') || lowerUrl.contains('gif')) {
        // ✅ GIF file - CachedNetworkImage supports GIFs natively
        return CachedNetworkImage(
          imageUrl: animUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(gift),
        );
      } else if (lowerUrl.contains('.mp4') ||
          lowerUrl.contains('.webm') ||
          lowerUrl.contains('.mov') ||
          lowerUrl.contains('video') ||
          lowerUrl.contains('.svga')) {
        // ✅ Video or animation file - show with play icon overlay
        return Stack(
          fit: StackFit.expand,
          children: [
            // Show thumbnail/placeholder for video
            Container(
              color: Colors.black.withOpacity(0.3),
              child: gift.image != null && gift.image!.isNotEmpty
                  ? _buildGiftImageWidget(gift.image!)
                  : Container(
                      color: Colors.purple.withOpacity(0.5),
                      child: const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
            // Play icon overlay
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ],
        );
      } else {
        // ✅ Other animation format - try to display as image (might be animated)
        return CachedNetworkImage(
          imageUrl: animUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(gift),
        );
      }
    }

    // ✅ Priority 2: Fall back to static image if no animation
    if (gift.image != null && gift.image!.isNotEmpty) {
      final imageUrl = gift.image!;

      // ✅ Check if it's a local file path (don't load as network URL)
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

      if (isLocalPath) {
        print(
          "⚠️ [GiftDisplayOverlay] Gift image is local file path, cannot load as network URL: $imageUrl",
        );
        return const SizedBox.shrink(); // Return empty for local paths
      }

      // ✅ Normalize URL if needed (only for server paths)
      String normalizedImageUrl = imageUrl;
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        normalizedImageUrl = 'https://shaheenstar.online/$imageUrl';
      }

      print(
        "🖼️ [GiftDisplayOverlay] Displaying static image: $normalizedImageUrl",
      );
      return CachedNetworkImage(
        imageUrl: normalizedImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(gift),
      );
    }

    // ✅ Priority 3: Fallback icon
    return _buildFallbackImage(gift);
  }

  /// Build fallback icon when image/animation fails to load
  Widget _buildFallbackImage(GiftModel gift) {
    return const Icon(Icons.card_giftcard, color: Colors.white, size: 30);
  }
}
