// =========================
// INVITE FRIENDS UI (SCREEN 1)
// Pixel-perfect inspired by provided screenshots
// Fully widget-based, reusable components
// Light functionality included (copy, tab switch)
// =========================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ========================= SCREEN 1 =========================
class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  int selectedTab = 0; // 0 Task | 1 List | 2 Lucky Draw

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _GoldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const InviteHeader(),
                const SizedBox(height: 24),
                const InviteStatsCard(),
                const SizedBox(height: 20),
                const InviteCodeCard(),
                const SizedBox(height: 24),
                InviteTabs(
                  currentIndex: selectedTab,
                  onChanged: (i) => setState(() => selectedTab = i),
                ),
                const SizedBox(height: 24),
                if (selectedTab == 0) const TaskTabView(),
                if (selectedTab == 1) const ListTabView(),
                if (selectedTab == 2) const LuckyDrawTabView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= SCREEN 2 =========================
class InvitationRecordScreen extends StatelessWidget {
  const InvitationRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A05),
      body: _GoldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                RecordHeader(),
                SizedBox(height: 24),
                InvitationRecordCard(),
                SizedBox(height: 20),
                RechargeRecordCard(),

                SizedBox(height: 12),
                InvitationRecordCard1(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= COMMON BACKGROUND =========================
class _GoldBackground extends StatelessWidget {
  final Widget child;
  const _GoldBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B120A), Color(0xFF3A2616), Color(0xFF120A05)],
        ),
      ),
      child: child,
    );
  }
}

// ========================= HEADERS =========================
class InviteHeader extends StatelessWidget {
  const InviteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisSize:
              MainAxisSize.min, // Text ke hisaab se height adjust kare
          children: [
            Text('Invite Friends', style: _titleStyle),
            SizedBox(height: 6),
            // Light divider line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: double.infinity, // jitna chhota ya lamba line chahiye
                height: 1, // line ki thickness
                color: Colors.grey.shade300, // light color
                margin: EdgeInsets.symmetric(vertical: 6), // upar neeche space
              ),
            ),
            Text(
              'New user registration, 24-hour binding is valid',
              style: _subTitleStyle,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: double.infinity, // jitna chhota ya lamba line chahiye
                height: 1, // line ki thickness
                color: Colors.grey.shade300, // light color
                margin: EdgeInsets.symmetric(vertical: 6), // upar neeche space
              ),
            ),
          ],
        ),

        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('', style: _titleStyle),
            Column(
              children: [
                _HeaderBtn(
                  title: 'Invitation Record',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvitationRecordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _HeaderBtn(
                  title: 'My inviter',
                  onTap: () {
                    // Future screen
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _HeaderBtn({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: _goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class RecordHeader extends StatelessWidget {
  const RecordHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Invitation Record', style: _titleStyle);
  }
}

// ========================= STATS =========================
class InviteStatsCard extends StatelessWidget {
  const InviteStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: _goldCard(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(title: 'Today Invite', value: '0'),
          _StatItem(title: 'Total Invite', value: '1'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title, value;
  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: _brownText),
        const SizedBox(height: 6),
        Text(value, style: _bigNumber),
      ],
    );
  }
}

// ========================= INVITE CODE =========================
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _darkCard(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Invite Code', style: _goldText),
          InkWell(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'enq1uyhd'));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Code Copied')));
            },
            child: Row(
              children: const [
                Text('enq1uyhd', style: _inviteCode),
                SizedBox(width: 8),
                Icon(Icons.copy, size: 18, color: Color(0xFFD8B56A)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= TABS =========================
class InviteTabs extends StatelessWidget {
  final int currentIndex;
  final Function(int) onChanged;

  const InviteTabs({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabBtn('TASK', 0),
        _TabBtn('LIST', 1),
        _TabBtn('LUCKY DRAW', 2),
      ],
    );
  }

  Widget _TabBtn(String text, int index) {
    final active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? _goldGradient : null,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF8A6235)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ========================= TAB VIEWS =========================
class TaskTabView extends StatelessWidget {
  const TaskTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SectionCard(title: 'SHARE TASKS', child: ShareTaskRow()),
        SizedBox(height: 16),
        SectionCard(title: 'INVITATION TASKS', child: InvitationTasks()),
        SizedBox(height: 16),
        SectionCard(title: 'RECHARGE TASKS', child: RechargeTask()),
      ],
    );
  }
}

class ListTabView extends StatelessWidget {
  const ListTabView({super.key});
  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'INVITE LIST',
      child: Text('Invite list data will appear here', style: _whiteText),
    );
  }
}

class LuckyDrawTabView extends StatelessWidget {
  const LuckyDrawTabView({super.key});
  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'LUCKY DRAW WHEEL',
      child: Text('Lucky draw UI here', style: _whiteText),
    );
  }
}

// ========================= TASK ITEMS =========================
class ShareTaskRow extends StatelessWidget {
  const ShareTaskRow({super.key});

  @override
  Widget build(BuildContext context) {
    return _taskRow('Share 5 times a day', 'Not reached');
  }
}

class InvitationTasks extends StatelessWidget {
  const InvitationTasks({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _taskRow('Invited users to register (1)', 'Receive', active: true),
        const SizedBox(height: 12),
        _taskRow('Invite users first deposit (3)', 'Not reached'),
      ],
    );
  }
}

class RechargeTask extends StatelessWidget {
  const RechargeTask({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Recharge within 15 days to get rewards. Claim within 30 days.',
      style: _whiteDim,
    );
  }
}

// ========================= RECORD CARDS =========================
class InvitationRecordCard extends StatelessWidget {
  const InvitationRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(title: 'INVITED USERS', child: RecordRow());
  }
}

class InvitationRecordCard1 extends StatelessWidget {
  const InvitationRecordCard1({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard1(title: 'INVITED USERS', child: RecordRow());
  }
}

class RechargeRecordCard extends StatelessWidget {
  const RechargeRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(title: 'RECHARGE RECORD', child: RecordRow());
  }
}

class RecordRow extends StatelessWidget {
  const RecordRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: Color(0xFF8A6235)),
        const SizedBox(width: 12),
        const Expanded(child: Text('ID: 9496406', style: _whiteText)),
        _statusChip('To be settled'),
      ],
    );
  }
}

// ========================= SHARED UI =========================
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _darkCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _goldText),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SectionCard1 extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard1({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(title, style: _goldText1),
            Text('15 days recharge', style: _goldText1),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 8,
            top: 8,
          ),
          decoration: _darkCard1(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 1), child],
          ),
        ),
      ],
    );
  }
}

Widget _taskRow(String text, String status, {bool active = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(text, style: _whiteText)),
      _statusChip(status, active: active),
    ],
  );
}

Widget _statusChip(String text, {bool active = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFF2D58A) : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: active ? Colors.black : Colors.black87),
    ),
  );
}

// ========================= STYLES =========================
const _titleStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Color(0xFFF6E4B3),
);
const _subTitleStyle = TextStyle(color: Colors.white70, fontSize: 12);
const _goldText = TextStyle(
  color: Color(0xFFD8B56A),
  fontWeight: FontWeight.bold,
);
const _goldText1 = TextStyle(
  color: Colors.white70,
  fontWeight: FontWeight.normal,

  fontSize: 10,
);
const _brownText = TextStyle(color: Color(0xFF7A5632));
const _whiteText = TextStyle(color: Colors.white);
const _whiteDim = TextStyle(color: Colors.white70, fontSize: 13);
const _inviteCode = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);
const _bigNumber = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: Color(0xFF7A5632),
);

final _goldGradient = const LinearGradient(
  colors: [Color(0xFFF2D58A), Color(0xFFC89A3C)],
);

BoxDecoration _goldCard() => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: _goldGradient,
);
BoxDecoration _darkCard() => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: const LinearGradient(
    colors: [Color(0xFF3B2615), Color(0xFF1E120A)],
  ),
  border: Border.all(color: const Color(0xFF8A6235)),
);
BoxDecoration _darkCard1() => BoxDecoration(
  borderRadius: BorderRadius.circular(5),
  color: Color(0xFF3B2615),
  // gradient: const LinearGradient(
  //   colors: [Color(0xFF3B2615), Color(0xFF1E120A)],
  // ),
  // border: Border.all(color: const Color(0xFF8A6235)),
);
