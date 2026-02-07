import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/room_ranking_model.dart';
import '../../model/room_gift_response.dart';
import 'period_toggle_provider.dart';


/// ================= USER RANKING MODEL =================
class UserRanking {
  final int userId;
  final String username;
  final int totalGold;

  // ✅ Additional user info
  final String? email;
  final String? country;
  final String? gender;
  final String? profileUrl;
  final String? googleId;
  final String? createdAt;
  final int? merchant;

  UserRanking({
    required this.userId,
    required this.username,
    required this.totalGold,
    this.email,
    this.country,
    this.gender,
    this.profileUrl,
    this.googleId,
    this.createdAt,
    this.merchant,
  });
}


/// ================= ROOM RANKING PROVIDER =================
class RoomRankingProvider with ChangeNotifier {

  String currentFilter = "sender"; // "sender" or "receiver"
bool _isLoading = false;
  String? _error;
  Map<int, Map<String, dynamic>> allUsersMap = {};
  PeriodType _currentPeriod = PeriodType.daily;

  List<UserRanking> _rankings = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  PeriodType get currentPeriod => _currentPeriod;

  /// 🔥 Top 3 users
  List<UserRanking> get topThreeUsers =>
      _rankings.length >= 3 ? _rankings.take(3).toList() : _rankings;

  /// 🔽 Remaining users
  List<UserRanking> get remainingUsers =>
      _rankings.length > 3 ? _rankings.sublist(3) : [];

  // ================= CHANGE PERIOD =================
  void changePeriod(PeriodType period) {
    _currentPeriod = period;
   
  }

  void setAllUsersMap(Map<int, Map<String, dynamic>> value) {
    allUsersMap = value;
    print("🔹 allUsersMap keys: set ${allUsersMap.keys.toList()}");
    print("🔹 allUsersMap values: set ${allUsersMap.values.toList()}");
  
    
    notifyListeners();
  }

  // ================= CHANGE FILTER (SENDER/RECEIVER) =================
  void changeFilter(String filter) {
    currentFilter = filter; // "sender" or "receiver"
  
    notifyListeners();
  }

  int? _roomId;

  // ================= SET ROOM ID =================
  void setRoomId(int? roomId) {
    _roomId = roomId;
  }

  // ================= FETCH FROM API =================
  Future<void> fetchRoomRanking({
  int? roomId,
  int? senderId,
  int? receiverId,
  required String type, // "sender" or "receiver"
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final currentRoomId = roomId ?? _roomId;

    final dateRange = _getDateRange(_currentPeriod);
    print("🔹 Fetching ranking for period: $_currentPeriod");
    print("🔹 Date range: ${dateRange['start']} - ${dateRange['end']}");

    final RoomGiftResponse response = await ApiManager.fetchRoomStats(
      roomId: currentRoomId,
      startDate: dateRange['start'],
      endDate: dateRange['end'],
      limit: 50,
      senderId: senderId,
      receiverId: receiverId,
    );

    print("✅ API call successful!");

    // Generate ranking depending on type
    _generateRanking(data: response, type: type);

  } catch (e) {
    _error = e.toString();
    print("❌ Error fetching room ranking: $_error");
    _rankings = [];
  }

  _isLoading = false;
  notifyListeners();
}

//   Future<void> fetchRoomRanking({int? roomId,  int? senderId,
//   int? receiverId,}) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       // Use provided roomId or stored roomId
//       final currentRoomId = roomId ?? _roomId;

//       // Get date range based on period
//         final dateRange = _getDateRange(_currentPeriod);
//             print("🔹 Fetching ranking for period: $_currentPeriod");
//     print("🔹 Date range: ${dateRange['start']} - ${dateRange['end']}");

// print(_roomId);
// print(roomId);


//       final RoomStatsResponse response = await ApiManager.fetchRoomStats(
//         roomId: currentRoomId,
//         startDate: dateRange['start'],
//       endDate: dateRange['end'],
//      //   sortBy: "gift_price",
//       //sortOrder: "DESC",
//       limit: 50,
//     senderId: senderId,
//     receiverId: receiverId

//       );

//       print("✅ API call successful!");
//       print("🔹 Total rooms received: ${response.rooms.length}");

//    _generateRanking(response.data.transactions);

//       // _rankings = response.rooms;
      
//       // // Sort based on current period - use GOLD VALUE for sorting (not gifts count)
//       // _rankings.sort((a, b) {
//       //   if (_currentPeriod == PeriodType.weekly) {
//       //     return b.weeklyGoldValue.compareTo(a.weeklyGoldValue);
//       //   } else if (_currentPeriod == PeriodType.monthly) {
//       //     return b.monthlyGoldValue.compareTo(a.monthlyGoldValue);
//       //   } else {
//       //     // Daily/Today - use todayGoldValue
//       //     return b.todayGoldValue.compareTo(a.todayGoldValue);
//       //   }
//       // });

//       // // Debug print to verify sorted data
//       // if (_rankings.isNotEmpty) {
//       //   final topRoom = _rankings.first;
//       //   print("🔹 Top room: ${topRoom.roomName}");
//       //   print("   - Today Gold: ${topRoom.todayGoldValue}");
//       //   print("   - Weekly Gold: ${topRoom.weeklyGoldValue}");
//       //   print("   - Monthly Gold: ${topRoom.monthlyGoldValue}");
//       //   print("   - Total Gold: ${topRoom.totalGoldValue}");
//       // } else {
//       //   print("🔹 No ranking data");
//       // }
//     } catch (e) {
//       _error = e.toString();
//       print("❌ Error fetching room ranking: $_error");
//       _rankings = [];
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

  

  // ================= NORMALIZE PROFILE URL =================
  String normalizeRoomProfileUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'jgh' ||
        profileUrl == 'null' ||
        profileUrl.trim().isEmpty) {
      return 'assets/images/person.png';
    }
    
    // ✅ If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }
    
    // ✅ If it starts with 'uploads/', 'room_profiles/', etc., it's a relative server path
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/') ||
        profileUrl.startsWith('gifts/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }
    
    // ✅ If it's a relative path (starts with /), check if it's a server path
    if (profileUrl.startsWith('/')) {
      String cleanPath = profileUrl.substring(1); // Remove leading slash
      return 'https://shaheenstar.online/$cleanPath';
    }
    
    // ✅ Unknown format - use placeholder
    return 'assets/images/person.png';
  }

  // ================= GET COINS FOR CURRENT PERIOD =================
  int getCoinsForPeriod(RoomRanking room) {
    switch (_currentPeriod) {
      case PeriodType.daily:
        return room.todayGoldValue;
      case PeriodType.weekly:
        return room.weeklyGoldValue;
      case PeriodType.monthly:
        return room.monthlyGoldValue;
    }
  }

  // ================= DATE RANGE =================
  Map<String, String> _getDateRange(PeriodType period) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

  switch (period) {
  case PeriodType.daily:
    final today = formatter.format(now);
    return {
      "start": today,
      "end": today,
    };

  case PeriodType.weekly:
    final startOfWeek = now.subtract(const Duration(days: 6));
    return {
      "start": formatter.format(startOfWeek),
      "end": formatter.format(now),
    };

  case PeriodType.monthly:
    final startOfMonth = DateTime(
      now.year,
      now.month - 1,
      now.day,
    );
    return {
      "start": formatter.format(startOfMonth),
      "end": formatter.format(now),
    };
}
  }


  // ================= RANKING LOGIC =================

  void _generateRanking({
  required RoomGiftResponse data,
  required String type, // "sender" or "receiver"
}) {
  print("🔹 Generating ranking | type: $type");

  final Map<int, UserRanking> rankingMap = {};

  /// ================= SINGLE ROOM =================
  if (data.data.room != null) {
    final users = type == "sender"
        ? data.data.room!.allSenders.list
        : data.data.room!.allReceivers.list;

    _aggregateUsers(
      users: users,
      rankingMap: rankingMap,
    );
  }

  /// ================= MULTIPLE ROOMS =================
  if (data.data.rooms != null) {
    for (final room in data.data.rooms!) {
      final users = type == "sender"
          ? room.allSenders.list
          : room.allReceivers.list;

      _aggregateUsers(
        users: users,
        rankingMap: rankingMap,
      );
    }
  }

  /// ================= FINAL SORT =================
  _rankings = rankingMap.values.toList()
    ..sort((a, b) => b.totalGold.compareTo(a.totalGold));

  print("✅ Final ranking count: ${_rankings.length}");
}

void _aggregateUsers({
  required List<User> users,
  required Map<int, UserRanking> rankingMap,
}) {
  for (final user in users) {
    final int userId = user.userId;
    final int coins = user.totalValue;

    if (rankingMap.containsKey(userId)) {
      final existing = rankingMap[userId]!;

      rankingMap[userId] = UserRanking(
        userId: userId,
        username: existing.username,
        totalGold: existing.totalGold + coins,
        email: existing.email,
        country: existing.country,
        gender: existing.gender,
        profileUrl: existing.profileUrl,
        googleId: existing.googleId,
        createdAt: existing.createdAt,
        merchant: existing.merchant,
      );
    } else {
      final userInfo = allUsersMap[userId];

      rankingMap[userId] = UserRanking(
        userId: userId,
        username: user.username,
        totalGold: coins,
        email: userInfo?['email'],
        country: userInfo?['country'],
        gender: userInfo?['gender'],
        profileUrl: userInfo?['profile_url'],
        googleId: userInfo?['google_id']?.toString(),
        createdAt: userInfo?['created_at'],
        merchant: userInfo?['merchant'],
      );
    }
  }
}


//   // ================= RANKING LOGIC =================
// void _generateRanking({
//   required RoomGiftResponse data,
//   required String type, // "sender" or "receiver"
// }) {
//   print("🔹 Starting _generateRanking for type: $type");
//   print("🔹 Data count: ${data.data.allSenders}");
//     print("🔹 Data count: ${data.data.allReceivers}");
//   print("🔹 Type: $type");
//   print("🔹 allUsersMap keys before ranking: ${allUsersMap.keys.toList()}");



//   List<User> users = type == "sender" 
//       ? data.data.allSenders.list 
//       : data.data.allReceivers.list;

//   print("🔹 Users count: ${users.length}");


//   // Aggregate total coins for ranking
//   Map<int, int> userCoinsMap = {};
//   Map<int, String> userNamesMap = {};
//   Map<int, Map<String, dynamic>?> userInfoMap = {};

//   for (var user in users) {
//     final int userId = user.senderId; // senderId and receiverId are same in User model
//     final int coins = type == "sender" ? user.totalValueSent : user.totalValueSent; // totalValueSent maps for both in User model

//     userCoinsMap[userId] = (userCoinsMap[userId] ?? 0) + coins;
//     userNamesMap[userId] = user.username;
//     // userInfoMap[userId] = user;

//         if (!userInfoMap.containsKey(userId)) {
//       userInfoMap[userId] = allUsersMap[userId];
//     }
//     print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
//       print(allUsersMap);
//     print(userInfoMap);
//   }

  

//   print("🔹 Aggregated coins for ${userCoinsMap.length} users");

//   // Create UserRanking list
//   _rankings = userCoinsMap.entries.map((entry) {
//     final int userId = entry.key;
//     final int totalGold = entry.value;
//     Map<String, dynamic>? userInfo = userInfoMap[userId];


//     print("🔹 User $userId: ${userNamesMap[userId]} - Total Coins: $totalGold");
//     print("   - User info from allUsersMap: $userInfo");


//     return UserRanking(
//       userId: userId,
//       username: userNamesMap[userId] ?? "Unknown",
//       totalGold: totalGold,
//        email: userInfo?['email'],
//       country: userInfo?['country'],
//       gender: userInfo?['gender'],
//       profileUrl: userInfo?['profile_url'],
//       googleId: userInfo?['google_id']?.toString(),
//       createdAt: userInfo?['created_at'],
//       merchant: userInfo?['merchant'],
//     );
//   }).toList();

//   // Sort descending by totalGold
//   _rankings.sort((a, b) => b.totalGold.compareTo(a.totalGold));

//   print("🔹 Rankings after sorting:");
//   for (var user in _rankings) {
//     print("   - ${user.username} (ID: ${user.userId}) | Total Gold: ${user.totalGold} | Profile: ${user.profileUrl}");
//   }

//     print("🔹 allUsersMap keys after ranking: ${allUsersMap.keys.toList()}");
//   print("🔹 allUsersMap values after ranking: ${allUsersMap.values.toList()}");

// }

// void _generateRanking(
//   List<GiftTransaction1> transactions, 
//   {int? senderId, int? receiverId,}
// ) {
//   print("🔹 Starting _generateRanking...");
//   print("🔹 Transactions count: ${transactions.length}");
//   print("🔹 senderId: $senderId, receiverId: $receiverId");
//   print("🔹 allUsersMap keys before ranking: ${allUsersMap.keys.toList()}");

//   // ✅ Map to aggregate coins by userId
//   Map<int, int> userCoinsMap = {};
//   Map<int, String> userNamesMap = {};
//   Map<int, Map<String, dynamic>?> userInfoMap = {};

//   // Group transactions by userId and sum coins
//   for (var tx in transactions) {
//     final int userKey = senderId != null ? tx.senderId : tx.receiverId;
    
//     // Sum coins for same user
//     userCoinsMap[userKey] = (userCoinsMap[userKey] ?? 0) + tx.giftPrice;
    
//     // Store username (use first non-empty one)
//     if (!userNamesMap.containsKey(userKey)) {
//       String displayName = senderId != null ? tx.senderUsername : tx.receiverUsername;
//       userNamesMap[userKey] = displayName;
//     }
    
//     // Store user info (from allUsersMap)

//     if (!userInfoMap.containsKey(userKey)) {
//       userInfoMap[userKey] = allUsersMap[userKey];
//     }
//     print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
//       print(allUsersMap);
//     print(userInfoMap);
//   }

//   print("🔹 Aggregated ${userCoinsMap.length} unique users from ${transactions.length} transactions");

//   // Create UserRanking list from aggregated data
//   _rankings = userCoinsMap.entries.map((entry) {
//     final int userKey = entry.key;
//     final int totalCoins = entry.value;
//     String displayName = userNamesMap[userKey] ?? "Unknown";
//     Map<String, dynamic>? userInfo = userInfoMap[userKey];

//     print("🔹 User $userKey: $displayName - Total Coins: $totalCoins");
//     print("   - User info from allUsersMap: $userInfo");

//     // Replace unknown or empty name with actual name from allUsersMap
//     if ((displayName.isEmpty || displayName == "Unknown") && userInfo != null) {
//       displayName = userInfo['name'] ?? displayName;
//       print("   - Updated displayName: $displayName");
//     }

//     return UserRanking(
//       userId: userKey,
//       username: displayName,
//       totalGold: totalCoins, // ✅ Total aggregated coins
//       email: userInfo?['email'],
//       country: userInfo?['country'],
//       gender: userInfo?['gender'],
//       profileUrl: userInfo?['profile_url'],
//       googleId: userInfo?['google_id']?.toString(),
//       createdAt: userInfo?['created_at'],
//       merchant: userInfo?['merchant'],
//     );
//   }).toList();

//   // Sort by total coins (descending)
//   _rankings.sort((a, b) => b.totalGold.compareTo(a.totalGold));

//   print("🔹 Rankings after sorting (${_rankings.length} unique users):");
//   for (var user in _rankings) {
//     print("   - ${user.username} (ID: ${user.userId}) | Total Gold: ${user.totalGold} | Profile: ${user.profileUrl}");
//   }

//   print("🔹 allUsersMap keys after ranking: ${allUsersMap.keys.toList()}");
//   print("🔹 allUsersMap values after ranking: ${allUsersMap.values.toList()}");
// }



}


  String normalizeRoomProfileUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'jgh' ||
        profileUrl == 'null' ||
        profileUrl.trim().isEmpty) {
      return 'assets/images/person.png';
    }
    
    // ✅ If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }
    
    // ✅ FIXED: Detect local file paths and return placeholder (don't try to load as network URL)
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.startsWith('/private/') ||
        profileUrl.startsWith('/var/') ||
        profileUrl.startsWith('/tmp/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.contains('cache/') ||
        profileUrl.contains('/com.example.') ||
        profileUrl.contains('/com.') ||
        profileUrl.startsWith('file://') ||
        profileUrl.contains('/data/user/')) {
      print("⚠️ [HomeScreen] Room profile is local file path, using placeholder: $profileUrl");
      return 'assets/images/person.png'; // Use placeholder for local paths
    }
    
    // ✅ If it starts with 'uploads/', 'room_profiles/', etc., it's a relative server path
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/') ||
        profileUrl.startsWith('gifts/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }
    
    // ✅ If it's a relative path (starts with /), check if it's a server path
    if (profileUrl.startsWith('/')) {
      // Double-check it's not a local path
      if (!profileUrl.contains('/data/') &&
          !profileUrl.contains('/storage/') &&
          !profileUrl.contains('/cache/') &&
          !profileUrl.contains('/com.')) {
        String cleanPath = profileUrl.substring(1); // Remove leading slash
        return 'https://shaheenstar.online/$cleanPath';
      } else {
        print("⚠️ [HomeScreen] Path starts with / but looks like local path: $profileUrl");
        return 'assets/images/person.png';
      }
    }
    
    // ✅ Unknown format - use placeholder
    print("⚠️ [HomeScreen] Unknown room profile format, using placeholder: $profileUrl");
    return 'assets/images/person.png';
  }

