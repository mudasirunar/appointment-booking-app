import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Item descriptor for [FluidSegmentedPill].
class FluidPillItem {
  final String label;
  final IconData? icon;
  final IconData? activeIcon;

  const FluidPillItem({
    required this.label,
    this.icon,
    this.activeIcon,
  });
}

/// Reusable fluid, draggable segmented pill control.
///
/// Features:
/// - Real-time finger gesture tracking across tab slots.
/// - Dynamic liquid width stretching (+8%) during drag motion.
/// - Luminous accent glow aura while active/dragging.
/// - Synchronized screen-swipe tracking when connected to [PageController].
/// - Tactile haptic feedback when crossing slot thresholds.
/// - Value committed only when placed/released on a slot.
/// - Seamless color cross-fading based on pill proximity.
/// - Zero-ripple tap gesture support.
class FluidSegmentedPill extends StatefulWidget {
  final int selectedIndex;
  final List<FluidPillItem> items;
  final ValueChanged<int> onSelectionChanged;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final PageController? pageController;
  final ValueNotifier<bool>? isPageDraggingNotifier;

  const FluidSegmentedPill({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelectionChanged,
    this.height = 44,
    this.activeColor,
    this.inactiveColor,
    this.pageController,
    this.isPageDraggingNotifier,
  });

  @override
  State<FluidSegmentedPill> createState() => _FluidSegmentedPillState();
}

class _FluidSegmentedPillState extends State<FluidSegmentedPill>
    with SingleTickerProviderStateMixin {
  late double _currentPillPosition;
  late int _lastHoveredIndex;
  late AnimationController _pillController;
  Animation<double>? _pillAnimation;

  bool _isDraggingPill = false;
  bool _isProgrammaticTransition = false;
  Timer? _programmaticTimer;
  double _containerWidth = 300.0;

  bool get _isEffectActive =>
      _isDraggingPill || (widget.isPageDraggingNotifier?.value == true);

  @override
  void initState() {
    super.initState();
    _currentPillPosition = widget.selectedIndex.toDouble();
    _lastHoveredIndex = widget.selectedIndex;
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    widget.pageController?.addListener(_onPageScrolled);
    widget.isPageDraggingNotifier?.addListener(_onPageDraggingChanged);
  }

  @override
  void didUpdateWidget(covariant FluidSegmentedPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController?.removeListener(_onPageScrolled);
      widget.pageController?.addListener(_onPageScrolled);
    }
    if (oldWidget.isPageDraggingNotifier != widget.isPageDraggingNotifier) {
      oldWidget.isPageDraggingNotifier?.removeListener(_onPageDraggingChanged);
      widget.isPageDraggingNotifier?.addListener(_onPageDraggingChanged);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        !_isDraggingPill &&
        !_isProgrammaticTransition &&
        (widget.pageController == null || !widget.pageController!.hasClients)) {
      _animatePillTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _programmaticTimer?.cancel();
    widget.pageController?.removeListener(_onPageScrolled);
    widget.isPageDraggingNotifier?.removeListener(_onPageDraggingChanged);
    _pillController.dispose();
    super.dispose();
  }

  void _onPageScrolled() {
    if (_isDraggingPill) return;
    if (_isProgrammaticTransition) return;
    if (widget.pageController == null || !widget.pageController!.hasClients) return;

    final page = widget.pageController!.page;
    if (page != null) {
      final clamped = page.clamp(0.0, (widget.items.length - 1).toDouble());
      setState(() {
        _currentPillPosition = clamped;
      });

      final hoveredIndex = clamped.round().clamp(0, widget.items.length - 1);
      if (hoveredIndex != _lastHoveredIndex) {
        HapticFeedback.selectionClick();
        _lastHoveredIndex = hoveredIndex;
      }
    }
  }

  void _onPageDraggingChanged() {
    if (mounted) {
      if (widget.isPageDraggingNotifier?.value == true) {
        _programmaticTimer?.cancel();
        _isProgrammaticTransition = false;
      }
      setState(() {});
    }
  }

  void _startProgrammaticCooldown() {
    _programmaticTimer?.cancel();
    _programmaticTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _isProgrammaticTransition = false;
        });
      }
    });
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
    _programmaticTimer?.cancel();
    _isProgrammaticTransition = false;
    setState(() {
      _isDraggingPill = true;
    });
    _lastHoveredIndex =
        _currentPillPosition.round().clamp(0, widget.items.length - 1);
    _updateDragPosition(details.localPosition.dx);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateDragPosition(details.localPosition.dx);
  }

  void _updateDragPosition(double localX) {
    final count = widget.items.length;
    if (count <= 1) return;

    final innerWidth = _containerWidth - 8; // 4px padding on each side
    final itemWidth = innerWidth / count;
    final adjustedX = localX - 4;
    final rawPos = (adjustedX - (itemWidth / 2)) / itemWidth;
    final clampedPos = rawPos.clamp(-0.15, (count - 1) + 0.15);

    final hoveredIndex = rawPos.round().clamp(0, count - 1);
    if (hoveredIndex != _lastHoveredIndex) {
      HapticFeedback.selectionClick();
      _lastHoveredIndex = hoveredIndex;
    }

    setState(() {
      _currentPillPosition = clampedPos;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final count = widget.items.length;
    final velocity = details.primaryVelocity ?? 0;
    int targetIndex = _currentPillPosition.round().clamp(0, count - 1);

    if (velocity > 320 && targetIndex < count - 1) {
      targetIndex = (_currentPillPosition.floor() + 1).clamp(0, count - 1);
    } else if (velocity < -320 && targetIndex > 0) {
      targetIndex = (_currentPillPosition.ceil() - 1).clamp(0, count - 1);
    }

    setState(() {
      _isDraggingPill = false;
      _isProgrammaticTransition = true;
    });

    HapticFeedback.selectionClick();

    _animatePillTo(targetIndex.toDouble(), onComplete: () {
      if (widget.selectedIndex != targetIndex) {
        widget.onSelectionChanged(targetIndex);
      }
      _startProgrammaticCooldown();
    });
  }

  void _onDragCancel() {
    setState(() {
      _isDraggingPill = false;
      _isProgrammaticTransition = true;
    });
    _animatePillTo(widget.selectedIndex.toDouble(), onComplete: () {
      _startProgrammaticCooldown();
    });
  }

  void _onTabTapped(int index) {
    if (_isDraggingPill) return;
    if (widget.selectedIndex == index &&
        (_currentPillPosition - index).abs() < 0.05) {
      return;
    }
    _programmaticTimer?.cancel();
    _isProgrammaticTransition = true;
    HapticFeedback.selectionClick();
    _animatePillTo(index.toDouble(), onComplete: () {
      if (widget.selectedIndex != index) {
        widget.onSelectionChanged(index);
      }
      _startProgrammaticCooldown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final count = widget.items.length;

    final effectiveActiveColor = widget.activeColor ?? AppTheme.primaryAccent;
    final effectiveInactiveColor =
        widget.inactiveColor ?? AppTheme.textSecondaryOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;
        final innerWidth = _containerWidth - 8;
        final baseWidth = innerWidth / count;
        final pillWidth = baseWidth * (_isEffectActive ? 1.08 : 1.0);

        // Alignment in Flutter goes from -1.0 (left) to 1.0 (right)
        final normalizedX = count > 1
            ? ((_currentPillPosition / (count - 1)) * 2.0) - 1.0
            : 0.0;
        final clampedAlignmentX = normalizedX.clamp(-1.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16181C) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: AppTheme.borderOf(context),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Liquid Sliding Pill Indicator
                Align(
                  alignment: Alignment(clampedAlignmentX, 0.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutQuad,
                    width: pillWidth,
                    height: widget.height - 8,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282E36) : Colors.white,
                      borderRadius:
                          BorderRadius.circular((widget.height - 8) / 2),
                      border: Border.all(
                        color: effectiveActiveColor.withValues(
                          alpha: _isEffectActive ? 0.65 : 0.45,
                        ),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: _isEffectActive ? 8 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Item Tap Targets
                Row(
                  children: List.generate(count, (index) {
                    final item = widget.items[index];
                    final proximity = (1.0 - (_currentPillPosition - index).abs())
                        .clamp(0.0, 1.0);
                    final isSelected = proximity > 0.5;

                    final itemColor = Color.lerp(
                      effectiveInactiveColor,
                      effectiveActiveColor,
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
                              if (item.icon != null) ...[
                                Icon(
                                  isSelected
                                      ? (item.activeIcon ?? item.icon)
                                      : item.icon,
                                  size: 17,
                                  color: itemColor,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
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
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
