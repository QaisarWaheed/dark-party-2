


// import 'package:flutter/material.dart';

// // import 'package:shaheen_star_app/view/screens/voice_calling/audio_live_room.dart';

// class VoiceOptionsBottomSheet extends StatefulWidget {
//   final String roomId;
//   final String roomName;

//   const VoiceOptionsBottomSheet({
//     Key? key,
//     required this.roomId,
//     required this.roomName,
//   }) : super(key: key);

//   @override
//   State<VoiceOptionsBottomSheet> createState() => _VoiceOptionsBottomSheetState();
// }

// class _VoiceOptionsBottomSheetState extends State<VoiceOptionsBottomSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Voice Options',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.close, color: Colors.white),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // ✅ JOIN AUDIO LIVE ROOM BUTTON
//           Container(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: () => _joinAudioLiveRoom(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.record_voice_over,
//                     color: Colors.white,
//                   ),
//                   SizedBox(width: 10),
//                   Text(
//                     'Join Audio Live Room',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 15),

//           // Room Info
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[800],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.info, color: Colors.white70, size: 16),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Room: ${widget.roomName}',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         'ID: ${widget.roomId}',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ JOIN AUDIO LIVE ROOM FUNCTION
  