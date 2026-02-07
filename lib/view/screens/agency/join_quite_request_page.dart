import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/member_management_screen.dart';



class JoinQuiteRequestPage extends StatefulWidget {
  final int? agencyId;
  
  const JoinQuiteRequestPage({super.key, this.agencyId});

  @override
  State<JoinQuiteRequestPage> createState() => _JoinQuiteRequestPageState();
}

class _JoinQuiteRequestPageState extends State<JoinQuiteRequestPage> {
  String selectedTab = 'Join Request';
  String selectedFilter = 'All';
  bool _isLoading = false;
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    // Defer loading until after build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
    final agencyId = widget.agencyId ?? 
                    (agencyProvider.userAgency?['id'] ?? 
                     agencyProvider.userAgency?['agency_id']);

    if (agencyId == null) {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingRequests = true);
    }

    if (selectedTab == 'Join Request') {
      await agencyProvider.getJoinRequests(agencyId, skipLoadingState: true);
    } else {
      await agencyProvider.getQuitRequests(agencyId, skipLoadingState: true);
    }

    if (mounted) {
      setState(() => _isLoadingRequests = false);
    }
  }

  List<JoinRequest> _convertToJoinRequests(List<dynamic> requestsData) {
    return requestsData.map((req) {
      final reqMap = req is Map ? req : {};
      return JoinRequest(
        requestId: reqMap['request_id'] ?? 0,
        name: (reqMap['username'] ?? reqMap['name'] ?? 'Unknown').toString(),
        id: (reqMap['user_id'] ?? '').toString(),
        userId: reqMap['user_id'] ?? 0,
        applicationTime: (reqMap['created_at'] ?? '').toString(),
        status: 'Confirming', // All from API are pending
        country: (reqMap['country'] ?? '').toString(),
        email: (reqMap['email'] ?? '').toString(),
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
          'Host Application',
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
              _loadRequests();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTab('Join Request'),
                      _buildTab('Apply to quit'),
                    ],
                  ),
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
                    const SizedBox(width: 12),
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<AgencyProvider>(
              builder: (context, agencyProvider, child) {
                if (_isLoadingRequests) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requestsData = selectedTab == 'Join Request' 
                    ? agencyProvider.joinRequests 
                    : agencyProvider.quitRequests;
                final requests = _convertToJoinRequests(requestsData);

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      '-- No more data --',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: requests.length + 1,
                  itemBuilder: (context, index) {
                    if (index == requests.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            '-- No more data --',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildRequestCard(requests[index], null);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () {
        // Use post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedTab = label;
          });
          _loadRequests(); // Reload requests when tab changes
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.blue,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(JoinRequest request, VoidCallback? ontap) {
    return InkWell(
      onTap: ontap,
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
        child: Column(
          children: [
            Row(
              children: [
                request.avatarImage != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(request.avatarImage!),
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: request.avatarColor,
                        child: Text(
                          request.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID:${request.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Application time: ${request.applicationTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: request.status == 'Agreed'
                        ? const Color(0xFFE0F2F1)
                        : const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: request.status == 'Agreed'
                          ? const Color(0xFF00897B)
                          : const Color(0xFF7E57C2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (request.status == 'Confirming') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        await _handleAgree(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Agree',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () async {
                        await _handleReject(request);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAgree(JoinRequest request) async {
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);

    if (request.requestId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid request ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (selectedTab == 'Join Request') {
        await agencyProvider.acceptJoinRequest(request.requestId);
      } else {
        await agencyProvider.acceptQuitRequest(request.requestId);
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedTab == 'Join Request' 
              ? 'User accepted into agency' 
              : 'User removed from agency'),
        ),
      );

      // Reload requests
      await _loadRequests();

      // Navigate to member management if join request
      if (selectedTab == 'Join Request') {
        final agencyId = widget.agencyId ?? 
                        (agencyProvider.userAgency?['id'] ?? 
                         agencyProvider.userAgency?['agency_id']);
        if (agencyId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberManagementScreen(agencyId: agencyId),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleReject(JoinRequest request) async {
    final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);

    if (request.requestId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid request ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (selectedTab == 'Join Request') {
        await agencyProvider.declineJoinRequest(request.requestId);
      } else {
        await agencyProvider.declineQuitRequest(request.requestId);
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );

      // Reload requests
      await _loadRequests();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

class JoinRequest {
  final int requestId;
  final String name;
  final String id;
  final int userId;
  final String applicationTime;
  String status;
  final Color? avatarColor;
  final String? avatarImage;
  final String country;
  final String email;

  JoinRequest({
    required this.requestId,
    required this.name,
    required this.id,
    required this.userId,
    required this.applicationTime,
    required this.status,
    this.avatarColor,
    this.avatarImage,
    this.country = '',
    this.email = '',
  });
}