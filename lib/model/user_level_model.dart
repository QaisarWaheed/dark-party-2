class UserLevelModel {
  final int userId;
  final LevelInfo sending;
  final LevelInfo receiving;
  final int totalSendingExp;
  final int totalReceivingExp;

  UserLevelModel({
    required this.userId,
    required this.sending,
    required this.receiving,
    required this.totalSendingExp,
    required this.totalReceivingExp,
  });

  factory UserLevelModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    

    final sendingData = data['sending'];
    final receivingData = data['receiving'];
    
    LevelInfo sendingLevel;
    LevelInfo receivingLevel;
    
    // ✅ Parse sending level
    if (sendingData == null) {
      sendingLevel = LevelInfo.defaultLevel();
    } else if (sendingData is Map<String, dynamic>) {

      sendingLevel = LevelInfo.fromJson(sendingData);
    } else if (sendingData is int || sendingData is String) {
      // Format 2: Direct level number (e.g., 193)
      final levelValue = int.tryParse(sendingData.toString()) ?? 0;
      sendingLevel = LevelInfo.fromLevelValue(levelValue);
    } else {
      sendingLevel = LevelInfo.defaultLevel();
    }
    
    // ✅ Parse receiving level
    if (receivingData == null) {
      receivingLevel = LevelInfo.defaultLevel();
    } else if (receivingData is Map<String, dynamic>) {
      // Format 1: Object with nested fields (expected format from backend)
      // Example: {"current_level": 12, "current_exp": 800000, ...}
      receivingLevel = LevelInfo.fromJson(receivingData);
    } else if (receivingData is int || receivingData is String) {
      // Format 2: Direct level number (e.g., 193)
      final levelValue = int.tryParse(receivingData.toString()) ?? 0;
      receivingLevel = LevelInfo.fromLevelValue(levelValue);
    } else {
      receivingLevel = LevelInfo.defaultLevel();
    }
    
    return UserLevelModel(
      userId: int.parse(data['user_id'].toString()),
      sending: sendingLevel,
      receiving: receivingLevel,
      totalSendingExp: data['total_sending_exp'] != null 
          ? int.parse(data['total_sending_exp'].toString())
          : 0,
      totalReceivingExp: data['total_receiving_exp'] != null
          ? int.parse(data['total_receiving_exp'].toString())
          : 0,
    );
  }
}

class LevelInfo {
  final int currentLevel;
  final int currentExp;
  final int minExp;
  final int maxExp;
  final int expToNextLevel;
  final double progressPercentage;
  final int levelRange;

  LevelInfo({
    required this.currentLevel,
    required this.currentExp,
    required this.minExp,
    required this.maxExp,
    required this.expToNextLevel,
    required this.progressPercentage,
    required this.levelRange,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      currentLevel: json['current_level'] != null
          ? int.parse(json['current_level'].toString())
          : 0,
      currentExp: json['current_exp'] != null
          ? int.parse(json['current_exp'].toString())
          : 0,
      minExp: json['min_exp'] != null
          ? int.parse(json['min_exp'].toString())
          : 0,
      maxExp: json['max_exp'] != null
          ? int.parse(json['max_exp'].toString())
          : 0,
      expToNextLevel: json['exp_to_next_level'] != null
          ? int.parse(json['exp_to_next_level'].toString())
          : 0,
      progressPercentage: json['progress_percentage'] != null
          ? double.parse(json['progress_percentage'].toString())
          : 0.0,
      levelRange: json['level_range'] != null
          ? int.parse(json['level_range'].toString())
          : 0,
    );
  }
  
  /// ✅ Default level for users with no level data
  factory LevelInfo.defaultLevel() {
    return LevelInfo(
      currentLevel: 0,
      currentExp: 0,
      minExp: 0,
      maxExp: 0,
      expToNextLevel: 0,
      progressPercentage: 0.0,
      levelRange: 0,
    );
  }
  
  /// ✅ Create LevelInfo from a direct level value (when backend returns just the level number)
  factory LevelInfo.fromLevelValue(int level) {
    return LevelInfo(
      currentLevel: level,
      currentExp: 0, // Not provided in simple format
      minExp: 0, // Not provided in simple format
      maxExp: 0, // Not provided in simple format
      expToNextLevel: 0, // Not provided in simple format
      progressPercentage: 0.0, // Not provided in simple format
      levelRange: 0, // Not provided in simple format
    );
  }
}

