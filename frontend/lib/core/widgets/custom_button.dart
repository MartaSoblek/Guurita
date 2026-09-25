import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

enum ButtonType { primary, secondary, outline, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case ButtonType.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        break;
      case ButtonType.secondary:
        bgColor = AppColors.primarySubtle;
        fgColor = AppColors.primaryDark;
        break;
      case ButtonType.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonType.danger:
        bgColor = AppColors.error;
        fgColor = Colors.white;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fgColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
