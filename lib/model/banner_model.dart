// class BannerItem {
//   final String id;
//   final String userId;
//   final String country;
//   final String imagePath;
//   final String redirectUrl;

//   BannerItem({
//     required this.id,
//     required this.userId,
//     required this.country,
//     required this.imagePath,
//     required this.redirectUrl,
//   });

//   factory BannerItem.fromJson(Map<String, dynamic> json) {
//     return BannerItem(
//       id: json['id'] ?? '',
//       userId: json['user_id'] ?? '',
//       country: json['country'] ?? '',
//       imagePath: json['image_path'] ?? '',
//       redirectUrl: json['redirect_url'] ?? '',
//     );
//   }
// }

// class BannerModel {
//   final String status;
//   final String message;
//   final int total;
//   final List<BannerItem> banners;

//   BannerModel({
//     required this.status,
//     required this.message,
//     required this.total,
//     required this.banners,
//   });

//   factory BannerModel.fromJson(Map<String, dynamic> json) {
//     return BannerModel(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
//       banners: json['banners'] == null
//           ? []
//           : List<BannerItem>.from(
//               json['banners'].map((x) => BannerItem.fromJson(x))),
//     );
//   }
// }
class BannerModel {
  final String status;
  final String message;
  final int total;
  final List<BannerItem> banners;

  BannerModel({
    required this.status,
    required this.message,
    required this.total,
    required this.banners,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final total = json['total'];
    final totalInt = total is int ? total : (int.tryParse(total?.toString() ?? '0') ?? 0);
    // Support multiple response shapes: "banners", "data" (list or map with banners), "banner_list"
    List<BannerItem> list = (json['banners'] as List<dynamic>?)
        ?.map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ?? [];
    if (list.isEmpty && json['data'] != null) {
      final data = json['data'];
      if (data is List) {
        list = data
            .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (data is Map) {
        final inner = data as Map<String, dynamic>;
        final innerList = inner['banners'] as List<dynamic>? ?? inner['list'] as List<dynamic>?;
        if (innerList != null) {
          list = innerList
              .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    }
    if (list.isEmpty && json['banner_list'] != null && json['banner_list'] is List) {
      list = (json['banner_list'] as List)
          .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return BannerModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      total: totalInt,
      banners: list,
    );
  }
}

class BannerItem {
  final String id;
  final String userId;
  final String country;
  final String imagePath;
  final String redirectUrl;

  BannerItem({
    required this.id,
    required this.userId,
    required this.country,
    required this.imagePath,
    required this.redirectUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    // Support image_path, image, url, img for image
    final imagePath = json['image_path']?.toString() ??
        json['image']?.toString() ??
        json['url']?.toString() ??
        json['img']?.toString() ??
        '';
    return BannerItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      imagePath: imagePath,
      redirectUrl: json['redirect_url']?.toString() ?? json['link']?.toString() ?? '',
    );
  }

  /// ✅ Getter to build full image URL
  String get fullImageUrl {
    const String baseUrl = "https://shaheenstar.online/"; // ✅ Real base URL
    if (imagePath.isEmpty || imagePath == 'null') {
      return ''; // Return empty if no image path
    }
    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // If starts with /, remove it and add base URL
    if (imagePath.startsWith('/')) {
      return "$baseUrl${imagePath.substring(1)}";
    }
    // Otherwise, add base URL
    return "$baseUrl$imagePath";
  }
}
