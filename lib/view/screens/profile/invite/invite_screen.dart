// // Professional Invite Friends UI inspired by provided design
// // Pure Flutter widgets, gold/brown gradient, reusable components
// // You can split widgets into separate files later

// import 'package:flutter/material.dart';

// class InviteFriendsPage extends StatelessWidget {
//   const InviteFriendsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF1B120A), Color(0xFF3A2616), Color(0xFF1A0F08)],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 _HeaderSection(),
//                 SizedBox(height: 24),
//                 _InviteStatsCard(),
//                 SizedBox(height: 20),
//                 _InviteCodeCard(),
//                 SizedBox(height: 24),
//                 _TabBarSection(),
//                 SizedBox(height: 20),
//                 _ShareTaskCard(),
//                 SizedBox(height: 20),
//                 _InvitationTaskSection(),
//                 SizedBox(height: 30),
//                 _RechargeTaskSection(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================= HEADER =================
// class _HeaderSection extends StatelessWidget {
//   const _HeaderSection();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Text(
//           'Invite Friends',
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFFF6E4B3),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'New user registration, 24-hour binding is valid',
//           style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
//         ),
//       ],
//     );
//   }
// }

// // ================= STATS CARD =================
// class _InviteStatsCard extends StatelessWidget {
//   const _InviteStatsCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//       decoration: _goldCardDecoration(),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: const [
//           _StatItem(title: 'Today Invite', value: '0'),
//           _StatItem(title: 'Total Invite', value: '1'),
//         ],
//       ),
//     );
//   }
// }

// class _StatItem extends StatelessWidget {
//   final String title;
//   final String value;

//   const _StatItem({required this.title, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(title, style: const TextStyle(color: Color(0xFF7A5632))),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF7A5632),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ================= INVITE CODE =================
// class _InviteCodeCard extends StatelessWidget {
//   const _InviteCodeCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _darkCardDecoration(),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text('Invite Code', style: TextStyle(color: Color(0xFFD8B56A))),
//           Row(
//             children: const [
//               Text(
//                 'enq1uyhd',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Icon(Icons.copy, color: Color(0xFFD8B56A), size: 18),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ================= TABS =================
// class _TabBarSection extends StatelessWidget {
//   const _TabBarSection();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: const [
//         _TabButton(title: 'TASK', active: true),
//         SizedBox(width: 12),
//         _TabButton(title: 'LIST'),
//         SizedBox(width: 12),
//         _TabButton(title: 'LUCKY DRAW WHEEL'),
//       ],
//     );
//   }
// }

// class _TabButton extends StatelessWidget {
//   final String title;
//   final bool active;

//   const _TabButton({required this.title, this.active = false});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           gradient: active
//               ? const LinearGradient(
//                   colors: [Color(0xFFF2D58A), Color(0xFFC89A3C)],
//                 )
//               : null,
//           color: active ? null : Colors.transparent,
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(color: const Color(0xFF8A6235)),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           title,
//           style: TextStyle(
//             color: active ? Colors.black : Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }

// // ================= SHARE TASK =================
// class _ShareTaskCard extends StatelessWidget {
//   const _ShareTaskCard();

//   @override
//   Widget build(BuildContext context) {
//     return _sectionCard(
//       title: 'SHARE TASKS',
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             'Share 5 times a day',
//             style: TextStyle(color: Colors.white),
//           ),
//           _statusChip('Not reached'),
//         ],
//       ),
//     );
//   }
// }

// // ================= INVITATION TASK =================
// class _InvitationTaskSection extends StatelessWidget {
//   const _InvitationTaskSection();

//   @override
//   Widget build(BuildContext context) {
//     return _sectionCard(
//       title: 'INVITATION TASKS',
//       child: Column(
//         children: [
//           _taskRow(
//             'Invited users to complete registration (1 people)',
//             'receive',
//             active: true,
//           ),
//           const SizedBox(height: 12),
//           _taskRow(
//             'Invite users to complete first deposit (3 people)',
//             'Not reached',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ================= RECHARGE TASK =================
// class _RechargeTaskSection extends StatelessWidget {
//   const _RechargeTaskSection();

//   @override
//   Widget build(BuildContext context) {
//     return _sectionCard(
//       title: 'RECHARGE TASKS',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             'If a new user recharges within 15 days after registration, rewards can be claimed within 30 days.',
//             style: TextStyle(color: Colors.white70, fontSize: 13),
//           ),
//           SizedBox(height: 16),
//           _RechargeUserRow(),
//         ],
//       ),
//     );
//   }
// }

// class _RechargeUserRow extends StatelessWidget {
//   const _RechargeUserRow();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const CircleAvatar(radius: 20, backgroundColor: Color(0xFF8A6235)),
//         const SizedBox(width: 12),
//         const Expanded(
//           child: Text('ID: 9496406', style: TextStyle(color: Colors.white)),
//         ),
//         _statusChip('To be settled'),
//       ],
//     );
//   }
// }

// // ================= HELPERS =================
// Widget _taskRow(String text, String status, {bool active = false}) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Expanded(
//         child: Text(text, style: const TextStyle(color: Colors.white)),
//       ),
//       _statusChip(status, active: active),
//     ],
//   );
// }

// Widget _statusChip(String text, {bool active = false}) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     decoration: BoxDecoration(
//       color: active ? const Color(0xFFF2D58A) : Colors.white,
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Text(
//       text,
//       style: TextStyle(color: active ? Colors.black : Colors.black87),
//     ),
//   );
// }

// Widget _sectionCard({required String title, required Widget child}) {
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: _darkCardDecoration(),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             color: Color(0xFFD8B56A),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         child,
//       ],
//     ),
//   );
// }

// BoxDecoration _goldCardDecoration() {
//   return BoxDecoration(
//     borderRadius: BorderRadius.circular(20),
//     gradient: const LinearGradient(
//       colors: [Color(0xFFFFE8B0), Color(0xFFE2B45A)],
//     ),
//   );
// }

// BoxDecoration _darkCardDecoration() {
//   return BoxDecoration(
//     borderRadius: BorderRadius.circular(20),
//     gradient: const LinearGradient(
//       colors: [Color(0xFF3B2615), Color(0xFF1E120A)],
//     ),
//     border: Border.all(color: const Color(0xFF8A6235)),
//   );
// }
