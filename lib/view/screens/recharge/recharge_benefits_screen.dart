import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

class RechargeBenefitsScreen extends StatelessWidget {
  const RechargeBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Stack(
                    children: [
                      AppImage.asset(
                        'assets/images/recharge_screen_bg.png',
                        width: screenWidth,
                        fit: BoxFit.contain,
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            return Stack(
                              children: [
                                Positioned(
                                  left: w * 0.23,
                                  top: 760,
                                  child: _OverlayButton(
                                    text: 'Week',
                                    width: w * 0.22,
                                    height: h * 0.01,
                                  ),
                                ),
                                Positioned(
                                  left: w * 0.55,
                                  top: 760,
                                  child: _OverlayButton(
                                    text: 'Month',
                                    width: w * 0.22,
                                    height: h * 0.01,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Text(
            'Recharge Benefits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;

  const _OverlayButton({
    required this.text,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
