import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/merchant_profile_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shaheen_star_app/components/coin_transfer_success_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewTransactionScreen extends StatefulWidget {
  const ReviewTransactionScreen({super.key});

  @override
  State<ReviewTransactionScreen> createState() => _ReviewTransactionScreenState();
}

class _ReviewTransactionScreenState extends State<ReviewTransactionScreen> {
  String? _receiverName;
  String? _lastReceiverId;
  bool _isLoadingReceiverName = false;

  Future<void> _loadReceiverName(String receiverId, String merchantId) async {
    // Skip if already loading the same receiver
    if (_lastReceiverId == receiverId && _receiverName != null) {
      return;
    }

    _lastReceiverId = receiverId;

    // If receiver is the same as merchant, use merchant's name
    if (receiverId == merchantId) {
      final profileProvider = Provider.of<ProfileUpdateProvider>(context, listen: false);
      setState(() {
        _receiverName = profileProvider.username ?? 'User';
        _isLoadingReceiverName = false;
      });
      print('✅ Receiver is merchant - using merchant name: $_receiverName');
      return;
    }

    // Otherwise, try to get receiver's name from SharedPreferences
    setState(() {
      _isLoadingReceiverName = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final receiverName = prefs.getString('userName_$receiverId') ?? 
                          prefs.getString('username_$receiverId');
      
      setState(() {
        _receiverName = receiverName ?? 'User';
        _isLoadingReceiverName = false;
      });
      
      if (receiverName != null) {
        print('✅ Loaded receiver name from SharedPreferences: $receiverName');
      } else {
        print('⚠️ Receiver name not found in SharedPreferences for ID: $receiverId');
      }
    } catch (e) {
      print('❌ Error loading receiver name: $e');
      setState(() {
        _receiverName = 'User';
        _isLoadingReceiverName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("📄 ========== REVIEW TRANSACTION SCREEN LOADED ==========");
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Review Your Transaction',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: Consumer2<MerchantProfileProvider, ProfileUpdateProvider>(
        builder: (context, merchantProvider, profileProvider, child) {
          final merchantName = profileProvider.username ?? 'MR Dark';
          final merchantId = profileProvider.userId ?? '30002';
          final amount = merchantProvider.amount.isNotEmpty 
              ? merchantProvider.amount 
              : '0';
          final receiverId = merchantProvider.receiverId.isNotEmpty
              ? merchantProvider.receiverId
              : '0';
          
          // Load receiver name on first build or when receiver ID changes
          if (_lastReceiverId != receiverId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadReceiverName(receiverId, merchantId);
            });
          }
          
          // Use loaded receiver name or fallback
          final receiverName = _receiverName ?? (_isLoadingReceiverName ? 'Loading...' : 'User');
          
          print("📊 Review Screen Data:");
          print("   - Merchant Name: $merchantName");
          print("   - Merchant ID: $merchantId");
          print("   - Amount: $amount");
          print("   - Receiver ID: $receiverId");
          print("   - Receiver Name: $receiverName");
          print("   - Available Coins: ${merchantProvider.availableCoins}");
          print("   - Is Transferring: ${merchantProvider.isTransferring}");

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                       
                          
                          // Merchant Card (App Color Gradient)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8C68FF),Color(0xFFFD5BFF), ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchantName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Merchant ID: $merchantId',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                           // Transaction Details Card (Mastercard Style)
                           Container(
                             width: double.infinity,
                             height: 220,
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   const Color(0xFF1A1A2E),
                                   const Color(0xFF16213E),
                                   const Color(0xFF0F3460),
                                 ],
                               ),
                               borderRadius: BorderRadius.circular(20),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.3),
                                   blurRadius: 20,
                                   offset: const Offset(0, 10),
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
                                 // Decorative circles (Mastercard style)
                                 Positioned(
                                   top: -40,
                                   right: -40,
                                   child: Container(
                                     width: 150,
                                     height: 150,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       gradient: RadialGradient(
                                         colors: [
                                           const Color(0xFFEB001B).withOpacity(0.3),
                                           Colors.transparent,
                                         ],
                                       ),
                                     ),
                                   ),
                                 ),
                                 Positioned(
                                   bottom: -50,
                                   left: -50,
                                   child: Container(
                                     width: 160,
                                     height: 160,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       gradient: RadialGradient(
                                         colors: [
                                           const Color(0xFFF79E1B).withOpacity(0.3),
                                           Colors.transparent,
                                         ],
                                       ),
                                     ),
                                   ),
                                 ),
                                 // Content
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     // Top section - Pay To
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           'PAY TO',
                                           style: TextStyle(
                                             color: Colors.white.withOpacity(0.7),
                                             fontSize: 11,
                                             fontWeight: FontWeight.w600,
                                             letterSpacing: 2,
                                           ),
                                         ),
                                         const SizedBox(height: 12),
                                         Text(
                                           receiverName,
                                           style: const TextStyle(
                                             color: Colors.white,
                                             fontSize: 26,
                                             fontWeight: FontWeight.bold,
                                             letterSpacing: 0.5,
                                           ),
                                         ),
                                         const SizedBox(height: 6),
                                         Text(
                                           'ID: $receiverId',
                                           style: TextStyle(
                                             color: Colors.white.withOpacity(0.8),
                                             fontSize: 14,
                                             fontWeight: FontWeight.w500,
                                             letterSpacing: 0.5,
                                           ),
                                         ),
                                       ],
                                     ),
                                     
                                     // Bottom section - Gold Coins
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       crossAxisAlignment: CrossAxisAlignment.end,
                                       children: [
                                         // Gold Coins Info
                                         Row(
                                           children: [
                                             // Gold Coins Icon
                                             SizedBox(
                                               width: 36,
                                               height: 36,
                                               child: CustomPaint(
                                                 painter: GoldCoinsIconPainter(),
                                               ),
                                             ),
                                             const SizedBox(width: 12),
                                             Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   amount,
                                                   style: const TextStyle(
                                                     color: AppColors.secondaryColor,
                                                     fontSize: 24,
                                                     fontWeight: FontWeight.bold,
                                                     letterSpacing: 0.5,
                                                   ),
                                                 ),
                                                 Text(
                                                   'Gold Coins',
                                                   style: TextStyle(
                                                     color: Colors.white.withOpacity(0.7),
                                                     fontSize: 12,
                                                     fontWeight: FontWeight.w500,
                                                     letterSpacing: 0.5,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ],
                                         ),
                                         // Mastercard logo circles
                                         SizedBox(
                                           width: 44,
                                           height: 32,
                                           child: Stack(
                                             clipBehavior: Clip.none,
                                             children: [
                                               Positioned(
                                                 left: 0,
                                                 child: Container(
                                                   width: 32,
                                                   height: 32,
                                                   decoration: BoxDecoration(
                                                     shape: BoxShape.circle,
                                                     color: const Color(0xFFEB001B),
                                                   ),
                                                 ),
                                               ),
                                               Positioned(
                                                 left: 20,
                                                 child: Container(
                                                   width: 32,
                                                   height: 32,
                                                   decoration: BoxDecoration(
                                                     shape: BoxShape.circle,
                                                     color: const Color(0xFFF79E1B),
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       ],
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
                
                // Send Now Button (Fixed at bottom)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<MerchantProfileProvider>(
                    builder: (context, merchantProvider, child) {
                      return GestureDetector(
                        onTap: merchantProvider.isTransferring
                            ? null
                            : () async {
                                print("🚀 ========== SEND NOW BUTTON CLICKED ==========");
                                print("   - Merchant ID: ${profileProvider.userId}");
                                print("   - Receiver ID: $receiverId");
                                print("   - Amount: $amount");
                                print("   - Available Coins: ${merchantProvider.availableCoins}");
                                print("   - API Endpoint: https://shaheenstar.online/merchant_coins.php");
                                print("   - API Method: POST");
                                print("   - Request Fields:");
                                print("     * admin_id: ${profileProvider.userId}");
                                print("     * merchant_id: ${profileProvider.userId}");
                                print("     * user_id: $receiverId");
                                print("     * amount: $amount");
                                print("     * action_type: merchant_to_user");
                                
                                // Call transfer API
                                print("📡 Calling merchantProvider.transferCoins()...");
                                final success = await merchantProvider.transferCoins(context);
                                
                                print("📥 Transfer API Response:");
                                print("   - Success: $success");
                                print("   - Transfer Error: ${merchantProvider.transferError}");
                                
                                if (success && context.mounted) {
                                  print("✅ Transfer successful - Showing success dialog");
                                  
                                  // Show success dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogContext) => CoinTransferSuccessDialog(
                                      amount: amount,
                                      transactionTime: DateTime.now(),
                                    ),
                                  ).then((_) {
                                    // Navigate back after dialog is closed
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  });
                                } else {
                                  print("❌ Transfer failed - Staying on review screen");
                                }
                              },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: merchantProvider.isTransferring
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF8C68FF), Color(0xFFFD5BFF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        color: merchantProvider.isTransferring
                            ? Colors.grey
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: merchantProvider.isTransferring
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Send Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.bgColor,
                                ),
                              ),
                      ),
                    ),
                      );
                    },
                  ),
                ),
              ],
            );
        },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// Custom Painter for Gold Coins Icon (Polygonal shapes)
class GoldCoinsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw multiple overlapping polygonal shapes to represent gold coins
    final path1 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.1)
      ..lineTo(size.width * 0.6, size.height * 0.15)
      ..lineTo(size.width * 0.5, size.height * 0.4)
      ..lineTo(size.width * 0.1, size.height * 0.35)
      ..close();
    paint.color = AppColors.secondaryColor.withOpacity(0.9);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.25)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.45)
      ..close();
    paint.color = AppColors.secondaryColor;
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(size.width * 0.4, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.35)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.55)
      ..close();
    paint.color = AppColors.secondaryColor.withOpacity(0.85);
    canvas.drawPath(path3, paint);

    final path4 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.0, size.height * 0.65)
      ..close();
    paint.color = AppColors.secondaryColor.withOpacity(0.8);
    canvas.drawPath(path4, paint);

    final path5 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.9, size.height * 0.55)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..close();
    paint.color = AppColors.secondaryColor.withOpacity(0.7);
    canvas.drawPath(path5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

