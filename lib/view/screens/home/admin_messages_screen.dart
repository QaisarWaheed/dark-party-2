// // admin_messages_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shaheen_star_app/controller/provider/user_message_provider.dart';
// import 'package:shaheen_star_app/model/admin_message_model.dart';

// class AdminMessagesScreen extends StatefulWidget {
//   const AdminMessagesScreen({super.key});

//   @override
//   State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
// }

// class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<UserMessageProvider>(context);
    
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           'Admin Messages',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: Colors.black),
//             onPressed: () {
//               provider.loadAdminMessages();
//             },
//           ),
//         ],
//       ),
//       body: _buildBody(provider),
//     );
//   }

//   Widget _buildBody(UserMessageProvider provider) {
//     if (provider.isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading admin messages...'),
//           ],
//         ),
//       );
//     }

//     if (provider.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, color: Colors.red, size: 64),
//             SizedBox(height: 16),
//             Text(
//               'Error loading messages',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             Text(
//               provider.error!,
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => provider.loadAdminMessages(),
//               child: Text('Try Again'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (provider.adminMessages.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
//             SizedBox(height: 16),
//             Text(
//               'No admin messages',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'You will see admin notifications here',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: provider.adminMessages.length,
//       itemBuilder: (context, index) {
//         return _buildAdminMessageCard(provider.adminMessages[index]);
//       },
//     );
//   }

//   Widget _buildAdminMessageCard(AdminMessage message) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Icon(Icons.notifications, color: Colors.orange),
//                 SizedBox(width: 8),
//                 Text(
//                   'Admin Notification',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange,
//                   ),
//                 ),
//                 Spacer(),
//                 Text(
//                   _formatDate(message.createdAt),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
            
//             // Title
//             Text(
//               message.title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             SizedBox(height: 8),
            
//             // Content
//             Text(
//               message.content,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 12),
            
//             // Footer
//             Row(
//               children: [
//                 Icon(Icons.flag, size: 16, color: Colors.grey),
//                 SizedBox(width: 4),
//                 Text(
//                   'Country: ${message.country}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 Spacer(),
//                 Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                 SizedBox(width: 4),
//                 Text(
//                   message.formattedDate,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
//     if (difference.inHours < 24) return '${difference.inHours}h ago';
//     if (difference.inDays < 7) return '${difference.inDays}d ago';
    
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }