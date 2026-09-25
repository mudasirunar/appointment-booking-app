import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Reusable salon-themed confirmation and alert dialog widget.
///
/// Features:
/// - Compact, well-proportioned dimensions (max width 320px).
/// - Centered icon on top with tinted circular background badge.
/// - Centered title and description text.
/// - Main app theme border (Warm Gold #C49A58).
/// - Symmetrical, balanced action buttons spanning the bottom width.
/// - Built-in async loading state support on the confirm button.
class AppDialog extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? description;
  final Widget? customContent;
  final String cancelText;
  final String confirmText;
  final Color? confirmColor;
  final bool isDestructive;
  final bool showCancel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Future<void> Function()? onConfirmAsync;
  final bool isLoading;

  const AppDialog({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.description,
    this.customContent,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    this.confirmColor,
    this.isDestructive = false,
    this.showCancel = true,
    this.onCancel,
    this.onConfirm,
    this.onConfirmAsync,
    this.isLoading = false,
  });

  /// Static helper to display the standardized dialog from any screen.
  static Future<bool?> show({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    required String title,
    String? description,
    Widget? customContent,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    Color? confirmColor,
    bool isDestructive = false,
    bool showCancel = true,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    Future<void> Function()? onConfirmAsync,
    bool barrierDismissible = true,
    bool isLoading = false,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialog(
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        description: description,
        customContent: customContent,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
        isDestructive: isDestructive,
        showCancel: showCancel,
        onCancel: onCancel,
        onConfirm: onConfirm,
        onConfirmAsync: onConfirmAsync,
        isLoading: isLoading,
      ),
    );
  }

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
  }

  @override
  void didUpdateWidget(covariant AppDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _isLoading = widget.isLoading;
    }
  }

  Future<void> _handleConfirm() async {
    if (_isLoading) return;

    if (widget.onConfirmAsync != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onConfirmAsync!();
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        rethrow;
      }
      return;
    }

    if (widget.onConfirm != null) {
      widget.onConfirm!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    final effectiveIconColor = widget.iconColor ??
        (widget.isDestructive ? Colors.redAccent : AppTheme.primaryAccent);
    final effectiveIconBg = widget.iconBackgroundColor ??
        effectiveIconColor.withValues(alpha: 0.12);

    final effectiveConfirmColor = widget.confirmColor ??
        (widget.isDestructive ? Colors.redAccent : AppTheme.primaryAccent);

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: isDark ? AppTheme.cardBackgroundDark : Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // Main app theme color border
          side: BorderSide(
            color: AppTheme.primaryAccent.withValues(alpha: isDark ? 0.55 : 0.65),
            width: 1.2,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Centered Icon on top
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: effectiveIconBg,
                    border: Border.all(
                      color: effectiveIconColor.withValues(alpha: 0.25),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: effectiveIconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Centered Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Centered Description or custom content
                if (widget.customContent != null)
                  widget.customContent!
                else if (widget.description != null)
                  Text(
                    widget.description!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                const SizedBox(height: 20),

                // 4. Symmetrical, balanced action buttons
                Row(
                  children: [
                    if (widget.showCancel) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? () {} // Unclickable (no-op), keeping original styling without greying out
                              : () {
                                  HapticFeedback.selectionClick();
                                  if (widget.onCancel != null) {
                                    widget.onCancel!();
                                  } else {
                                    Navigator.of(context).pop(false);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF33383F)
                                  : const Color(0xFFE2E4E8),
                              width: 1.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.cancelText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? () {} // Unclickable (no-op) while loading
                            : () {
                                HapticFeedback.selectionClick();
                                _handleConfirm();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: effectiveConfirmColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.isDestructive
                                        ? Colors.white
                                        : (isDark ? Colors.black : Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                widget.confirmText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDestructive
                                      ? Colors.white
                                      : (isDark ? Colors.black : Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
