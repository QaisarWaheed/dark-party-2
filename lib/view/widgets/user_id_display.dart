import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays user ID. When [isIdChanged] is true, uses newid.svg design.
class UserIdDisplay extends StatelessWidget {
  final String userId;
  final bool isIdChanged;

  const UserIdDisplay({
    super.key,
    required this.userId,
    this.isIdChanged = false,
  });

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isIdChanged) {
      return GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: SizedBox(
          height: 36,
          width: 120, // Set a fixed width for better background visibility
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/newid.png',
                fit: BoxFit.cover, // Cover the entire box
                height: 36,
                width: 120,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ), // Less padding
                child: Text(
                  userId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ID: $userId',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _copyToClipboard(context),
          child: const Icon(Icons.copy_outlined, size: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
