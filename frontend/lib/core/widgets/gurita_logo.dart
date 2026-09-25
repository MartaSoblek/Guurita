import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_constants.dart';

class GuritaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isLightText;

  const GuritaLogo({
    super.key,
    this.size = 48.0,
    this.showText = true,
    this.isLightText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLightText ? Colors.white : AppColors.textMain;
    final subtextColor = isLightText ? Colors.white70 : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.58,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.28),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppConstants.appSubtitle,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
