import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../../providers/booking_provider.dart';

class FloatingGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int? badgeCount;

  const FloatingGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.badgeCount,
  });

  @override
  State<FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<FloatingGlassNavBar>
    with SingleTickerProviderStateMixin {
  late double _currentPillPosition;
  late int _lastHoveredIndex;
  late AnimationController _pillController;
  Animation<double>? _pillAnimation;

  bool _isDragging = false;
  double _navBarWidth = 320.0;

  @override
  void initState() {
    super.initState();
    _currentPillPosition = widget.currentIndex.toDouble();
    _lastHoveredIndex = widget.currentIndex;
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant FloatingGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animatePillTo(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _animatePillTo(double target, {VoidCallback? onComplete}) {
    _pillController.stop();
    final start = _currentPillPosition;
    _pillAnimation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(
        parent: _pillController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {
          _currentPillPosition = _pillAnimation!.value;
        });
      });

    _pillController.forward(from: 0.0).then((_) {
      if (mounted) {
        onComplete?.call();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    _pillController.stop();
    setState(() {
      _isDragging = true;
    });
    _lastHoveredIndex = _currentPillPosition.round().clamp(0, 2);
    _updateDragPosition(details.localPosition.dx);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateDragPosition(details.localPosition.dx);
  }

  void _updateDragPosition(double localX) {
    final innerWidth = _navBarWidth - 12; // 6px padding on left & right
    final tabWidth = innerWidth / 3;
    final adjustedX = localX - 6;
    // tab 0 center is at tabWidth * 0.5
    final rawPos = (adjustedX - (tabWidth / 2)) / tabWidth;
    final clampedPos = rawPos.clamp(-0.15, 2.15);

    final hoveredIndex = rawPos.round().clamp(0, 2);
    if (hoveredIndex != _lastHoveredIndex) {
      HapticFeedback.selectionClick();
      _lastHoveredIndex = hoveredIndex;
    }

    setState(() {
      _currentPillPosition = clampedPos;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    int targetIndex = _currentPillPosition.round().clamp(0, 2);

    if (velocity > 320 && targetIndex < 2) {
      targetIndex = (_currentPillPosition.floor() + 1).clamp(0, 2);
    } else if (velocity < -320 && targetIndex > 0) {
      targetIndex = (_currentPillPosition.ceil() - 1).clamp(0, 2);
    }

    setState(() {
      _isDragging = false;
    });

    HapticFeedback.selectionClick();

    _animatePillTo(targetIndex.toDouble(), onComplete: () {
      if (widget.currentIndex != targetIndex) {
        widget.onTabSelected(targetIndex);
      }
    });
  }

  void _onDragCancel() {
    setState(() {
      _isDragging = false;
    });
    _animatePillTo(widget.currentIndex.toDouble());
  }

  void _onTabTapped(int index) {
    if (_isDragging) return;
    if (widget.currentIndex == index &&
        (_currentPillPosition - index).abs() < 0.05) {
      return;
    }
    HapticFeedback.selectionClick();
    _animatePillTo(index.toDouble(), onComplete: () {
      if (widget.currentIndex != index) {
        widget.onTabSelected(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    int upcomingCount = widget.badgeCount ?? 0;
    if (widget.badgeCount == null) {
      try {
        final provider = Provider.of<BookingProvider?>(context, listen: true);
        upcomingCount = provider?.upcomingBookings.length ?? 0;
      } catch (_) {
        upcomingCount = 0;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    _navBarWidth = screenWidth > 360 ? 320.0 : (screenWidth - 40);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: Container(
            width: _navBarWidth,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppTheme.primaryAccent
                      .withValues(alpha: isDark ? 0.08 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101216).withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withValues(
                        alpha: isDark ? 0.35 : 0.65,
                      ),
                      width: isDark ? 1.0 : 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Fluid Liquid Sliding Pill Background Indicator
                      Align(
                        alignment: Alignment(
                          (_currentPillPosition - 1.0).clamp(-1.0, 1.0),
                          0.0,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutQuad,
                          width: (_navBarWidth - 12) *
                              (_isDragging ? 0.365 : (1.0 / 3.0)),
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      AppTheme.primaryAccent.withValues(
                                          alpha: _isDragging ? 0.36 : 0.25),
                                      AppTheme.primaryAccent.withValues(
                                          alpha: _isDragging ? 0.22 : 0.14),
                                    ]
                                  : [
                                      AppTheme.primaryAccent.withValues(
                                          alpha: _isDragging ? 0.30 : 0.22),
                                      AppTheme.primaryAccent.withValues(
                                          alpha: _isDragging ? 0.18 : 0.12),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.primaryAccent.withValues(
                                  alpha: _isDragging ? 0.70 : 0.48),
                              width: _isDragging ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryAccent.withValues(
                                    alpha: _isDragging ? 0.32 : 0.14),
                                blurRadius: _isDragging ? 14 : 8,
                                spreadRadius: _isDragging ? 1.5 : 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Navigation Items Row (No Ripple, Pure Fluid Haptics)
                      Row(
                        children: [
                          _buildNavItem(
                            context: context,
                            index: 0,
                            icon: Icons.spa_outlined,
                            activeIcon: Icons.spa_rounded,
                            label: 'Services',
                          ),
                          _buildNavItem(
                            context: context,
                            index: 1,
                            icon: Icons.calendar_month_outlined,
                            activeIcon: Icons.calendar_month_rounded,
                            label: 'Bookings',
                            badgeCount: upcomingCount,
                          ),
                          _buildNavItem(
                            context: context,
                            index: 2,
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final proximity =
        (1.0 - (_currentPillPosition - index).abs()).clamp(0.0, 1.0);
    final isSelected = proximity > 0.5;
    final itemColor = Color.lerp(
      AppTheme.textSecondaryOf(context),
      AppTheme.primaryAccent,
      proximity,
    )!;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 19,
                    color: itemColor,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                    color: itemColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
