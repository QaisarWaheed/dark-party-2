// ignore_for_file: dead_code, unused_element, unused_import, unused_local_variable, unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/merchant_profile_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/payout_provider.dart';
import 'package:shaheen_star_app/view/screens/merchant/agent_withdraw_screen.dart';
import 'package:shaheen_star_app/view/screens/merchant/diamond_exchange_screen.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/withdrawal_model.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

// Small info tile used in the info card
class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.diamond, color: Color(0xFF8C68FF), size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ],
    );
  }
}

// Dotted divider similar to design
class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dotWidth = 4.0;
          const gap = 6.0;
          final count = (boxWidth / (dotWidth + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              return Container(
                width: dotWidth,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: gap / 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// Helper to format diamond counts like 11.5K
String _formatDiamondCount(double value) {
  if (value >= 1000) {
    double v = value / 1000.0;
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}K';
  }
  return value.toInt().toString();
}

String _formatDiamondCountDouble(double value) => _formatDiamondCount(value);

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final withdrawProvider = Provider.of<WithdrawProvider>(context, listen: false);
      withdrawProvider.loadUserBalance();
      withdrawProvider.loadTransactionHistory();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // AppBar
              AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Withdraw',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              
              // Content
              Expanded(
                child: Consumer3<MerchantProfileProvider, ProfileUpdateProvider, WithdrawProvider>(
                  builder: (context, merchantProvider, profileProvider, withdrawProvider, child) {
                    // Use diamond coins balance from provider (for withdrawal)
                    final availableBalance = withdrawProvider.userBalance;

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Purple Card (Diamonds available)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9C68FF), Color(0xFFFD9BFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Diamonds available',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Bill',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.diamond, color: Colors.white, size: 28),
                                      const SizedBox(width: 8),
                                      withdrawProvider.isLoadingBalance
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(
                                              _formatDiamondCount(availableBalance),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // small rounded pink connector (matches design)
                            Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              alignment: Alignment.center,
                              child: Container(
                                height: 8,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFC0E8), Color(0xFFFF9BD6)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                            // Info Card (light purple background)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              // Info card background color: tweak these two colors
                              // to adjust the light purple look. Example:
                              // const Color(0xFFF6EEFF) (light) -> const Color(0xFFFFFFFF) (white)
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFF6EEFF), Color(0xFFFFFFFF)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 107, 82, 155).withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InfoTile(
                                          title: 'The number of diamonds',
                                          value: _formatDiamondCountDouble(availableBalance),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _InfoTile(
                                          title: 'Frozen diamonds count',
                                          value: '0',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InfoTile(
                                          title: "Host's diamonds this week",
                                          value: '0',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _InfoTile(
                                          title: "Host's rating last week",
                                          value: '1',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // "ins for week's rating" row (left aligned, with emoji and value)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        const Text(
                                          "ins for week's rating",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.emoji_emotions, size: 16, color: Colors.amber),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // dotted divider and date
                                  const _DottedDivider(),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      'Date time 2026-01-26 18:57:16',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Diamonds operation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Operations List
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: AppImage.asset('assets/icons/diamond_exchange.png', width: 20, height: 20),
                                    ),
                                    title: const Text('Diamonds exchange'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const DiamondExchangeScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: AppImage.asset('assets/icons/diamond_withdraw.png', width: 20, height: 20),
                                    ),
                                      title: const Text('Diamonds withdraw'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const AgentWithdrawScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: AppImage.asset('assets/icons/diamond_transfer.png', width: 20, height: 20),
                                    ),
                                    title: const Text('Diamonds transfer'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      _showTransferBottomSheet(context);
                                    },
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  void _showTransactionDetailsSheet(
    BuildContext context, {
    required String   transactionId,
    required String transactionType,
    required String date,
    required String status,
    required String amount,
    required String payoutMethod,
    required String payoutNumber,
    required String otherParty,
    required String otherPartyId,
    required String goldCoinsSent,
    required String diamondCoinsReceived,
    required String timestamp,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // Transaction ID
                      Text(
                              'Transaction ID: TID# $otherParty',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Date and Status
                      Row(
                        children: [
                          Text(
                            '$date : ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Payout Details
                      Text(
                        'Payout: $payoutMethod ($payoutNumber)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Centered Content
                      Center(
                        child: Column(
                          children: [
                            // Diamond Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8C68FF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.diamond,
                                color: Color(0xFF8C68FF),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Amount
                            Text(
                              amount,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFD5BFF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Success Message
                            const Text(
                              'Transfer succeed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
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
        );
      },
    );
  }

  void _showTransferBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transfer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                         
                        ],
                      ),
                    ),
                    
                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount Field
                            const Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'enter Amount',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // ID No. Field
                            const Text(
                              'ID No.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _userIdController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter User ID to transfer',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  
                  // Transfer Now Button (Fixed at bottom)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _TransferButton(
                      amountController: _amountController,
                      userIdController: _userIdController,
                      onSuccess: () {
                        Navigator.pop(context);
                        final withdrawProvider = Provider.of<WithdrawProvider>(context, listen: false);
                        withdrawProvider.refresh();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        );
      },
    );
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
        return AppColors.primaryColor;
      default:
        return Colors.grey;
    }
  }

  Color _getTransactionAmountColor(String type) {
    switch (type.toLowerCase()) {
      case 'transfer':
      case 'sent':
        return Colors.orange;
      case 'received':
        return Colors.green;
      case 'payout':
        return AppColors.primaryColor;
      default:
        return Colors.black87;
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
      // Try to parse the date and format it
      // Assuming format like "2025-11-12" or "2025-11-12 10:30:00"
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

  void _showPayoutBottomSheet(BuildContext context) {
    final payoutProvider = Provider.of<PayoutProvider>(context, listen: false);
    payoutProvider.showPayoutSheet();
    payoutProvider.resetForm();
    // Load payment methods when sheet is shown
    payoutProvider.loadPaymentMethods();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return _PayoutBottomSheetContent();
      },
    ).whenComplete(() {
      payoutProvider.hidePayoutSheet();
    });
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Color(0xFF8C68FF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8C68FF).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
                color: Color(0xFF8C68FF),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Transfer Button Widget
class _TransferButton extends StatefulWidget {
  final TextEditingController amountController;
  final TextEditingController userIdController;
  final VoidCallback onSuccess;

  const _TransferButton({
    required this.amountController,
    required this.userIdController,
    required this.onSuccess,
  });

  @override
  State<_TransferButton> createState() => _TransferButtonState();
}

class _TransferButtonState extends State<_TransferButton> {
  final ValueNotifier<bool> _isTransferring = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isTransferring.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    final amount = widget.amountController.text.trim();
    final receiverId = widget.userIdController.text.trim();

    if (amount.isEmpty || receiverId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter amount and user ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _isTransferring.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Safely get user_id (handles both int and String types)
      String senderId = '';
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          senderId = userIdInt.toString();
        } else {
          senderId = prefs.getString('user_id') ?? '';
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          senderId = userIdValue.toString();
        }
      }

      if (senderId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _isTransferring.value = false;
        return;
      }

      final response = await ApiManager.transferCoinsUserToUser(
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
      );

      if (context.mounted) {
        if (response != null && response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty ? response.message : 'Transfer successful'),
            backgroundColor: Colors.green,
          ),
          );
          widget.onSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?.message ?? 'Transfer failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isTransferring.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTransferring,
      builder: (context, isTransferring, child) {
        return GestureDetector(
          onTap: isTransferring ? null : _handleTransfer,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isTransferring
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF8C68FF), Color(0xFFFD5BFF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: isTransferring ? Colors.grey : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: isTransferring
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Transfer Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// Separate StatefulWidget to manage controllers properly
class _PayoutBottomSheetContent extends StatefulWidget {
  @override
  State<_PayoutBottomSheetContent> createState() => _PayoutBottomSheetContentState();
}

class _PayoutBottomSheetContentState extends State<_PayoutBottomSheetContent> {
  late TextEditingController _accountController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final payoutProvider = Provider.of<PayoutProvider>(context, listen: false);
    _accountController = TextEditingController(text: payoutProvider.accountNumber);
    _amountController = TextEditingController(text: payoutProvider.amount);
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PayoutProvider>(
      builder: (context, payoutProvider, child) {
        // Sync controllers with provider values
        if (_accountController.text != payoutProvider.accountNumber) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _accountController.text = payoutProvider.accountNumber;
            }
          });
        }
        if (_amountController.text != payoutProvider.amount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _amountController.text = payoutProvider.amount;
            }
          });
        }
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payout',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Error Message
                        if (payoutProvider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      payoutProvider.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Info Note
                                Consumer<WithdrawProvider>(
                                  builder: (context, withdrawProvider, child) {
                                    final fullBalance = withdrawProvider.userBalance;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Available balance: ${fullBalance.toStringAsFixed(2)}. Enter amount to withdraw (optional - leave empty to withdraw full balance).',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Amount Field (Optional)
                                const Text(
                                  'Amount (Optional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _amountController,
                                    onChanged: (value) {
                                      payoutProvider.setAmount(value);
                                    },
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter amount (leave empty for full balance)',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Select Payment Method Field (Dropdown)
                                const Text(
                                  'Select Payment Method',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: payoutProvider.isLoadingPaymentMethods
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Center(
                                            child: SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        )
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton<PaymentMethod>(
                                            value: payoutProvider.selectedPaymentMethod,
                                            hint: const Text(
                                              'select payment method',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            isExpanded: true,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            items: payoutProvider.paymentMethods.map((method) {
                                              return DropdownMenuItem<PaymentMethod>(
                                                value: method,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      method.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (method.description.isNotEmpty)
                                                      Text(
                                                        method.description,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (PaymentMethod? method) {
                                              if (method != null) {
                                                payoutProvider.setSelectedPaymentMethod(method);
                                              }
                                            },
                                          ),
                                        ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Account No. Field
                                const Text(
                                  'Account No.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _accountController,
                                    onChanged: (value) {
                                      payoutProvider.setAccountNumber(value);
                                    },
                                    keyboardType: TextInputType.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Account No.',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      
                        // Submit Button (Fixed at bottom)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: payoutProvider.isLoading
                                ? null
                                : () => payoutProvider.submitPayout(context),
                            child: Container(
                                 width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                     gradient: const LinearGradient(
                                colors: [Color(0xFF8C68FF),Color(0xFFFD5BFF), ],
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
                              child: Center(
                                child: payoutProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Submit Withdrawal Request',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      }
  
  }

