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
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameSheet(BuildContext context, AuthProvider auth) {
    final isDark = AppTheme.isDark(context);
    final controller = TextEditingController(text: auth.displayName ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.cardBackgroundDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Display Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF16181C)
                          : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.borderOf(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.borderOf(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryAccent,
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    width: double.infinity,
                    text: 'Save Changes',
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newName = controller.text.trim();
                            if (newName.isEmpty) {
                              AppSnackBar.showError(ctx, 'Name cannot be empty');
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final success = await auth.updateDisplayName(newName);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (success) {
                                AppSnackBar.showSuccess(
                                  context,
                                  'Display name updated successfully',
                                );
                              } else {
                                AppSnackBar.showError(
                                  context,
                                  'Could not update name. Please try again.',
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    AppDialog.show(
      context: context,
      icon: Icons.logout_rounded,
      isDestructive: true,
      title: 'Sign Out',
      description: 'Are you sure you want to sign out of your Salon Luxe account?',
      cancelText: 'Cancel',
      confirmText: 'Sign Out',
      onConfirm: () {
        Navigator.pop(context);
        auth.signOut();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final auth = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final user = auth.user;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Valued Client');
    final email = user?.email ?? '';

    // Compute stats
    final totalBookings = bookingProvider.bookings.length;
    final upcomingCount = bookingProvider.upcomingBookings.length;
    final totalSpentPkr = bookingProvider.bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .fold<int>(0, (sum, b) => sum + b.servicePricePkr);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 16,
            20,
            110,
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account & Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'CLIENT TIER',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // User Identity Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderOf(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF24282C) : AppTheme.primary,
                          border: Border.all(
                            color: AppTheme.primaryAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showEditNameSheet(context, auth),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimaryOf(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppTheme.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bento Statistics Section
                Text(
                  'APPOINTMENT ACTIVITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // Total Bookings Card
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.calendar_month_rounded,
                        label: 'Total Bookings',
                        value: '$totalBookings',
                        accentColor: AppTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Upcoming Card
                    Expanded(
                      child: _buildBentoCard(
                        context: context,
                        isDark: isDark,
                        icon: Icons.schedule_rounded,
                        label: 'Upcoming',
                        value: '$upcomingCount',
                        accentColor: const Color(0xFF0D9488),
                        hasLiveDot: upcomingCount > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total Invested Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salon Investment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PKR ${totalSpentPkr.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Fluid Theme Switcher Bento Card
                Text(
                  'APPEARANCE & THEME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderOf(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Theme Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryOf(context),
                            ),
                          ),
                          Text(
                            themeProvider.themeMode == ThemeMode.system
                                ? 'Auto (System)'
                                : (themeProvider.themeMode == ThemeMode.dark
                                    ? 'Dark Mode'
                                    : 'Light Mode'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Fluid 3-Option Draggable Sliding Pill
                      FluidSegmentedPill(
                        selectedIndex: themeProvider.themeMode == ThemeMode.system
                            ? 0
                            : (themeProvider.themeMode == ThemeMode.light ? 1 : 2),
                        height: 48,
                        items: const [
                          FluidPillItem(
                            label: 'System',
                            icon: Icons.brightness_auto_rounded,
                          ),
                          FluidPillItem(
                            label: 'Light',
                            icon: Icons.light_mode_rounded,
                          ),
                          FluidPillItem(
                            label: 'Dark',
                            icon: Icons.dark_mode_rounded,
                          ),
                        ],
                        onSelectionChanged: (index) {
                          final mode = index == 0
                              ? ThemeMode.system
                              : (index == 1 ? ThemeMode.light : ThemeMode.dark);
                          themeProvider.setThemeMode(mode);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Salon Info & Business Hours
                Text(
                  'SALON INFORMATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderOf(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppTheme.primaryAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                                ),
                                Text(
                                  '10:00 – 18:00 PKT (Mon – Sat)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sun Closed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppTheme.primaryAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                                ),
                                Text(
                                  'Salon Luxe, Clifton Block 4, Karachi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            size: 18,
                            color: AppTheme.primaryAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timezone Engine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                                ),
                                Text(
                                  'Asia/Karachi (${TimezoneUtil.timezoneLabel} UTC+5)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Action Button
                InkWell(
                  onTap: () => _confirmSignOut(context, auth),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out of Salon Luxe',
                          style: TextStyle(
                            fontSize: 14,
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
          ),
        ),
    );
  }


  Widget _buildBentoCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    bool hasLiveDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              if (hasLiveDot)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D9488),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
