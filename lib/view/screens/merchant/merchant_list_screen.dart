import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/merchant_list_provider.dart';
import 'package:shaheen_star_app/model/merchant_model.dart';
import 'package:shaheen_star_app/view/screens/merchant/confirm_transfer_screen.dart';
// removed unused imports: ApiManager, WithdrawProvider, SharedPreferences

class MerchantListScreen extends StatefulWidget {
  final String amount; // amount string like '300'
  final String? initialSearch;
  const MerchantListScreen({super.key, required this.amount, this.initialSearch});

  @override
  State<MerchantListScreen> createState() => _MerchantListScreenState();
}

class _MerchantListScreenState extends State<MerchantListScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MerchantListProvider>(context, listen: false);
      provider.fetchMerchants();
      if ((widget.initialSearch ?? '').isNotEmpty) {
        provider.searchMerchants(widget.initialSearch!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Seller list', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<MerchantListProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final merchants = provider.merchants;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search ID'),
                      onChanged: (v) => provider.searchMerchants(v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: merchants.isEmpty
                        ? Center(child: Text('No merchants found', style: TextStyle(color: Colors.grey[600])))
                        : ListView.builder(
                            itemCount: merchants.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final m = merchants[index];
                              final selected = _selectedIndex == index;
                              return _merchantCard(m, index, selected);
                            },
                          ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedIndex == null ? Colors.green.shade100 : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _selectedIndex == null ? null : () async {
                        final merchant = provider.merchants[_selectedIndex!];
                        // Open confirmation screen first. The confirmation screen will perform the API call.
                        final confirmed = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmTransferScreen(merchant: merchant, amount: widget.amount),
                          ),
                        );

                        if (confirmed == true) {
                          // after successful transfer, pop this list to return to previous screen
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Confirm', style: TextStyle(color: _selectedIndex == null ? Colors.green.shade700 : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _merchantCard(MerchantModel m, int index, bool selected) {
    String? profileImageUrl;
    if (m.profileUrl != null && m.profileUrl!.isNotEmpty) {
      if (m.profileUrl!.startsWith('http://') || m.profileUrl!.startsWith('https://')) {
        profileImageUrl = m.profileUrl;
      } else {
        profileImageUrl = 'https://shaheenstar.online/${m.profileUrl}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? Colors.green.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
            child: profileImageUrl == null ? Icon(Icons.person, color: Colors.grey[600]) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('ID: ${m.uniqueUserId ?? m.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? Colors.green : Colors.grey.shade400),
                color: selected ? Colors.green : Colors.white,
              ),
              child: selected ? Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
        ],
      ),
    );
  }
}
