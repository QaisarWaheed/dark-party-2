import 'package:flutter/material.dart';

class RoomAssets {
  final String background;
  final String seatIcon;
  final String adminSeatIcon;
  final String ownerSeatIcon;
  final String lockBadge;
  final String roomAvatar;
  final String micIcon;
  final String giftIcon;
  final String emojiIcon;

  const RoomAssets({
    required this.background,
    required this.seatIcon,
    required this.adminSeatIcon,
    required this.ownerSeatIcon,
    required this.lockBadge,
    required this.roomAvatar,
    required this.micIcon,
    required this.giftIcon,
    required this.emojiIcon,
  });

  factory RoomAssets.defaults() => const RoomAssets(
        background: 'assets/images/wel.jpeg',
      seatIcon: 'assets/icons/room_seat.svg',
        adminSeatIcon: 'assets/images/room_1.png',
        ownerSeatIcon: 'assets/images/room_2.png',
        lockBadge: 'assets/images/ic_edit.png',
        roomAvatar: 'assets/images/app_logo.jpeg',
        micIcon: 'assets/images/say_hi.png',
        giftIcon: 'assets/images/mine_store.png',
        emojiIcon: 'assets/images/sms.png',
      );
}

/// helper function for safely loading asset
Widget safeAsset(
  String assetPath, {
  double? width,
  double? height,
  BoxFit? fit,
  IconData fallback = Icons.image_not_supported,
  Color? color,
}) {
  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: fit,
    color: color,
    errorBuilder: (context, error, stack) => Icon(
      fallback,
      size: (width ?? height ?? 20),
      color: color ?? Colors.white,
    ),
  );
}
