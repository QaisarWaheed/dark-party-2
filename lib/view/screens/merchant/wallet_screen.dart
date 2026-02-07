import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/provider/merchant_list_provider.dart';
import 'package:shaheen_star_app/model/merchant_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shaheen_star_app/view/screens/merchant/merchant_profile_screen.dart';
import 'package:shaheen_star_app/utils/user_session.dart';

class WalletScreen extends StatefulWidget {
  final int initialTabIndex;
  const WalletScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Balance data
  double _goldCoins = 0.0;
  double _diamondCoins = 0.0;
  bool _isLoadingBalance = false;

  // Exchange fields (for Dollar tab)
  final TextEditingController _dollarController = TextEditingController();
  final double _exchangeRate = 8500.0; // 1$ = 8500 Coin
  double _calculatedCoins = 0.0;

  // Recharge packages (for Coin tab)
  // Updated diamond packages (ascending order)
  final List<Map<String, dynamic>> _rechargePackages = [
    {'coins': 200000, 'price': 8.57},     // 200k
    {'coins': 400000, 'price': 17.14},    // 400k
    {'coins': 600000, 'price': 25.71},    // 600k
    {'coins': 800000, 'price': 34.28},    // 800k
    {'coins': 1000000, 'price': 42.85},   // 1M
    {'coins': 1400000, 'price': 59.99},   // 1.4M
    {'coins': 2000000, 'price': 85.70},   // 2M
    {'coins': 4000000, 'price': 171.40},  // 4M
    {'coins': 6000000, 'price': 257.10},  // 6M
  ];

  // Selected action button under RECHARGE (0 = Google Play, 1 = Recharge)
  int _selectedActionButton = -1;

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 3)
      ? widget.initialTabIndex
      : 0;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _dollarController.addListener(_calculateExchange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserWalletBalance();
      final merchantProvider = Provider.of<MerchantListProvider>(context, listen: false);
      merchantProvider.fetchMerchants();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dollarController.dispose();
    super.dispose();
  }

  void _calculateExchange() {
    final dollarValue = double.tryParse(_dollarController.text) ?? 0.0;
    setState(() {
      _calculatedCoins = dollarValue * _exchangeRate;
    });
  }

  Future<void> _loadUserWalletBalance() async {
    setState(() { _isLoadingBalance = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      String userId = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userId = userIdInt.toString();
        } else {
          userId = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) userId = userIdValue.toString();
      }

      if (userId.isEmpty) {
        setState(() { _isLoadingBalance = false; });
        return;
      }

      final response = await ApiManager.getUserCoinsBalance(userId: userId);
      if (response != null && response.isSuccess) {
        setState(() {
          _goldCoins = response.goldCoins ?? 0.0;
          _diamondCoins = response.diamondCoins ?? 0.0;
          _isLoadingBalance = false;
        });
      } else {
        setState(() { _isLoadingBalance = false; });
      }
    } catch (e) {
      setState(() { _isLoadingBalance = false; });
    }
  }

  Widget _buildProfileAvatarWidget(String? url) {
    if (url == null || url.isEmpty) {
      return AppImage.asset('assets/images/person.png', width: 80, height: 80, fit: BoxFit.cover);
    }
    if (url.startsWith('assets/')) {
      return AppImage.asset(url, width: 80, height: 80, fit: BoxFit.cover);
    }
    return Image.network(url, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s)=> AppImage.asset('assets/images/person.png', width:80, height:80, fit:BoxFit.cover));
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;
    final isCoinTab = tabIndex == 0;
    final isMerchantTab = tabIndex == 2;
    final currentBalance = isCoinTab ? _goldCoins : _diamondCoins;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Wallet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox.shrink(),

            if (!isMerchantTab)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0.0, 0.6, 1.0],
                    colors: [
                      Color(0xFF7A5C1E),
                      Color(0xFFD4AF37),
                      Color(0xFFFFF1A8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7A5C1E).withOpacity(0.18),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gold',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isLoadingBalance ? 'Loading...' : currentBalance.toInt().toString(),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: isCoinTab
                          ? ClipOval(child: _buildProfileAvatarWidget(Provider.of<ProfileUpdateProvider>(context, listen: false).profile_url))
                          : Icon(Icons.attach_money, color: Colors.white, size: 50),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCoinRechargeTab(),
                  _buildDollarExchangeTab(),
                  _buildMerchantListTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Coin Tab - Recharge UI (matches first image)
  Widget _buildCoinRechargeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App banner replacing previous RECHARGE card
          Container(
            width: double.infinity,
            height: 120,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.18),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dark Party',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Welcome to the wallet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Two action buttons under RECHARGE banner: Google Play and Recharge (transparent)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActionButton = 0;
                    });
                    // TODO: implement Google Play purchase flow
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 48,
                        margin: EdgeInsets.only(right: 8, bottom: 6),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Google Play',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: double.infinity,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedActionButton == 0
                              ? Colors.green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActionButton = 1;
                    });
                    // Switch to the "The best discount Seller" (merchant) tab
                    if (_tabController.length > 2) {
                      _tabController.animateTo(2);
                      setState(() {});
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 48,
                        margin: EdgeInsets.only(left: 8, bottom: 6),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Recharge',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: double.infinity,
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: _selectedActionButton == 1
                              ? Colors.green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // (Section title removed as requested)

          // Recharge Packages Grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _rechargePackages.length,
            itemBuilder: (context, index) {
              final package = _rechargePackages[index];
              return _buildRechargePackageCard(package);
            },
          ),

          SizedBox(height: 20),

          // Explanation Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                children: [
                  TextSpan(
                    text:
                        'Explanation: If you encounter any problems with recharging, please contact our ',
                  ),
                  TextSpan(
                    text: 'online customer service.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Recharge Button - Golden theme
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFB300), // Darker Gold/Orange
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFB300).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Recharge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRechargePackageCard(Map<String, dynamic> package) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppImage.asset(
            'assets/images/coinsicon.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 8),
          Text(
            _formatNumber(package['coins']),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$${package['price'].toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    // Show actual number without formatting
    return number.toString();
  }

  // Dollar Tab - Exchange UI (matches second image)
  Widget _buildDollarExchangeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Exchange Button (Top)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'Exchange',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Dollar Input Field
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dollar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _dollarController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Please enter',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Coin Display Field
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _calculatedCoins.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Exchange Button (Bottom)
          GestureDetector(
            onTap: () {
              if (_dollarController.text.isEmpty ||
                  double.tryParse(_dollarController.text) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid dollar amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              // Handle exchange
              print(
                "Exchange tapped: ${_dollarController.text} dollars = $_calculatedCoins coins",
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exchange functionality will be implemented'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Exchange',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Merchant Tab - Merchant List UI
  Widget _buildMerchantListTab() {
    return Consumer<MerchantListProvider>(
      builder: (context, merchantProvider, child) {
        // No special merchant header - use the same card design for all merchants
        if (merchantProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        final merchants = merchantProvider.merchants;

        // No special header — use unified merchant card design for all items

        if (merchants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No merchants available',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.green.withOpacity(0.28),
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              // Merchant List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = merchants[index];
                    return _buildMerchantCard(merchant, highlight: true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMerchantCard(MerchantModel merchant, {bool highlight = false}) {
    // Normalize profile URL
    String? profileImageUrl;
    if (merchant.profileUrl != null && merchant.profileUrl!.isNotEmpty) {
      if (merchant.profileUrl!.startsWith('http://') ||
          merchant.profileUrl!.startsWith('https://')) {
        profileImageUrl = merchant.profileUrl;
      } else {
        // Relative path - prepend base URL
        profileImageUrl = 'https://shaheenstar.online/${merchant.profileUrl}';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle merchant tap - could navigate to merchant profile
            print("Merchant tapped: ${merchant.name}");
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.primaryColor.withOpacity(0.1),
          highlightColor: AppColors.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Profile & Header Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image with Gradient Border
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          image: profileImageUrl != null
                              ? DecorationImage(
                                image: NetworkImage(profileImageUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  print("❌ Error loading profile image: $exception");
                                },
                              )
                              : null,
                        ),
                        child: profileImageUrl == null
                            ? Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryColor,
                              size: 28,
                            )
                            : null,
                      ),
                    ),
                    SizedBox(width: 16),

                    // Merchant Name and ID Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Merchant Name
                          Text(
                            merchant.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),

                          // Merchant ID Badge with country flag under the ID
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  merchant.uniqueUserId != null
                                      ? 'ID: ${merchant.uniqueUserId}'
                                      : 'ID: ${merchant.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              if (merchant.country != null && merchant.country!.isNotEmpty)
                                SizedBox(
                                  width: 28,
                                  height: 18,
                                  child: AppImage.asset(
                                    'assets/images/flags/${merchant.country!.toLowerCase()}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 28,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Icon(Icons.flag, size: 12, color: Colors.grey[500]),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Username (if available)
                          if (merchant.username != null &&
                              merchant.username!.isNotEmpty &&
                              merchant.username != merchant.name)
                            Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                '@${merchant.username}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Action buttons: Profile and WhatsApp — make them fill the bordered box
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                side: BorderSide(color: AppColors.primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: Colors.transparent,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => MerchantProfileScreen(merchant: merchant),
                                ));
                              },
                              child: Center(
                                child: AppImage.asset(
                                  'assets/images/merchanthome.png',
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) => AppImage.asset(
                                    'assets/images/storeIcon.png',
                                    width: 18,
                                    height: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                side: BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: Colors.transparent,
                              ),
                              onPressed: () async {
                                final number = merchant.whatsappNumber ?? merchant.phone ?? '';
                                if (number.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No contact number available')));
                                  return;
                                }

                                // Load current user's session to get user ID
                                final session = UserSession();
                                await session.loadSession();
                                final userIdStr = session.userId?.toString() ?? '';

                                final message =
                                    'Hello, I want to buy coins for the Dark Party app.\nMy User ID is: ${userIdStr.isNotEmpty ? userIdStr : '{USER_ID}'}\nPlease share the rates and payment details. Thank you.';
                                final encodedMessage = Uri.encodeComponent(message);

                                final sanitized = number.replaceAll(RegExp(r'[^0-9+]'), '');
                                final phone = sanitized.replaceAll('+', '');
                                final uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open WhatsApp')));
                                }
                              },
                              child: Center(
                                child: AppImage.asset('assets/images/merchantwhatsapp.png', width: 20, height: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleValueChip(String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
