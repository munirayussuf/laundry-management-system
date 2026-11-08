import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_service_app/core/theme/app_theme.dart';
import 'package:laundry_service_app/core/widgets/app_widgets.dart';

void main() {
  testWidgets('long screen headers fit a narrow phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PinkAppBar(
            title: 'Laundry Provider Registration',
            subtitle: 'Set up your laundry profile',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('primary actions remain tappable on a compact phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: PremiumButton(
                label: 'Create Laundry Provider Profile',
                icon: Icons.storefront_outlined,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevatedButton)).height,
        greaterThanOrEqualTo(48));
    await tester.tap(find.byType(ElevatedButton));
    expect(pressed, isTrue);
  });

  testWidgets('bottom navigation stays accessible on narrow scaled screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          bottomNavigationBar: ResponsiveBottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shops'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.support), label: 'Support'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Home'));
    expect(selectedIndex, 0);
  });
}
