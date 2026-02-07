import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/banner_model.dart';


class BannerProvider extends ChangeNotifier {
  List<BannerItem> get banners => bannerModel?.banners ?? [];

  bool isLoading = false;
  BannerModel? bannerModel;

  
  Future<void> fetchBanners(String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString('token') ?? prefs.getString('api_token');
      bannerModel = await ApiManager.getUserBanners(userId: userId, apiToken: apiToken);
      if (bannerModel != null && bannerModel!.banners.isEmpty && apiToken != null && apiToken.isNotEmpty) {
        final retryModel = await ApiManager.getUserBanners(userId: userId, apiToken: null);
        if (retryModel != null && retryModel.banners.isNotEmpty) {
          bannerModel = retryModel;
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [BannerProvider] fetchBanners: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  
}
