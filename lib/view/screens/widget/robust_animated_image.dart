import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

class RobustAnimatedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RobustAnimatedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return AppImage.asset(
        'assets/images/image_9.png',
        width: width,
        height: height,
        fit: fit,
      );
    }

    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    if (!isNetwork) {
      return AppImage.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }

    // Decode network image at device DPR to avoid blur
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = width ?? 100.0;
    final logicalHeight = height ?? 100.0;
    final cacheWidth = (logicalWidth * dpr).round();
    final cacheHeight = (logicalHeight * dpr).round();

    return Image(
      image: ResizeImage(
        CachedNetworkImageProvider(imageUrl),
        width: cacheWidth,
        height: cacheHeight,
      ),
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [RobustAnimatedImage] Error: $imageUrl - $error');
        return AppImage.asset(
          'assets/images/image_9.png',
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}
