import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_center_screen.dart';

class AllAgencyScreen extends StatefulWidget {
  const AllAgencyScreen({super.key});

  @override
  State<AllAgencyScreen> createState() => _AllAgencyScreenState();
}

class _AllAgencyScreenState extends State<AllAgencyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize agency provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AgencyProvider>(context, listen: false);
        if (!provider.isInitializing) {
        print('🔄 [AllAgencyScreen] Initializing agency provider...');
        provider.initialize();
      }
    });

    // Listen to search changes
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
      appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
      onPressed: () { Navigator.pop(context); },
    ),
    centerTitle: true,
    title: Text(
      'Agency center',
      style: TextStyle(
        fontSize: screenWidth * 0.055,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  ),

      body: Consumer<AgencyProvider>(
        builder: (context, agencyProvider, child) {
          // Show loading state
          if (agencyProvider.isLoading && agencyProvider.agencies.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
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
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading agencies...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final agencies = agencyProvider.agencies;

          return SafeArea(
            child: Column(
              children: [
                // Main Content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    children: [
                  // Banner
                  Container(
                    height: screenHeight * 0.12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B68EE), Color(0xFF9B8FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -20,
                          left: 20,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          right: 60,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Agency Recruitment Plan',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'DO IT',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 15,
                          top: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.emoji_events,
                            size: screenWidth * 0.15,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Host Center Button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B6914), Color(0xFFB8860B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.grade,
                            size: screenWidth * 0.05,
                            color: const Color(0xFF8B6914),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Host Center',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Search Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.02),

                        /// ---- Converted to TextField ----
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                agencyProvider.getAllAgencies();
                              }
                            },
                          ),
                        ),

                        Icon(
                          Icons.menu,
                          color: Colors.grey[600],
                          size: screenWidth * 0.05,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Agency List
                  if (agencies.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.2),
                        child: Column(
                          children: [
                            Icon(Icons.business, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No agencies found',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...agencies.map(
                      (agency) {
                        // Agencies come as Map from API
                        final agencyMap = agency is Map ? agency : {};
                        final agencyName = (agencyMap['agency_name'] ?? agencyMap['name'] ?? 'Unknown').toString();
                        final agencyId = (agencyMap['agency_code'] ?? agencyMap['id'] ?? '').toString();
                        final memberCount = agencyMap['member_count'] ?? agencyMap['members']?.length ?? 0;

                        return Padding(
    padding: EdgeInsets.only(bottom: screenHeight * 0.012),
    child: GestureDetector(
      onTap: () {
        // Navigate to agency center screen to view and join agency
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
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 119, 106, 236),
              Color.fromARGB(255, 171, 156, 252)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ---- Left Side Circle Avatar ----
          CircleAvatar(
            radius: screenWidth * 0.07,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.business,
              size: screenWidth * 0.06,
              color: const Color(0xFF7B68EE),
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          /// ---- Your Original Content (unchanged) ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agencyName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                
                Row(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: screenWidth * 0.04,
                      color: Colors.white70,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      agencyId,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.004),

                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: screenWidth * 0.04,
                      color: Colors.white70,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      memberCount.toString(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white70,
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
                      }),
                    ],
                
              ) 
              
               )] )
              );
        }
      )
    );
  }

}
