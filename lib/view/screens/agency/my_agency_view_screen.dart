import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';

/// View-mode screen for "My Agency" – shows agency profile, rating, rank, and members.
/// Used when user is in an agency (owner or member) for a read-only overview.
class MyAgencyViewScreen extends StatefulWidget {
  final Map<String, dynamic> agency;

  const MyAgencyViewScreen({
    super.key,
    required this.agency,
  });

  @override
  State<MyAgencyViewScreen> createState() => _MyAgencyViewScreenState();
}

class _MyAgencyViewScreenState extends State<MyAgencyViewScreen> {
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

  String _getStatString(Map<String, dynamic>? stats, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = stats?[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final agencyProvider = context.watch<AgencyProvider>();
    final stats = agencyProvider.stats;

    final agencyName =
        (widget.agency['agency_name'] ?? widget.agency['name'] ?? 'Unknown Agency')
            .toString();
    final agencyLogo = widget.agency['logo'] ??
        widget.agency['agency_logo'] ??
        widget.agency['profile_url'];
    final logoUrl = _normalizeProfileUrl(agencyLogo);

    final agencyRating = _getStatString(
      stats,
      ['agency_rating', 'rating'],
      fallback: '-',
    );
    final membersCount = agencyProvider.agencyMembers.length;
    final rankStr = _getStatString(
      stats,
      ['agency_rank', 'rank', 'ranking'],
      fallback: '-',
    );
    final rankDisplay = rankStr != '-'
        ? (rankStr.startsWith('No.') ? rankStr : 'No. $rankStr')
        : 'No. —';

    const darkBg = Color(0xFF1A1A1A);
    const goldColor = Color(0xFFD99724);
    const goldLight = Color(0xFFE8B84C);

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.03),

              // Agency profile image (circular with golden border)
              Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: logoUrl.isNotEmpty
                      ? cachedImage(logoUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.business,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Agency name
              Text(
                agencyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: size.height * 0.04),

              // Agency's rating last week
              _buildRatingCard(
                size,
                goldColor,
                goldLight,
                'Agency\'s rating last week',
                agencyRating,
              ),

              SizedBox(height: size.height * 0.04),

              // Rank and Members cards side by side
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      size,
                      goldColor,
                      goldLight,
                      'Rank',
                      rankDisplay,
                      Icons.emoji_events,
                    ),
                  ),
                  SizedBox(width: size.width * 0.04),
                  Expanded(
                    child: _buildStatCard(
                      size,
                      goldColor,
                      goldLight,
                      'Members',
                      membersCount.toString(),
                      Icons.people,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(
    Size size,
    Color goldColor,
    Color goldLight,
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldColor.withOpacity(0.9),
            goldLight.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    Size size,
    Color goldColor,
    Color goldLight,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.03,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldColor.withOpacity(0.9),
            goldLight.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -4,
            bottom: -4,
            child: Opacity(
              opacity: 0.15,
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
