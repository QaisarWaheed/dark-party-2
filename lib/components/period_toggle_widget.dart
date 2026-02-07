import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/period_toggle_provider.dart';

class PeriodToggleWidget extends StatelessWidget {
  final Function(PeriodType)? onPeriodChanged;
  
  const PeriodToggleWidget({super.key, this.onPeriodChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<PeriodToggleProvider>(
      builder: (context, periodProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final containerWidth = constraints.maxWidth;
            final margin = 2.0;
            final segmentWidth = (containerWidth - (margin * 3)) / 3;

            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .3),
                border: Border.all(color: Color(0xffac8a78), width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Animated Switch Indicator (Background layer)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: margin + (periodProvider.selectedPeriod == PeriodType.daily
                        ? 0
                        : periodProvider.selectedPeriod == PeriodType.weekly
                        ? segmentWidth
                        : segmentWidth * 2),
                    top: margin,
                    bottom: margin,
                    child: Container(
                      width: segmentWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xffb88a2e), // Dark gold shadow (top)
                            Color(0xfff5e6b0), // Soft gold highlight
                            Colors.white, // Bright center shine
                            Color(0xfff5e6b0), // Soft gold highlight
                            Color(0xffb88a2e), // Dark gold shadow (bottom)
                          ],
                          stops: [0.0, 0.35, 0.5, 0.65, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  // Row with three texts (Foreground layer)
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodOption(
                          context,
                          'Daily',
                          PeriodType.daily,
                          periodProvider,
                        ),
                      ),
                      Expanded(
                        child: _buildPeriodOption(
                          context,
                          'Weekly',
                          PeriodType.weekly,
                          periodProvider,
                        ),
                      ),
                      Expanded(
                        child: _buildPeriodOption(
                          context,
                          'Monthly',
                          PeriodType.monthly,
                          periodProvider,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeriodOption(
    BuildContext context,
    String text,
    PeriodType period,
    PeriodToggleProvider provider,
  ) {
    final isSelected = provider.selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        provider.setPeriod(period);
        // Call the callback if provided
        if (onPeriodChanged != null) {
          onPeriodChanged!(period);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Color(0xff453f17) : Color(0xffac8a78),
            ),
          ),
        ),
      ),
    );
  }
}
