import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/fluid_segmented_pill.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  final VoidCallback? onExploreServices;

  const MyBookingsScreen({super.key, this.onExploreServices});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTabIndex = 0; // 0: Upcoming, 1: Past, 2: Cancelled

  late final PageController _pageController;
  final ValueNotifier<bool> _isPageDraggingNotifier = ValueNotifier<bool>(false);

  // Set of booking IDs that were just copied (for animated copy feedback)
  final Set<String> _copiedBookingIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isPageDraggingNotifier.dispose();
    super.dispose();
  }

  void _handleCopy(String bookingId) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: bookingId));
    AppSnackBar.showSuccess(context, 'Booking ID copied: $bookingId');

    setState(() {
      _copiedBookingIds.add(bookingId);
    });

    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _copiedBookingIds.remove(bookingId);
        });
      }
    });
  }

  void _confirmCancelBooking(BuildContext context, BookingModel booking) {
    // Safety check: is appointment still in the future?
    if (TimezoneUtil.isPastSlot(booking.startAt)) {
      AppSnackBar.showError(context, 'Cannot cancel an appointment that has already elapsed.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    AppDialog.show(
      context: context,
      icon: Icons.event_busy_rounded,
      isDestructive: true,
      title: 'Cancel Appointment?',
      description:
          'Are you sure you want to cancel your ${booking.serviceName} session on ${TimezoneUtil.formatDate(booking.startAt)} at ${TimezoneUtil.formatTimeOnly(booking.startAt)} with ${booking.staffName}?\n\nThe slot will be released back to the salon schedule immediately.',
      cancelText: 'Keep',
      confirmText: 'Cancel',
      onConfirm: () async {
        Navigator.pop(context);
        final user = auth.user;
        if (user == null) return;

              final success = await bookingProvider.cancelBooking(
                uid: user.uid,
                booking: booking,
              );

              if (!mounted) return;
              if (success) {
                AppSnackBar.showSuccess(
                  this.context,
                  'Appointment cancelled. Slot has been released.',
                );
              } else {
                AppSnackBar.showError(
                  this.context,
                  bookingProvider.errorMessage ?? 'Failed to cancel appointment.',
                );
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bookingProvider = context.watch<BookingProvider>();

    final upcoming = bookingProvider.upcomingBookings;
    final past = bookingProvider.pastBookings;
    final cancelled = bookingProvider.cancelledBookings;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Screen Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Appointments',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Asia/Karachi (${TimezoneUtil.timezoneLabel} UTC+5)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                    if (upcoming.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0D9488)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${upcoming.length} ACTIVE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Segmented Tab Selector with Fluid Drag Physics (Upcoming | Past | Cancelled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FluidSegmentedPill(
                  selectedIndex: _selectedTabIndex,
                  pageController: _pageController,
                  isPageDraggingNotifier: _isPageDraggingNotifier,
                  height: 46,
                  items: [
                    FluidPillItem(label: 'Upcoming (${upcoming.length})'),
                    FluidPillItem(label: 'Past (${past.length})'),
                    FluidPillItem(label: 'Cancelled (${cancelled.length})'),
                  ],
                  onSelectionChanged: (index) {
                    setState(() => _selectedTabIndex = index);
                    if (_pageController.hasClients &&
                        _pageController.page?.round() != index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Swipeable Tab Views (Upcoming | Past | Cancelled)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      if (notification.dragDetails != null) {
                        _isPageDraggingNotifier.value = true;
                      }
                    } else if (notification is ScrollEndNotification) {
                      _isPageDraggingNotifier.value = false;
                    }
                    return false;
                  },
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (_selectedTabIndex != index) {
                        setState(() => _selectedTabIndex = index);
                      }
                    },
                    children: [
                      _buildBookingListView(
                        context: context,
                        isDark: isDark,
                        bookingProvider: bookingProvider,
                        list: upcoming,
                        tabIndex: 0,
                      ),
                      _buildBookingListView(
                        context: context,
                        isDark: isDark,
                        bookingProvider: bookingProvider,
                        list: past,
                        tabIndex: 1,
                      ),
                      _buildBookingListView(
                        context: context,
                        isDark: isDark,
                        bookingProvider: bookingProvider,
                        list: cancelled,
                        tabIndex: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingListView({
    required BuildContext context,
    required bool isDark,
    required BookingProvider bookingProvider,
    required List<BookingModel> list,
    required int tabIndex,
  }) {
    if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
      return _buildLoadingSkeleton(isDark);
    }
    if (list.isEmpty) {
      return _buildEmptyState(context, isDark, tabIndex);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = list[index];
        return _buildBookingCard(
          context: context,
          isDark: isDark,
          booking: booking,
          isCopied: _copiedBookingIds.contains(booking.bookingId),
          onCopy: () => _handleCopy(booking.bookingId),
          onCancel: tabIndex == 0
              ? () => _confirmCancelBooking(context, booking)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, int tabIndex) {
    final IconData icon;
    final String title;
    final String description;
    final bool showCta;

    switch (tabIndex) {
      case 0:
        icon = Icons.calendar_today_outlined;
        title = 'No Upcoming Appointments';
        description =
            'You do not have any appointments scheduled. Explore our premier salon services to reserve a session with our stylists.';
        showCta = true;
        break;
      case 1:
        icon = Icons.history_rounded;
        title = 'No Past Appointments';
        description = 'Your completed salon visits and service history will appear here.';
        showCta = false;
        break;
      case 2:
      default:
        icon = Icons.event_busy_rounded;
        title = 'No Cancelled Appointments';
        description = 'You have no cancelled appointments on record.';
        showCta = false;
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Themed Icon Container with Gold Glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),

            if (showCta) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Book an Appointment',
                icon: Icons.add_rounded,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (widget.onExploreServices != null) {
                    widget.onExploreServices!();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required bool isDark,
    required BookingModel booking,
    required bool isCopied,
    required VoidCallback onCopy,
    VoidCallback? onCancel,
  }) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(booking.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge + Reference ID Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Reference ID with animated copy
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCopied
                        ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFDCFCE7))
                        : (isDark ? const Color(0xFF16181C) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCopied
                          ? const Color(0xFF16A34A)
                          : AppTheme.borderOf(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        booking.bookingId,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isCopied
                              ? const Color(0xFF16A34A)
                              : AppTheme.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isCopied
                            ? const Icon(
                                Icons.check_rounded,
                                key: ValueKey('c_tick'),
                                size: 12,
                                color: Color(0xFF16A34A),
                              )
                            : Icon(
                                Icons.copy_rounded,
                                key: const ValueKey('c_icon'),
                                size: 12,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Service Title & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
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
          const SizedBox(height: 8),

          // Stylist Detail
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Stylist: ${booking.staffName}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const Divider(height: 22),

          // Date & Time (Asia/Karachi PKT UTC+5)
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                TimezoneUtil.formatDate(booking.startAt),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${TimezoneUtil.formatTimeOnly(booking.startAt)} – ${TimezoneUtil.formatTimeOnly(booking.endAt)} (${TimezoneUtil.timezoneLabel})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Special Notes (if available)
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16181C) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 13,
                    color: AppTheme.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Cancel Action (Upcoming Tab Only)
          if (onCancel != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cancel Appointment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return const Color(0xFF0D9488); // Teal
      case BookingStatus.past:
        return const Color(0xFF6B7280); // Grey
      case BookingStatus.cancelled:
        return const Color(0xFFDC2626); // Ruby Red
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'UPCOMING';
      case BookingStatus.past:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24282C) : const Color(0xFFE8EAEB),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
