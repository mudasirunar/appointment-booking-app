import 'package:flutter/material.dart';
import '../../core/widgets/floating_glass_nav_bar.dart';
import '../catalog/services_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  /// Global key or static state reference for tab switching
  static final GlobalKey<MainNavigationShellState> globalKey =
      GlobalKey<MainNavigationShellState>();
  static MainNavigationShellState? instance;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  /// Static helper to switch tabs from anywhere in the app
  static void switchToTab(BuildContext? context, int tabIndex) {
    if (instance != null) {
      instance!.setTab(tabIndex);
      return;
    }
    if (globalKey.currentState != null) {
      globalKey.currentState!.setTab(tabIndex);
      return;
    }
    if (context != null) {
      final state = context.findAncestorStateOfType<MainNavigationShellState>();
      state?.setTab(tabIndex);
    }
  }

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    MainNavigationShell.instance = this;
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    if (MainNavigationShell.instance == this) {
      MainNavigationShell.instance = null;
    }
    super.dispose();
  }

  void setTab(int index) {
    if (index >= 0 && index <= 2) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack preserves scroll offsets and state across all 3 tabs
          IndexedStack(
            index: _currentIndex,
            children: [
              ServicesScreen(
                onNavigateToBookings: () => setTab(1),
              ),
              MyBookingsScreen(
                onExploreServices: () => setTab(0),
              ),
              const ProfileScreen(),
            ],
          ),

          // Floating Glassmorphic Navigation Bar
          FloatingGlassNavBar(
            currentIndex: _currentIndex,
            onTabSelected: setTab,
          ),
        ],
      ),
    );
  }
}
