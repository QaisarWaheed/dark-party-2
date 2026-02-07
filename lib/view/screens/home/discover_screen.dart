import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/view/screens/home/cp_screen.dart';
import 'package:shaheen_star_app/view/screens/ranking/ranking_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int selectedLiveTab = 0; // 0: Offical Live, 1: Popular Live

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // First Featured Section - Mine_Page_photo_Top.png (Honors Broadcast) - Full width
                  _buildSecondFeaturedSection(),
                  const SizedBox(height: 30),
                  // Second Featured Section - Mine_Page_Photo_Second.png (Horizontal Cards)
                  _buildFeaturedSection(
                    title: 'Featured',
                    isFirst: true,
                  ),
                  const SizedBox(height: 30),
                  // Live Content Tabs
                  _buildLiveTabs(),
                  const SizedBox(height: 20),
                  // Content based on selected tab
                  if (selectedLiveTab == 0)
                    _buildOfficalLiveContent()
                  else
                    _buildPopularLiveContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Full-screen overlay: center the three buttons vertically & horizontally
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: SizedBox(
                            width: 130,
                            child: _smallTopButton(
                              context,
                              'Gifter List',
                              iconOnRight: true,
                              bgColor: const Color(0xFFFFD700),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gifter List tapped')));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 140,
                          child: _smallTopButton(
                            context,
                            'Cp Leaderboard',
                            iconOnRight: true,
                            bgColor: const Color(0xFFFF69B4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CpScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 140,
                          child: _smallTopButton(
                            context,
                            'Game LeaderBoard',
                            iconOnRight: true,
                            bgColor: const Color(0xFF42A5F5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RankingScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection({required String title, bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Using the actual image for horizontal scrollable cards - Full width and scrollable
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: AppImage.asset(
                'assets/images/Card.png',
                fit: BoxFit.fitHeight,
                height: 220,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error loading Mine_Page_Photo_Second.png: $error');
                  return Container(
                    height: 220,
                    width: 300,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text('Image not found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Text(
            'Featured',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Using the actual image for the second featured section - Full width, edge-to-edge
        // Using MediaQuery to get full screen width without negative margins
        Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: screenWidth,
                  color: Colors.transparent,
                ),

                

              ],
            );
          },
        ),
      ],
    );
  }

  Widget _smallTopButton(BuildContext context, String label, {required VoidCallback onTap, String? iconAsset, bool iconOnRight = false, Color? bgColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        highlightColor: Colors.white10,
        splashColor: Colors.white12,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!iconOnRight && iconAsset != null) ...[
                AppImage.asset(
                  iconAsset,
                  width: 28,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(width: 28, height: 24),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: bgColor != null ? Colors.white : Colors.black87),
              ),
              if (iconOnRight && iconAsset != null) ...[
                const SizedBox(width: 6),
                AppImage.asset(
                  iconAsset,
                  width: 28,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(width: 28, height: 24),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLiveTab('Offical Live', 0),
              const SizedBox(width: 20),
              _buildLiveTab('Popular Live', 1),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.black87),
            onPressed: () {
              // Toggle grid/list view
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab(String title, int index) {
    final isSelected = selectedLiveTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLiveTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfficalLiveContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          'Offical Live Content',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildPopularLiveContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          'Popular Live Content',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
