import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_profile_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/my_agency_view_screen.dart';
import 'package:shaheen_star_app/utils/country_utils.dart';

/// Dark theme colors matching reference image
const _bgDark = Color(0xFF1A1A2E);
const _searchBarBg = Color(0xFF2D2D44);
const _cardGoldenBorder = Color(0xFFD4AF37);

class AllAgencyScreen extends StatefulWidget {
  const AllAgencyScreen({super.key});

  @override
  State<AllAgencyScreen> createState() => _AllAgencyScreenState();
}

class _AllAgencyScreenState extends State<AllAgencyScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _didRedirectToJoinedAgency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AgencyProvider>(context, listen: false);
      if (!provider.isInitializing) {
        print('🔄 [AllAgencyScreen] Initializing agency provider...');
        provider.initialize();
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final provider = Provider.of<AgencyProvider>(context, listen: false);
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      provider.searchAgencies(query);
    } else {
      provider.getAllAgencies();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'My Agency',
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<AgencyProvider>(
        builder: (context, agencyProvider, child) {
          // Debug logging
          print('🖥️ [AllAgencyScreen] Build - isInitializing: ${agencyProvider.isInitializing}, userAgency: ${agencyProvider.userAgency != null ? agencyProvider.userAgency!['agency_name'] : 'null'}');
          
          // Redirect to joined/owned agency when user has one (instead of showing list)
          if (!_didRedirectToJoinedAgency &&
              !agencyProvider.isInitializing &&
              agencyProvider.userAgency != null) {
            _didRedirectToJoinedAgency = true;
            print('🔄 [AllAgencyScreen] Redirecting to agency: ${agencyProvider.userAgency!['agency_name']}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final agency = Map<String, dynamic>.from(agencyProvider.userAgency!);
              final currentUserId = agencyProvider.currentUserId;
              final ownerId = agency['user_id'] ?? agency['owner_id'];
              final isOwner = currentUserId != null &&
                  ownerId != null &&
                  currentUserId.toString() == ownerId.toString();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => isOwner
                      ? AgencyProfileCenterScreen(agency: agency)
                      : MyAgencyViewScreen(agency: agency),
                ),
              );
            });
          }

          // Show loading state
          if (agencyProvider.isLoading && agencyProvider.agencies.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }

          // Show error state
          if (agencyProvider.error != null && agencyProvider.agencies.isEmpty) {
            final isDatabaseError = agencyProvider.error!.toLowerCase().contains('mysql') ||
                                   agencyProvider.error!.toLowerCase().contains('database') ||
                                   agencyProvider.error!.toLowerCase().contains('connection');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDatabaseError ? Icons.cloud_off : Icons.error_outline,
                      size: 64,
                      color: Colors.orange[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isDatabaseError
                          ? 'Database connection issue. The server is temporarily unavailable.'
                          : agencyProvider.error!,
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            agencyProvider.clearError();
                            agencyProvider.refresh();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            agencyProvider.clearError();
                            agencyProvider.getAllAgencies();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Show connection status when initializing
          if (agencyProvider.isInitializing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white70),
                  SizedBox(height: 16),
                  Text(
                    'Loading agencies...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          final agencies = agencyProvider.agencies;

          return SafeArea(
            child: Column(
              children: [
                // Search bar (reference: dark grey, magnifying glass, "Search by ID or Nick", Search button)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.012,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: _searchBarBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white70, size: screenWidth * 0.055),
                        SizedBox(width: screenWidth * 0.025),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search by ID or Nick',
                              hintStyle: TextStyle(
                                fontSize: screenWidth * 0.038,
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) agencyProvider.getAllAgencies();
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: _onSearchChanged,
                          child: Text(
                            'Search',
                            style: TextStyle(
                              color: _cardGoldenBorder,
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.038,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Agency grid (2 columns, agency_image.png cards)
                Expanded(
                  child: agencies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business, size: 64, color: Colors.white38),
                              const SizedBox(height: 16),
                              Text(
                                'No agencies found',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: screenWidth * 0.03,
                            mainAxisSpacing: screenHeight * 0.02,
                          ),
                          itemCount: agencies.length,
                          itemBuilder: (context, index) {
                            final agency = agencies[index];
                            final agencyMap = agency is Map ? agency : {};
                            final agencyName = (agencyMap['agency_name'] ?? agencyMap['name'] ?? 'Unknown').toString();
                            final memberCount = agencyMap['member_count'] ?? agencyMap['members']?.length ?? 0;
                            final ownerCountry = (agencyMap['owner_country'] ?? agencyMap['country'] ?? '').toString();
                            final rawLogo = (agencyMap['logo_url'] ?? agencyMap['profile_url'] ?? '').toString();
                            // Skip invalid logo URLs (admin pages, placeholders)
                            final logoUrl = (rawLogo.contains('AgencyManagment') ||
                                    (rawLogo.contains('admin/') && !rawLogo.contains('/uploads/')) ||
                                    rawLogo.endsWith('#'))
                                ? ''
                                : rawLogo;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AgencyCenterScreen(
                                      agency: Map<String, dynamic>.from(agencyMap),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Golden/cream card background (agency_image.png)
                                        Image.asset(
                                          'assets/images/agency_image.png',
                                          fit: BoxFit.cover,
                                        ),
                                        // Content overlay
                                        Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.04),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Circular avatar with golden border
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _cardGoldenBorder,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: CircleAvatar(
                                                  radius: screenWidth * 0.1,
                                                  backgroundColor: Colors.white,
                                                  backgroundImage: logoUrl.isNotEmpty
                                                      ? NetworkImage(logoUrl)
                                                      : null,
                                                  child: logoUrl.isEmpty
                                                      ? Icon(
                                                          Icons.business,
                                                          size: screenWidth * 0.1,
                                                          color: const Color(0xFF8B7355),
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              SizedBox(height: screenHeight * 0.01),
                                              // Agency name
                                              Text(
                                                agencyName,
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.038,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF3D3D3D),
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: screenHeight * 0.006),
                                              // Flag + person icon + number
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // Real country flag
                                                  if (ownerCountry.isNotEmpty)
                                                    CountryUtils.getCountryFlag(
                                                      ownerCountry,
                                                      width: screenWidth * 0.04,
                                                      height: screenWidth * 0.04,
                                                    )
                                                  else
                                                    Icon(
                                                      Icons.flag,
                                                      size: screenWidth * 0.04,
                                                      color: const Color(0xFF6B6B6B),
                                                    ),
                                                  SizedBox(width: screenWidth * 0.02),
                                                  Icon(
                                                    Icons.person,
                                                    size: screenWidth * 0.04,
                                                    color: const Color(0xFF6B6B6B),
                                                  ),
                                                  SizedBox(width: screenWidth * 0.015),
                                                  Text(
                                                    memberCount.toString(),
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.035,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF4A4A4A),
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
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

}
