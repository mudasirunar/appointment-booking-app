import 'package:flutter/material.dart';

enum PaymentType {
  card,
  easypaisa,
  jazzcash,
  cash,
}

class PaymentBadge extends StatelessWidget {
  final PaymentType type;
  final double size;
  final bool showLabel;

  const PaymentBadge({
    super.key,
    required this.type,
    this.size = 28,
    this.showLabel = false,
  });

  factory PaymentBadge.fromMethod(String method, {double size = 28, bool showLabel = false}) {
    switch (method.toLowerCase()) {
      case 'card':
        return PaymentBadge(type: PaymentType.card, size: size, showLabel: showLabel);
      case 'easypaisa':
        return PaymentBadge(type: PaymentType.easypaisa, size: size, showLabel: showLabel);
      case 'jazzcash':
        return PaymentBadge(type: PaymentType.jazzcash, size: size, showLabel: showLabel);
      case 'cash':
      case 'pay_at_venue':
      default:
        return PaymentBadge(type: PaymentType.cash, size: size, showLabel: showLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    String label = '';

    switch (type) {
      case PaymentType.easypaisa:
        iconWidget = _buildEasyPaisaLogo(size);
        label = 'EasyPaisa';
        break;
      case PaymentType.jazzcash:
        iconWidget = _buildJazzCashLogo(size);
        label = 'JazzCash';
        break;
      case PaymentType.card:
        iconWidget = _buildCardLogo(size);
        label = 'Credit / Debit Card';
        break;
      case PaymentType.cash:
        iconWidget = _buildCashLogo(size);
        label = 'Pay at Venue';
        break;
    }

    if (!showLabel) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Official EasyPaisa Brand Icon (Utilizing transparent PNG with crisp luxury pill container)
  static Widget _buildEasyPaisaLogo(double h) {
    final w = h * 1.45;
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.symmetric(horizontal: h * 0.12, vertical: h * 0.08),
      decoration: BoxDecoration(
        color: Colors.white, // Crisp white base ensures transparent logo pops in dark & light modes
        borderRadius: BorderRadius.circular(h * 0.25),
        border: Border.all(color: const Color(0xFF00A859).withValues(alpha: 0.35), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A859).withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/payment_icons/easypaisa_icon.png',
          height: h * 0.82,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildEasyPaisaFallback(h),
        ),
      ),
    );
  }

  /// Official JazzCash Brand Icon (Utilizing transparent PNG with crisp luxury pill container)
  static Widget _buildJazzCashLogo(double h) {
    final w = h * 1.45;
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.symmetric(horizontal: h * 0.12, vertical: h * 0.08),
      decoration: BoxDecoration(
        color: Colors.white, // Crisp white base ensures transparent red/yellow logo pops cleanly
        borderRadius: BorderRadius.circular(h * 0.25),
        border: Border.all(color: const Color(0xFFE20613).withValues(alpha: 0.35), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE20613).withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/payment_icons/jazzcash_icon.png',
          height: h * 0.82,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildJazzCashFallback(h),
        ),
      ),
    );
  }

  /// Premium Credit / Debit Card Badge (Mastercard + Visa dual badge)
  static Widget _buildCardLogo(double h) {
    final w = h * 1.55;
    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(h * 0.25),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Overlapping Mastercard Circles
              SizedBox(
                width: 22,
                height: 16,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB001B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // VISA Typography
              const Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'sans-serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium Cash / Pay at Venue Badge
  static Widget _buildCashLogo(double h) {
    final w = h * 1.45;
    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF022C22)],
        ),
        borderRadius: BorderRadius.circular(h * 0.25),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_rounded,
                color: const Color(0xFF34D399),
                size: h * 0.55,
              ),
              const SizedBox(width: 3),
              Text(
                'CASH',
                style: TextStyle(
                  color: const Color(0xFF34D399),
                  fontWeight: FontWeight.w800,
                  fontSize: h * 0.36,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Graceful Fallback for EasyPaisa
  static Widget _buildEasyPaisaFallback(double h) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: h * 0.45,
            height: h * 0.45,
            decoration: const BoxDecoration(
              color: Color(0xFF00A859),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'e',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'easypaisa',
            style: TextStyle(
              color: Color(0xFF00A859),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Graceful Fallback for JazzCash
  static Widget _buildJazzCashFallback(double h) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: h * 0.45,
            height: h * 0.45,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC828),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'J',
                style: TextStyle(
                  color: Color(0xFFE20613),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'JazzCash',
            style: TextStyle(
              color: Color(0xFFE20613),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
