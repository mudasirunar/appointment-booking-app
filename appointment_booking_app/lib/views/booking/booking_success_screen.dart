import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../models/booking_model.dart';
import '../../models/staff_model.dart';
import '../navigation/main_navigation_shell.dart';

class BookingSuccessScreen extends StatefulWidget {
  final BookingModel booking;
  final StaffModel? staff;

  const BookingSuccessScreen({
    super.key,
    required this.booking,
    this.staff,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  bool _isCopied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    _resetTimer?.cancel();
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: widget.booking.bookingId));
    AppSnackBar.showSuccess(context, 'Booking ID copied to clipboard');

    setState(() {
      _isCopied = true;
    });

    _resetTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationShell(initialIndex: tabIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final booking = widget.booking;
    final staff = widget.staff;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _navigateToTab(context, 1);
        },
        child: Scaffold(
          body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Animated / Glowing Success Badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppTheme.primaryAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryAccent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Appointment Confirmed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your slot has been reserved at Salon Luxe in Asia/Karachi (PKT UTC+5).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reference ID Pill with Animated Copy / Done State & Haptics
                      InkWell(
                        onTap: _handleCopy,
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isCopied
                                ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFDCFCE7))
                                : (isDark ? AppTheme.cardBackgroundDark : Colors.white),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isCopied
                                  ? const Color(0xFF16A34A)
                                  : AppTheme.borderOf(context),
                              width: _isCopied ? 1.5 : 1.0,
                            ),
                            boxShadow: _isCopied
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: _isCopied
                                      ? const Color(0xFF16A34A)
                                      : AppTheme.primaryAccent,
                                ),
                                child: Text('REF: ${booking.bookingId}'),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: _isCopied
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        key: ValueKey('copied_icon'),
                                        size: 16,
                                        color: Color(0xFF16A34A),
                                      )
                                    : Icon(
                                        Icons.copy_rounded,
                                        key: const ValueKey('copy_icon'),
                                        size: 15,
                                        color: AppTheme.textSecondaryOf(context),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Detailed Confirmation Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderOf(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Detail
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SERVICE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                          color: AppTheme.textSecondaryOf(context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        booking.serviceName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimaryOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  booking.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Stylist Detail
                            Row(
                              children: [
                                ClipOval(
                                  child: staff != null
                                      ? AppNetworkImage(
                                          imageUrl: staff.avatarUrl,
                                          width: 44,
                                          height: 44,
                                          fallbackIcon: Icons.person_rounded,
                                        )
                                      : Container(
                                          width: 44,
                                          height: 44,
                                          color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: AppTheme.primaryAccent,
                                            size: 22,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STYLIST',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: AppTheme.textSecondaryOf(context),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.staffName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Date & Time
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppTheme.primaryAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        TimezoneUtil.formatDate(booking.startAt),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimaryOf(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${TimezoneUtil.formatTimeOnly(booking.startAt)} – ${TimezoneUtil.formatTimeOnly(booking.endAt)} (${TimezoneUtil.timezoneLabel} UTC+5)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondaryOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                              const Divider(height: 28),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SPECIAL REQUEST',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: AppTheme.textSecondaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.notes!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textPrimaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Docked Bottom Bar (Tuned to 22px bottom padding, no safe area gap)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceOf(context),
                  border: Border(top: BorderSide(color: AppTheme.borderOf(context))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomButton(
                      width: double.infinity,
                      text: 'View in My Bookings',
                      icon: Icons.calendar_month_rounded,
                      onPressed: () => _navigateToTab(context, 1),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => _navigateToTab(context, 0),
                      child: Text(
                        'Back to Salon Services',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
