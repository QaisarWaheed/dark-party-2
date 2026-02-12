import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/view/screens/agency/host_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/member_management_screen.dart';
import 'package:shaheen_star_app/view/screens/merchant/wallet_screen.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';
import 'package:shaheen_star_app/utils/country_utils.dart';
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
  Map<String, dynamic>? _enrichedAgency;

  Map<String, dynamic> get _agency => _enrichedAgency ?? widget.agency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didRequestData) return;
    _didRequestData = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final agencyProvider = context.read<AgencyProvider>();
      final agencyIdValue = _agency['id'] ?? _agency['agency_id'];
      final agencyId = agencyIdValue is int
          ? agencyIdValue
          : int.tryParse(agencyIdValue?.toString() ?? '');

      agencyProvider.getStats();
      if (agencyId != null) {
        agencyProvider.getMembers(agencyId);
        // Fetch full agency to get total_diamond_coins, logo_url, owner_country, member_count, etc.
        var response = await ApiManager.getAgency(agencyId: agencyId);
        var data = response != null && response['status'] == 'success'
            ? response['data'] as Map<String, dynamic>?
            : null;
        // Fallback: get_all returns total_diamond_coins; get may not - fetch from get_all if missing
        final hasDiamonds = data != null &&
            (data['total_diamond_coins'] != null ||
                data['period_15_days_diamond_coins'] != null);
        if (mounted && !hasDiamonds) {
          final allRes = await ApiManager.getAllAgenciesViaManager(limit: 100);
          if (allRes != null &&
              allRes['status'] == 'success' &&
              allRes['data'] != null) {
            final agencies = (allRes['data'] as Map)['agencies'] as List?;
            if (agencies != null) {
              for (final a in agencies) {
                final m = a is Map ? a : {};
                final aid = m['id'] ?? m['agency_id'];
                if (aid != null &&
                    (aid == agencyId ||
                        aid.toString() == agencyId.toString())) {
                  data = {...?data, ...Map<String, dynamic>.from(m)};
                  break;
                }
              }
            }
          }
        }
        if (mounted && data != null) {
          final merged = Map<String, dynamic>.from(widget.agency)..addAll(data);
          setState(() {
            _enrichedAgency = merged;
          });
        }
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

  String _normalizeProfileUrl(dynamic url) {
    if (url == null || url.toString().isEmpty) return '';
    final s = url.toString().trim();
    // Reject invalid URLs (admin pages, placeholders - not image URLs)
    if (s.contains('AgencyManagment') ||
        (s.contains('admin/') && !s.contains('/uploads/')) ||
        s.endsWith('#')) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = ApiConstants.baseUrl.endsWith('/') ? ApiConstants.baseUrl : '${ApiConstants.baseUrl}/';
    final path = s.startsWith('/') ? s.substring(1) : s;
    return '$base$path';
  }

  String _formatLargeNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    final num = double.tryParse(cleaned) ?? int.tryParse(cleaned) ?? 0;
    final n = num.toDouble();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}K';
    if (n >= 1) return n.toInt().toString();
    // For 0 or values < 1, return the integer part
    return n.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final agencyProvider = context.watch<AgencyProvider>();
    final stats = agencyProvider.stats;

    final agencyName =
        (_agency['agency_name'] ?? _agency['name'] ?? 'Unknown Agency')
            .toString();
    final agencyCode =
        (_agency['agency_code'] ?? _agency['id'] ?? '').toString();
    final agencyId = _agency['id'] ?? _agency['agency_id'];
    // Real owner user ID: prefer display ID (unique_user_id), then owner_id/user_id - never agency code
    final ownerId = (_agency['owner_display_id'] ??
            _agency['owner_id'] ??
            _agency['user_id'])
        ?.toString() ?? '';
    // Owner's country (from users table) for the flag; fallback to agency country
    final agencyCountry = _agency['owner_country'] ??
        _agency['country'] ??
        _agency['agency_country'];
    // Agency owner's profile image (person who owns the agency) - show on right of top card
    final rawOwnerProfile = _agency['owner_profile_url'] ??
        _agency['owner_avatar'] ??
        _agency['owner_profile'];
    final rawAgencyLogo = _agency['logo_url'] ??
        _agency['logo'] ??
        _agency['agency_logo'] ??
        _agency['profile_url'];
    // Prefer agency logo for agency profile; fallback to owner profile
    final ownerProfileUrl = _normalizeProfileUrl(rawAgencyLogo ?? rawOwnerProfile);

    // Total Score / Diamonds: prefer agency-level data, then stats
    final totalSalaryFromStats = _getStatString(
      stats,
      ['total_salary', 'salary', 'monthly_salary'],
    );
    final totalGiftFromStats = _getStatString(
      stats,
      ['total_gift_gold_coins', 'gift_gold_coins', 'total_gift_coins', 'gift_coins'],
    );
    final totalSalaryFromAgency = _getStatString(
      _agency,
      ['total_salary', 'salary', 'monthly_salary'],
    );
    final totalGiftFromAgency = _getStatString(
      _agency,
      ['total_diamond_coins', 'period_15_days_diamond_coins', 'total_gift_gold_coins', 'gift_gold_coins', 'total_gift_coins', 'gift_coins', 'total_score', 'diamonds'],
    );
    
    final totalGiftGoldCoins = totalGiftFromAgency.isNotEmpty
        ? totalGiftFromAgency
        : totalGiftFromStats;
    final totalSalary = totalSalaryFromAgency.isNotEmpty
        ? totalSalaryFromAgency
        : totalSalaryFromStats;
    final totalScore = _formatLargeNumber(totalGiftGoldCoins.isNotEmpty ? totalGiftGoldCoins : totalSalary);
    final agencyRating = _getStatString(
      _agency,
      ['agency_rating', 'rating'],
      fallback: _getStatString(stats, ['agency_rating', 'rating'], fallback: '-'),
    );

    final membersFromApi = _getStatInt(_agency, ['member_count'], fallback: -1);
    final membersCount = membersFromApi >= 0
        ? membersFromApi
        : agencyProvider.agencyMembers.length;
    final broadcastingCount = _getStatInt(
      _agency,
      ['currently_broadcasting', 'broadcasting_hosts', 'online_hosts'],
      fallback: _getStatInt(stats, ['broadcasting_hosts', 'currently_broadcasting', 'online_hosts']),
    );
    final addHostsCount = _getStatInt(
      _agency,
      ['add_hosts', 'new_hosts', 'hosts_added'],
      fallback: _getStatInt(stats, ['add_hosts', 'new_hosts', 'hosts_added']),
    );
    final inactiveFromAgency = _getStatInt(
      _agency,
      ['inactive_hosts', 'inactive_members'],
      fallback: -1,
    );
    final inactiveHostsCount = inactiveFromAgency >= 0
        ? inactiveFromAgency
        : (membersCount > 0 ? membersCount - broadcastingCount : 0);

    const darkBg = Color(0xFF2C2C2E);
    const goldColor = Color(0xFFFFD700);
    const topCardTextColor = Color(0xFFD99724);
    const menuItemBg = Color(0xFFF5F0E6);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Agency',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gold-themed dashboard card (agency_dashboard_card.svg)
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: size.height * 0.165,
                  width: double.infinity,
                  child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage.asset(
                      'assets/images/agency_dashboard_card.png',
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total Score',
                                    style: TextStyle(
                                      color: topCardTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.diamond, color: Colors.purple[300], size: 22),
                                      const SizedBox(width: 4),
                                      Text(
                                        totalScore,
                                        style: const TextStyle(
                                          color: topCardTextColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white24,
                                    child: ownerProfileUrl.isNotEmpty
                                        ? ClipOval(
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: cachedImage(
                                                ownerProfileUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.person, color: Colors.white70, size: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ownerId.isNotEmpty ? 'ID: $ownerId' : 'ID: —',
                                    style: TextStyle(
                                      color: topCardTextColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Agency Country',
                                        style: TextStyle(
                                          color: topCardTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      CountryUtils.getCountryFlag(agencyCountry, width: 20, height: 14),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Agency Rating: ',
                                style: TextStyle(
                                  color: topCardTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                agencyRating,
                                style: const TextStyle(
                                  color: topCardTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),

            // Menu items (7 rows with agency_first_row to agency_seventh_row)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: 'assets/images/agency_first_row.png',
                    label: 'Number of Agency members ($membersCount)',
                    onTap: () => _navigateToMembers(context),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_second_row.png',
                    label: 'Currently broadcasting ($broadcastingCount)',
                    onTap: () => _navigateToMembers(context),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_third_row.png',
                    label: 'Add Hosts ($addHostsCount)',
                    onTap: () => _navigateToMembers(context),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_fourth_row.png',
                    label: 'Inactive Hosts ($inactiveHostsCount)',
                    onTap: () => _navigateToMembers(context),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_fifth_row.png',
                    label: 'Wallet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_sixth_row.png',
                    label: 'Policy',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Policy - Coming soon')),
                    ),
                  ),
                  _buildMenuItem(
                    icon: 'assets/images/agency_seventh_row.png',
                    label: 'Agency Recruitment Plan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HostCenterScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer with agency name
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.03,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.02,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      agencyName,
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agency Code: $agencyCode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMembers(BuildContext context) {
    final agencyIdValue = _agency['id'] ?? _agency['agency_id'];
    final agencyId = agencyIdValue is int
        ? agencyIdValue
        : int.tryParse(agencyIdValue?.toString() ?? '');
    if (agencyId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberManagementScreen(agencyId: agencyId),
        ),
      );
    }
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF5F0E6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: AppImage.asset(icon, fit: BoxFit.contain),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[500], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
