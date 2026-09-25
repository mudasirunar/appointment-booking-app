import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/app_empty_view.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_network_image.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/availability_provider.dart';
import 'staff_availability_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  String _getGreeting() {
    final nowPkt = TimezoneUtil.nowInPkt();
    final hour = nowPkt.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceOf(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(ctx),
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryOf(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondaryOf(ctx)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await authProvider.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final availability = context.watch<AvailabilityProvider>();
    final isDark = AppTheme.isDark(context);

    final user = authProvider.user;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Valued Client');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        body: RefreshIndicator(
          color: AppTheme.primaryAccent,
          onRefresh: () async {
            availability.refreshCatalog();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top App Bar & Greeting Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 16,
                    20,
                    20,
                  ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Salon Brand Badge
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.cardBackgroundDark : AppTheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isDark
                                        ? Border.all(color: AppTheme.borderSubtleDark)
                                        : null,
                                  ),
                                  child: const Icon(
                                    Icons.content_cut_rounded,
                                    size: 18,
                                    color: AppTheme.primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SALON LUXE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: AppTheme.textPrimaryOf(context),
                                      ),
                                    ),
                                    Text(
                                      'Karachi • PKT (UTC+5)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Header Action Buttons
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Sign Out',
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    size: 22,
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                                  onPressed: () => _confirmSignOut(context, authProvider),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Personalized Greeting Headline
                        Text(
                          '${_getGreeting()},',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Operating Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.borderOf(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Open Mon–Sat • 10:00 AM – 6:00 PM PKT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                              Text(
                                'Sunday Closed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section Title
                        Text(
                          'Our Signature Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Services List or State Views
                _buildCatalogBody(context, availability, isDark),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildCatalogBody(
    BuildContext context,
    AvailabilityProvider availability,
    bool isDark,
  ) {
    if (availability.isLoadingServices && availability.services.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, _) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildServiceSkeleton(isDark),
            ),
            childCount: 3,
          ),
        ),
      );
    }

    if (availability.errorMessage != null && availability.services.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorView(
          message: availability.errorMessage!,
          onRetry: availability.refreshCatalog,
        ),
      );
    }

    if (availability.services.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyView(
          icon: Icons.spa_outlined,
          title: 'No Services Available',
          message: 'Please check back shortly or refresh to reload available catalog.',
          actionText: 'Refresh Catalog',
          onAction: availability.refreshCatalog,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final service = availability.services[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 120)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1.0 - value) * 30),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildServiceCard(context, service, availability, isDark),
              ),
            );
          },
          childCount: availability.services.length,
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ServiceModel service,
    AvailabilityProvider availability,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        availability.selectService(service);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffAvailabilityScreen(service: service),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderOf(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Header with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AppNetworkImage(
                    imageUrl: service.displayImageUrl,
                    heroTag: 'service_${service.id}',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Subtle gradient overlay for contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                // Duration Badge (Top Right)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppTheme.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationMinutes} MINS',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Divider & Action Footer
                  Container(
                    height: 1,
                    color: AppTheme.borderOf(context),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRICE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppTheme.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.formattedPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),

                      // Golden Action CTA Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSkeleton(bool isDark) {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24282C) : const Color(0xFFE8EAEB),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
