import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/merchant_profile_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/transaction_model.dart';
import 'package:shaheen_star_app/model/merchant_model.dart';
import 'package:shaheen_star_app/view/screens/merchant/review_transaction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantProfileScreen extends StatefulWidget {
  final MerchantModel? merchant;
  final bool autoShowTransfer;

  const MerchantProfileScreen({super.key, this.merchant, this.autoShowTransfer = false});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  // Transaction history
  List<TransactionModel> _transactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    // Load user data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadTransactionHistory();

      // If requested, immediately open the transfer bottom sheet
      if (widget.autoShowTransfer) {
        try {
          final merchantProvider = Provider.of<MerchantProfileProvider>(context, listen: false);
          // Show the transfer bottom sheet after the frame
          _showTransferBottomSheet(context, merchantProvider);
        } catch (e) {
          // Ignore if provider not available yet
          print('⚠️ Could not auto-show transfer sheet: $e');
        }
      }
    });
  }

  void _loadUserData() {
    final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
    final merchantProvider = Provider.of<MerchantProfileProvider>(context, listen: false);

    // If a merchant was passed in, we won't overwrite the header info, but still load merchant coins
    merchantProvider.loadMerchantCoins();

    // If no merchant provided, fetch current user data as before
    if (widget.merchant == null) {
      if (profileProvider.username == null || profileProvider.username!.isEmpty) {
        profileProvider.fetchUserData();
      }
    }
  }

  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Safely get user_id (handles both int and String types)
      String userId = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userId = userIdInt.toString();
        } else {
          userId = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userId = userIdValue.toString();
        }
      }

      if (userId.isEmpty) {
        setState(() {
          _isLoadingTransactions = false;
        });
        return;
      }

      final response = await ApiManager.getTransactionHistory(userId: userId);
      
      if (response != null && response.status.toLowerCase() == 'success') {
        setState(() {
          _transactions = response.transactions;
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  // Helper methods for transaction display
  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'transfer':
      case 'sent':
        return Icons.arrow_upward;
      case 'received':
        return Icons.arrow_downward;
      case 'payout':
        return Icons.attach_money;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'transfer':
      case 'sent':
        return Colors.orange;
      case 'received':
        return Colors.green;
      case 'payout':
        return const Color(0xFF8C68FF);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
        }
      }
      return date;
    } catch (e) {
      return date;
    }
  }


  // Format coins for display - show actual number without decimals
  String _formatCoinsDisplay(double coins) {
    if (coins <= 0) {
      return '0';
    }
 
    return coins.toInt().toString();
  }

  ImageProvider _getProfileImage(String? profileUrl) {
    if (profileUrl == null || profileUrl.isEmpty || profileUrl == 'yyyy' || profileUrl == 'Profile Url') {
      return const AssetImage('assets/images/person.png');
    }

    // Check if it's a network URL
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return NetworkImage(profileUrl);
    }

    // Check if it's a local file path
    if (profileUrl.startsWith('/data/') || profileUrl.startsWith('/storage/') || profileUrl.contains('cache')) {
      try {
        File file = File(profileUrl);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          return const AssetImage('assets/images/person.png');
        }
      } catch (e) {
        return const AssetImage('assets/images/person.png');
      }
    }

    return const AssetImage('assets/images/person.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF8F4FF),
              const Color(0xFFF0E8FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
          leading: widget.merchant != null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundImage: widget.merchant!.profileUrl != null
                        ? NetworkImage(widget.merchant!.profileUrl!)
                        : const AssetImage('assets/images/person.png') as ImageProvider,
                  ),
                )
              : Consumer<ProfileUpdateProvider>(
                  builder: (context, profileProvider, child) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: _getProfileImage(profileProvider.profile_url),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback if image fails to load
                        },
                      ),
                    );
                  },
                ),
          title: widget.merchant != null
              ? Text(
                  widget.merchant!.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Consumer<ProfileUpdateProvider>(
                  builder: (context, profileProvider, child) {
                    final username = profileProvider.username ?? 'User';
                    final displayName = username.isNotEmpty ? username : 'User';
                    return Text(
                      'Hi, $displayName',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
        actions: [
          // You can add dynamic data here if needed (e.g., level, points, etc.)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Text(
                  '78',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.flash_on, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
            Expanded(
              child: Consumer2<MerchantProfileProvider, ProfileUpdateProvider>(
        builder: (context, merchantProvider, profileProvider, child) {
          return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gold Card (Premium Style)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -40,
                              left: -40,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            // Content
                            Column(
                              children: [
                                // Decorative Graphic Elements (Polygonal shapes)
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 60,
                                    height: 50,
                                    child: CustomPaint(
                                      painter: GoldShardsPainter(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                    'Your available coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                merchantProvider.isLoadingCoins
                                    ? const SizedBox(
                                        height: 56,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _formatCoinsDisplay(merchantProvider.availableCoins),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -2,
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.swap_vert_rounded,
                              label: 'Transfer',
                              color: const Color(0xFFFFB300),
                              onTap: () {
                                print("🖱️🖱️🖱️ TRANSFER BUTTON CLICKED 🖱️🖱️🖱️");
                                print("   - isSheetShowing: ${merchantProvider.isSheetShowing}");
                                print("   - isTransferSheetVisible: ${merchantProvider.isTransferSheetVisible}");
                                
                                // Show the transfer bottom sheet
                                _showTransferBottomSheet(context, merchantProvider);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.shopping_bag_outlined,
                              label: 'Buy Coins',
                              color: const Color(0xFFFFB300),
                              onTap: () {
                                // Handle Buy Coins
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Latest Transactions
                      const Text(
                        'Latest Transactions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Transaction List
                      _isLoadingTransactions
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _transactions.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No transactions yet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Your transfer history will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: _transactions.take(5).map((transaction) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _getTransactionIconColor(transaction.type).withOpacity(0.1),
                                              ),
                                              child: Icon(
                                                _getTransactionIcon(transaction.type),
                                                color: _getTransactionIconColor(transaction.type),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transaction.getDisplayTitle(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      _formatDate(transaction.date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    if (transaction.status.isNotEmpty) ...[
                                                      Text(
                                                        ' • ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade400,
                                                        ),
                                                      ),
                                                      Text(
                                                        transaction.status[0].toUpperCase() + transaction.status.substring(1),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: _getStatusColor(transaction.status),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Text(
                                              transaction.amount,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _getTransactionIconColor(transaction.type),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                    ],
                  ),
                ),
              );
        },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        print("🖱️ Action button tapped: $label");
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
         color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(5, 5),
            ),
          ],
         
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.amber,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferBottomSheet(
      BuildContext context, MerchantProfileProvider provider) {
    print("📋 ========== SHOWING TRANSFER BOTTOM SHEET ==========");
    print("   - Context mounted: ${context.mounted}");
    print("   - Current isSheetShowing: ${provider.isSheetShowing}");
    
    if (!context.mounted) {
      print("❌ Context not mounted, cannot show sheet");
      return;
    }
    
    // Reset state first
    provider.hideTransferSheet();
    
    try {
      print("📋 Calling showModalBottomSheet directly...");
      
      // Set state BEFORE showing the sheet (not during build)
      provider.showTransferSheet();
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (sheetContext) {
          print("✅✅✅ Bottom sheet builder called - SHEET IS SHOWING!");
          // DON'T call provider.showTransferSheet() here - it causes setState during build!
          return _buildTransferBottomSheetContent(sheetContext, provider);
        },
      ).then((value) {
        print("📋 Bottom sheet dismissed with value: $value");
        provider.hideTransferSheet();
      }).catchError((error, stackTrace) {
        print("❌ Error in bottom sheet: $error");
        print("   - Stack trace: $stackTrace");
        provider.hideTransferSheet();
      });
      
      print("✅ showModalBottomSheet called successfully");
    } catch (e, stackTrace) {
      print("❌❌❌ EXCEPTION showing bottom sheet: $e");
      print("   - Stack trace: $stackTrace");
      provider.hideTransferSheet();
    }
    
    print("📋 ========== SHOW TRANSFER BOTTOM SHEET END ==========");
  }

  Widget _buildTransferBottomSheetContent(
      BuildContext context, MerchantProfileProvider provider) {
    final amountController = TextEditingController(text: provider.amount);
    final receiverIdController = TextEditingController(text: provider.receiverId);

    print("📋 Building transfer bottom sheet content");
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (sheetContext, scrollController) {
        print("📋 DraggableScrollableSheet builder called");
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFCCF1D6),
                Color(0xFFA7E7B0),
                Color(0xFF8FE599),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Gold Coins',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Available Balance Field (green)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                          decoration: BoxDecoration(
                          color: const Color(0xFFE7FBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade500,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppImage.asset(
                              'assets/images/coinsicon.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Available: ${_formatCoinsDisplay(provider.availableCoins)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Amount Label
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Amount Input Field
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: amountController,
                          onChanged: (value) => provider.setAmount(value),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter amount',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Receiver ID Label
                      const Text(
                        'Receiver ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Receiver ID Input Field
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: receiverIdController,
                          onChanged: (value) => provider.setReceiverId(value),
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter receiver's User ID",
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Review Transaction Button
                      GestureDetector(
                        onTap: () {
                          print("🔄 ========== REVIEW TRANSACTION BUTTON CLICKED ==========");
                          print("   - Amount: ${provider.amount}");
                          print("   - Receiver ID: ${provider.receiverId}");
                          print("   - Available Merchant Coins: ${provider.availableCoins}");
                          print("   - Is Transferring: ${provider.isTransferring}");
                          print("   - Transfer Error: ${provider.transferError}");
                          
                          // Validate inputs before navigating
                          if (provider.amount.isEmpty) {
                            print("⚠️ Validation Failed: Amount is empty");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          if (provider.receiverId.isEmpty) {
                            print("⚠️ Validation Failed: Receiver ID is empty");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter receiver ID'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          final amountValue = double.tryParse(provider.amount);
                          if (amountValue == null || amountValue <= 0) {
                            print("⚠️ Validation Failed: Invalid amount value");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // ✅ Use only merchant coins, no fallback to user balance
                          final availableCoins = provider.availableCoins;
                          if (amountValue > availableCoins) {
                            print("❌ Validation Failed: Insufficient balance");
                            print("   - Requested: $amountValue");
                            print("   - Available Merchant Coins: $availableCoins");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Insufficient balance. Available: $availableCoins'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          print("✅ Validation Passed - Navigating to Review Screen");
                          print("   - Merchant Coins Transfer API will be called from Review Screen");
                          print("   - API Endpoint: https://shaheenstar.online/Merchant_Coins_Distribution_API.php");
                          print("   - Action Type: merchant_to_user (adds to user's GOLD coins)");
                          
                          Navigator.pop(context);
                          provider.hideTransferSheet();
                          
                          // Navigate to Review Transaction Screen
                          print("🧭 Navigating to ReviewTransactionScreen...");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReviewTransactionScreen(),
                            ),
                          ).then((value) {
                            print("🔄 Returned from ReviewTransactionScreen");
                            print("   - Return value: $value");
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFD5BFF), Color(0xFF8C68FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Review Transaction',
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter for Gold Shards Graphic
class GoldShardsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw polygonal shapes (gold shards)
    final path1 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.1)
      ..lineTo(size.width * 0.6, size.height * 0.2)
      ..lineTo(size.width * 0.5, size.height * 0.4)
      ..lineTo(size.width * 0.2, size.height * 0.3)
      ..close();
    paint.color = const Color(0xFFFFD54F).withOpacity(0.8);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.15)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.4)
      ..close();
    paint.color = const Color(0xFFFFB300).withOpacity(0.9);
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.45, size.height * 0.4)
      ..lineTo(size.width * 0.35, size.height * 0.65)
      ..lineTo(size.width * 0.1, size.height * 0.55)
      ..close();
    paint.color = const Color(0xFFFF8F00).withOpacity(0.85);
    canvas.drawPath(path3, paint);

    final path4 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width * 0.85, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..close();
    paint.color = const Color(0xFFFF6F00).withOpacity(0.8);
    canvas.drawPath(path4, paint);

    final path5 = Path()
      ..moveTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..lineTo(size.width * 0.55, size.height * 0.85)
      ..lineTo(size.width * 0.3, size.height * 0.75)
      ..close();
    paint.color = const Color(0xFFFFB300).withOpacity(0.75);
    canvas.drawPath(path5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
