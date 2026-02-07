import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/view/screens/agency/agency_profile_center_screen.dart';

class AgencyDashboardScreen extends StatelessWidget {
  const AgencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<AgencyProvider>(
            builder: (context, agencyProvider, _) {
              final membersCount = agencyProvider.agencyMembers.length;
              

              // Build Agency Center style UI
              final userAgency = agencyProvider.userAgency;
              final agencyName = userAgency != null
                  ? (userAgency['agency_name'] ?? userAgency['name'] ?? 'Agency').toString()
                  : 'Your Agency';
              final agencyCode = userAgency != null
                  ? (userAgency['agency_code'] ?? userAgency['id'] ?? '').toString()
                  : '';

              // Stats from provider (safe fallbacks)
              final stats = agencyProvider.stats ?? {};
              String totalSalary = stats['total_salary']?.toString() ?? '0';
              String totalGift = stats['total_gift_gold_coins']?.toString() ?? stats['gift_gold_coins']?.toString() ?? '0';

              final broadcasting = stats['broadcasting_hosts']?.toString() ?? '0';
              final addHosts = stats['add_hosts']?.toString() ?? '0';
              final inactiveHosts = stats['inactive_hosts']?.toString() ?? (membersCount - int.tryParse(broadcasting)!.abs()).toString();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purple Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8C68FF), Color(0xFFFD5BFF)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white24,
                              child: const Icon(Icons.apartment, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agencyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 6),
                                  Text(agencyCode.isNotEmpty ? agencyCode : '', style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // navigate to agency center details
                                if (userAgency != null) {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgencyProfileCenterScreen(agency: userAgency)));
                                }
                              },
                              icon: const Icon(Icons.settings, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("This month's data", style: TextStyle(color: Colors.white70)),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View Details', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),

                        const SizedBox(height: 8),
                        // inner stats box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _innerStatRow('Total salary', totalSalary, Icons.monetization_on),
                              const SizedBox(height: 8),
                              _innerStatRow('Total gift gold coins received', totalGift, Icons.card_giftcard),
                              const SizedBox(height: 6),
                              Align(alignment: Alignment.centerRight, child: Text('Compare last month: 100%', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recruitment plan button (big purple)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C68FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('Agency Recruitment Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),

                  const SizedBox(height: 16),

                  // Host management card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Host management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Row(children: [const Icon(Icons.people_outline, size: 16), const SizedBox(width: 6), Text(membersCount.toString())]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _hostStatColumn('Currently broadcasting', broadcasting),
                            _hostStatColumn('Add Hosts', addHosts),
                            _hostStatColumn('Inactive Hosts', inactiveHosts),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action tiles row (simplified)
                  Row(
                    children: [
                      Expanded(child: _actionTile(Icons.person_add, 'Host Application')),
                      const SizedBox(width: 12),
                      Expanded(child: _actionTile(Icons.mail_outline, 'Initiate invitation')),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: agencyProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : agencyProvider.agencyMembers.isEmpty
                            ? const Center(child: Text('No members yet'))
                            : ListView.builder(
                                itemCount: agencyProvider.agencyMembers.length,
                                itemBuilder: (context, index) {
                                  final member = agencyProvider.agencyMembers[index];
                                  final name = member['name']?.toString() ?? member['username']?.toString() ?? 'Member';
                                  final id = member['id']?.toString() ?? member['user_id']?.toString() ?? '';
                                  return ListTile(
                                    leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M')),
                                    title: Text(name),
                                    subtitle: Text('ID: $id'),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  

  Widget _innerStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _hostStatColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
