import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A production-grade network image widget designed for 60fps performance:
/// - Smooth shimmer loading skeleton
/// - Offline/error fallback with branded icon & subtle background
/// - Automatic retry timer that re-attempts failed loads when connectivity returns
/// - Optional Hero animation support
class AppNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final String heroTag;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.content_cut_rounded,
    this.heroTag = '',
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  int _retryKey = 0;
  bool _hasError = false;
  Timer? _autoRetryTimer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
      _cancelAutoRetry();
    }
  }

  @override
  void dispose() {
    _cancelAutoRetry();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onImageError() {
    if (!mounted) return;
    setState(() {
      _hasError = true;
    });

    // Setup automatic retry after 6 seconds if network dropped temporarily
    _cancelAutoRetry();
    _autoRetryTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _hasError) {
        setState(() {
          _hasError = false;
          _retryKey++;
        });
      }
    });
  }

  void _cancelAutoRetry() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
  }

  Widget _buildShimmer(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerVal = _shimmerController.value;
        final baseColor = isDark ? const Color(0xFF24282C) : const Color(0xFFE8EAEB);
        final highlightColor = isDark ? const Color(0xFF33383E) : const Color(0xFFF7F8F9);

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(shimmerVal - 1.0, 0),
              end: Alignment(shimmerVal, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBackgroundDark : const Color(0xFFEEF0F2),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtle,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.fallbackIcon,
              size: (widget.height != null && widget.height! < 80) ? 24 : 36,
              color: AppTheme.primaryAccent.withValues(alpha: 0.8),
            ),
            if (widget.height == null || widget.height! >= 100) ...[
              const SizedBox(height: 6),
              Text(
                'Salon Luxe',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final url = widget.imageUrl;

    if (url == null || url.trim().isEmpty || _hasError) {
      return _buildFallback(isDark);
    }

    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        url,
        key: ValueKey('${url}_$_retryKey'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildShimmer(isDark);
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onImageError();
          });
          return _buildFallback(isDark);
        },
      ),
    );

    if (widget.heroTag.isNotEmpty) {
      return Hero(
        tag: widget.heroTag,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
