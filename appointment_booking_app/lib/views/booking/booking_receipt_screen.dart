import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/payment_badge.dart';
import '../../models/booking_model.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';

class BookingReceiptScreen extends StatefulWidget {
  final BookingModel booking;
  final StaffModel? staff;

  const BookingReceiptScreen({
    super.key,
    required this.booking,
    this.staff,
  });

  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen> {
  final GlobalKey _receiptBoundaryKey = GlobalKey();
  bool _isExporting = false;

  Rect _getSharePositionOrigin(BuildContext context) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
        final origin = box.localToGlobal(Offset.zero);
        return Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height / 2);
      }
    } catch (_) {}
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width * 0.1, size.height * 0.4, size.width * 0.8, size.height * 0.2);
  }

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      final boundary = _receiptBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 60));
      }

      // 3.0 pixelRatio produces a crisp, high-resolution retina receipt
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt image: $e');
      return null;
    }
  }

  Future<void> _handleSaveToDevice() async {
    if (_isExporting) return;
    final origin = _getSharePositionOrigin(context);
    setState(() => _isExporting = true);

    try {
      final bytes = await _captureReceiptPng();
      if (bytes == null) {
        if (mounted) AppSnackBar.showError(context, 'Could not generate receipt image.');
        return;
      }

      final fileName = 'Receipt_${widget.booking.bookingId}.png';
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      HapticFeedback.mediumImpact();

      if (Platform.isIOS) {
        await Share.shareXFiles(
          [
            XFile(
              file.path,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          subject: 'LUMEN Salon Receipt - ${widget.booking.bookingId}',
          sharePositionOrigin: origin,
        );
        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            'Receipt ready! Tap "Save Image" to add to Photos or "Save to Files".',
          );
        }
      } else {
        Directory? androidDir;
        try {
          androidDir = await getExternalStorageDirectory();
        } catch (_) {}
        androidDir ??= docDir;

        final androidFile = File('${androidDir.path}/$fileName');
        await androidFile.writeAsBytes(bytes, flush: true);

        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            'Receipt saved to device documents ($fileName)',
          );
        }
      }
    } catch (e) {
      debugPrint('Save to device error: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save receipt image to device.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShareReceipt() async {
    if (_isExporting) return;
    final origin = _getSharePositionOrigin(context);
    setState(() => _isExporting = true);

    try {
      final bytes = await _captureReceiptPng();
      if (bytes == null) {
        if (mounted) AppSnackBar.showError(context, 'Could not generate receipt image.');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'Receipt_${widget.booking.bookingId}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      HapticFeedback.lightImpact();
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        text: 'Appointment Receipt - ${widget.booking.serviceName} at LUMEN Atelier (REF: ${widget.booking.bookingId})',
        subject: 'LUMEN Salon Receipt - ${widget.booking.bookingId}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('Share receipt error: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to open share sheet.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final booking = widget.booking;
    final user = context.watch<AuthProvider>().user;
    final clientName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Valued Client');
    final clientEmail = user?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Official Receipt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              tooltip: 'Share Receipt',
              onPressed: _isExporting ? null : _handleShareReceipt,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: RepaintBoundary(
                    key: _receiptBoundaryKey,
                    child: _buildLuxuryReceiptCard(
                      context,
                      isDark: isDark,
                      booking: booking,
                      clientName: clientName,
                      clientEmail: clientEmail,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppTheme.borderOf(context), width: 1.2),
                      ),
                      onPressed: _isExporting ? null : _handleShareReceipt,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomButton(
                      text: 'Save to Device',
                      icon: Icons.download_rounded,
                      isLoading: _isExporting,
                      onPressed: _isExporting ? null : _handleSaveToDevice,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryReceiptCard(
    BuildContext context, {
    required bool isDark,
    required BookingModel booking,
    required String clientName,
    required String clientEmail,
  }) {
    final isPaidOnline = booking.paymentStatus == 'paid';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Receipt Top Accent Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF21262D), const Color(0xFF161B22)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      isPaidOnline ? 'OFFICIALLY PAID & CONFIRMED' : 'RESERVATION CONFIRMED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                Text(
                  TimezoneUtil.formatDate(booking.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon Brand & Emblem
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFA67C00)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.spa_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'LUMEN ATELIER & SALON',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Haute Coiffure & Aesthetic Lounge',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'F-7/2, Jinnah Super, Islamabad • +92 (51) 844-5500',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Perforated Divider
                _buildPerforatedDivider(isDark),
                const SizedBox(height: 16),

                // Reference & Transaction IDs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBlock(
                      'BOOKING REF',
                      booking.bookingId,
                      context,
                      isBold: true,
                      color: AppTheme.primaryAccent,
                    ),
                    _infoBlock(
                      'TRANSACTION ID',
                      booking.transactionId,
                      context,
                      isBold: true,
                      crossAlign: CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Client Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBlock('CLIENT NAME', clientName, context),
                    if (clientEmail.isNotEmpty)
                      _infoBlock(
                        'ACCOUNT EMAIL',
                        clientEmail,
                        context,
                        crossAlign: CrossAxisAlignment.end,
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Perforated Divider
                _buildPerforatedDivider(isDark),
                const SizedBox(height: 16),

                // Appointment Particulars Header
                Text(
                  'APPOINTMENT DETAILS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 10),

                // Service & Stylist rows
                _receiptRow('Service', booking.serviceName, context, isBold: true),
                const SizedBox(height: 6),
                _receiptRow('Specialist', booking.staffName, context),
                const SizedBox(height: 6),
                _receiptRow('Date', TimezoneUtil.formatDate(booking.startAt), context),
                const SizedBox(height: 6),
                _receiptRow(
                  'Time Window',
                  '${TimezoneUtil.formatTimeOnly(booking.startAt)} – ${TimezoneUtil.formatTimeOnly(booking.endAt)} (${TimezoneUtil.timezoneLabel} UTC+5)',
                  context,
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _receiptRow('Special Note', booking.notes!, context),
                ],

                const SizedBox(height: 14),
                _buildPerforatedDivider(isDark),
                const SizedBox(height: 16),

                // Financial Breakdown
                Text(
                  'PAYMENT BREAKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 10),

                _receiptRow('Service Subtotal', booking.formattedPrice, context),
                const SizedBox(height: 6),
                _receiptRow('Reservation & App Fee', 'PKR 0 (Free)', context),
                const SizedBox(height: 6),
                _receiptRow('Taxes & Surcharge', 'Included in Price', context),
                const SizedBox(height: 6),
                _receiptRow(
                  'Payment Method',
                  booking.paymentDetails ?? booking.paymentMethod.toUpperCase(),
                  context,
                ),
                const Divider(height: 20),

                // Grand Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAID',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      booking.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Status Badge
                Row(
                  children: [
                    PaymentBadge.fromMethod(booking.paymentMethod, size: 24),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaidOnline
                            ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                            : const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPaidOnline ? 'STATUS: PAID (Online Gateway)' : 'STATUS: PAY AT SALON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isPaidOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Digital Check-in Barcode Simulation
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(40, (i) {
                            final isThick = i % 3 == 0;
                            final isSkip = i % 7 == 0;
                            if (isSkip) return const SizedBox(width: 3);
                            return Container(
                              width: isThick ? 3.0 : 1.5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              color: isDark ? Colors.white70 : Colors.black87,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '* ${booking.bookingId} *',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Courier',
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Present this digital barcode at salon reception for seamless check-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedDivider(bool isDark) {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            height: 1,
            color: index % 2 == 0
                ? (isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1))
                : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(
    String label,
    String value,
    BuildContext context, {
    bool isBold = false,
    Color? color,
    CrossAxisAlignment crossAlign = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppTheme.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value, BuildContext context, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryOf(context),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
