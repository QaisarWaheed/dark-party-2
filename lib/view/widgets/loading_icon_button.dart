import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingIconButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final String? iconPath; // Image asset path
  final IconData? icon; // Material icon
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final double iconSize;
  final double fontSize;
  final Color? iconColor;

  const LoadingIconButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.iconPath,
    this.icon,
    this.iconColor,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.height = 50,
    this.borderRadius = 25,
    this.iconSize = 24,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (isLoading) {
      iconWidget = SizedBox(
        height: iconSize.h,
        width: iconSize.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.black,
        ),
      );
    } else if (icon != null) {
      iconWidget = Icon(
        icon,
        size: iconSize.sp,
        color: iconColor ?? textColor,
      );
    } else if (iconPath != null) {
      iconWidget = Image.asset(
        iconPath!,
        height: iconSize.h,
        width: iconSize.w,
        fit: BoxFit.contain,
        color: iconColor,
        colorBlendMode: BlendMode.srcIn,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: height.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left icon
            SizedBox(
              height: iconSize.h,
              width: iconSize.w,
              child: iconWidget,
            ),
            SizedBox(width: 12.w),
            // Centered label
            Expanded(
              child: Center(
                child: Text(
                  isLoading ? "Please wait..." : label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Keep spacing to balance icon on left
            SizedBox(width: iconSize.w + 12.w),
          ],
        ),
      ),
    );
  }
}
