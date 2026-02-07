import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Add this helper to get cached file (MP4) or SVGA
Future<String?> getCachedFile(String url) async {
  try {
    final fileInfo = await DefaultCacheManager().getSingleFile(url);
    return fileInfo.path; // Local file path
  } catch (e) {
    print("⚠️ Cache error: $e");
    return null;
  }
}
