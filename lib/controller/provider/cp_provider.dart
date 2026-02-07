
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import '../../model/cp_gift_response.dart';
import 'cp_toggle_provider.dart';


/// ================= CP PROVIDER =================
class CpProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  CpPeriodType _currentPeriod = CpPeriodType.Ranking;

  List<CpUser> users=[];
    List<CpUser> usersProfile=[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  CpPeriodType get currentPeriod => _currentPeriod;

  // ================= CHANGE PERIOD =================
  void changeCpPeriod(CpPeriodType period) {
    _currentPeriod = period;
  }

// ================= FETCH FROM API =================
Future<void> fetchCpWall(
) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
   
    final response =
        await ApiManager.fetchCpUser(
    );

users.clear();
users = response.data.users;

print(users);
   
    print("✅ API call successful!");
    print("🔹 Top Three Cps received:");

    notifyListeners();
      
    
  } catch (e) {
    _error = e.toString();
    print("❌ Error fetching cp: $_error");
  }
  _isLoading = false;
  notifyListeners();
}


// ================= FETCH FROM API =================
Future<void> fetchCpRanking(
) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
   
    final response =
        await ApiManager.fetchCpRankingUser(
    );

users.clear();
users = response.data.users;

print(users);
   
    print("✅ API call successful!");
    print("🔹 Cps received:");

    notifyListeners();
      
    
  } catch (e) {
    _error = e.toString();
    print("❌ Error fetching cp: $_error");
  }
  _isLoading = false;
  notifyListeners();
}


// ================= FETCH FROM API =================
Future<void> fetchCpRankingByUserId(String userId
) async {
  print("🔍 [CpProvider] fetchCpRankingByUserId called with userId: $userId");
  _isLoading = true;
  _error = null;

  try {
   
    final response =
        await ApiManager.fetchCpRankingUserById(userId
    );

users.clear();
users = response.data.users;

print("✅ [CpProvider] CP data loaded successfully!");
print("🔹 [CpProvider] Total CP users: ${users.length}");
if (users.isNotEmpty) {
  print("🔹 [CpProvider] CP Partner: ${users[0].cpUser?.name ?? 'No name'}");
  print("🔹 [CpProvider] totalDiamond: ${users[0].totalDiamond}");
  print("🔹 [CpProvider] cpSince: ${users[0].cpSince}");
  print("🔹 [CpProvider] id: ${users[0].id}");
}
   
    print("✅ API call successful!");
    print("🔹 Cps received:");

    notifyListeners();
      
    
  } catch (e) {
    _error = e.toString();
    print("❌ Error fetching cp: $_error");
  }
  _isLoading = false;
  notifyListeners();
}

// Remove CP partner
Future<void> removeCpPartner(String userId) async {
  print("🔍 [CpProvider] removeCpPartner called with userId: $userId");
  _isLoading = true;
  _error = null;

  try {
    final response = await ApiManager.removeCpPartner(userId);
    
    print("✅ [CpProvider] CP partner removed successfully!");
    
    // Clear the users list after removal
    users.clear();
    
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    print("❌ Error removing CP partner: $_error");
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
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



// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
// import 'package:shaheen_star_app/model/gift_transaction_model.dart';
// import '../../model/room_gift_response.dart';
// import 'cp_toggle_provider.dart';
// import 'period_toggle_provider.dart';

// /// ================= USER RANKING MODEL =================
// class UserCpRanking {
//   final int userId;
//   final String username;
//   final int totalGold;

//   // ✅ Additional user info
//   final String? email;
//   final String? country;
//   final String? gender;
//   final String? profileUrl;
//   final String? googleId;
//   final String? createdAt;
//   final int? merchant;

//   UserCpRanking({
//     required this.userId,
//     required this.username,
//     required this.totalGold,
//     this.email,
//     this.country,
//     this.gender,
//     this.profileUrl,
//     this.googleId,
//     this.createdAt,
//     this.merchant,
//   });
// }


// /// ================= CP PROVIDER =================
// class CpProvider with ChangeNotifier {
//   bool _isLoading = false;
//     String currentFilter = "ranking";
//   String? _error;
//   Map<int, Map<String, dynamic>> allUsersMap = {};
//   CpPeriodType _currentPeriod = CpPeriodType.Ranking;

//   List<UserCpRanking> _cpRankings = [];

//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   CpPeriodType get currentPeriod => _currentPeriod;

//   /// 🔥 Top 3 users
//   List<UserCpRanking> get topThreeUsers =>
//       _cpRankings.length >= 3 ? _cpRankings.take(3).toList() : _cpRankings;

//   /// 🔽 Remaining users
//   List<UserCpRanking> get remainingUsers =>
//       _cpRankings.length > 3 ? _cpRankings.sublist(3) : [];

//   // ================= CHANGE PERIOD =================
//   void changeCpPeriod(CpPeriodType period) {
//     _currentPeriod = period;
//   }

//   void setAllUsersMap(Map<int, Map<String, dynamic>> value) {
//     allUsersMap = value;
//     print("🔹 allUsersMap keys: set ${allUsersMap.keys.toList()}");
//     print("🔹 allUsersMap values: set ${allUsersMap.values.toList()}");
  
    
//     notifyListeners();
//   }

//   // ================= CHANGE FILTER (SENDER/RECEIVER) =================
//   void changeFilter(String filter) {
//     currentFilter = filter; 
  
//     notifyListeners();
//   }

// // // ================= FETCH FROM API =================
// // Future<void> fetchRanking({
// //   int? senderId,
// //   int? receiverId,
// //   required String type, 
// // }) async {
// //   _isLoading = true;
// //   _error = null;
// //   notifyListeners();
// //   try {
// //     final dateRange = _getDateRange(_currentPeriod);
// //     print("🔹 Fetching ranking for period: $_currentPeriod");
// //     print("🔹 Date range: ${dateRange['start']} - ${dateRange['end']}");
// //     print("🔹 Sender ID: $senderId, Receiver ID: $receiverId");
// //     final RoomGiftResponse response =
// //         await ApiManager.fetchRoomStats(
// //       startDate: dateRange['start'],
// //       endDate: dateRange['end'],
// //       limit: 50,
// //       senderId: senderId,
// //     receiverId: receiverId
// //     );
// //     print("✅ API call successful!");
// //     print("🔹 Total Rooms received: ${response.data.rooms!.length}");
// //       _generateRanking(data: response, type: type);
// //     print("🔹 Top user: ${_rankings.isNotEmpty ? _rankings.first.username + ' - ' + _rankings.first.totalGold.toString() : 'No data'}");
// //   } catch (e) {
// //     _error = e.toString();
// //     print("❌ Error fetching ranking: $_error");
// //   }
// //   _isLoading = false;
// //   notifyListeners();
// // }



//   // ================= CP RANKING LOGIC =================

//   void _generateCpRanking({
//   required RoomGiftResponse data,
//   required String type, 
// }) {
//   print("🔹 Generating cp ranking | type: $type");

//   final Map<int, UserCpRanking> cpRankingMap = {};

//   /// ================= SINGLE ROOM =================
//   if (data.data.room != null) {
//     final users = type == "sender"
//         ? data.data.room!.allSenders.list
//         : data.data.room!.allReceivers.list;

//     _aggregateUsers(
//       users: users,
//       cpRankingMap: cpRankingMap,
//     );
//   }

//   /// ================= MULTIPLE ROOMS =================
//   if (data.data.rooms != null) {
//     for (final room in data.data.rooms!) {
//       final users = type == "sender"
//           ? room.allSenders.list
//           : room.allReceivers.list;

//       _aggregateUsers(
//         users: users,
//         cpRankingMap: cpRankingMap,
//       );
//     }
//   }

//   /// ================= FINAL SORT =================
//   _cpRankings = cpRankingMap.values.toList()
//     ..sort((a, b) => b.totalGold.compareTo(a.totalGold));

//   print("✅ Final cp ranking count: ${_cpRankings.length}");
// }

// void _aggregateUsers({
//   required List<User> users,
//   required Map<int, UserCpRanking> cpRankingMap,
// }) {
//   for (final user in users) {
//     final int userId = user.userId;
//     final int coins = user.totalValue;

//     if (cpRankingMap.containsKey(userId)) {
//       final existing = cpRankingMap[userId]!;

//       cpRankingMap[userId] = UserCpRanking(
//         userId: userId,
//         username: existing.username,
//         totalGold: existing.totalGold + coins,
//         email: existing.email,
//         country: existing.country,
//         gender: existing.gender,
//         profileUrl: existing.profileUrl,
//         googleId: existing.googleId,
//         createdAt: existing.createdAt,
//         merchant: existing.merchant,
//       );
//     } else {
//       final userInfo = allUsersMap[userId];

//       cpRankingMap[userId] = UserCpRanking(
//         userId: userId,
//         username: user.username,
//         totalGold: coins,
//         email: userInfo?['email'],
//         country: userInfo?['country'],
//         gender: userInfo?['gender'],
//         profileUrl: userInfo?['profile_url'],
//         googleId: userInfo?['google_id']?.toString(),
//         createdAt: userInfo?['created_at'],
//         merchant: userInfo?['merchant'],
//       );
//     }
//   }
// }

//   // ================= DATE RANGE =================
//   Map<String, String> _getDateRange(CpPeriodType period) {
//     final now = DateTime.now();
//     final formatter = DateFormat('yyyy-MM-dd');

//   switch (period) {
//   case CpPeriodType.Ranking:
//     final today = formatter.format(now);
//     return {
//       "start": today,
//       "end": today,
//     };

//   case CpPeriodType.CpWall:
//     final startOfWeek = now.subtract(const Duration(days: 6));
//     return {
//       "start": formatter.format(startOfWeek),
//       "end": formatter.format(now),
//     };
// }
//   }

//   String normalizeRoomProfileUrl(String? profileUrl) {
//     if (profileUrl == null ||
//         profileUrl.isEmpty ||
//         profileUrl == 'yyyy' ||
//         profileUrl == 'Profile Url' ||
//         profileUrl == 'upload' ||
//         profileUrl == 'jgh' ||
//         profileUrl == 'null' ||
//         profileUrl.trim().isEmpty) {
//       return 'assets/images/person.png';
//     }
    
//     // ✅ If it's already a network URL, return as is
//     if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
//       return profileUrl;
//     }
    
//     // ✅ FIXED: Detect local file paths and return placeholder (don't try to load as network URL)
//     if (profileUrl.startsWith('/data/') ||
//         profileUrl.startsWith('/storage/') ||
//         profileUrl.startsWith('/private/') ||
//         profileUrl.startsWith('/var/') ||
//         profileUrl.startsWith('/tmp/') ||
//         profileUrl.contains('/cache/') ||
//         profileUrl.contains('cache/') ||
//         profileUrl.contains('/com.example.') ||
//         profileUrl.contains('/com.') ||
//         profileUrl.startsWith('file://') ||
//         profileUrl.contains('/data/user/')) {
//       print("⚠️ [HomeScreen] Room profile is local file path, using placeholder: $profileUrl");
//       return 'assets/images/person.png'; // Use placeholder for local paths
//     }
    
//     // ✅ If it starts with 'uploads/', 'room_profiles/', etc., it's a relative server path
//     if (profileUrl.startsWith('uploads/') ||
//         profileUrl.startsWith('images/') ||
//         profileUrl.startsWith('profiles/') ||
//         profileUrl.startsWith('room_profiles/') ||
//         profileUrl.startsWith('gifts/')) {
//       return 'https://shaheenstar.online/$profileUrl';
//     }
    
//     // ✅ If it's a relative path (starts with /), check if it's a server path
//     if (profileUrl.startsWith('/')) {
//       // Double-check it's not a local path
//       if (!profileUrl.contains('/data/') &&
//           !profileUrl.contains('/storage/') &&
//           !profileUrl.contains('/cache/') &&
//           !profileUrl.contains('/com.')) {
//         String cleanPath = profileUrl.substring(1); // Remove leading slash
//         return 'https://shaheenstar.online/$cleanPath';
//       } else {
//         print("⚠️ [HomeScreen] Path starts with / but looks like local path: $profileUrl");
//         return 'assets/images/person.png';
//       }
//     }
    
//     // ✅ Unknown format - use placeholder
//     print("⚠️ [HomeScreen] Unknown room profile format, using placeholder: $profileUrl");
//     return 'assets/images/person.png';
//   }

  
// }
