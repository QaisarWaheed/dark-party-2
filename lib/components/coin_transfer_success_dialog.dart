import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:intl/intl.dart';

/// Success dialog shown after successful coin transfer
class CoinTransferSuccessDialog extends StatelessWidget {
  final String amount;
  final DateTime? transactionTime;


  const CoinTransferSuccessDialog({
    super.key,
    required this.amount,
    this.transactionTime,
  });

  @override
  Widget build(BuildContext context) {
    // Format transaction time or use current time
    final time = transactionTime ?? DateTime.now();
    final formattedTime = DateFormat('h:mm a').format(time);
    
    // Format amount (remove decimals if whole number)
    final amountValue = double.tryParse(amount) ?? 0.0;
    final formattedAmount = amountValue == amountValue.toInt()
        ? amountValue.toInt().toString()
        : amountValue.toStringAsFixed(2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'COIN TRANSFER SUCCESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            
            // Success Icon (Green Circle with Checkmark)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            
            // Transaction Complete Message
            const Text(
              'TRANSACTION COMPLETE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 32),
            
            // Amount with Gold Coin Image
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatNumber(formattedAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                AppImage.asset(
                  'assets/images/coinsicon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Transaction Time
            Text(
              formattedTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            
            // OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format number with commas for thousands
  String _formatNumber(String numberStr) {
    try {
      final number = double.parse(numberStr);
      if (number == number.toInt()) {
        // Whole number - format with commas
        return number.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      } else {
        // Decimal number - format with commas and keep decimals
        final parts = numberStr.split('.');
        final intPart = int.parse(parts[0]);
        final formattedInt = intPart.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        return '$formattedInt.${parts[1]}';
      }
    } catch (e) {
      return numberStr;
    }
  }
}

