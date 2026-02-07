import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

class DiamondExchangeScreen extends StatefulWidget {
  const DiamondExchangeScreen({super.key});

  @override
  State<DiamondExchangeScreen> createState() => _DiamondExchangeScreenState();
}

class _DiamondExchangeScreenState extends State<DiamondExchangeScreen> {
  int? _selectedIndex;
  String _customAmount = '';

  final List<Map<String, String>> _stalls = [
    {'coins': '30', 'price': '60'},
    {'coins': '100000', 'price': '50000'},
    {'coins': '200000', 'price': '100000'},
    {'coins': '500000', 'price': '250000'},
    {'coins': '1000000', 'price': '500000'},
  
  ];

  static String _formatCoinsCompact(String coinsStr) {
    final v = double.tryParse(coinsStr) ?? 0.0;
    if (v >= 1000000) {
      final m = v / 1000000.0;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      final k = v / 1000.0;
      return k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final balance = Provider.of<WithdrawProvider>(context).userBalance;

    // local loading state handled via setState in this widget

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Diamod Exchange', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Purple gradient balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB89BFF), Color(0xFFED9AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diamonds available', style: TextStyle(color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Detail', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.diamond, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _formatDisplayBalance(balance),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Exchange stalls', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _stalls.length,
                  itemBuilder: (context, index) {
                    final item = _stalls[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${_formatCoinsCompact(item['price']!)} coins', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('${_formatCoinsCompact(item['coins']!)} coins', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 6),
                            const Icon(Icons.diamond, size: 14, color: Colors.purple),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                // Input field (Frame in design)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Amount of diamonds you entered, you want to exchange'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _customAmount = v),
                  ),
                ),

                const SizedBox(height: 8),
                Text('Based on the diamonds you entered, you will receive 0 coins', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),

                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(child: Text('op-up agent you want to redeem and click the confirm Redemption')),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _selectedIndex == null && _customAmount.isEmpty ? null : () async {
                    // Prepare values
                    final selectedIndex = _selectedIndex;
                    final baseCoins = selectedIndex != null ? (_stalls[selectedIndex]['coins'] ?? '0') : '0';
                    final basePrice = selectedIndex != null ? (_stalls[selectedIndex]['price'] ?? '0') : '1';
                    final diamondsInput = _customAmount.isNotEmpty ? _customAmount : basePrice;

                    double parseValue(String s) {
                      final str = s.trim().toLowerCase();
                      if (str.endsWith('m')) {
                        final num = double.tryParse(str.substring(0, str.length - 1)) ?? 0.0;
                        return num * 1000000.0;
                      }
                      if (str.endsWith('k')) {
                        final num = double.tryParse(str.substring(0, str.length - 1)) ?? 0.0;
                        return num * 1000.0;
                      }
                      return double.tryParse(str.replaceAll(',', '')) ?? 0.0;
                    }

                    final parsedDiamonds = parseValue(diamondsInput);
                    final parsedBasePrice = parseValue(basePrice);
                    final parsedBaseCoins = parseValue(baseCoins);

                    final estimatedCoins = parsedBasePrice > 0 ? (parsedDiamonds / parsedBasePrice) * parsedBaseCoins : 0.0;

                    final diamondsDisplay = diamondsInput;
                    final coinsDisplay = estimatedCoins >= 1 ? estimatedCoins.toStringAsFixed(0) : '0';

                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: true,
                      builder: (ctx) {
                        return Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You will use $diamondsDisplay diamonds to exchange for $coinsDisplay coins', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade100,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: Text('Close', style: TextStyle(color: Colors.black54)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: Text('Yes', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (confirmed != true) return;

                    // proceed with API call
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      String userId = '';
                      try {
                        final intId = prefs.getInt('user_id');
                        if (intId != null) {
                          userId = intId.toString();
                        } else {
                          userId = prefs.getString('user_id') ?? '';
                        }
                      } catch (_) {
                        userId = prefs.get('user_id')?.toString() ?? '';
                      }

                      if (userId.isEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID not found')));
                        return;
                      }

                      final resp = await ApiManager.exchangeDiamondToGold(userId: userId, diamondCoins: diamondsInput);
                      Navigator.pop(context); // remove loader
                      if (resp != null && resp.isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Exchange successful')));
                        final withdrawProvider = Provider.of<WithdrawProvider>(context, listen: false);
                        withdrawProvider.loadUserBalance();
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp?.message ?? 'Exchange failed')));
                      }
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred')));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: (_selectedIndex == null && _customAmount.isEmpty) ? Colors.green.shade100 : Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text('Confirm exchange', style: TextStyle(color: (_selectedIndex == null && _customAmount.isEmpty) ? Colors.green.shade700 : Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDisplayBalance(double value) {
    if (value >= 1000) {
      final v = value / 1000.0;
      return v < 10 ? '${v.toStringAsFixed(1)}K' : '${v.toInt()}K';
    }
    return value.toInt().toString();
  }
}
