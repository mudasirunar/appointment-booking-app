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

  final ScrollController _servicesScrollController = ScrollController();
  final ScrollController _profileScrollController = ScrollController();
  final GlobalKey<MyBookingsScreenState> _myBookingsKey =
      GlobalKey<MyBookingsScreenState>();

  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    MainNavigationShell.instance = this;
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _servicesScrollController.dispose();
    _profileScrollController.dispose();
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

  void _onTabReselected(int index) {
    switch (index) {
      case 0:
        if (_servicesScrollController.hasClients) {
          _servicesScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case 1:
        _myBookingsKey.currentState?.scrollToTop();
        break;
      case 2:
        if (_profileScrollController.hasClients) {
          _profileScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // IndexedStack preserves scroll offsets and state across all 3 tabs
          IndexedStack(
            index: _currentIndex,
            children: [
              ServicesScreen(
                scrollController: _servicesScrollController,
                onNavigateToBookings: () => setTab(1),
              ),
              MyBookingsScreen(
                key: _myBookingsKey,
                onExploreServices: () => setTab(0),
              ),
              ProfileScreen(
                scrollController: _profileScrollController,
              ),
            ],
          ),

          // Floating Glassmorphic Navigation Bar
          FloatingGlassNavBar(
            currentIndex: _currentIndex,
            onTabSelected: setTab,
            onTabReselected: _onTabReselected,
          ),
        ],
      ),
    );
  }
}
