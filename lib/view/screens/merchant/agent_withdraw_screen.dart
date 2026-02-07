import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';
import 'package:shaheen_star_app/view/screens/merchant/merchant_list_screen.dart';
// removed unused imports

class AgentWithdrawScreen extends StatefulWidget {
  const AgentWithdrawScreen({super.key});

  @override
  State<AgentWithdrawScreen> createState() => _AgentWithdrawScreenState();
}

class _AgentWithdrawScreenState extends State<AgentWithdrawScreen> {
  String selectedTab = 'Agent Withdraw';
  String searchText = '';
  int? selectedIndex;

  // Updated stalls: `coins` = diamond count (integer string), `price` = USD string
  final List<Map<String, String>> stalls = [
    {'coins': '200000', 'price': '8.57'},
    {'coins': '400000', 'price': '17.14'},
    {'coins': '600000', 'price': '25.71'},
    {'coins': '800000', 'price': '34.28'},
    {'coins': '1000000', 'price': '42.85'},
    {'coins': '1400000', 'price': '59.99'},
    {'coins': '2000000', 'price': '85.70'},
    {'coins': '4000000', 'price': '171.40'},
    {'coins': '6000000', 'price': '257.10'},
  ];

  @override
  Widget build(BuildContext context) {
    final withdrawProvider = Provider.of<WithdrawProvider>(context);
    final balance = withdrawProvider.userBalance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
                // top purple card
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
                            _formatBalance(balance),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _tabButton('Agent Withdraw'),
                      _tabButton('Agent Coin Exchange'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Search
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search ID',
                          ),
                          onChanged: (v) => setState(() => searchText = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text('Exchange stalls', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: stalls.length,
                  itemBuilder: (context, index) {
                    final item = stalls[index];
                    final selected = selectedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: selected
                              ? [BoxShadow(color: Colors.green.withOpacity(0.06), blurRadius: 6)]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Price on top
                            Text('\$${item['price']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            // Diamonds count (short format)
                            Text(_formatCoinsDisplay(item['coins']!), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 6),
                            const Icon(Icons.diamond, size: 14, color: Colors.purple),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  onTap: selectedIndex == null
                      ? null
                      : () {
                          // Instead of calling the transfer API here, open the full merchant list
                          // so user can select the merchant from the list (merchant tab index = 2)
                          // Navigate to the dedicated merchant list screen and pass selected amount
                          final item = stalls[selectedIndex!];
                          final amountCoins = item['coins'] ?? '0'; // e.g. '200000'

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MerchantListScreen(amount: amountCoins),
                            ),
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selectedIndex == null ? Colors.green.shade100 : Colors.green.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        'Confirm Transfer',
                        style: TextStyle(
                          color: selectedIndex == null ? Colors.green.shade700 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _tabButton(String label) {
    final selected = selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.grey)),
          ),
        ),
      ),
    );
  }

  static String _formatBalance(double value) {
    if (value >= 1000) {
      final v = value / 1000.0;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)}K';
    }
    return value.toInt().toString();
  }

  static String _formatCoinsDisplay(String coinsStr) {
    // Show compact display like 200k, 1M, 1.4M etc.
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
}
