import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_booking_app/core/utils/timezone_util.dart';
import 'package:appointment_booking_app/models/service_model.dart';
import 'package:appointment_booking_app/models/slot_model.dart';
import 'package:appointment_booking_app/models/booking_model.dart';
import 'package:appointment_booking_app/services/booking_service.dart';
import 'package:appointment_booking_app/providers/theme_provider.dart';
import 'package:appointment_booking_app/core/widgets/floating_glass_nav_bar.dart';
import 'package:appointment_booking_app/core/widgets/app_dialog.dart';
import 'package:appointment_booking_app/core/widgets/fluid_segmented_pill.dart';

void main() {
  group('Timezone & Domain Tests (Asia/Karachi PKT UTC+5)', () {
    test('14 calendar days generation returns exactly 14 dates', () {
      final days = TimezoneUtil.get14CalendarDays();
      expect(days.length, 14);
      expect(days.first.isBefore(days.last), isTrue);
    });

    test('Sunday detection works accurately', () {
      // Find any Sunday in the 14-day window
      final days = TimezoneUtil.get14CalendarDays();
      final sundays = days.where((d) => TimezoneUtil.isSunday(d)).toList();
      expect(sundays.isNotEmpty, isTrue);
      for (final sunday in sundays) {
        expect(sunday.weekday, DateTime.sunday);
        expect(TimezoneUtil.isSunday(sunday), isTrue);
      }
    });

    test('ServiceModel serialization and formatting', () {
      final service = ServiceModel(
        id: 'service_haircut_styling',
        name: 'Haircut & Styling',
        description: 'Precision scissor cut',
        durationMinutes: 30,
        pricePkr: 2500,
        imageUrl: 'https://example.com/haircut.jpg',
      );

      expect(service.formattedPrice, 'PKR 2,500');
      expect(service.displayImageUrl, 'https://example.com/haircut.jpg');

      final json = service.toJson();
      final fromJson = ServiceModel.fromJson(json);
      expect(fromJson.id, service.id);
      expect(fromJson.name, service.name);
      expect(fromJson.pricePkr, 2500);
      expect(fromJson.durationMinutes, 30);
    });

    test('SlotModel formatting and past status', () {
      final futureStart = DateTime.now().toUtc().add(const Duration(days: 2));
      final futureEnd = futureStart.add(const Duration(minutes: 30));

      final slot = SlotModel(
        id: 'staff_1_2026-09-27T10:00:00Z',
        staffId: 'staff_1',
        staffName: 'Hamza Khan',
        startAt: futureStart,
        endAt: futureEnd,
        isReserved: false,
      );

      expect(slot.isPast, isFalse);
      expect(slot.formattedTime.contains(TimezoneUtil.timezoneLabel), isTrue);
    });

    test('BookingModel serialization and formatted values', () {
      final now = DateTime.now().toUtc();
      final start = now.add(const Duration(days: 1));
      final end = start.add(const Duration(minutes: 30));

      final booking = BookingModel(
        bookingId: 'BK-TEST01',
        slotId: 'staff_1_slot_123',
        serviceId: 'service_haircut_styling',
        serviceName: 'Haircut & Styling',
        servicePricePkr: 2500,
        staffId: 'staff_1',
        staffName: 'Hamza Khan',
        startAt: start,
        endAt: end,
        status: BookingStatus.upcoming,
        createdAt: now,
        notes: 'Low fade on sides please',
      );

      expect(booking.formattedPrice, 'PKR 2,500');
      expect(booking.notes, 'Low fade on sides please');
      expect(booking.status, BookingStatus.upcoming);

      final json = booking.toJson();
      expect(json['bookingId'], 'BK-TEST01');
      expect(json['servicePricePkr'], 2500);
      expect(json['notes'], 'Low fade on sides please');
    });

    test('BookingConflictException and PastSlotException have descriptive messages', () {
      final conflict = BookingConflictException();
      expect(conflict.message.contains('booked by another client'), isTrue);

      final past = PastSlotException();
      expect(past.message.contains('already passed'), isTrue);
    });

    test('ThemeProvider initializes with ThemeMode.system and updates mode', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      final themeProvider = ThemeProvider();
      expect(themeProvider.themeMode, ThemeMode.system);

      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    testWidgets('FloatingGlassNavBar renders tabs and handles selection and reselection', (tester) async {
      int selectedTab = 0;
      int? reselectedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingGlassNavBar(
              currentIndex: selectedTab,
              badgeCount: 2,
              onTabSelected: (index) {
                selectedTab = index;
              },
              onTabReselected: (index) {
                reselectedTab = index;
              },
            ),
          ),
        ),
      );

      // Verify labels render
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Bookings (tab 1)
      await tester.tap(find.text('Bookings'));
      // Pump animation
      await tester.pumpAndSettle();

      expect(selectedTab, 1);

      // Re-tap already active tab to trigger scroll to top
      await tester.tap(find.text('Services')); // Currently active in widget since currentIndex wasn't rebuilt
      await tester.pumpAndSettle();
      expect(reselectedTab, 0);
    });

    testWidgets('FloatingGlassNavBar handles fluid drag and switches tab only upon placement', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingGlassNavBar(
              currentIndex: selectedTab,
              onTabSelected: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );

      // Drag from center of tab 0 across towards tab 2
      // Start drag at Services (Tab 0) and drag to Profile (Tab 2)
      final servicesCenter = tester.getCenter(find.text('Services'));
      final profileCenter = tester.getCenter(find.text('Profile'));

      final gesture = await tester.startGesture(servicesCenter);
      await gesture.moveTo(profileCenter);
      await tester.pump();

      // While still dragging, the tab should not have committed yet
      expect(selectedTab, 0);

      // Finish drag / place pill
      await gesture.up();
      await tester.pumpAndSettle();

      // Now placed on tab 2
      expect(selectedTab, 2);
    });

    testWidgets('AppDialog displays centered icon, text, and balanced action buttons', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppDialog.show(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Sign Out Test',
                    description: 'Are you sure you want to sign out?',
                    cancelText: 'Cancel',
                    confirmText: 'Sign Out',
                    onConfirm: () {
                      confirmed = true;
                      Navigator.pop(context);
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify centered content and icon
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.text('Sign Out Test'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Tap confirm button in right corner
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Sign Out Test'), findsNothing);
    });

    testWidgets('FluidSegmentedPill handles fluid drag and commits selection only on placement', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: FluidSegmentedPill(
                  selectedIndex: selected,
                  items: const [
                    FluidPillItem(label: 'Upcoming (2)', icon: Icons.schedule_rounded),
                    FluidPillItem(label: 'Past (5)', icon: Icons.history_rounded),
                    FluidPillItem(label: 'Cancelled (1)', icon: Icons.cancel_outlined),
                  ],
                  onSelectionChanged: (index) {
                    selected = index;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify items render
      expect(find.text('Upcoming (2)'), findsOneWidget);
      expect(find.text('Past (5)'), findsOneWidget);
      expect(find.text('Cancelled (1)'), findsOneWidget);

      // Start drag from 'Upcoming' to 'Cancelled'
      final upcomingCenter = tester.getCenter(find.text('Upcoming (2)'));
      final cancelledCenter = tester.getCenter(find.text('Cancelled (1)'));

      final gesture = await tester.startGesture(upcomingCenter);
      await gesture.moveTo(cancelledCenter);
      await tester.pump();

      // While dragging, selection is not committed yet
      expect(selected, 0);

      // Finish drag / place pill
      await gesture.up();
      await tester.pumpAndSettle();

      // Placed on index 2
      expect(selected, 2);

      // Tap to switch to Past (index 1)
      await tester.tap(find.text('Past (5)'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('PageView swipe drives FluidSegmentedPill while pill dragging only navigates on release', (tester) async {
      final pageController = PageController(initialPage: 0);
      final isDraggingNotifier = ValueNotifier<bool>(false);
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    FluidSegmentedPill(
                      selectedIndex: selectedIndex,
                      pageController: pageController,
                      isPageDraggingNotifier: isDraggingNotifier,
                      items: const [
                        FluidPillItem(label: 'Page 0'),
                        FluidPillItem(label: 'Page 1'),
                        FluidPillItem(label: 'Page 2'),
                      ],
                      onSelectionChanged: (index) {
                        setState(() => selectedIndex = index);
                        pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis == Axis.horizontal) {
                            if (notification is ScrollStartNotification) {
                              if (notification.dragDetails != null) {
                                isDraggingNotifier.value = true;
                              }
                            } else if (notification is ScrollEndNotification) {
                              isDraggingNotifier.value = false;
                            }
                          }
                          return false;
                        },
                        child: PageView(
                          controller: pageController,
                          onPageChanged: (index) {
                            setState(() => selectedIndex = index);
                          },
                          children: const [
                            Center(child: Text('Screen Content 0')),
                            Center(child: Text('Screen Content 1')),
                            Center(child: Text('Screen Content 2')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Screen Content 0'), findsOneWidget);
      expect(selectedIndex, 0);

      // 1. Swipe the screen horizontally from Screen Content 0 to the left (moving to page 1)
      await tester.drag(find.text('Screen Content 0'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Page swiping successfully shifted the active tab and screen
      expect(selectedIndex, 1);
      expect(find.text('Screen Content 1'), findsOneWidget);

      // 2. Drag the pill at the top: dragging pill does not scroll page while being held
      final page1PillCenter = tester.getCenter(find.text('Page 1'));
      final page2PillCenter = tester.getCenter(find.text('Page 2'));

      final pillGesture = await tester.startGesture(page1PillCenter);
      await pillGesture.moveTo(page2PillCenter);
      await tester.pump();

      // Page is still on Page 1 while user is dragging the pill
      expect(pageController.page, 1.0);

      // Now place/release the pill
      await pillGesture.up();
      await tester.pumpAndSettle();

      // Page navigates to Page 2 upon placement
      expect(selectedIndex, 2);
      expect(find.text('Screen Content 2'), findsOneWidget);
    });
  });
}

