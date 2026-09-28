import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/timezone_util.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/payment_badge.dart';
import '../../core/widgets/payment_processing_dialog.dart';
import '../../models/service_model.dart';
import '../../models/staff_model.dart';
import '../../models/slot_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/availability_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';
import 'booking_success_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final ServiceModel service;
  final StaffModel staff;
  final SlotModel slot;
  final String? notes;

  const PaymentCheckoutScreen({
    super.key,
    required this.service,
    required this.staff,
    required this.slot,
    this.notes,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  PaymentType _selectedMethod = PaymentType.card;

  // Card Controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // EasyPaisa Controllers
  final _easyPaisaPhoneController = TextEditingController();
  final _easyPaisaNameController = TextEditingController();

  // JazzCash Controllers
  final _jazzCashPhoneController = TextEditingController();
  final _jazzCashNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  BookingModel? _createdBooking;

  @override
  void initState() {
    super.initState();
    // Default pre-fill for user's convenience
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final name = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : (user?.email?.split('@').first ?? 'Valued Client');
      _cardHolderController.text = name;
      _easyPaisaNameController.text = name;
      _jazzCashNameController.text = name;
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _easyPaisaPhoneController.dispose();
    _easyPaisaNameController.dispose();
    _jazzCashPhoneController.dispose();
    _jazzCashNameController.dispose();
    super.dispose();
  }

  String _generateTransactionId() {
    final randomDigits = Random().nextInt(900000) + 100000;
    return 'TXN-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-$randomDigits';
  }

  void _handlePay() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      AppSnackBar.showError(context, 'Please log in to finalize your booking.');
      return;
    }

    final bookingProvider = context.read<BookingProvider>();
    final transactionId = _generateTransactionId();

    String paymentStatus;
    String paymentMethod;
    String paymentDetails;

    switch (_selectedMethod) {
      case PaymentType.card:
        paymentStatus = 'paid';
        paymentMethod = 'card';
        final rawNum = _cardNumberController.text.replaceAll(' ', '');
        final last4 = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : '4242';
        final brand = rawNum.startsWith('5') ? 'Mastercard' : 'Visa';
        paymentDetails = '$brand ending in $last4';
        break;
      case PaymentType.easypaisa:
        paymentStatus = 'paid';
        paymentMethod = 'easypaisa';
        paymentDetails = 'EasyPaisa (${_easyPaisaPhoneController.text.trim()})';
        break;
      case PaymentType.jazzcash:
        paymentStatus = 'paid';
        paymentMethod = 'jazzcash';
        paymentDetails = 'JazzCash (${_jazzCashPhoneController.text.trim()})';
        break;
      case PaymentType.cash:
        paymentStatus = 'pay_at_venue';
        paymentMethod = 'cash';
        paymentDetails = 'Pay at Venue (Cash / POS)';
        break;
    }

    PaymentProcessingDialog.show(
      context: context,
      onProcess: () async {
        final booking = await bookingProvider.confirmBooking(
          uid: user.uid,
          slot: widget.slot,
          service: widget.service,
          staff: widget.staff,
          notes: widget.notes,
          paymentStatus: paymentStatus,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          amountPaid: widget.service.pricePkr,
          paymentDetails: paymentDetails,
        );
        _createdBooking = booking;
      },
      onSuccess: () {
        if (_createdBooking != null && mounted) {
          context.read<AvailabilityProvider>().clearSelection();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BookingSuccessScreen(
                booking: _createdBooking!,
                staff: widget.staff,
              ),
            ),
          );
        }
      },
      onError: (err) {
        if (!mounted) return;
        if (err is BookingConflictException) {
          _showConflictDialog();
        } else if (err is PastSlotException) {
          _showPastSlotDialog();
        } else {
          AppSnackBar.showError(
            context,
            'Transaction declined by bank network. Please check your details and try again.',
          );
        }
      },
    );
  }

  void _showConflictDialog() {
    AppDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Icons.event_busy_rounded,
      isDestructive: true,
      title: 'Slot No Longer Available',
      description:
          'Another client just confirmed this time slot at ${TimezoneUtil.formatTimeOnly(widget.slot.startAt)}. Please select another available slot.',
      showCancel: false,
      confirmText: 'Select Another Time',
      onConfirm: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Pop checkout
        Navigator.pop(context); // Return to slot selection
      },
    );
  }

  void _showPastSlotDialog() {
    AppDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Icons.history_rounded,
      title: 'Slot Has Passed',
      description:
          'This appointment time has already elapsed. Please pick an upcoming available slot.',
      showCancel: false,
      confirmText: 'Pick Another Time',
      onConfirm: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Pop checkout
        Navigator.pop(context); // Return to slot selection
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Secure Checkout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking mini summary header
                      _buildAppointmentSummaryHeader(isDark),
                      const SizedBox(height: 24),

                      // Payment Method Selector
                      Text(
                        'SELECT PAYMENT METHOD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMethodSelector(isDark),
                      const SizedBox(height: 24),

                      // Dynamic Payment Input Section
                      if (_selectedMethod == PaymentType.card) ...[
                        _buildInteractiveCardPreview(isDark),
                        const SizedBox(height: 20),
                        _buildCardForm(isDark),
                      ] else if (_selectedMethod == PaymentType.easypaisa) ...[
                        _buildEasyPaisaForm(isDark),
                      ] else if (_selectedMethod == PaymentType.jazzcash) ...[
                        _buildJazzCashForm(isDark),
                      ] else ...[
                        _buildCashNotice(isDark),
                      ],
                      const SizedBox(height: 24),

                      // Price Breakdown
                      _buildPriceBreakdown(isDark),
                      const SizedBox(height: 16),

                      // 256-bit encryption assurance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            '256-Bit SSL Encrypted & Bank Guaranteed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                        Text(
                          widget.service.formattedPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: CustomButton(
                        text: _selectedMethod == PaymentType.cash
                            ? 'Confirm Reservation'
                            : 'Pay ${widget.service.formattedPrice}',
                        icon: _selectedMethod == PaymentType.cash
                            ? Icons.check_circle_outline_rounded
                            : Icons.lock_outline_rounded,
                        onPressed: _handlePay,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentSummaryHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.spa_rounded, color: AppTheme.primaryAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.staff.name} • ${TimezoneUtil.formatDate(widget.slot.startAt)} at ${TimezoneUtil.formatTimeOnly(widget.slot.startAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark) {
    final methods = [
      {'type': PaymentType.card, 'label': 'Card', 'badge': PaymentBadge.fromMethod('card', size: 24)},
      {'type': PaymentType.easypaisa, 'label': 'EasyPaisa', 'badge': PaymentBadge.fromMethod('easypaisa', size: 24)},
      {'type': PaymentType.jazzcash, 'label': 'JazzCash', 'badge': PaymentBadge.fromMethod('jazzcash', size: 24)},
      {'type': PaymentType.cash, 'label': 'Pay at Venue', 'badge': PaymentBadge.fromMethod('cash', size: 24)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final m = methods[index];
        final type = m['type'] as PaymentType;
        final isSelected = _selectedMethod == type;

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedMethod = type);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryAccent.withValues(alpha: isDark ? 0.18 : 0.08)
                  : AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primaryAccent : AppTheme.borderOf(context),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                m['badge'] as Widget,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryAccent : AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryAccent),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveCardPreview(bool isDark) {
    final rawNumber = _cardNumberController.text.replaceAll(' ', '');
    final isMastercard = rawNumber.startsWith('5');
    final formattedCardNum = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final cardHolder = _cardHolderController.text.isEmpty
        ? 'CARDHOLDER NAME'
        : _cardHolderController.text.toUpperCase();
    final expiry = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFF020617),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Chip + Brand Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Metallic Chip
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37), Color(0xFFA67C00)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26, width: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              // Brand logo
              isMastercard
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEB001B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.2,
                      ),
                    ),
            ],
          ),

          // Card Number
          Text(
            formattedCardNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier',
            ),
          ),

          // Bottom: Holder & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cardHolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm(bool isDark) {
    return Column(
      children: [
        // Cardholder Name
        TextFormField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration('Cardholder Full Name', Icons.person_outline_rounded),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter cardholder name';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration('Card Number (16 digits)', Icons.credit_card_rounded),
          validator: (val) {
            final cleaned = val?.replaceAll(' ', '') ?? '';
            if (cleaned.length < 15) return 'Enter valid 16-digit card number';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Expiry & CVV Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _CardExpiryFormatter(),
                ],
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('MM/YY', Icons.calendar_today_outlined),
                validator: (val) {
                  if (val == null || val.length < 5) return 'Invalid expiry';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: _inputDecoration('CVV (3 digits)', Icons.security_rounded),
                validator: (val) {
                  if (val == null || val.length < 3) return 'Enter 3-digit CVV';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEasyPaisaForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PaymentBadge.fromMethod('easypaisa', size: 30),
              const SizedBox(width: 10),
              const Text(
                'EasyPaisa Mobile Account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _easyPaisaNameController,
            decoration: _inputDecoration('Account Title / Name', Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter account title';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _easyPaisaPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: _inputDecoration('EasyPaisa Number (e.g. 03001234567)', Icons.phone_android_rounded),
            validator: (val) {
              if (val == null || val.length != 11 || !val.startsWith('03')) {
                return 'Enter valid 11-digit mobile number (03XX...)';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Text(
            'A payment request will be sent to your EasyPaisa app for approval.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJazzCashForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE20613).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PaymentBadge.fromMethod('jazzcash', size: 30),
              const SizedBox(width: 10),
              const Text(
                'JazzCash Mobile Account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _jazzCashNameController,
            decoration: _inputDecoration('Account Title / Name', Icons.person_outline),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter account title';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _jazzCashPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: _inputDecoration('JazzCash Number (e.g. 03001234567)', Icons.phone_android_rounded),
            validator: (val) {
              if (val == null || val.length != 11 || !val.startsWith('03')) {
                return 'Enter valid 11-digit mobile number (03XX...)';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Text(
            'An MPIN verification prompt will be sent to your JazzCash registered SIM.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D3B36) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay at Salon Check-In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No advance deposit required. You can settle the bill via cash or terminal card swipe upon your arrival at the salon.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          _summaryRow('Service Subtotal', widget.service.formattedPrice),
          const SizedBox(height: 8),
          _summaryRow('Platform & Reservation Fee', 'FREE', isHighlight: true),
          const SizedBox(height: 8),
          _summaryRow('Taxes & Salon Surcharge', 'Included in Price'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount Due',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                widget.service.formattedPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isHighlight = false}) {
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
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isHighlight ? const Color(0xFF16A34A) : AppTheme.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondaryOf(context),
      ),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondaryOf(context)),
      filled: true,
      fillColor: AppTheme.surfaceOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
      ),
    );
  }
}

/// Helper formatter for spacing 16 card digits: 0000 0000 0000 0000
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

/// Helper formatter for card expiry: MM/YY
class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
