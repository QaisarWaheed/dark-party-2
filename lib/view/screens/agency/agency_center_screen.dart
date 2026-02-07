import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/host_center_screen.dart';
import 'package:shaheen_star_app/view/screens/agency/waiting_approval_screen.dart';

class AgencyCenterScreen extends StatefulWidget {
  final Map<String, dynamic>? agency; // Optional agency to view/join
  
  const AgencyCenterScreen({
    super.key,
    this.agency, // If provided, shows this agency (for joining). If null, shows user's own agency.
  });

  @override
  State<AgencyCenterScreen> createState() => _AgencyCenterScreenState();
}

class _AgencyCenterScreenState extends State<AgencyCenterScreen> {
  @override
  void initState() {
    super.initState();
    // Only initialize if we don't have agency data passed in
    // If agency is passed, we don't need to initialize (it's for viewing/joining)
    if (widget.agency == null) {
      // Initialize agency provider when screen loads (only for user's own agency)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<AgencyProvider>(context, listen: false);
        // Only initialize if not already initialized and not currently initializing
        if (!provider.isInitializing && provider.agencies.isEmpty) {
          print('🔄 [AgencyCenterScreen] Initializing agency provider...');
          provider.initialize();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Consumer<AgencyProvider>(
      builder: (context, agencyProvider, child) {
        // Use passed agency if provided (for joining), otherwise use user's own agency
        final displayAgency = widget.agency ?? agencyProvider.userAgency;
        final userAgency = agencyProvider.userAgency;
        final currentUserId = agencyProvider.currentUserId;
        
        // Check if user owns this agency
        final agencyOwnerId = displayAgency?['user_id'] ?? displayAgency?['owner_id'];
        final isOwner = currentUserId != null && 
                       agencyOwnerId != null && 
                       currentUserId.toString() == agencyOwnerId.toString();
        
        final agencyName = displayAgency?['agency_name'] ?? 
                          displayAgency?['name'] ?? 
                          'Agency';
        final agencyCode = displayAgency?['agency_code'] ?? 
                          displayAgency?['id']?.toString() ?? 
                          '';
        final agencyId = displayAgency?['id'] ?? 
                        displayAgency?['agency_id'];

        return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB84FFF),
              Color(0xFF9D4FFF),
              Color(0xFF6B4FFF),
              Color(0xFF4F8FFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.015,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      iconSize: isSmallScreen ? 20 : 24,
                      onPressed: () { Navigator.pop(context); },
                    ),
                    Expanded(
                      child: Text(
                        'Agency center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 40 : 48),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // Profile Section
              Container(
                width: size.width * 0.28,
                height: size.width * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Agency Name
              Text(
                agencyName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: size.height * 0.008),

              // Agency ID
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.006,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: $agencyCode',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.04),

              // Content Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.025),

                      // Owner Section
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                        ),
                        padding: EdgeInsets.all(size.width * 0.04),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0F3E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Owner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: size.width * 0.11,
                              height: size.width * 0.11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.purple,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.purple.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Currently Broadcasting Section
                      Container(
                        margin: EdgeInsets.symmetric(
                          // horizontal: size.width * 0.04,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.018,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Currently broadcasting(0)',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          
                            Text(
                              'Agency introduction',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isSmallScreen ? 10 : 12,
                              ),
                            ),
                            SizedBox(width: size.width * 0.01),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom Buttons
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.02,
                        ),
                        child: Row(
                          children: [
                            // Contact Button
                            Expanded(
                              flex: 5,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFF1A0F3E),
                                ),
                                label: Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00E676),
                                  foregroundColor: const Color(0xFF1A0F3E),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    vertical: size.height * 0.018,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: size.width * 0.03),

                            // Apply to Join Button or Host Center Button
                            Expanded(
                              flex: 6,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (isOwner) {
                                    // User owns this agency - go to Host Center
                                    if (userAgency != null) {
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => const HostCenterScreen(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Agency data not available'),
                                        ),
                                      );
                                    }
                                  } else {
                                    // User doesn't own this agency - create join request
                                    if (agencyId != null) {
                                      try {
                                        // Show loading
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                        
                                        // Create join request
                                        final agencyIdInt = agencyId is int 
                                            ? agencyId 
                                            : (agencyId is String 
                                                ? int.tryParse(agencyId) 
                                                : int.tryParse(agencyId.toString())) ?? 0;
                                        
                                        if (agencyIdInt > 0) {
                                          await agencyProvider.createJoinRequest(agencyIdInt);
                                          
                                          // Check if there was an error
                                          if (agencyProvider.error != null) {
                                            final errorMsg = agencyProvider.error!;
                                            print('⚠️ [AgencyCenterScreen] Error detected: $errorMsg');
                                            
                                            // Close loading
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              
                                                // Check if it's a pending request error
                                              if (errorMsg.toLowerCase().contains('already have') || 
                                                  errorMsg.toLowerCase().contains('pending')) {
                                                // Navigate to waiting approval screen instead of showing snackbar
                                                print('ℹ️ [AgencyCenterScreen] User has pending request - navigating to WaitingApprovalScreen');
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => WaitingApprovalScreen(
                                                      agency: Map<String, dynamic>.from(displayAgency ?? {}),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                // Show error message for other errors
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(errorMsg),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                                print('✅ [AgencyCenterScreen] Error SnackBar displayed to user');
                                              }
                                            }
                                          } else {
                                            // Success - no error
                                            print('✅ [AgencyCenterScreen] Join request created successfully');
                                            // Close loading
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              
                                              // Navigate to waiting approval screen since request is now pending
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WaitingApprovalScreen(
                                                    agency: Map<String, dynamic>.from(displayAgency ?? {}),
                                                  ),
                                                ),
                                              );
                                              print('✅ [AgencyCenterScreen] Navigated to WaitingApprovalScreen');
                                            }
                                          }
                                        } else {
                                          // Close loading
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Invalid agency ID'),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        // Close loading
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          
                                          // Show error message
                                          String errorMsg = 'Failed to send join request';
                                          if (e.toString().contains('already have') || 
                                              e.toString().contains('pending')) {
                                            errorMsg = 'You already have a pending join request for this agency.';
                                          } else if (e.toString().isNotEmpty) {
                                            errorMsg = e.toString();
                                          }
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(errorMsg),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid agency ID'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(
                                  isOwner ? Icons.home : Icons.person_add_outlined,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isOwner ? 'Host Center' : 'Apply to join',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B4FFF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    vertical: size.height * 0.018,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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