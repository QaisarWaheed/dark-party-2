import 'package:flutter/material.dart';
import 'package:shaheen_star_app/view/screens/store/store_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  // internal merchant data removed since this screen now redirects to Store

  // This screen now forwards to `StoreScreen` and no longer needs merchant data loading.

  @override
  Widget build(BuildContext context) {
    return StoreScreen();
  }
}
