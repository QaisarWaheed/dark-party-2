class StoreCategory {
  final String id;
  final String name;

  StoreCategory({
    required this.id,
    required this.name,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: json['id']?.toString().toLowerCase() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class StoreItem {
  final int id;
  final String itemName;
  final String price; // Legacy field - will use price_7_days or price_30_days
  final String? price7Days; // Price for 7 days
  final String? price30Days; // Price for 30 days
  final String imageUrl;
  final String? category;
  final String? animationFile; // SVGA, SVG, or video file
  final String? svgaFile; // SVGA animation file
  final String? svgFile; // SVG file
  final String? description; // Item description
  final String? status; // Item status (active, inactive, etc.)
  final String? createdAt; // Creation timestamp
  final String? updatedAt; // Update timestamp

  StoreItem({
    required this.id,
    required this.itemName,
    required this.price,
    this.price7Days,
    this.price30Days,
    required this.imageUrl,
    this.category,
    this.animationFile,
    this.svgaFile,
    this.svgFile,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    // Handle image URL
    String? imageUrl = json['image_url']?.toString() ?? 
                       json['imageUrl']?.toString() ??
                       json['image']?.toString();
    
    // Convert relative path to full URL if needed
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
      if (!imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
        if (imageUrl.startsWith('/')) {
          imageUrl = imageUrl.substring(1);
        }
        imageUrl = 'https://shaheenstar.online/$imageUrl';
      } else if (imageUrl.contains('api.shaheenapp.com')) {
        // ✅ Convert api.shaheenapp.com URLs to shaheenstar.online to avoid certificate issues
        imageUrl = imageUrl.replaceAll('api.shaheenapp.com', 'shaheenstar.online');
        print("   🔄 [StoreItem] Converted imageUrl from api.shaheenapp.com to shaheenstar.online");
      }
    } else {
      imageUrl = null;
    }

    // Handle animation files - check multiple fields
    // Priority: svga_url (new API) > item_svga (SVGA) > item_svg (SVG) > animation_file > item_file
    String? animUrl;
    String? svgaUrl;
    String? svgUrl;

    // Helper function to normalize URLs (convert api.shaheenapp.com to shaheenstar.online)
    String normalizeUrl(String url) {
      if (url.contains('api.shaheenapp.com')) {
        final normalized = url.replaceAll('api.shaheenapp.com', 'shaheenstar.online');
        print("   🔄 [StoreItem] Normalized URL: $url -> $normalized");
        return normalized;
      }
      // Also handle if URL contains the domain in different formats
      if (url.contains('shaheenapp.com')) {
        final normalized = url.replaceAll('shaheenapp.com', 'shaheenstar.online');
        print("   🔄 [StoreItem] Normalized URL (shaheenapp.com): $url -> $normalized");
        return normalized;
      }
      return url;
    }

    // Check svga_url first (new API field - highest priority)
    if (json['svga_url'] != null && 
        json['svga_url'].toString().isNotEmpty && 
        json['svga_url'].toString() != 'null') {
      svgaUrl = normalizeUrl(json['svga_url'].toString());
      animUrl = svgaUrl;
      print("   🎨 [StoreItem] Using svga_url field (SVGA): $svgaUrl");
    }
    // Check item_svga second (SVGA animation file)
    else if (json['item_svga'] != null && 
        json['item_svga'].toString().isNotEmpty && 
        json['item_svga'].toString() != 'null') {
      svgaUrl = normalizeUrl(json['item_svga'].toString());
      animUrl = svgaUrl;
      print("   🎨 [StoreItem] Using item_svga field (SVGA): $svgaUrl");
    }
    // Check item_svg third (SVG file)
    else if (json['item_svg'] != null && 
             json['item_svg'].toString().isNotEmpty && 
             json['item_svg'].toString() != 'null') {
      svgUrl = normalizeUrl(json['item_svg'].toString());
      animUrl = svgUrl;
      print("   🎨 [StoreItem] Using item_svg field (SVG): $svgUrl");
    }
    // Check animation_file fourth
    else if (json['animation_file'] != null && 
             json['animation_file'].toString().isNotEmpty && 
             json['animation_file'].toString() != 'null') {
      animUrl = normalizeUrl(json['animation_file'].toString());
      print("   🎬 [StoreItem] Using animation_file field: $animUrl");
    }
    // Check item_file as fallback
    else if (json['item_file'] != null && 
             json['item_file'].toString().isNotEmpty && 
             json['item_file'].toString() != 'null') {
      animUrl = normalizeUrl(json['item_file'].toString());
      print("   📁 [StoreItem] Using item_file field: $animUrl");
    }

    // Normalize animation URL (handle relative paths)
    if (animUrl != null && animUrl.isNotEmpty && animUrl != 'null') {
      if (!animUrl.startsWith('http://') && !animUrl.startsWith('https://')) {
        // Convert relative path to full URL
        if (animUrl.startsWith('/')) {
          animUrl = animUrl.substring(1);
        }
        animUrl = 'https://shaheenstar.online/$animUrl';
      }
      
      // Ensure svgaUrl and svgUrl are also normalized if they were set
      if (svgaUrl != null && svgaUrl == animUrl) {
        // If svgaUrl was used as animUrl, ensure it's the same normalized value
        svgaUrl = animUrl;
      } else if (svgaUrl != null && !svgaUrl.startsWith('http://') && !svgaUrl.startsWith('https://')) {
        // Convert relative path to full URL
        if (svgaUrl.startsWith('/')) {
          svgaUrl = svgaUrl.substring(1);
        }
        svgaUrl = 'https://shaheenstar.online/$svgaUrl';
      }
      
      if (svgUrl != null && !svgUrl.startsWith('http://') && !svgUrl.startsWith('https://')) {
        // Convert relative path to full URL
        if (svgUrl.startsWith('/')) {
          svgUrl = svgUrl.substring(1);
        }
        svgUrl = 'https://shaheenstar.online/$svgUrl';
      }
    } else {
      animUrl = null;
    }

    // Handle prices - support both new API (price_7_days, price_30_days) and legacy (price)
    String? price7Days = json['price_7_days']?.toString();
    String? price30Days = json['price_30_days']?.toString();
    String legacyPrice = json['price']?.toString() ?? 
                        price7Days ?? 
                        price30Days ?? 
                        '0.00';

    return StoreItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      itemName: json['item_name']?.toString() ?? 
                json['itemName']?.toString() ?? 
                '',
      price: legacyPrice,
      price7Days: price7Days,
      price30Days: price30Days,
      imageUrl: imageUrl ?? '',
      category: json['category']?.toString().toLowerCase(),
      animationFile: animUrl,
      svgaFile: svgaUrl,
      svgFile: svgUrl,
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'price': price,
      'price_7_days': price7Days,
      'price_30_days': price30Days,
      'image_url': imageUrl,
      'category': category,
      'animation_file': animationFile,
      'svga_url': svgaFile,
      'item_svga': svgaFile,
      'item_svg': svgFile,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper to get price as double (uses legacy price or price_7_days as fallback)
  double get priceAsDouble {
    return double.tryParse(price) ?? 0.0;
  }

  // Helper to get price for 7 days as double
  double get price7DaysAsDouble {
    return price7Days != null ? (double.tryParse(price7Days!) ?? 0.0) : priceAsDouble;
  }

  // Helper to get price for 30 days as double
  double get price30DaysAsDouble {
    return price30Days != null ? (double.tryParse(price30Days!) ?? 0.0) : priceAsDouble;
  }

  // Helper to get price based on selected days
  double getPriceForDays(int days) {
    if (days <= 7) {
      return price7DaysAsDouble;
    } else {
      return price30DaysAsDouble;
    }
  }

  // Helper to check if item has animation
  bool get hasAnimation => animationFile != null && animationFile!.isNotEmpty;
  
  // Helper to check if item has SVGA animation
  bool get hasSvgaAnimation => svgaFile != null && svgaFile!.isNotEmpty;
  
  // Helper to check if item has SVG
  bool get hasSvg => svgFile != null && svgFile!.isNotEmpty;
}

class BackpackItem {
  final int backpackId;
  final int itemId;
  final String itemCategory;
  final String expiresAt;
  final String itemName;
  final String imageUrl;
  final String? svgaUrl; // SVGA animation URL
  final int daysRemaining;
  final String status; // "active" or "expired"

  BackpackItem({
    required this.backpackId,
    required this.itemId,
    required this.itemCategory,
    required this.expiresAt,
    required this.itemName,
    required this.imageUrl,
    this.svgaUrl,
    required this.daysRemaining,
    required this.status,
  });

  factory BackpackItem.fromJson(Map<String, dynamic> json) {
    // Helper to normalize URLs
    String? normalizeUrl(String? url) {
      if (url == null || url.isEmpty || url == 'null') return null;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // Convert api.shaheenapp.com or your-domain.com to shaheenstar.online
        if (url.contains('api.shaheenapp.com')) {
          return url.replaceAll('api.shaheenapp.com', 'shaheenstar.online');
        }
        if (url.contains('your-domain.com')) {
          return url.replaceAll('your-domain.com', 'shaheenstar.online');
        }
        return url;
      }
      // Convert relative path to full URL
      if (url.startsWith('/')) {
        url = url.substring(1);
      }
      return 'https://shaheenstar.online/$url';
    }

    String? imageUrl = normalizeUrl(json['image_url']?.toString() ?? 
                                    json['imageUrl']?.toString() ??
                                    json['image']?.toString()) ?? '';

    String? svgaUrl = normalizeUrl(json['svga_url']?.toString() ??
                                   json['svgaUrl']?.toString());

    return BackpackItem(
      backpackId: json['backpack_id'] != null 
          ? int.tryParse(json['backpack_id'].toString()) ?? 0 
          : 0,
      itemId: json['item_id'] != null 
          ? int.tryParse(json['item_id'].toString()) ?? 0 
          : 0,
      itemCategory: json['item_category']?.toString().toLowerCase() ?? 
                    json['itemCategory']?.toString().toLowerCase() ?? 
                    '',
      expiresAt: json['expires_at']?.toString() ?? 
                 json['expiresAt']?.toString() ?? 
                 '',
      itemName: json['item_name']?.toString() ?? 
                json['itemName']?.toString() ?? 
                '',
      imageUrl: imageUrl,
      svgaUrl: svgaUrl,
      daysRemaining: json['days_remaining'] != null 
          ? int.tryParse(json['days_remaining'].toString()) ?? 0 
          : 0,
      status: json['status']?.toString().toLowerCase() ?? 'expired',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backpack_id': backpackId,
      'item_id': itemId,
      'item_category': itemCategory,
      'expires_at': expiresAt,
      'item_name': itemName,
      'image_url': imageUrl,
      'svga_url': svgaUrl,
      'days_remaining': daysRemaining,
      'status': status,
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
}

class MallResponse {
  final String status;
  final String? message;
  final List<StoreCategory> categories;
  final Map<String, List<StoreItem>> itemsByCategory;

  MallResponse({
    required this.status,
    this.message,
    required this.categories,
    required this.itemsByCategory,
  });

  factory MallResponse.fromJson(Map<String, dynamic> json) {
    List<StoreCategory> categoriesList = [];
    Map<String, List<StoreItem>> itemsMap = {};

    if (json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      
      // Parse categories
      if (data['categories'] != null && data['categories'] is List) {
        categoriesList = (data['categories'] as List)
            .map((item) => StoreCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Parse items by category
      if (data['items_by_category'] != null && 
          data['items_by_category'] is Map) {
        final itemsByCat = data['items_by_category'] as Map<String, dynamic>;
        itemsByCat.forEach((categoryKey, itemsList) {
          if (itemsList is List) {
            // Handle both empty arrays and arrays with items
            if (itemsList.isEmpty) {
              itemsMap[categoryKey.toLowerCase()] = [];
            } else {
              itemsMap[categoryKey.toLowerCase()] = itemsList
                  .map((item) => StoreItem.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          }
        });
      }
    }

    return MallResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
      categories: categoriesList,
      itemsByCategory: itemsMap,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class PurchaseResponse {
  final String status;
  final String message;
  final int? newBalance;
  final String? itemName;
  final String? expiresAt;

  PurchaseResponse({
    required this.status,
    required this.message,
    this.newBalance,
    this.itemName,
    this.expiresAt,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    return PurchaseResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      newBalance: data != null && data['new_balance'] != null
          ? int.tryParse(data['new_balance'].toString())
          : null,
      itemName: data?['item_name']?.toString(),
      expiresAt: data?['expires_at']?.toString(),
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class BackpackResponse {
  final String status;
  final String? message;
  final int totalItems;
  final int activeItems;
  final List<BackpackItem> items;

  BackpackResponse({
    required this.status,
    this.message,
    required this.totalItems,
    required this.activeItems,
    required this.items,
  });

  factory BackpackResponse.fromJson(Map<String, dynamic> json) {
    List<BackpackItem> itemsList = [];
    final data = json['data'] as Map<String, dynamic>?;

    if (data != null) {
      // Parse items list
      if (data['items'] != null && data['items'] is List) {
        itemsList = (data['items'] as List)
            .map((item) => BackpackItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return BackpackResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
      totalItems: data != null && data['total_items'] != null
          ? int.tryParse(data['total_items'].toString()) ?? 0
          : 0,
      activeItems: data != null && data['active_items'] != null
          ? int.tryParse(data['active_items'].toString()) ?? 0
          : 0,
      items: itemsList,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

