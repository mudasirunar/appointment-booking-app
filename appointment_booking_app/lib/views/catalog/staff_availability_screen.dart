import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/service_model.dart';
import '../../models/slot_model.dart';
import '../../models/staff_model.dart';
import '../../providers/availability_provider.dart';
import '../booking/booking_review_screen.dart';

class StaffAvailabilityScreen extends StatefulWidget {
  final ServiceModel service;

  const StaffAvailabilityScreen({super.key, required this.service});

  @override
  State<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState extends State<StaffAvailabilityScreen> {
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AvailabilityProvider>();
      provider.clearSelection();
      provider.selectService(widget.service);
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final availability = context.watch<AvailabilityProvider>();

    final selectedStaff = availability.selectedStaff;
    final selectedDate = availability.selectedDate;
    final selectedSlot = availability.selectedSlot;
    final visibleSlots = availability.visibleSlots;
    final isSunday = availability.isSelectedDateSunday;
    final fourteenDays = TimezoneUtil.get14CalendarDays();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              const Text(
                'Schedule Appointment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Asia/Karachi (${TimezoneUtil.timezoneLabel} UTC+5)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Service Summary Card
              _buildServiceSummary(context, isDark),
              const SizedBox(height: 24),

              // Section 1: Specialist Selection
              _buildSectionHeader(
                context,
                title: 'Select Specialist',
                subtitle: 'Choose your preferred styling expert',
                icon: Icons.person_search_rounded,
              ),
              const SizedBox(height: 12),
              _buildStaffSelector(context, availability, isDark),
              const SizedBox(height: 24),

              // Section 2: Date Selector (14-Day Calendar)
              _buildSectionHeader(
                context,
                title: 'Select Date',
                subtitle: 'Next 14 calendar days (Mon–Sat)',
                icon: Icons.calendar_month_rounded,
                badge: '14 DAYS',
              ),
              const SizedBox(height: 12),
              _buildDateStrip(
                context,
                availability,
                fourteenDays,
                isDark,
              ),
              const SizedBox(height: 24),

              // Section 3: Time Slots or Sunday Closed
              _buildSlotsSection(
                context,
                availability,
                isSunday,
                visibleSlots,
                isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(
          context,
          availability,
          selectedSlot,
          selectedDate,
          selectedStaff,
          isDark,
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildServiceSummary(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Service Image Thumbnail with Hero Animation
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              imageUrl: widget.service.displayImageUrl,
              heroTag: 'service_${widget.service.id}',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.service.durationMinutes} mins',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.service.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        ?trailing,
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaffSelector(
    BuildContext context,
    AvailabilityProvider availability,
    bool isDark,
  ) {
    final staffList = availability.staffList;

    if (staffList.isEmpty && availability.isLoading) {
      return Row(
        children: [
          Expanded(child: _buildStaffSkeleton(isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildStaffSkeleton(isDark)),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < staffList.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _buildStaffItem(context, availability, staffList[i], isDark),
          ),
        ],
      ],
    );
  }

  Widget _buildStaffItem(
    BuildContext context,
    AvailabilityProvider availability,
    StaffModel staff,
    bool isDark,
  ) {
    final isSelected = availability.selectedStaff?.id == staff.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        availability.selectStaff(staff);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppTheme.primaryAccent.withValues(alpha: 0.15)
                    : AppTheme.primaryAccent.withValues(alpha: 0.1))
              : AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : AppTheme.borderOf(context),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: AppNetworkImage(
                    imageUrl: staff.avatarUrl,
                    width: 52,
                    height: 52,
                    fallbackIcon: Icons.person_rounded,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              staff.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryAccent
                    : AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              staff.role,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateStrip(
    BuildContext context,
    AvailabilityProvider availability,
    List<DateTime> days,
    bool isDark,
  ) {
    final selectedDate = availability.selectedDate;

    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected =
              selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;
          final isToday = index == 0;
          final isSunday = TimezoneUtil.isSunday(date);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              availability.selectDate(date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 66,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryAccent
                    : AppTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : AppTheme.borderOf(context),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday
                        ? 'TODAY'
                        : TimezoneUtil.formatDayShort(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isSunday
                                ? Colors.redAccent
                                : AppTheme.textSecondaryOf(context)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimezoneUtil.formatDayNumber(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TimezoneUtil.formatMonthShort(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsSection(
    BuildContext context,
    AvailabilityProvider availability,
    bool isSunday,
    List<SlotModel> slots,
    bool isDark,
  ) {
    if (isSunday) {
      return _buildSundayClosedView(context, isDark);
    }

    final availableCount = slots.where((s) => !s.isReserved).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Time Slots',
          subtitle: '10:00 AM – 6:00 PM PKT (30 min duration)',
          icon: Icons.access_time_filled_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: availableCount > 0
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$availableCount available',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: availableCount > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (availability.isLoadingSlots && slots.isEmpty) ...[
          _buildSlotsSkeleton(isDark),
        ] else if (slots.isEmpty) ...[
          _buildNoSlotsView(context, isDark),
        ] else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return _buildSlotTile(context, availability, slot, isDark);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSlotTile(
    BuildContext context,
    AvailabilityProvider availability,
    SlotModel slot,
    bool isDark,
  ) {
    final isSelected = availability.selectedSlot?.id == slot.id;
    final isReserved = slot.isReserved;

    return GestureDetector(
      onTap: isReserved
          ? null
          : () {
              HapticFeedback.lightImpact();
              availability.selectSlot(slot);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isReserved
              ? (isDark ? const Color(0xFF1E2124) : const Color(0xFFF1F3F5))
              : (isSelected
                    ? AppTheme.primaryAccent
                    : AppTheme.surfaceOf(context)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReserved
                ? Colors.transparent
                : (isSelected
                      ? AppTheme.primaryAccent
                      : AppTheme.borderOf(context)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TimezoneUtil.formatTimeOnly(slot.startAt),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isReserved
                    ? AppTheme.textSecondaryOf(context).withValues(alpha: 0.4)
                    : (isSelected
                          ? Colors.white
                          : AppTheme.textPrimaryOf(context)),
                decoration: isReserved ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isReserved)
              Text(
                'Booked',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSundayClosedView(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryAccent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 36,
              color: AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Salon Closed on Sundays',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our specialists are off on Sundays to recharge. Please pick Monday through Saturday to schedule your appointment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryOf(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsView(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 32,
            color: AppTheme.textSecondaryOf(context),
          ),
          const SizedBox(height: 10),
          Text(
            'No Available Slots',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All slots for this day have concluded or are booked. Try selecting another date above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSkeleton(bool isDark) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282C) : const Color(0xFFE8EAEB),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSlotsSkeleton(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24282C) : const Color(0xFFE8EAEB),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    AvailabilityProvider availability,
    SlotModel? selectedSlot,
    DateTime selectedDate,
    StaffModel? selectedStaff,
    bool isDark,
  ) {
    final isSlotValid = selectedSlot != null &&
        !selectedSlot.isReserved &&
        !selectedSlot.isPast;
    final hasSelection = isSlotValid && selectedStaff != null;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSelection)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppTheme.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${TimezoneUtil.formatDate(selectedSlot.startAt)} at ${TimezoneUtil.formatTimeOnly(selectedSlot.startAt)} (${TimezoneUtil.timezoneLabel}) with ${selectedStaff.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          CustomButton(
            width: double.infinity,
            text: hasSelection
                ? 'Continue to Review'
                : 'Select a Slot to Continue',
            onPressed: hasSelection
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingReviewScreen(
                          service: widget.service,
                          staff: selectedStaff,
                          slot: selectedSlot,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
