import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_notification.dart';

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
      await agencyProvider.getMembers(agencyId);
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Member> _convertToMembers(List<dynamic> membersData) {
    return membersData.map((member) {
      final memberMap = member is Map ? member : {};
      final joinedAt = memberMap['joined_at'] ?? memberMap['user_created'] ?? '';
      final profileUrl = memberMap['profile_url'] ?? '';
      
      return Member(
        name: (memberMap['name'] ?? memberMap['username'] ?? 'Unknown').toString(),
        id: (memberMap['id'] ?? '').toString(),
        joinTime: joinedAt.toString(),
        avatarImage: profileUrl.toString().isNotEmpty 
            ? profileUrl.toString() 
            : 'assets/images/person.png',
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
                Row(
                  children: [
                    _buildStatItem('20', 'All Hosts', 0, Colors.blue),
                    _buildStatItem('0', 'Current Anchor', 1, Colors.grey),
                    _buildStatItem('1', 'Add Hosts', 2, Colors.grey),
                    _buildStatItem('18', 'Inactive Hosts', 3, Colors.grey),
                  ],
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
          // Members List
          Expanded(
            child: Consumer<AgencyProvider>(
              builder: (context, agencyProvider, child) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

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
              backgroundImage: NetworkImage(member.avatarImage),
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