import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaatra_app/services/host_api_service.dart';
import 'package:zaatra_app/views/screens/host_updated/host_updated.dart';

/// Pumps the main host screens on static data and checks the key behaviour.
void main() {
  setUpAll(() {
    HostApiService.useStaticData = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(412 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(milliseconds: 600));
  }

  // google_fonts logs a font-load error in tests; it must not fail the test.
  void ignoreFontErrors() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('google_fonts')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  setUp(ignoreFontErrors);

  testWidgets('Bookings list shows static bookings and switches tabs', (tester) async {
    await pump(tester, const Scaffold(body: HostBookingsListScreen()));
    expect(find.text('Booking'), findsWidgets);
    expect(find.textContaining('Confirm ID'), findsWidgets);

    // The 4th chip can be off-screen, so scroll the chip row to it first.
    await tester.dragUntilVisible(
      find.text('Cancelled'),
      find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal),
      const Offset(-200, 0),
    );
    await tester.tap(find.text('Cancelled'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Confirm ID'), findsWidgets);
  });

  testWidgets('Property name is required on wizard screen 10', (tester) async {
    await pump(tester, const HostScreen10PropertyNameRating(draft: HostUpdatedPropertyDraft()));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Property name is required'), findsOneWidget);
  });

  testWidgets('GST screen opens on Yes and validates the PAN', (tester) async {
    await pump(tester, const HostScreen22GstPurpose(draft: HostUpdatedPropertyDraft()));
    expect(find.text('Enter GST Number'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.textContaining('GST number is required'), findsOneWidget);
  });

  testWidgets('Registration requires the legitimacy checkbox', (tester) async {
    await pump(tester, const HostScreen24Registration(draft: HostUpdatedPropertyDraft()));
    await tester.tap(find.text('Complete Registratation'));
    await tester.pump();
    expect(find.textContaining('certify'), findsOneWidget);
  });

  testWidgets('Messages list loads and shows the Requests count', (tester) async {
    await pump(tester, const Scaffold(body: HostMessagesScreen()));
    expect(find.textContaining('Requests'), findsWidgets);
    expect(find.text('Ravi Sharma'), findsOneWidget);
  });
}
