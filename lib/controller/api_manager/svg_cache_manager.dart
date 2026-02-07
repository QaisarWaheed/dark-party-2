import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:svgaplayer_plus/svgaplayer_flutter.dart';

class SvgaCacheManager {
  static final Map<String, MovieEntity> _memoryCache = {};

  /// Load SVGA with memory + disk cache
  static Future<MovieEntity?> load(String url) async {
    // 1️⃣ Memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    try {
      final file = await _getCachedFile(url);

      final bytes = await file.readAsBytes();

      final movie = await SVGAParser.shared.decodeFromBuffer(bytes);
      // Keep the movie alive even if controller disposes
      movie.autorelease = false;

      _memoryCache[url] = movie;
      return movie;
    } catch (e) {
      print('❌ SVGA cache load error: $e');
      return null;
    }
  }

  static Future<File> _getCachedFile(String url) async {
    final dir = await getTemporaryDirectory();
    final hash = md5.convert(utf8.encode(url)).toString();
    final file = File('${dir.path}/svga_$hash.svga');

    if (await file.exists()) return file;

    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);

    await file.writeAsBytes(bytes);
    return file;
  }

  /// Clear memory cache
  static void clearMemory() {
    _memoryCache.forEach((key, movie) => movie.dispose());
    _memoryCache.clear();
  }
}
