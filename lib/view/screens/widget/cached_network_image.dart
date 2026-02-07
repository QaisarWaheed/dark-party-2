import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

Widget cachedImage(String url,
    {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  // If the URL is not an HTTP/HTTPS network URL, treat it as a local asset path
  if (!(url.startsWith('http://') || url.startsWith('https://'))) {
    return AppImage.asset(url, width: width, height: height, fit: fit);
  }

  // Decode network images at device DPR to avoid upscaling blur
  return Builder(builder: (context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = width ?? 100.0;
    final logicalHeight = height ?? 100.0;
    final cacheWidth = (logicalWidth * dpr).round();
    final cacheHeight = (logicalHeight * dpr).round();

    return Image(
      image: ResizeImage(
        CachedNetworkImageProvider(url),
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
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [cachedImage] Error: $url - $error');
        return AppImage.asset(
          'assets/images/person.png',
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  });
}
