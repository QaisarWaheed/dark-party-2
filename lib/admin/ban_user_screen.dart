import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/admin/admin_provider.dart';

class BanUserScreen extends StatelessWidget {
  const BanUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BanUserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Ban User")),
      body: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.read<BanUserProvider>().banUser(
                        adminUserId: 101, // 0 = super admin
                        targetUserId: 205,
                        roomId: 68,
                        banDuration: "3days",
                      );
                    },
                    child: const Text("Ban User"),
                  ),

                  if (provider.banResponse != null)
                    Text(
                      provider.banResponse!.message,
                      style: const TextStyle(color: Colors.green),
                    ),

                  if (provider.errorMessage != null)
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
      ),
    );
  }
}
