// // Dart imports:
// import 'dart:math';

// // Flutter imports:
// import 'package:flutter/material.dart';
// import 'package:shaheen_star_app/view/screens/game/live_page.dart';

// class HomePage extends StatelessWidget {
//   HomePage({super.key});

//   /// Users who use the same liveID can join the same live streaming.
//   final liveTextCtrl = TextEditingController(
//     text: Random().nextInt(10000).toString(),
//   );

//   @override
//   Widget build(BuildContext context) {
//     final buttonStyle = ElevatedButton.styleFrom(
//       fixedSize: const Size(150, 60),
//       backgroundColor: Color.fromARGB(255, 17, 122, 111).withOpacity(0.6),
//     );

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'SUD MiniGame Demo1',
//               style: TextStyle(color: Colors.black, fontSize: 25),
//             ),
//             const SizedBox(height: 100),
//             // Text('User ID:$localUserID'),
//             const Text('Please test with two or more devices'),
//             TextFormField(
//               controller: liveTextCtrl,
//               decoration: const InputDecoration(labelText: 'join a live by id'),
//             ),
//             const SizedBox(height: 20),
//             const SizedBox(height: 20),
//             // click me to navigate to LivePage
//             ElevatedButton(
//               style: buttonStyle,
//               child: const Text(
//                 'Enter Room',
//                 style: TextStyle(color: Colors.white),
//                 textAlign: TextAlign.center,
//               ),
//               onPressed: () => jumpToLivePage(
//                 context,
//                 liveID: liveTextCtrl.text,
//                 isHost: false,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void jumpToLivePage(
//     BuildContext context, {
//     required String liveID,
//     required bool isHost,
//   }) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => LivePage(liveID: liveID, isHost: isHost),
//       ),
//     );
//   }
// }
