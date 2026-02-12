import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/utils/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgencyProvider extends ChangeNotifier {
  final UserSession _session = UserSession();

  // State
  List<dynamic> _agencies = [];
  final List<dynamic> _userAgencies = [];
  List<dynamic> _agencyMembers = [];
  List<dynamic> _allUsers = [];
  Map<String, dynamic>? _userAgency;
  Map<String, dynamic>? _stats;
  
  bool _isLoading = false;
  bool _isInitializing = false;
  String? _error;

  // Getters
  List<dynamic> get agencies => _agencies;
  List<dynamic> get userAgencies => _userAgencies;
  List<dynamic> get agencyMembers => _agencyMembers;
  List<dynamic> get allUsers => _allUsers;
  Map<String, dynamic>? get userAgency => _userAgency;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentUserId => _session.userId;
  bool get isInitializing => _isInitializing;

  // Initialize
  Future<void> initialize() async {
    try {
      // Prevent multiple simultaneous initializations
      if (_isInitializing) {
        print('⚠️ [AgencyProvider] Already initializing, skipping...');
        return;
      }

      print('🚀 [AgencyProvider] Starting agency initialization...');
      _isInitializing = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load session first
      print('📂 [AgencyProvider] Loading user session...');
      await _session.loadSession();
      
      // Verify session is properly loaded
      if (!_session.isInitialized) {
        _handleError('Please login to use agency features', showToUser: true);
        return;
      }

      if (_session.userId == null) {
        _handleError('User ID not found. Please login again.', showToUser: true);
        return;
      }

      print('✅ [AgencyProvider] Session verified: UserID=${_session.userId}');

      // Clear any stale agency data first
      _userAgency = null;

      // Load initial data via HTTP API - run in parallel for faster loading
      await Future.wait([
        getAllAgencies(),
        getStats(),
      ]);

      // Fetch and validate: use get_my_agency as source of truth
      if (_session.userId != null) {
        print('🔍 [AgencyProvider] Fetching user agency for UserID=${_session.userId}');
        final response = await ApiManager.getMyAgency(userId: _session.userId!);
        print('📡 [AgencyProvider] API Response: ${response != null ? response['status'] : 'null'}');
        
        if (response != null && response['status'] == 'success') {
          if (response['data'] != null) {
            _userAgency = Map<String, dynamic>.from(response['data']);
            print('✅ [AgencyProvider] User has agency: ${_userAgency?['agency_name']} (ID: ${_userAgency?['id']})');
          } else {
            _userAgency = null;
            // Clear stale cache when user has no agency
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('agency_info_${_session.userId}');
            await prefs.remove('agency_info');
            print('ℹ️ [AgencyProvider] No agency found - cleared cache, user will see agency list');
          }
          notifyListeners();
        } else {
          // API error - keep userAgency as null, don't load from cache
          _userAgency = null;
          print('⚠️ [AgencyProvider] API error - keeping userAgency as null');
          notifyListeners();
        }
      }

      print('✅ [AgencyProvider] Agency initialization completed');

    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Initialization error: $e');
      print('Stack trace: $stackTrace');
      _handleError(
        'Failed to initialize agency. Please try again.', 
        showToUser: true,
        exception: e
      );
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enhanced error handling
  void _handleError(String errorMessage, {bool showToUser = false, dynamic exception}) {
    print('❌ [AgencyProvider] Error: $errorMessage');
    if (exception != null) {
      print('Exception: $exception');
    }
    
    if (showToUser) {
      _error = errorMessage;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void _handleSuccess(String message) {
    print('✅ [AgencyProvider] Success: $message');
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ========== PUBLIC METHODS ==========

  // Agency management methods
  Future<void> createAgency(String agencyName) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('🏢 [AgencyProvider] Creating agency via HTTP API: $agencyName');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.createAgency(
        userId: _session.userId!,
        agencyName: agencyName,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Agency created successfully');
        // Refresh agencies list
        await getAllAgencies();
        _handleSuccess('Agency created successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to create agency';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Create agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to create agency', showToUser: true, exception: e);
    }
  }

  Future<void> updateAgency(int agencyId, String agencyName) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('🏢 [AgencyProvider] Updating agency via HTTP API: $agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.updateAgency(
        agencyId: agencyId,
        userId: _session.userId!,
        agencyName: agencyName,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Agency updated successfully');
        // Refresh agencies list
        await getAllAgencies();
        _handleSuccess('Agency updated successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to update agency';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Update agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to update agency', showToUser: true, exception: e);
    }
  }

  Future<void> deleteAgency(int agencyId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('🏢 [AgencyProvider] Deleting agency via HTTP API: $agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.deleteAgency(
        agencyId: agencyId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Agency deleted successfully');
        // Refresh agencies list
        await getAllAgencies();
        _handleSuccess('Agency deleted successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to delete agency';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Delete agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to delete agency', showToUser: true, exception: e);
    }
  }

  Future<void> getAgency(int agencyId) async {
    try {
      print('🏢 [AgencyProvider] Getting agency via HTTP API: $agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.getAgency(agencyId: agencyId);
      
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null) {
          // Update or add to agencies list
          final agency = data is Map ? Map<String, dynamic>.from(data) : data;
          final agencyIdValue = agency['id'] ?? agency['agency_id'];
          final index = _agencies.indexWhere((a) => 
            (a is Map && (a['id'] ?? a['agency_id']) == agencyIdValue)
          );
          if (index != -1) {
            _agencies[index] = agency;
          } else {
            _agencies.insert(0, agency);
          }
        }
        print('✅ [AgencyProvider] Agency retrieved successfully');
        _handleSuccess('Agency retrieved successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get agency';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get agency', showToUser: true, exception: e);
    }
  }

  // Track retry attempts for getAllAgencies
  int _getAllAgenciesRetryCount = 0;
  bool _isRetryingGetAllAgencies = false;
  static const int _maxRetries = 3;

  Future<void> getAllAgencies({int limit = 50, int offset = 0, bool isRetry = false}) async {
    try {
      // If this is not a retry, reset the retry count
      if (!isRetry) {
        _getAllAgenciesRetryCount = 0;
        _isRetryingGetAllAgencies = false;
      }
      
      print('🏢 [AgencyProvider] Getting all agencies via HTTP API${isRetry ? " (retry attempt $_getAllAgenciesRetryCount)" : ""}');
      // Only set loading state if not already initializing (to avoid redundant state updates)
      if (!_isInitializing) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }
      
      // ✅ Use HTTP API via unified agency_manager.php endpoint
      final response = await ApiManager.getAllAgenciesViaManager(limit: limit, offset: offset);
      
      if (response != null && response['status'] == 'success') {
        // Reset retry count on success
        _getAllAgenciesRetryCount = 0;
        _isRetryingGetAllAgencies = false;
        
        // Parse response data
        final data = response['data'];
        if (data != null && data['agencies'] != null && data['agencies'] is List) {
          _agencies = List.from(data['agencies']);
          print('✅ [AgencyProvider] Loaded ${_agencies.length} agencies via HTTP API');
          // Only call _handleSuccess if not initializing (to avoid setting _isLoading = false prematurely)
          if (!_isInitializing) {
            _handleSuccess('Loaded ${_agencies.length} agencies');
          } else {
            _error = null;
            _isLoading = false;
            notifyListeners();
          }
        } else {
          _agencies = [];
          print('⚠️ [AgencyProvider] No agencies found in response');
          if (!_isInitializing) {
            _handleSuccess('No agencies found');
          } else {
            _error = null;
            _isLoading = false;
            notifyListeners();
          }
        }
      } else {
        // Handle error response
        final errorMsg = response?['message'] ?? 'Failed to load agencies';
        print('❌ [AgencyProvider] HTTP API error: $errorMsg');
        
        // Check for database connection errors - retry for these
        final errorMsgLower = errorMsg.toString().toLowerCase();
        final isDatabaseError = errorMsgLower.contains('mysql server has gone away') ||
            errorMsgLower.contains('database') ||
            errorMsgLower.contains('connection') ||
            errorMsgLower.contains('server has gone away');
        
        if (isDatabaseError) {
          print('🔄 [AgencyProvider] Database error detected, will retry...');
          _retryGetAllAgencies(limit: limit, offset: offset);
        } else {
          _getAllAgenciesRetryCount = 0;
          _isRetryingGetAllAgencies = false;
          _handleError(errorMsg, showToUser: true);
        }
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get all agencies error: $e');
      print('Stack trace: $stackTrace');
      
      // Check if it's a network error that should be retried
      final errorMsg = e.toString().toLowerCase();
      final isNetworkError = errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('failed host lookup');
      
      if (isNetworkError) {
        print('🔄 [AgencyProvider] Network error detected, will retry...');
        _retryGetAllAgencies(limit: limit, offset: offset);
      } else {
        _getAllAgenciesRetryCount = 0;
        _isRetryingGetAllAgencies = false;
        _handleError('Failed to get agencies', showToUser: true, exception: e);
      }
    }
  }

  // Retry getAllAgencies with exponential backoff for database errors
  void _retryGetAllAgencies({int limit = 50, int offset = 0}) {
    // Prevent multiple simultaneous retries
    if (_isRetryingGetAllAgencies) {
      print('⚠️ [AgencyProvider] Retry already in progress, skipping...');
      return;
    }

    if (_getAllAgenciesRetryCount >= _maxRetries) {
      print('❌ [AgencyProvider] Max retries ($_maxRetries) reached for getAllAgencies');
      _getAllAgenciesRetryCount = 0;
      _isRetryingGetAllAgencies = false;
      _handleError(
        'Unable to load agencies. The server is temporarily unavailable. Please try again later.',
        showToUser: true
      );
      return;
    }

    _getAllAgenciesRetryCount++;
    _isRetryingGetAllAgencies = true;
    final retryDelay = [2, 5, 10][_getAllAgenciesRetryCount - 1]; // seconds
    
    print('🔄 [AgencyProvider] Scheduling retry for getAllAgencies (attempt $_getAllAgenciesRetryCount/$_maxRetries) after ${retryDelay}s');
    
    Future.delayed(Duration(seconds: retryDelay), () {
      _isRetryingGetAllAgencies = false;
      // ✅ HTTP API doesn't need connection check, just retry
      getAllAgencies(limit: limit, offset: offset, isRetry: true);
    });
  }

  // Member management methods
  Future<void> addMember(int agencyId, int memberUserId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('👤 [AgencyProvider] Adding member via HTTP API: agencyId=$agencyId, memberUserId=$memberUserId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.addAgencyMember(
        agencyId: agencyId,
        userId: _session.userId!,
        memberUserId: memberUserId,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Member added successfully');
        // Refresh members list
        getMembers(agencyId);
        _handleSuccess('Member added successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to add member';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Add member error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to add member', showToUser: true, exception: e);
    }
  }

  Future<void> removeMember(int agencyId, int memberUserId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('👤 [AgencyProvider] Removing member via HTTP API: agencyId=$agencyId, memberUserId=$memberUserId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.removeAgencyMember(
        agencyId: agencyId,
        userId: _session.userId!,
        memberUserId: memberUserId,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Member removed successfully');
        // Refresh members list
        getMembers(agencyId);
        _handleSuccess('Member removed successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to remove member';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Remove member error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to remove member', showToUser: true, exception: e);
    }
  }

  Future<void> getMembers(int agencyId) async {
    try {
      print('👥 [AgencyProvider] Getting members via HTTP API: agencyId=$agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.getAgencyMembers(agencyId: agencyId);
      
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data['members'] != null && data['members'] is List) {
          _agencyMembers = List.from(data['members']);
          print('✅ [AgencyProvider] Loaded ${_agencyMembers.length} members via HTTP API');
          _handleSuccess('Loaded ${_agencyMembers.length} members');
        } else {
          _agencyMembers = [];
          _handleSuccess('No members found');
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get members';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get members error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get members', showToUser: true, exception: e);
    }
  }

  Future<void> getAllUsers({int limit = 100, int offset = 0}) async {
    try {
      print('👥 [AgencyProvider] Getting all users via HTTP API');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.getAllUsersViaAgencyManager(limit: limit, offset: offset);
      
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data['users'] != null && data['users'] is List) {
          _allUsers = List.from(data['users']);
          print('✅ [AgencyProvider] Loaded ${_allUsers.length} users via HTTP API');
          _handleSuccess('Loaded ${_allUsers.length} users');
        } else {
          _allUsers = [];
          _handleSuccess('No users found');
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get users';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get all users error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get users', showToUser: true, exception: e);
    }
  }

  Future<void> getUser(int userId) async {
    try {
      print('👤 [AgencyProvider] Getting user via HTTP API: userId=$userId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.getUserViaAgencyManager(userId: userId);
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] User retrieved via HTTP API');
        _handleSuccess('User retrieved successfully');
        // User data is in response['data'] if needed
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get user';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get user error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get user', showToUser: true, exception: e);
    }
  }

  Future<void> getStats() async {
    try {
      print('📊 [AgencyProvider] Getting stats via HTTP API');
      // Don't set loading state for stats (non-blocking)
      
      final response = await ApiManager.getAgencyStats();
      
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        // Stats are directly in data, not in data['stats']
        if (data != null && data is Map) {
          _stats = Map<String, dynamic>.from(data);
          print('✅ [AgencyProvider] Stats loaded via HTTP API: $_stats');
          notifyListeners();
        } else {
          _stats = null;
          print('⚠️ [AgencyProvider] No stats data in response');
        }
      } else {
        // Stats error is non-critical, just log it
        final errorMsg = response?['message'] ?? 'Failed to get stats';
        print('⚠️ [AgencyProvider] Stats error (non-critical): $errorMsg');
        _stats = null; // Set to null so UI doesn't break
        notifyListeners();
      }
    } catch (e) {
      // Stats error is non-critical, just log it
      print('⚠️ [AgencyProvider] Get stats error (non-critical): $e');
      _stats = null;
      notifyListeners();
    }
  }

  Future<void> joinAgency(int agencyId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('🚪 [AgencyProvider] Joining agency via HTTP API: agencyId=$agencyId');
      // Join agency is same as adding member (user joins as member)
      await addMember(agencyId, _session.userId!);
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Join agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to join agency', showToUser: true, exception: e);
    }
  }

  Future<void> leaveAgency(int agencyId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('🚪 [AgencyProvider] Leaving agency via HTTP API: agencyId=$agencyId');
      // Leave agency is same as removing member (user leaves by removing themselves)
      await removeMember(agencyId, _session.userId!);
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Leave agency error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to leave agency', showToUser: true, exception: e);
    }
  }

  Future<void> searchAgencies(String searchTerm, {int limit = 20, int offset = 0}) async {
    try {
      print('🔍 [AgencyProvider] Searching agencies via HTTP API: searchTerm=$searchTerm');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Get all agencies first, then filter client-side
      final response = await ApiManager.getAllAgenciesViaManager(limit: 100, offset: 0);
      
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        if (data != null && data['agencies'] != null && data['agencies'] is List) {
          final allAgencies = List<dynamic>.from(data['agencies']);
          
          // Filter agencies by search term (case-insensitive)
          final searchLower = searchTerm.toLowerCase();
          final filteredAgencies = allAgencies.where((agency) {
            final agencyName = (agency['agency_name'] ?? '').toString().toLowerCase();
            final agencyCode = (agency['agency_code'] ?? '').toString().toLowerCase();
            final ownerName = (agency['owner_username'] ?? '').toString().toLowerCase();
            return agencyName.contains(searchLower) || 
                   agencyCode.contains(searchLower) || 
                   ownerName.contains(searchLower);
          }).toList();
          
          // Apply limit and offset
          final startIndex = offset;
          final endIndex = (startIndex + limit).clamp(0, filteredAgencies.length);
          _agencies = filteredAgencies.sublist(
            startIndex.clamp(0, filteredAgencies.length),
            endIndex,
          );
          
          print('✅ [AgencyProvider] Found ${filteredAgencies.length} agencies matching "$searchTerm"');
          _handleSuccess('Found ${filteredAgencies.length} agencies');
        } else {
          _agencies = [];
          _handleSuccess('No agencies found');
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to search agencies';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Search agencies error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to search agencies', showToUser: true, exception: e);
    }
  }

  // Refresh data method
  Future<void> refresh() async {
    print('🔄 [AgencyProvider] Manual refresh requested');
    _error = null;
    _isLoading = true;
    notifyListeners();
    
    // Reload data
    await getAllAgencies();
    await getStats();
  }

  // Clear error manually
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load user agency from SharedPreferences (from login response)
  Future<void> _loadUserAgencyFromStorage() async {
    try {
      if (_session.userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final agencyInfoJson = prefs.getString('agency_info_${_session.userId}') ?? 
                            prefs.getString('agency_info');
      
      if (agencyInfoJson != null) {
        final agencyInfo = jsonDecode(agencyInfoJson);
        // User owns an agency (agency_details from backend, owned_agency from model toJson)
        final agencyDetails = agencyInfo['agency_details'] ?? agencyInfo['owned_agency'];
        if ((agencyInfo['has_agency'] == true || agencyInfo['has_agency'] == 1) &&
            agencyDetails != null) {
          _userAgency = Map<String, dynamic>.from(agencyDetails);
          if (_userAgency!['id'] == null && _userAgency!['agency_id'] != null) {
            _userAgency!['id'] = _userAgency!['agency_id'];
          }
          // Storage agency_details lacks user_id - set it so owner gets admin page
          if (_userAgency!['user_id'] == null && _session.userId != null) {
            _userAgency!['user_id'] = _session.userId;
          }
          print('✅ [AgencyProvider] Loaded owned agency from storage: ${_userAgency?['agency_name']}');
          notifyListeners();
          return;
        }
        // User joined an agency (member_agencies from backend, agencies from model toJson)
        final memberAgencies = agencyInfo['member_agencies'] ?? agencyInfo['agencies'];
        final isMember = agencyInfo['is_member_of_agency'] == true ||
            agencyInfo['is_member_of_agency'] == 1 ||
            agencyInfo['is_member'] == true ||
            agencyInfo['is_member'] == 1;
        if (isMember && memberAgencies != null && memberAgencies is List && memberAgencies.isNotEmpty) {
          final first = memberAgencies.first;
          if (first is Map) {
            _userAgency = Map<String, dynamic>.from(first);
            if (_userAgency!['id'] == null && _userAgency!['agency_id'] != null) {
              _userAgency!['id'] = _userAgency!['agency_id'];
            }
            print('✅ [AgencyProvider] Loaded joined agency from storage: ${_userAgency?['agency_name']}');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('⚠️ [AgencyProvider] Error loading user agency from storage: $e');
    }
  }

  // Fetch user's agency from API if not in storage (owner OR member)
  Future<void> _fetchUserAgency() async {
    try {
      if (_session.userId == null) return;

      // First check if user owns an agency in the agencies list (already loaded)
      try {
        final owned = _agencies.firstWhere(
          (agency) => agency is Map && (agency['user_id'] == _session.userId),
        );
        _userAgency = Map<String, dynamic>.from(owned);
        print('✅ [AgencyProvider] Found owned agency in agencies list');
        notifyListeners();
        return;
      } catch (_) {}

      // Call get_my_agency API (handles owner + member in one query)
      final response = await ApiManager.getMyAgency(userId: _session.userId!);
      if (response != null && response['status'] == 'success' && response['data'] != null) {
        _userAgency = Map<String, dynamic>.from(response['data']);
        print('✅ [AgencyProvider] Fetched user agency via get_my_agency API');
        notifyListeners();
      } else {
        print('ℹ️ [AgencyProvider] User has no agency (owner or member)');
      }
    } catch (e) {
      print('⚠️ [AgencyProvider] Error fetching user agency: $e');
    }
  }

  // Set user agency (called from login response)
  void setUserAgency(Map<String, dynamic>? agency) {
    _userAgency = agency;
    notifyListeners();
  }

  // ========== AGENCY REQUESTS METHODS ==========

  List<dynamic> _joinRequests = [];
  List<dynamic> _quitRequests = [];
  
  List<dynamic> get joinRequests => _joinRequests;
  List<dynamic> get quitRequests => _quitRequests;

  /// Create join request
  Future<void> createJoinRequest(int agencyId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Creating join request: agencyId=$agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.createJoinRequest(
        userId: _session.userId!,
        agencyId: agencyId,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Join request created successfully');
        _handleSuccess('Join request sent successfully');
      } else {
        // Handle error response
        final errorMsg = response?['message'] ?? 'Failed to create join request';
        
        // Check if backend returned wrong response format (agencies list instead of join request response)
        if (response != null && response['data'] != null && response['data']['agencies'] != null) {
          print('⚠️ [AgencyProvider] Backend returned agencies list instead of join request response');
          _handleError('Backend error: Invalid response format. Please try again.', showToUser: true);
        } else {
          _handleError(errorMsg, showToUser: true);
        }
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Create join request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to create join request', showToUser: true, exception: e);
    }
  }

  /// Get join requests (for agency owner)
  Future<void> getJoinRequests(int agencyId, {bool skipLoadingState = false}) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Getting join requests: agencyId=$agencyId');
      if (!skipLoadingState) {
        _isLoading = true;
        _error = null;
        // Defer notifyListeners to avoid calling during build
        Future.microtask(() => notifyListeners());
      }
      
      final response = await ApiManager.getJoinRequests(
        agencyId: agencyId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        _joinRequests = response['data'] is List 
            ? List.from(response['data']) 
            : [];
        print('✅ [AgencyProvider] Loaded ${_joinRequests.length} join requests');
        if (!skipLoadingState) {
          _handleSuccess('Loaded ${_joinRequests.length} join requests');
        } else {
          _isLoading = false;
          _error = null;
          Future.microtask(() => notifyListeners());
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get join requests';
        if (!skipLoadingState) {
          _handleError(errorMsg, showToUser: true);
        } else {
          _isLoading = false;
          _error = errorMsg;
          Future.microtask(() => notifyListeners());
        }
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get join requests error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get join requests', showToUser: true, exception: e);
    }
  }

  /// Accept join request
  Future<void> acceptJoinRequest(int requestId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Accepting join request: requestId=$requestId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.acceptJoinRequest(
        requestId: requestId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Join request accepted successfully');
        // Remove from pending requests
        _joinRequests.removeWhere((req) => req['request_id'] == requestId);
        _handleSuccess('User accepted into agency');
        // Refresh members list
        final agencyId = _userAgency?['id'] ?? _userAgency?['agency_id'];
        if (agencyId != null) {
          await getMembers(agencyId);
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to accept join request';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Accept join request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to accept join request', showToUser: true, exception: e);
    }
  }

  /// Decline join request
  Future<void> declineJoinRequest(int requestId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Declining join request: requestId=$requestId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.declineJoinRequest(
        requestId: requestId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Join request declined successfully');
        // Remove from pending requests
        _joinRequests.removeWhere((req) => req['request_id'] == requestId);
        _handleSuccess('Request declined');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to decline join request';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Decline join request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to decline join request', showToUser: true, exception: e);
    }
  }

  /// Create quit request
  Future<void> createQuitRequest(int agencyId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Creating quit request: agencyId=$agencyId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.createQuitRequest(
        userId: _session.userId!,
        agencyId: agencyId,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Quit request created successfully');
        _handleSuccess('Quit request sent successfully');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to create quit request';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Create quit request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to create quit request', showToUser: true, exception: e);
    }
  }

  /// Get quit requests (for agency owner)
  Future<void> getQuitRequests(int agencyId, {bool skipLoadingState = false}) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Getting quit requests: agencyId=$agencyId');
      if (!skipLoadingState) {
        _isLoading = true;
        _error = null;
        // Defer notifyListeners to avoid calling during build
        Future.microtask(() => notifyListeners());
      }
      
      final response = await ApiManager.getQuitRequests(
        agencyId: agencyId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        _quitRequests = response['data'] is List 
            ? List.from(response['data']) 
            : [];
        print('✅ [AgencyProvider] Loaded ${_quitRequests.length} quit requests');
        if (!skipLoadingState) {
          _handleSuccess('Loaded ${_quitRequests.length} quit requests');
        } else {
          _isLoading = false;
          _error = null;
          Future.microtask(() => notifyListeners());
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to get quit requests';
        if (!skipLoadingState) {
          _handleError(errorMsg, showToUser: true);
        } else {
          _isLoading = false;
          _error = errorMsg;
          Future.microtask(() => notifyListeners());
        }
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Get quit requests error: $e');
      print('Stack trace: $stackTrace');
      if (!skipLoadingState) {
        _handleError('Failed to get quit requests', showToUser: true, exception: e);
      } else {
        _isLoading = false;
        _error = 'Failed to get quit requests';
        Future.microtask(() => notifyListeners());
      }
    }
  }

  /// Accept quit request
  Future<void> acceptQuitRequest(int requestId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Accepting quit request: requestId=$requestId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.acceptQuitRequest(
        requestId: requestId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Quit request accepted successfully');
        // Remove from pending requests
        _quitRequests.removeWhere((req) => req['request_id'] == requestId);
        _handleSuccess('User removed from agency');
        // Refresh members list
        final agencyId = _userAgency?['id'] ?? _userAgency?['agency_id'];
        if (agencyId != null) {
          await getMembers(agencyId);
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to accept quit request';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Accept quit request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to accept quit request', showToUser: true, exception: e);
    }
  }

  /// Decline quit request
  Future<void> declineQuitRequest(int requestId) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      print('📋 [AgencyProvider] Declining quit request: requestId=$requestId');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await ApiManager.declineQuitRequest(
        requestId: requestId,
        userId: _session.userId!,
      );
      
      if (response != null && response['status'] == 'success') {
        print('✅ [AgencyProvider] Quit request declined successfully');
        // Remove from pending requests
        _quitRequests.removeWhere((req) => req['request_id'] == requestId);
        _handleSuccess('Quit request declined');
      } else {
        final errorMsg = response?['message'] ?? 'Failed to decline quit request';
        _handleError(errorMsg, showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ [AgencyProvider] Decline quit request error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to decline quit request', showToUser: true, exception: e);
    }
  }

}

