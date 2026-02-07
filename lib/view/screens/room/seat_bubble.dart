
// @@ -0,0 +1,89 @@
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shaheen_star_app/view/screens/room/room_assets.dart';

/// Visual state of a seat bubble.
enum SeatState { available, taken, locked, admin, owner }

/// A circular seat bubble with a background frame, optional avatar, and badges.
class SeatBubble extends StatelessWidget {
  final RoomAssets assets;
 final SeatState state;  final String? avatarPath;
  final String? label; // small numeric label beneath the seat

  /// Size of the seat circle. The widget will scale other elements from it.
  final double size;

  const SeatBubble({
    super.key,    required this.assets,
    required this.state,
    this.avatarPath,
    this.label,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final double frameSize = size;
    final double avatarSize = size * 0.58;

    String framePath = assets.seatIcon;
    if (state == SeatState.admin) framePath = assets.adminSeatIcon;
    if (state == SeatState.owner) framePath = assets.ownerSeatIcon;

    final bool showLock = state == SeatState.locked;

    return Column(
      children: [
        SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // frame/background
              ClipOval(
                child: framePath.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                        framePath,
                        width: frameSize,
                        height: frameSize,
                        fit: BoxFit.cover,
                      )
                    : safeAsset(
                        framePath,
                        width: frameSize,
                        height: frameSize,
                        fit: BoxFit.cover,
                      ),
              ),

              // avatar if provided
              if (state != SeatState.available)
                ClipOval(
                  child: safeAsset(
                    avatarPath ?? assets.roomAvatar,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                  ),
                ),

              // lock overlay
              if (showLock)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: SizedBox(
                    width: size * 0.24,
                    height: size * 0.24,
                    child: safeAsset(assets.lockBadge, fit: BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: size * 0.26,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
