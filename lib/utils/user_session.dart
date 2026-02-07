import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // User data
  int? _userId;
  String? _username;
  String? _name;
  String? _email;
  String? _profileUrl;
  String? _token;
  bool _isInitialized = false;

  // Getters
  int? get userId => _userId;
  String? get username => _username;
  String? get name => _name;
  String? get email => _email;
  String? get profileUrl => _profileUrl;
  String? get token => _token;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isInitialized && _userId != null;

  // Initialize session (alias for loadSession)
  Future<void> initialize() async {
    await loadSession();
  }

  // Load session from SharedPreferences with flexible type handling
  Future<void> loadSession() async {
    try {
      print('📂 Loading user session from storage...');
      final prefs = await SharedPreferences.getInstance();
      
      // First, print all keys to debug
      final allKeys = prefs.getKeys();
      print('🔑 Available keys in SharedPreferences: $allKeys');
      
      // ✅ Handle userId as both int and String
      final userIdValue = prefs.get('user_id');
      print('🆔 Raw user_id value: $userIdValue (type: ${userIdValue?.runtimeType})');
      
      if (userIdValue != null) {
        if (userIdValue is int) {
          _userId = userIdValue;
        } else if (userIdValue is String) {
          _userId = int.tryParse(userIdValue);
        }
      }
      
      _username = prefs.getString('username');
      _name = prefs.getString('name');
      
      // ✅ FALLBACK: If name is null, use username
      if (_name == null && _username != null) {
        _name = _username;
        print('⚠️ Name was null, using username as fallback: $_name');
      }
      
      _email = prefs.getString('email');
      _profileUrl = prefs.getString('profile_url');
      _token = prefs.getString('token');
      
      // ✅ FALLBACK: If token is null, try api_token
      if (_token == null) {
        _token = prefs.getString('api_token');
        if (_token != null) {
          print('⚠️ Token was null, using api_token as fallback');
        }
      }
      
      // Debug print
      print('📊 Loaded values:');
      print('   UserID: $_userId');
      print('   Username: $_username');
      print('   Name: $_name');
      print('   Email: $_email');
      print('   Profile URL: $_profileUrl');
      print('   Token exists: ${_token != null}');
      
      if (_userId != null && _username != null && _name != null) {
        _isInitialized = true;
        print('✅ Session loaded successfully');
      } else {
        print('⚠️ Incomplete session data - Cannot initialize');
        print('   Missing values:');
        if (_userId == null) print('   ❌ UserID is null');
        if (_username == null) print('   ❌ Username is null');
        if (_name == null) print('   ❌ Name is null');
        _isInitialized = false;
      }
    } catch (e, stackTrace) {
      print('❌ Failed to load session: $e');
      print('📍 Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  // Save session after login - handles both int and String for userId
  Future<void> saveSession({
    required dynamic userId,  // Can be int or String
    required String username,
    required String name,
    String? email,
    String? profileUrl,
    String? token,
  }) async {
    try {
      print('💾 Saving user session...');
      final prefs = await SharedPreferences.getInstance();
      
      // Convert userId to int if it's a String
      int finalUserId;
      if (userId is int) {
        finalUserId = userId;
      } else if (userId is String) {
        finalUserId = int.parse(userId);
      } else {
        throw Exception('Invalid userId type: ${userId.runtimeType}');
      }
      
      await prefs.setInt('user_id', finalUserId);
      await prefs.setString('username', username);
      await prefs.setString('name', name);
      
      if (email != null) {
        await prefs.setString('email', email);
      }
      if (profileUrl != null) {
        await prefs.setString('profile_url', profileUrl);
      }
      if (token != null) {
        await prefs.setString('token', token);
      }
      
      _userId = finalUserId;
      _username = username;
      _name = name;
      _email = email;
      _profileUrl = profileUrl;
      _token = token;
      _isInitialized = true;
      
      print('✅ Session saved successfully');
      print('   UserID: $_userId');
      print('   Username: $_username');
    } catch (e) {
      print('❌ Failed to save session: $e');
      throw Exception('Failed to save session: $e');
    }
  }

  // Update profile URL
  Future<void> updateProfileUrl(String profileUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_url', profileUrl);
      _profileUrl = profileUrl;
      print('✅ Profile URL updated: $profileUrl');
    } catch (e) {
      print('❌ Failed to update profile URL: $e');
    }
  }

  // Update user name
  Future<void> updateName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      _name = name;
      print('✅ Name updated: $name');
    } catch (e) {
      print('❌ Failed to update name: $e');
    }
  }

  // Clear session on logout
  Future<void> clearSession() async {
    try {
      print('🗑️ Clearing user session...');
      final prefs = await SharedPreferences.getInstance();
      
      // Clear specific keys instead of all
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('profile_url');
      await prefs.remove('token');
      
      _userId = null;
      _username = null;
      _name = null;
      _email = null;
      _profileUrl = null;
      _token = null;
      _isInitialized = false;
      
      print('✅ Session cleared successfully');
    } catch (e) {
      print('❌ Failed to clear session: $e');
      throw Exception('Failed to clear session: $e');
    }
  }

  // Check if user is logged in
  Future<bool> checkLoginStatus() async {
    if (!_isInitialized) {
      await loadSession();
    }
    return isLoggedIn;
  }

  // Print all SharedPreferences keys for debugging
  Future<void> debugPrintAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('🔍 All SharedPreferences keys:');
      for (var key in keys) {
        final value = prefs.get(key);
        print('   $key: $value (${value.runtimeType})');
      }
    } catch (e) {
      print('❌ Failed to debug keys: $e');
    }
  }

  // Print session info (for debugging)
  void printSessionInfo() {
      print('✅ User session initialized: $_username');
    print('✅ User ID: $_userId');
    print('✅ Username: $_username');
    print('✅ Name: $_name');
    print('✅ Email: $_email');
    print('✅ Profile URL: $_profileUrl');
    print('✅ Token: $_token');
  }


 
 

 
}