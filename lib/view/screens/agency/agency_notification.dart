import 'package:flutter/material.dart';


class AgencyNotification extends StatefulWidget {
  const AgencyNotification({super.key});

  @override
  State<AgencyNotification> createState() => _AgencyNotificationState();
}

class _AgencyNotificationState extends State<AgencyNotification> {
  final List<NotificationItem> notifications = [
    NotificationItem(
      time: '20:08',
      title: 'Host certification has been passed',
      message: 'Congratulations on becoming a host. Please enjoy the happiness of Boli',
    ),
    NotificationItem(
      time: '20:15',
      title: 'Application processing notice',
      message:
          'The guild president2360677(Gabru Jutt) has agreed to the application you initiated to join the guild. If you have any questions, please contact the official customer service',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 230, 230),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 243, 241, 241),
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, size: 20, color: Colors.black54),
            ),
          ],
        ),
        leadingWidth: 100,
        title: const Text(
          'Agency',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_horiz, size: 24, color: Colors.black54),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Time stamp
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.time,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 20, 20, 20).withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Notification content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String time;
  final String title;
  final String message;

  NotificationItem({
    required this.time,
    required this.title,
    required this.message,
  });
}