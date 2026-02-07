import 'package:flutter/material.dart';

void showContributionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xff1c0c26),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ContributionBottomSheet(),
  );
}

class ContributionBottomSheet extends StatefulWidget {
  const ContributionBottomSheet({super.key});

  @override
  State<ContributionBottomSheet> createState() =>
      _ContributionBottomSheetState();
}

class _ContributionBottomSheetState extends State<ContributionBottomSheet> {
  int selectedTab = 1; // 0 Daily | 1 Monthly | 2 Yearly

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // ── Heading ──
          const Text(
            "Contribution",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // ── Tabs ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton("Daily", 0),
              _tabButton("Monthly", 1),
              _tabButton("Yearly", 2),
            ],
          ),

          const SizedBox(height: 20),

          // ── List ──
          ListView.builder(
            shrinkWrap: true,
            itemCount: 6,
            itemBuilder: (context, index) {
              return _contributionTile(
                rank: index + 1,
                name: "User ${index + 1}",
                coins: "${(index + 1) * 250}K",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _contributionTile({
    required int rank,
    required String name,
    required String coins,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff2a143d),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Rank
          Text(
            "$rank",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          const CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150",
            ),
          ),
          const SizedBox(width: 12),

          // Name + Flag
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Text("🇵🇰", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),

          // Coins
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                coins,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
