import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const defaultBgColor = AppTheme.primaryAccent;
    final effectiveBgColor = backgroundColor ?? defaultBgColor;
    final effectiveTextColor = textColor ??
        (isOutlined
            ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary)
            : (isDark ? Colors.black : Colors.white));
    final isInteractive = !isLoading && onPressed != null;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: effectiveTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
              ),
            ],
          );

    final buttonWidget = isOutlined
        ? OutlinedButton(
            onPressed: isInteractive ? onPressed : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isInteractive
                    ? (backgroundColor ?? (isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtle))
                    : (isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtle),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isInteractive ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveBgColor,
              foregroundColor: effectiveTextColor,
              disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.5),
              disabledForegroundColor: effectiveTextColor.withValues(alpha: 0.7),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: child,
          );

    return width != null ? SizedBox(width: width, child: buttonWidget) : buttonWidget;
  }
}
