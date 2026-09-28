import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PaymentProcessingDialog extends StatefulWidget {
  final Future<void> Function() onProcess;
  final VoidCallback onSuccess;
  final void Function(dynamic error) onError;

  const PaymentProcessingDialog({
    super.key,
    required this.onProcess,
    required this.onSuccess,
    required this.onError,
  });

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function() onProcess,
    required VoidCallback onSuccess,
    required void Function(dynamic error) onError,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PaymentProcessingDialog(
        onProcess: onProcess,
        onSuccess: onSuccess,
        onError: onError,
      ),
    );
  }

  @override
  State<PaymentProcessingDialog> createState() => _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Connecting, 1: Authorizing, 2: Verified
  late AnimationController _animController;
  Timer? _stepTimer;
  bool _processDone = false;
  dynamic _processError;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Securing Gateway Connection',
      'subtitle': '256-bit TLS encrypted session',
      'icon': Icons.lock_outline_rounded,
    },
    {
      'title': 'Contacting Payment Network',
      'subtitle': 'Authorizing transaction with bank',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'title': 'Payment Verified',
      'subtitle': 'Reservation secured successfully',
      'icon': Icons.check_circle_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _runProcessAndSteps();
  }

  Future<void> _runProcessAndSteps() async {
    // 1. Kick off the actual backend / Firestore transaction
    widget.onProcess().then((_) {
      _processDone = true;
    }).catchError((err) {
      _processError = err;
    });

    // Step 0: Initial connecting (600ms)
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_processError != null) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onError(_processError);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _currentStep = 1);

    // Step 1: Bank authorization (700ms)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_processError != null) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onError(_processError);
      return;
    }

    // Wait until backend process is done if still running
    while (!_processDone && _processError == null && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    if (_processError != null) {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onError(_processError);
      return;
    }

    // Step 2: Verified!
    HapticFeedback.mediumImpact();
    setState(() => _currentStep = 2);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    widget.onSuccess();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radar Pulse Spinner or Success Icon
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentStep < 2) ...[
                      RotationTransition(
                        turns: _animController,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                              width: 3,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.shield_outlined,
                        color: AppTheme.primaryAccent,
                        size: 32,
                      ),
                    ] else ...[
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF16A34A),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 36,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step Title & Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey(_currentStep),
                  children: [
                    Text(
                      _steps[_currentStep]['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _steps[_currentStep]['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Progress Indicator Steps
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == _currentStep;
                  final isDone = index < _currentStep;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF16A34A)
                          : (isActive ? AppTheme.primaryAccent : AppTheme.borderOf(context)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
