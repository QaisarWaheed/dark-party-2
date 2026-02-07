import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

class VipRewardScreen extends StatefulWidget {
  const VipRewardScreen({super.key});

  @override
  State<VipRewardScreen> createState() => _VipRewardScreenState();
}

class _VipRewardScreenState extends State<VipRewardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('VIP Rewards', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'VIP-1'),
            Tab(text: 'VIP-2'),
            Tab(text: 'VIP-3'),
            Tab(text: 'VIP-4'),
            Tab(text: 'VIP-5'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVipLevelWithFallback("assets/images/vip1.png"),
                _buildVipLevelWithFallback("assets/images/vip2.png"),
                _buildVipLevelWithFallback("assets/images/vip3.png"),
                _buildVipLevelWithFallback("assets/images/vip4.png"),
                _buildVipLevelWithFallback("assets/images/vip5.png"),
              ],
            ),
          ),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildVipLevelWithFallback(String imagePath) {
    return FutureBuilder<bool>(
      future: _checkImageExists(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasData && snapshot.data!) {
          // Image exists - show it
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover
                
              ),
            ),
          );
        } else {
          // Image doesn't exist - show fallback
          return _buildFallbackUI(imagePath);
        }
      },
    );
  }

  Widget _buildFallbackUI(String imagePath) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
            SizedBox(height: 16),
            Text(
              'VIP Image Not Found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Add: $imagePath',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Test with a placeholder image
                setState(() {});
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkImageExists(String path) async {
    try {
      // Try to load the image
      await precacheImage(AssetImage(path), context);
      return true;
    } catch (e) {
      print("❌ Image not found: $path");
      return false;
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade900, Colors.green.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppImage.asset(
                'assets/images/coinsicon.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '1M/30 days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchase VIP-${_tabController.index + 1}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Purchase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}