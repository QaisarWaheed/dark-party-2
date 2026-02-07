import 'package:flutter/material.dart';

/// Use this for all asset images so they render sharp (no blur from scaling).
/// Always uses [FilterQuality.high]. Use instead of [Image.asset] for app assets.
class AppImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AppImage.asset(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => Icon(
                Icons.image_not_supported,
                size: (width != null || height != null) ? 24 : 48,
                color: Colors.grey,
              ),
    );
  }
}

/// Use for [DecorationImage] / [BoxDecoration] so background images stay sharp.
class AppDecorationImage {
  static DecorationImage asset(String path, {BoxFit fit = BoxFit.cover}) {
    return DecorationImage(
      image: AssetImage(path),
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
