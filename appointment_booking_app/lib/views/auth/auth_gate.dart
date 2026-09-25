import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import '../navigation/main_navigation_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (authProvider.status == AuthStatus.uninitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentOf(context),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated && authProvider.uid != null) {
      // Bind user listener to booking provider for isolated account updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookingProvider.bindUser(authProvider.uid!);
      });
      return MainNavigationShell();
    }

    // Immediately clear booking cache and listeners on sign out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bookingProvider.unbindUser();
    });

    return const LoginScreen();
  }
}
