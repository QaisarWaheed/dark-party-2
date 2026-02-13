import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/components/follow_button.dart';
import 'package:shaheen_star_app/model/get_all_room_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:shaheen_star_app/view/screens/profile/detailed_profile_screen.dart';
import 'package:shaheen_star_app/view/screens/room/room_screen.dart';
import 'package:shaheen_star_app/components/profile_with_frame.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<GetAllRoomModel> _allRooms = [];
  List<GetAllRoomModel> _filteredRooms = [];
  bool _isLoadingUsers = false;
  bool _isLoadingRooms = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    // ✅ Load data after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
      _loadRooms();
      // Initialize follow provider
      final followProvider = Provider.of<UserFollowProvider>(
        context,
        listen: false,
      );
      followProvider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterUsers();
      _filterRooms();
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await ApiManager.getAllUsers();
      if (!mounted) return;
      setState(() {
        _allUsers = users.cast<Map<String, dynamic>>();
        // ✅ Start with empty filtered list - only show when searching
        _filteredUsers =
            []; // Empty by default, will be populated when user searches
        _isLoadingUsers = false;
      });
    } catch (e) {
      print("❌ Error loading users: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final roomProvider = Provider.of<GetAllRoomProvider>(
        context,
        listen: false,
      );
      await roomProvider.fetchRooms();
      if (!mounted) return;
      setState(() {
        _allRooms = roomProvider.rooms;
        // ✅ Start with empty filtered list - only show when searching
        _filteredRooms =
            []; // Empty by default, will be populated when user searches
        _isLoadingRooms = false;
      });
    } catch (e) {
      print("❌ Error loading rooms: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingRooms = false;
      });
    }
  }

  void _filterUsers() {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    print(_searchQuery);
    // ✅ Only show results when user searches (not empty by default)
    if (_searchQuery.isEmpty) {
      _filteredUsers = [];
      return;
    }

    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    print(_allUsers);
    _filteredUsers = _allUsers.where((user) {
      // ✅ Search by user ID
      final userId =
          (user['id']?.toString() ?? user['user_id']?.toString() ?? '')
              .toLowerCase();

      return userId.contains(_searchQuery);
    }).toList();
  }

  void _filterRooms() {
    // ✅ Only show results when user searches (not empty by default)
    if (_searchQuery.isEmpty) {
      _filteredRooms = [];
      return;
    }

    _filteredRooms = _allRooms.where((room) {
      // ✅ Search by room ID
      final roomId = room.id.toLowerCase();
      final roomCode = room.roomCode.toLowerCase();

      return roomId.contains(_searchQuery) || roomCode.contains(_searchQuery);
    }).toList();
  }

  String _normalizeProfileUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'null') {
      return 'assets/images/person.png';
    }

    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }

    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.startsWith('file://')) {
      return 'assets/images/person.png';
    }

    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }

    if (profileUrl.startsWith('/')) {
      String cleanPath = profileUrl.substring(1);
      return 'https://shaheenstar.online/$cleanPath';
    }

    return 'assets/images/person.png';
  }

  String _normalizeRoomProfileUrl(String? profileUrl) {
    if (profileUrl == null ||
        profileUrl.isEmpty ||
        profileUrl == 'yyyy' ||
        profileUrl == 'Profile Url' ||
        profileUrl == 'upload' ||
        profileUrl == 'null') {
      return 'assets/images/person.png';
    }

    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }

    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.contains('/cache/') ||
        profileUrl.startsWith('file://')) {
      return 'assets/images/person.png';
    }

    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('room_profiles/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }

    if (profileUrl.startsWith('/')) {
      String cleanPath = profileUrl.substring(1);
      return 'https://shaheenstar.online/$cleanPath';
    }

    return 'assets/images/person.png';
  }

  File? _getRoomAvatarFile(String? profileUrl) {
    if (profileUrl == null || profileUrl.isEmpty) return null;
    if (profileUrl.startsWith('/data/') ||
        profileUrl.startsWith('/storage/') ||
        profileUrl.contains('/cache/')) {
      try {
        final file = File(profileUrl);
        if (file.existsSync()) return file;
      } catch (e) {
        print("❌ Error creating file: $e");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Plain white background for this page
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: size.width,
              height: size.height * 0.25,
              color: Colors.white,
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar with search
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search by ID...',
                              hintStyle: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: AppColors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                Container(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: Colors.black,
                    indicatorColor: AppColors.primaryColor,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Users'),
                      Tab(text: 'Rooms'),
                    ],
                  ),
                ),
                // Tab Content
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildUsersTab(), _buildRoomsTab()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    // ✅ Show loading only when actively loading
    if (_isLoadingUsers && _allUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    // ✅ Show empty state if no search query or no results
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No users found for ID "$_searchQuery"'
                  : 'Search for users by ID',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final name = user['name']?.toString() ?? 'Unknown';
        final country = user['country']?.toString() ?? '';
        final profileUrl = _normalizeProfileUrl(
          user['profile_url']?.toString(),
        );
        final countryFlag = country.isNotEmpty
            ? CountryFlagUtils.getFlagEmoji(country)
            : '🌍';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            tileColor: AppColors.bgColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Builder(
              builder: (context) {
                // ✅ Get userId for ProfileWithFrame
                final userId =
                    user['id']?.toString() ?? user['user_id']?.toString() ?? '';

                // ✅ Use ProfileWithFrame to show purchased item frames
                return ProfileWithFrame(
                  size: 40, // radius 28 * 2 = 56
                  profileUrl: profileUrl.startsWith('http') ? profileUrl : null,

                  userId: userId.isNotEmpty ? userId : null,
                );
              },
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(countryFlag, style: const TextStyle(fontSize: 20)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (country.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    country,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<UserFollowProvider>(
                  builder: (context, followProvider, _) {
                    final userId =
                        user['id']?.toString() ??
                        user['user_id']?.toString() ??
                        '';
                    final targetUserId = int.tryParse(userId);
                    if (targetUserId == null || userId.isEmpty) {
                      return Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      );
                    }
                    return FollowButton(
                      targetUserId: targetUserId,
                      initialIsFollowing: followProvider.isFollowing(
                        targetUserId,
                      ),
                      width: 85,
                      height: 32,
                      fontSize: 12,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              // ✅ Pass selected user's ID to DetailedProfileScreen
              final userId =
                  user['id']?.toString() ?? user['user_id']?.toString() ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedProfileScreen(
                    userId: userId.isNotEmpty ? userId : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomsTab() {
    // ✅ Show loading only when actively loading
    if (_isLoadingRooms && _allRooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    // ✅ Show empty state if no search query or no results
    if (_filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No rooms found for ID "$_searchQuery"'
                  : 'Search for rooms by ID or room code',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        final roomCreatorId = room.creatorId;
        final roomName = room.name;
        final topic = room.topic;
        final totalMembers = room.participantCount ?? 0;
        final formattedMembers = totalMembers >= 1000
            ? '${(totalMembers / 1000).toStringAsFixed(1)}K'.replaceAll(
                '.0K',
                'K',
              )
            : totalMembers.toString();
        final profileUrl = _normalizeRoomProfileUrl(room.roomProfile);
        final countryFlag = room.countryFlag?.isNotEmpty == true
            ? room.countryFlag!
            : CountryFlagUtils.getFlagEmoji(null);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () async {
              final avatarFile = _getRoomAvatarFile(room.roomProfile);
              final networkUrl = profileUrl.startsWith('http')
                  ? profileUrl
                  : null;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomScreen(
                    roomCreatorId: roomCreatorId!,
                    roomName: roomName,
                    roomId: room.id,
                    topic: topic,
                    avatarUrl: avatarFile,
                    roomProfileUrl: networkUrl,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: profileUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: profileUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/person.png',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            profileUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/person.png',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                roomName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              countryFlag,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        if (topic.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            topic,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedMembers,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
