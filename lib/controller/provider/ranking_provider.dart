import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
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


/// ================= RANKING PROVIDER =================
class RankingProvider with ChangeNotifier {
  bool _isLoading = false;
    String currentFilter = "sender";
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
  void changePeriod(PeriodType period, {int? senderId, int? receiverId}) {
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

// ================= FETCH FROM API =================
Future<void> fetchRanking({
  int? senderId,
  int? receiverId,
  required String type, 
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final dateRange = _getDateRange(_currentPeriod);
    print("🔹 Fetching ranking for period: $_currentPeriod");
    print("🔹 Date range: ${dateRange['start']} - ${dateRange['end']}");
    print("🔹 Sender ID: $senderId, Receiver ID: $receiverId");
    final RoomGiftResponse response =
        await ApiManager.fetchRoomStats(
      startDate: dateRange['start'],
      endDate: dateRange['end'],
      limit: 50,
      senderId: senderId,
    receiverId: receiverId
    );
    print("✅ API call successful!");
    print("🔹 Total Rooms received: ${response.data.rooms!.length}");
      _generateRanking(data: response, type: type);
    print("🔹 Top user: ${_rankings.isNotEmpty ? '${_rankings.first.username} - ${_rankings.first.totalGold}' : 'No data'}");
  } catch (e) {
    _error = e.toString();
    print("❌ Error fetching ranking: $_error");
  }
  _isLoading = false;
  notifyListeners();
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
// void _generateRanking({
//   required RoomGiftResponse data,
//   required String type, // "sender" or "receiver"
// }) {
//   print("🔹 Generating unified $type ranking from ALL rooms...");

//   final Map<int, UserRanking> rankingMap = {};

//   // 🔥 Loop through ALL rooms
//   for (final room in data.data.rooms ?? []) {
//     final users = type == "sender"
//         ? room.allSenders.list
//         : room.allReceivers.list;

//     for (final user in users) {
//       final int userId = user.userId;
//       final int coins = user.totalValue;

//       if (rankingMap.containsKey(userId)) {
//         // ✅ Aggregate coins if user already exists
//         rankingMap[userId] = UserRanking(
//           userId: userId,
//           username: rankingMap[userId]!.username,
//           totalGold: rankingMap[userId]!.totalGold + coins,
//           email: rankingMap[userId]!.email,
//           country: rankingMap[userId]!.country,
//           gender: rankingMap[userId]!.gender,
//           profileUrl: rankingMap[userId]!.profileUrl,
//           googleId: rankingMap[userId]!.googleId,
//           createdAt: rankingMap[userId]!.createdAt,
//           merchant: rankingMap[userId]!.merchant,
//         );
//       } else {
//         // ✅ First time entry (unique user)
//         rankingMap[userId] = UserRanking(
//           userId: userId,
//           username: user.username,
//           totalGold: coins,
//           email: null,
//           country: null,
//           gender: null,
//           profileUrl: null,
//           googleId: null,
//           createdAt: null,
//           merchant: null,
//         );
//       }
//     }
//   }

//   // 🔽 Convert map → sorted list
//   _rankings = rankingMap.values.toList()
//     ..sort((a, b) => b.totalGold.compareTo(a.totalGold));

//   print("✅ Final unified ${type.toUpperCase()} ranking:");
//   for (final u in _rankings) {
//     print("   ${u.username} → ${u.totalGold}");
//   }
// }




//   // ================= RANKING LOGIC =================
// void _generateRanking({
//     required RoomGiftResponse data,
//   required String type, // "sender" or "receiver"
// }
// ) {
//   print("🔹 Starting _generateRanking...");
//    List<User> users = type == "sender" 
//       ? data.data.allSenders.list 
//       : data.data.allReceivers.list;
//         print("🔹 Users count: ${users.length}");
//   // Aggregate total coins for ranking
//   Map<int, int> userCoinsMap = {};
//   Map<int, String> userNamesMap = {};
//   Map<int, User> userInfoMap = {};

  
//   for (var user in users) {
//     final int userId = user.senderId; // senderId and receiverId are same in User model
//     final int coins = type == "sender" ? user.totalValueSent : user.totalValueSent; // totalValueSent maps for both in User model

//     userCoinsMap[userId] = (userCoinsMap[userId] ?? 0) + coins;
//     userNamesMap[userId] = user.username;
//     userInfoMap[userId] = user;
//   }

//   print("🔹 Aggregated coins for ${userCoinsMap.length} users");

//   // Create UserRanking list
//   _rankings = userCoinsMap.entries.map((entry) {
//     final int userId = entry.key;
//     final int totalGold = entry.value;
//     final User userInfo = userInfoMap[userId]!;

//     return UserRanking(
//       userId: userId,
//       username: userNamesMap[userId] ?? "Unknown",
//       totalGold: totalGold,
//       email: null,
//       country: null,
//       gender: null,
//       profileUrl: userInfo.profilePic,
//       googleId: null,
//       createdAt: null,
//       merchant: null,
//     );
//   }).toList();

//   // Sort descending by totalGold
//   _rankings.sort((a, b) => b.totalGold.compareTo(a.totalGold));

//   print("🔹 Rankings after sorting:");
//   for (var user in _rankings) {
//     print("   - ${user.username} | Total Gold: ${user.totalGold}");
//   }
// }




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

  
}
