import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _otpController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyResetOtp(otp);

    if (success && mounted) {
      AppSnackBar.showSuccess(context, 'Code verified successfully.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else if (mounted) {
      AppSnackBar.showError(
        context,
        authProvider.errorMessage ?? 'Invalid verification code. Please check and try again.',
      );
    }
  }

  Future<void> _handleResend() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendResetOtp(widget.email);
    if (mounted) {
      if (success) {
        AppSnackBar.showSuccess(context, 'A new verification code has been sent.');
      } else {
        AppSnackBar.showError(
          context,
          authProvider.errorMessage ?? 'Failed to resend code. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyleOf(context),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceOf(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderOf(context)),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 28,
                        color: AppTheme.accentOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter Verification Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit verification code to:\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryOf(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _otpController,
                    label: '6-Digit Code',
                    hintText: '123456',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Verification code is required';
                      if (val.trim().length != 6) return 'Code must be exactly 6 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Code valid for 10 minutes',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                      ),
                      TextButton(
                        onPressed: authProvider.isOtpSending ? null : _handleResend,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: Text(
                          authProvider.isOtpSending ? 'Sending...' : 'Resend Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Verify Code',
                    isLoading: authProvider.isOtpVerifying,
                    onPressed: _handleVerify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
