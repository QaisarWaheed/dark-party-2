import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/merchant_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';

class ConfirmTransferScreen extends StatefulWidget {
  final MerchantModel merchant;
  final String amount; // amount that agent will receive (as string number)

  const ConfirmTransferScreen({super.key, required this.merchant, required this.amount});

  @override
  State<ConfirmTransferScreen> createState() => _ConfirmTransferScreenState();
}

class _ConfirmTransferScreenState extends State<ConfirmTransferScreen> {
  String selectedPayout = 'Easypaisa';
  bool _loading = false;

  double _toDouble(String v) {
    return double.tryParse(v.replaceAll(',', '').trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final received = _toDouble(widget.amount);
    final fee = (received * 0.03);
    final actual = (received + fee);

    // resolve merchant profile image (handle relative paths)
    String? profileImageUrl;
    if (widget.merchant.profileUrl != null && widget.merchant.profileUrl!.isNotEmpty) {
      if (widget.merchant.profileUrl!.startsWith('http://') || widget.merchant.profileUrl!.startsWith('https://')) {
        profileImageUrl = widget.merchant.profileUrl;
      } else {
        profileImageUrl = 'https://shaheenstar.online/${widget.merchant.profileUrl}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Confirm Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('You will use ${_formatNumber(actual)} diamonds to transfer to the top-up agent. The top-up agent information and transfer information you selected are as follows', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 16),

                  // Merchant info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                        child: profileImageUrl == null ? Icon(Icons.person, color: Colors.grey[600]) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.merchant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('ID: ${widget.merchant.uniqueUserId ?? widget.merchant.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _infoRow('Actual transfer Diamonds', _formatNumber(actual)),
                  _infoRow('Processing Fee', '${_formatNumber(fee)} (${(fee/actual*100).toStringAsFixed(1)}%)'),
                  _infoRow('Agent Received Diamonds', _formatNumber(received)),

                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: Text('Please select your Payout method:', style: TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  Row(children: [
                    _payoutOption('Easypaisa'),
                    const SizedBox(width: 8),
                    _payoutOption('Bank'),
                  ]),

                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context, false),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _loading ? null : () async {
                          await _confirmTransfer(actual);
                        },
                        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ])
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _payoutOption(String label) {
    final selected = selectedPayout == label;
    return GestureDetector(
      onTap: () => setState(() => selectedPayout = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: selected ? Colors.green.shade50 : Colors.grey.shade100),
        child: Row(children: [if (selected) Icon(Icons.check_circle, color: Colors.green, size: 18) else Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18), const SizedBox(width: 8), Text(label)]),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }

  String _formatNumber(double v) {
    if (v >= 1000) return v.toStringAsFixed(0).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
  }

  Future<void> _confirmTransfer(double actualTransfer) async {
    setState(() => _loading = true);
    try {
      final withdrawProvider = Provider.of<WithdrawProvider>(context, listen: false);
      final availableDiamonds = withdrawProvider.userBalance;
      if (actualTransfer > availableDiamonds) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You do not have enough diamonds. Your balance is insufficient for this transfer.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String senderId = '';
      try {
        final intId = prefs.getInt('user_id');
        if (intId != null) {
          senderId = intId.toString();
        } else {
          senderId = prefs.getString('user_id') ?? '';
        }
      } catch (_) {
        senderId = prefs.get('user_id')?.toString() ?? '';
      }

      if (senderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID not found')));
        setState(() => _loading = false);
        return;
      }

      // API: https://shaheenstar.online/transfer_diamond_to_merchant.php (POST, form-data: sender_id, merchant_id, diamond_coins)
      final merchantId = widget.merchant.uniqueUserId?.trim().isNotEmpty == true
          ? widget.merchant.uniqueUserId!
          : widget.merchant.id;
      final resp = await ApiManager.transferDiamondToMerchant(
        userId: senderId,
        merchantId: merchantId,
        amount: actualTransfer.toInt().toString(),
      );

      setState(() => _loading = false);

      if (resp != null && resp.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Transfer successful')));
        final wp = Provider.of<WithdrawProvider>(context, listen: false);
        wp.loadUserBalance();
        Navigator.pop(context, true);
      } else {
        final msg = resp?.message ?? 'Transfer failed';
        final lower = msg.toLowerCase();
        final isInsufficient = lower.contains('insufficient') ||
            lower.contains('not enough') ||
            (lower.contains('balance') && lower.contains('low'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInsufficient ? 'You do not have enough diamonds. Your balance is insufficient for this transfer.' : msg),
            backgroundColor: isInsufficient ? Colors.red : null,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred')));
    }
  }
}
