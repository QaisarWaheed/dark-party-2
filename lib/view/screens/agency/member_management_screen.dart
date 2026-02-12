import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_notification.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';

class MemberManagementScreen extends StatefulWidget {
  final int? agencyId;
  
  const MemberManagementScreen({super.key, this.agencyId});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  int selectedTab = 0;
  String sortBy = 'Join duration';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
    final agencyId = widget.agencyId ?? 
                    (agencyProvider.userAgency?['id'] ?? 
                     agencyProvider.userAgency?['agency_id']);
    
    if (agencyId != null) {
      setState(() => _isLoading = true);
      await Future.wait([
        agencyProvider.getMembers(agencyId),
        agencyProvider.getJoinRequests(agencyId, skipLoadingState: true),
      ]);
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _normalizeProfileUrl(dynamic url) {
    if (url == null || url.toString().isEmpty) return '';
    final s = url.toString().trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/';
    final path = s.startsWith('/') ? s.substring(1) : s;
    return '$base$path';
  }

  List<Member> _convertToMembers(List<dynamic> membersData) {
    return membersData.map((member) {
      final memberMap = member is Map ? member : {};
      final joinedAt = memberMap['joined_at'] ?? memberMap['user_created'] ?? '';
      final rawProfile = memberMap['profile_url'] ?? '';
      final profileUrl = _normalizeProfileUrl(rawProfile);
      // Use display_id (unique_user_id) for user-facing ID when available
      final displayId = memberMap['display_id'] ?? memberMap['user_id'] ?? memberMap['id'];
      return Member(
        name: (memberMap['name'] ?? memberMap['username'] ?? 'Unknown').toString(),
        id: (displayId ?? '').toString(),
        joinTime: joinedAt.toString(),
        avatarImage: profileUrl.isNotEmpty ? profileUrl : 'assets/images/person.png',
        country: (memberMap['country'] ?? '').toString(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Member Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 24),
            onPressed: () {
              _loadMembers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Consumer<AgencyProvider>(
                  builder: (context, agencyProvider, _) {
                    final allHostsCount = agencyProvider.agencyMembers.length;
                    final pendingCount = agencyProvider.joinRequests.length;
                    // Add Hosts and Inactive Hosts would need backend support
                    // For now, showing 0 until backend provides this data
                    final addHostsCount = 0;
                    final inactiveHostsCount = 0;
                    
                    return Row(
                      children: [
                        _buildStatItem(allHostsCount.toString(), 'All Hosts', 0, Colors.blue),
                        _buildStatItem(pendingCount.toString(), 'Pending', 1, Colors.orange),
                        _buildStatItem(addHostsCount.toString(), 'Add Hosts', 2, Colors.grey),
                        _buildStatItem(inactiveHostsCount.toString(), 'Inactive Hosts', 3, Colors.grey),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Join duration',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 20, color: Colors.grey),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Members List or Pending Requests
          Expanded(
            child: Consumer<AgencyProvider>(
              builder: (context, agencyProvider, child) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show pending requests when "Pending" tab (index 1) is selected
                if (selectedTab == 1) {
                  final requests = agencyProvider.joinRequests;
                  if (requests.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending join requests',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final reqMap = request is Map<String, dynamic> 
                          ? request 
                          : (request is Map ? Map<String, dynamic>.from(request) : <String, dynamic>{});
                      return _buildJoinRequestCard(reqMap, agencyProvider);
                    },
                  );
                }

                // Show members for other tabs
                final membersData = agencyProvider.agencyMembers;
                final members = _convertToMembers(membersData);

                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(members[index], () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AgencyNotification(),
                        ),
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, int index, Color color) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRequestCard(Map<String, dynamic> request, AgencyProvider provider) {
    final userName = request['username'] ?? request['user_name'] ?? 'Unknown User';
    final userId = request['user_id']?.toString() ?? '';
    final requestId = request['request_id'] ?? request['id'];
    final profileUrl = _normalizeProfileUrl(request['profile_url'] ?? '');
    final requestDate = request['created_at'] ?? request['request_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade300,
            child: ClipOval(
              child: profileUrl.isNotEmpty && profileUrl.startsWith('http')
                  ? SizedBox(
                      width: 56,
                      height: 56,
                      child: cachedImage(profileUrl, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $userId',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (requestDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Requested: $requestDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Accept/Decline Actions
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (requestId != null) {
                    await provider.acceptJoinRequest(requestId);
                    await _loadMembers(); // Refresh the list
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Accept', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  if (requestId != null) {
                    await provider.declineJoinRequest(requestId);
                    await _loadMembers(); // Refresh the list
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Decline', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              child: ClipOval(
                child: member.avatarImage.startsWith('http')
                    ? SizedBox(
                        width: 56,
                        height: 56,
                        child: cachedImage(member.avatarImage, fit: BoxFit.cover),
                      )
                    : Image.asset(
                        member.avatarImage,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${member.id}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join Time:${member.joinTime}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Action Icons
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade600),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Member {
  final String name;
  final String id;
  final String joinTime;
  final String avatarImage;
  final String country;

  Member({
    required this.name,
    required this.id,
    required this.joinTime,
    required this.avatarImage,
    this.country = '',
  });
}