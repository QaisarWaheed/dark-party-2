import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/utils/user_session.dart';
import 'package:shaheen_star_app/view/screens/agency/all_agency_screen.dart';

class HostCenterScreen extends StatelessWidget {
  const HostCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final monthFormat = DateFormat('yyyy-MM');

    return Consumer2<AgencyProvider, ProfileUpdateProvider>(
      builder: (context, agencyProvider, profileProvider, child) {
        // Get user's agency data
        final userAgency = agencyProvider.userAgency;
        final stats = agencyProvider.stats;
        final userSession = UserSession();
        
        // If no agency data, redirect to AllAgencyScreen so user can join an agency
        if (userAgency == null) {
          // Use post-frame callback to navigate after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AllAgencyScreen(),
              ),
            );
          });
          
          // Show loading while redirecting
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                'Host center',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Extract data
        final agencyName = userAgency['agency_name']?.toString() ?? 
                          userAgency['name']?.toString() ?? 
                          'Agency';
        final agencyId = userAgency['id']?.toString() ?? 
                        userAgency['agency_id']?.toString() ?? 
                        userAgency['agency_code']?.toString() ?? 
                        '';
        final userId = userSession.userId?.toString() ?? 
                      profileProvider.userId ?? 
                      '';
        final profileImageUrl = userAgency['profile_url']?.toString() ?? 
                              userAgency['image']?.toString() ?? 
                              profileProvider.profile_url ?? 
                              '';
        
        // Extract stats data
        final salary = stats?['total_salary']?.toString() ?? 
                      stats?['salary']?.toString() ?? 
                      stats?['monthly_salary']?.toString() ?? 
                      '0';
        final currentLevel = stats?['level']?.toString() ?? 
                           stats?['current_level']?.toString() ?? 
                           '0';
        final currentCoins = stats?['coins']?.toString() ?? 
                           stats?['current_coins']?.toString() ?? 
                           stats?['coin_turnover']?.toString() ?? 
                           '0';
        final coinsNeeded = stats?['coins_needed']?.toString() ?? 
                           stats?['coins_for_next_level']?.toString() ?? 
                           '80000';
        final validDays = stats?['valid_days']?.toString() ?? 
                         stats?['days_valid']?.toString() ?? 
                         '0';
        final maxValidDays = stats?['max_valid_days']?.toString() ?? 
                           stats?['total_valid_days']?.toString() ?? 
                           '10';
        
        // Calculate progress
        final currentCoinsInt = int.tryParse(currentCoins) ?? 0;
        final coinsNeededInt = int.tryParse(coinsNeeded) ?? 80000;
        final progress = coinsNeededInt > 0 ? (currentCoinsInt / coinsNeededInt).clamp(0.0, 1.0) : 0.0;
        final progressText = '$currentCoins/$coinsNeededInt';
        final remainingCoins = (coinsNeededInt - currentCoinsInt).clamp(0, coinsNeededInt);
        final progressDescription = remainingCoins > 0 
            ? 'Still need $remainingCoins to upgrade' 
            : 'Ready to upgrade';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Host center',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black, size: 22),
                onPressed: () {
                  agencyProvider.refresh();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Date Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.012,
                  ),
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      dateFormat.format(now),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                // Profile Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        width: size.width * 0.15,
                        height: size.width * 0.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF7B4FFF)],
                          ),
                        ),
                        child: profileImageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF9C27B0), Color(0xFF7B4FFF)],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          agencyName.isNotEmpty ? agencyName[0].toUpperCase() : 'A',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF9C27B0), Color(0xFF7B4FFF)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    agencyName.isNotEmpty ? agencyName[0].toUpperCase() : 'A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      SizedBox(width: size.width * 0.03),

                      // Profile Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agencyName.length > 20 
                                  ? '${agencyName.substring(0, 20)}...' 
                                  : agencyName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'ID: $userId',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Agency ID:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  agencyId,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: agencyId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Agency ID copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.grey[600],
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

                SizedBox(height: size.height * 0.015),

                // Date Badge
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      monthFormat.format(now),
                      style: const TextStyle(
                        color: Color(0xFF7B4FFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                // Total Salary Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.02,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Date badge in top left
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            monthFormat.format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Main content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'Total salary for this month',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: AppImage.asset(
                                    'assets/images/coinsicon.png',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.attach_money,
                                        color: Colors.white,
                                        size: 16,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                salary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                // Coin Turnover Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coin turnover',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Navigate to coin turnover details
                            },
                            child: Row(
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: size.height * 0.02),

                      // Level Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Your Level ',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'LV.$currentLevel',
                                  style: const TextStyle(
                                    color: Color(0xFF7B4FFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Upgrade info
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Upgrading will earn you a salary of 5 B coins.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Level Badges with Progress
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B4FFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Lv$currentLevel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF7B4FFF),
                                      ),
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B4FFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Lv${(int.tryParse(currentLevel) ?? 0) + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Progress text
                            Text(
                              '$progressText, $progressDescription',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Valid days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Valid days',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$validDays/$maxValidDays',
                                  style: const TextStyle(
                                    color: Color(0xFF7B4FFF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

                SizedBox(height: size.height * 0.02),

                // Bottom Navigation Buttons
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Wallet
                      _BottomNavButton(
                        icon: Icons.account_balance_wallet,
                        label: 'Wallet',
                        color: const Color(0xFFFF9800),
                        backgroundColor: const Color(0xFFFFF3E0),
                        onTap: () {
                        
                        },
                      ),

                      // Policy
                      _BottomNavButton(
                        icon: Icons.description,
                        label: 'Policy',
                        color: const Color(0xFF7B4FFF),
                        backgroundColor: const Color(0xFFE8D5FF),
                        onTap: () {
                          // TODO: Navigate to policy screen
                        },
                      ),

                    

                      // Cancel Verification
                      _BottomNavButton(
                        icon: Icons.cancel,
                        label: 'Cancel\nVerification',
                        color: const Color(0xFF00897B),
                        backgroundColor: const Color(0xFFE0F2F1),
                        onTap: () {
                          // TODO: Navigate to cancel verification screen
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
