class GiftModel {
  final int? id;
  final String name;
  final String category;
  final double price;
  final String coinType; // 'gold' or 'diamond'
  final String? description;
  final String? image;
  final String? animationFile;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GiftModel({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.coinType,
    this.description,
    this.image,
    this.animationFile,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    final giftId = json['id']?.toString() ?? 'unknown';
    final giftName = json['gift_name']?.toString() ?? 'unknown';
    
    // ✅ Log all file types from API response
    print("📦 ===== GIFT FILE ANALYSIS: Gift $giftId ($giftName) =====");
    print("   📷 gift_image: ${json['gift_image'] ?? 'null'}");
    print("   🎥 gift_video: ${json['gift_video'] ?? 'null'}");
    print("   🎨 gift_svg: ${json['gift_svg'] ?? 'null'}");
    print("   📁 gift_file: ${json['gift_file'] ?? 'null'}");
    print("   📄 file_type: ${json['file_type'] ?? 'null'}");
    
    // Handle image URL - API returns 'gift_image' field
    String? imageUrl = json['gift_image']?.toString() ?? 
                       json['image']?.toString();
    
    // ✅ Check if it's a local file path (don't normalize local paths)
    bool isLocalPath = imageUrl != null && (
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
        imageUrl.contains('/data/user/')
    );
    
    // Convert relative path to full URL if needed (only for server paths, not local files)
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null' && !isLocalPath && !imageUrl.startsWith('http')) {
      // Remove leading slash if present
      if (imageUrl.startsWith('/')) {
        imageUrl = imageUrl.substring(1);
      }
      imageUrl = 'https://shaheenstar.online/$imageUrl';
    } else if (imageUrl == 'null' || imageUrl?.isEmpty == true || isLocalPath) {
      // ✅ If it's a local path, set to null (will use placeholder)
      if (isLocalPath) {
        print("⚠️ [GiftModel] Gift image is local file path, setting to null: $imageUrl");
      }
      imageUrl = null;
    }
    
    // ✅ Handle animation/video file URL - check multiple fields
    // Priority: gift_svg (SVGA) > gift_file > gift_video > animation_file
    String? animUrl;
    
    // Check gift_svg first (SVGA animation file - highest priority)
    if (json['gift_svg'] != null && 
        json['gift_svg'].toString().isNotEmpty && 
        json['gift_svg'].toString() != 'null') {
      animUrl = json['gift_svg'].toString();
      print("   🎨 Using gift_svg field (SVGA)");
    }
    // Check gift_file second (primary animation file)
    else if (json['gift_file'] != null && 
             json['gift_file'].toString().isNotEmpty && 
             json['gift_file'].toString() != 'null') {
      animUrl = json['gift_file'].toString();
      print("   📁 Using gift_file field");
    }
    // Check gift_video third (video file)
    else if (json['gift_video'] != null && 
             json['gift_video'].toString().isNotEmpty && 
             json['gift_video'].toString() != 'null') {
      animUrl = json['gift_video'].toString();
      print("   🎥 Using gift_video field");
    }
    // Check animation_file as fallback
    else if (json['animation_file'] != null && 
             json['animation_file'].toString().isNotEmpty && 
             json['animation_file'].toString() != 'null') {
      animUrl = json['animation_file'].toString();
      print("   🎬 Using animation_file field");
    }
    else if (json['animationFile'] != null && 
             json['animationFile'].toString().isNotEmpty && 
             json['animationFile'].toString() != 'null') {
      animUrl = json['animationFile'].toString();
      print("   🎬 Using animationFile field");
    }
    
    // Normalize animation URL
    if (animUrl != null && animUrl.isNotEmpty && animUrl != 'null') {
      // If it's already a full URL (http/https), keep it as is
      if (animUrl.startsWith('http://') || animUrl.startsWith('https://')) {
        print("   ✅ Animation URL is already full URL: $animUrl");
      } else {
        // Convert relative path to full URL
        if (animUrl.startsWith('/')) {
          animUrl = animUrl.substring(1);
        }
        animUrl = 'https://shaheenstar.online/$animUrl';
        print("   ✅ Converted relative path to full URL: $animUrl");
      }
    } else {
      animUrl = null;
      print("   ⚠️ No animation URL found");
    }
    
    // ✅ Determine file type and log
    String? detectedFileType;
    String? detectedFileUrl;
    
    if (animUrl != null && animUrl.isNotEmpty) {
      detectedFileUrl = animUrl;
      final lowerUrl = animUrl.toLowerCase();
      if (lowerUrl.contains('.gif')) {
        detectedFileType = 'GIF';
      } else if (lowerUrl.contains('.mp4')) {
        detectedFileType = 'MP4';
      } else if (lowerUrl.contains('.webm')) {
        detectedFileType = 'WEBM';
      } else if (lowerUrl.contains('.mov')) {
        detectedFileType = 'MOV';
      } else if (lowerUrl.contains('.svga')) {
        detectedFileType = 'SVGA';
      } else if (lowerUrl.contains('video') || lowerUrl.contains('pexels') || lowerUrl.contains('youtube')) {
        detectedFileType = 'VIDEO_URL';
      } else {
        detectedFileType = 'ANIMATION';
      }
      print("   🎬 ✅ Animation/Video file detected: $detectedFileType");
      print("   🎬    URL: $detectedFileUrl");
      print("   ✅ Will display $detectedFileType instead of static PNG");
    } else {
      print("   ⚠️ NO animation/video file found");
      if (imageUrl != null) {
        print("   🖼️ Will display static image: $imageUrl");
        final imageExt = imageUrl.toLowerCase();
        if (imageExt.contains('.png')) {
          detectedFileType = 'PNG';
        } else if (imageExt.contains('.jpg') || imageExt.contains('.jpeg')) {
          detectedFileType = 'JPG';
        } else if (imageExt.contains('.gif')) {
          detectedFileType = 'GIF';
        } else {
          detectedFileType = 'IMAGE';
        }
        detectedFileUrl = imageUrl;
    } else {
        print("   ❌ NO image file found either");
        detectedFileType = 'NONE';
      }
    }
    
    print("   📊 Final: Type=$detectedFileType, URL=${detectedFileUrl ?? 'none'}");
    print("   ==========================================");
    
    return GiftModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['gift_name']?.toString() ?? json['name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? '',
      price: double.tryParse(json['gift_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      coinType: json['coin_type']?.toString().toLowerCase() ?? 'gold',
      description: json['description']?.toString(),
      image: imageUrl,
      animationFile: animUrl, // ✅ Contains gift_file or gift_video (prioritized)
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['isActive'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gift_name': name,
      'name': name,
      'category': category,
      'gift_price': price.toString(),
      'price': price.toString(),
      'coin_type': coinType,
      'description': description,
      'image': image,
      'animation_file': animationFile,
      'animationFile': animationFile,
      'is_active': isActive ? 1 : 0,
      'isActive': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter for formatted price
  String get formattedPrice {
    if (price % 1 == 0) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  // Helper to check if gift has animation
  bool get hasAnimation => animationFile != null && animationFile!.isNotEmpty;
}

class GiftResponse {
  final String status;
  final String? message;
  final List<GiftModel> gifts;
  final int? total;
  final int? limit;
  final int? offset;

  GiftResponse({
    required this.status,
    this.message,
    required this.gifts,
    this.total,
    this.limit,
    this.offset,
  });

  factory GiftResponse.fromJson(Map<String, dynamic> json) {
    List<GiftModel> giftsList = [];
    
    if (json['data'] != null) {
      if (json['data'] is List) {
        giftsList = (json['data'] as List)
            .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['data'] is Map) {
        final data = json['data'] as Map<String, dynamic>;
        if (data['gifts'] != null && data['gifts'] is List) {
          giftsList = (data['gifts'] as List)
              .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } else if (json['gifts'] != null && json['gifts'] is List) {
      giftsList = (json['gifts'] as List)
          .map((item) => GiftModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return GiftResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
      gifts: giftsList,
      total: json['total'] != null ? int.tryParse(json['total'].toString()) : null,
      limit: json['limit'] != null ? int.tryParse(json['limit'].toString()) : null,
      offset: json['offset'] != null ? int.tryParse(json['offset'].toString()) : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class SendGiftResponse {
  final String status;
  final String? message;
  final Map<String, dynamic>? data;

  SendGiftResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory SendGiftResponse.fromJson(Map<String, dynamic> json) {
    return SendGiftResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

