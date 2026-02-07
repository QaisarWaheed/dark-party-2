import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/all_agency_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/join_quite_request_page.dart';

class AgencyProfileCenterScreen extends StatefulWidget {
  final Map<String, dynamic> agency;

  const AgencyProfileCenterScreen({
    super.key,
    required this.agency,
  });

  @override
  State<AgencyProfileCenterScreen> createState() =>
      _AgencyProfileCenterScreenState();
}

class _AgencyProfileCenterScreenState extends State<AgencyProfileCenterScreen> {
  bool _didRequestData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didRequestData) return;
    _didRequestData = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agencyProvider = context.read<AgencyProvider>();
      final agencyIdValue = widget.agency['id'] ?? widget.agency['agency_id'];
      final agencyId = agencyIdValue is int
          ? agencyIdValue
          : int.tryParse(agencyIdValue?.toString() ?? '');

      agencyProvider.getStats();
      if (agencyId != null) {
        agencyProvider.getMembers(agencyId);
      }
    });
  }

  String _getStatString(Map<String, dynamic>? stats, List<String> keys,
      {String fallback = '0'}) {
    for (final key in keys) {
      final value = stats?[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  int _getStatInt(Map<String, dynamic>? stats, List<String> keys,
      {int fallback = 0}) {
    for (final key in keys) {
      final value = stats?[key];
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final agencyProvider = context.watch<AgencyProvider>();
    final stats = agencyProvider.stats;

    // Extract agency data
    final agencyName =
        (widget.agency['agency_name'] ?? widget.agency['name'] ?? 'Unknown Agency')
            .toString();
    final agencyCode =
        (widget.agency['agency_code'] ?? widget.agency['id'] ?? '').toString();
    final agencyId = widget.agency['id'] ?? widget.agency['agency_id'];

    // Stats data
    final monthLabel =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final totalSalary = _getStatString(
      stats,
      ['total_salary', 'salary', 'monthly_salary'],
    );
    final totalGiftGoldCoins = _getStatString(
      stats,
      ['total_gift_gold_coins', 'gift_gold_coins', 'total_gift_coins', 'gift_coins'],
    );
    final compareLastMonth = _getStatString(
      stats,
      ['compare_last_month', 'compare_last_month_percent', 'compare_percent'],
      fallback: '0',
    );

    // Host management data
    final membersCount = agencyProvider.agencyMembers.length;
    final broadcastingCount = _getStatInt(
      stats,
      ['broadcasting_hosts', 'currently_broadcasting', 'online_hosts'],
    );
    final addHostsCount = _getStatInt(
      stats,
      ['add_hosts', 'new_hosts', 'hosts_added'],
    );
    final inactiveHostsCount = _getStatInt(
      stats,
      ['inactive_hosts', 'inactive_members'],
      fallback: membersCount > 0 ? membersCount - broadcastingCount : 0,
    );

    print(
        '🏢 [AgencyProfileCenterScreen] Building screen for agency: $agencyName (ID: $agencyId)');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () { Navigator.pop(context); },
        ),
        title: const Text(
          'Agency Center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Purple Header Card
            Container(
              margin: EdgeInsets.all(size.width * 0.04),
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B4FFF),
                    Color(0xFF6B3FEF),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Profile and Agency Info
                  Row(
                    children: [
                      Container(
                        width: size.width * 0.14,
                        height: size.width * 0.14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.white.withOpacity(0.3),
                            child: const Icon(Icons.business, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agencyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agencyCode,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.02),

                  // This month's data section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'This month\'s data($monthLabel)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.015),

                  // Stats Container
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Total salary row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total salary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: AppImage.asset(
                                      'assets/images/coinsicon.png',
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  totalSalary,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(color: Colors.white24, height: 24),

                        // Total gift gold coins row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total gift gold coins received',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.card_giftcard,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  totalGiftGoldCoins,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Compare last month
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Compare last month: $compareLastMonth%',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.015),

                  // Wallet and Policy buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet, 
                                color: Color(0xFF7B4FFF), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Wallet',
                                style: TextStyle(
                                  color: Color(0xFF7B4FFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, 
                                color: Color(0xFF7B4FFF), size: 14),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description, 
                                color: Color(0xFF7B4FFF), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Policy',
                                style: TextStyle(
                                  color: Color(0xFF7B4FFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, 
                                color: Color(0xFF7B4FFF), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Banner Image
            Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              height: size.height * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B4FFF), Color(0xFF6B3FEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  'Agency Recruitment Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Host Management Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Host management',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey[400], size: 18),
                          const SizedBox(width: 4),
                          Text(
                            membersCount.toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, 
                            color: Colors.grey[400], size: 14),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Currently\nbroadcasting',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              broadcastingCount.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Add Hosts',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              addHostsCount.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Inactive Hosts',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              inactiveHostsCount.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.02),

            // Action Buttons
            Consumer<AgencyProvider>(
              builder: (context, agencyProvider, child) {
                final currentUserId = agencyProvider.currentUserId;
                final agencyOwnerId = widget.agency['user_id'];
                final isOwner = currentUserId != null && agencyOwnerId == currentUserId;
                
                print('🏢 [AgencyProfileCenterScreen] Current User ID: $currentUserId, Agency Owner ID: $agencyOwnerId, Is Owner: $isOwner');
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: isOwner
                                  ? () {
                                      // Owner: View requests
                                      print('🏢 [AgencyProfileCenterScreen] Owner clicked "Host Application" button');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JoinQuiteRequestPage(
                                            agencyId: agencyId,
                                          ),
                                        ),
                                      );
                                    }
                                  : () async {
                                      // Non-owner: Create join request
                                      print('🏢 [AgencyProfileCenterScreen] Non-owner clicked "Join Agency" button for agency ID: $agencyId');
                                      if (agencyId == null) {
                                        print('❌ [AgencyProfileCenterScreen] Invalid agency ID');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Invalid agency ID')),
                                        );
                                        return;
                                      }
                                      
                                      print('📋 [AgencyProfileCenterScreen] Creating join request...');
                                      final loadingSnackbar = ScaffoldMessenger.of(context)
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text('Sending join request...'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      
                                      await agencyProvider.createJoinRequest(agencyId);
                                      
                                      if (context.mounted) {
                                        loadingSnackbar.hideCurrentSnackBar();
                                        final message = agencyProvider.error ?? 'Join request sent successfully';
                                        print('📋 [AgencyProfileCenterScreen] Join request result: $message');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            backgroundColor: agencyProvider.error != null
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        );
                                      }
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8D5FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      isOwner ? Icons.person_add : Icons.how_to_reg,
                                      color: const Color(0xFF7B4FFF),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isOwner ? 'Host Application' : 'Join Agency',
                                      style: const TextStyle(
                                        color: Color(0xFF7B4FFF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isOwner && agencyProvider.joinRequests.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 10,
                                child: Container(
                                  height: 16,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${agencyProvider.joinRequests.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllAgencyScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8D5FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.mail, color: Color(0xFFFF6B9D), size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'Initiate invitation',
                                  style: TextStyle(
                                    color: Color(0xFF7B4FFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }
}