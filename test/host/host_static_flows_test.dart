import 'package:flutter_test/flutter_test.dart';
import 'package:zaatra_app/models/host_booking_model.dart';
import 'package:zaatra_app/services/host_api_service.dart';

/// Exercises the host flows through HostApiService while it serves static data.
/// The static store is shared between tests, so each test uses its own records.
void main() {
  setUpAll(() => HostApiService.useStaticData = true);

  Future<List<HostBooking>> bookings(String status) async {
    final res = await HostApiService.getBookings(status);
    expect(res['success'], true);
    return (res['bookings'] as List)
        .map((e) => HostBooking.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  group('metadata and dashboard', () {
    test('wizard metadata has the lists the screens need', () async {
      final res = await HostApiService.getPropertiesMetadata();
      final m = res['metadata'] as Map;
      expect((m['categories'] as List).length, 11);
      expect(m['facilities'], isNotEmpty);
      expect(m['languages'], contains('English'));
      expect(m['unitTypes'], isNotEmpty);
    });

    test('dashboard returns the stay and event booking cards', () async {
      final res = await HostApiService.getDashboard();
      final list = (res['dashboard'] as Map)['recentBookings'] as List;
      expect(list.map((b) => (b as Map)['type']), containsAll(['stay', 'event']));
    });

    test('publish and wizard-step saves succeed', () async {
      expect((await HostApiService.saveWizardStep(step: 5))['success'], true);
      final pub = await HostApiService.publishProperty(propertyId: 'P1', price: 1000);
      expect(pub['success'], true);
    });
  });

  group('bookings', () {
    test('lists are split by status', () async {
      for (final status in ['active', 'upcoming', 'completed', 'cancelled']) {
        final list = await bookings(status);
        expect(list, isNotEmpty, reason: status);
        expect(list.every((b) => b.status == status), true);
      }
    });

    test('wrong PIN is rejected and does not change status', () async {
      final res = await HostApiService.verifyBookingOtp(
          bookingId: 'BK-1003', otpNumber: 1, otp: '0000');
      expect(res['success'], false);
      final b = HostBooking.fromMap(
          Map<String, dynamic>.from((await HostApiService.getBooking('BK-1003'))['booking'] as Map));
      expect(b.status, 'upcoming');
      expect(b.otp1Done, false);
    });

    test('OTP 1 activates and OTP 2 completes a booking', () async {
      final ok1 = await HostApiService.verifyBookingOtp(
          bookingId: 'BK-1004', otpNumber: 1, otp: '1234');
      expect(ok1['success'], true);
      expect((ok1['booking'] as Map)['status'], 'active');

      final ok2 = await HostApiService.verifyBookingOtp(
          bookingId: 'BK-1004', otpNumber: 2, otp: '1234');
      expect((ok2['booking'] as Map)['status'], 'completed');
    });

    test('collecting a payment reduces the amount due', () async {
      final before = HostBooking.fromMap(
          Map<String, dynamic>.from((await HostApiService.getBooking('BK-1001'))['booking'] as Map));
      final res = await HostApiService.collectPayment(
          bookingId: 'BK-1001', kind: 'balance', method: 'UPI', amount: 1000);
      expect(res['success'], true);
      expect(res['transactionId'], isNotEmpty);
      final after = HostBooking.fromMap(Map<String, dynamic>.from(res['booking'] as Map));
      expect(after.due, before.due - 1000);
      expect(after.paid, before.paid + 1000);
    });

    test('reviewing a customer marks the booking reviewed', () async {
      final res = await HostApiService.submitCustomerReview(
        bookingId: 'BK-1006',
        ratings: {'Respectful Behaviour': 5, 'On-time Payment': 4},
        comment: 'ok',
      );
      expect((res['booking'] as Map)['reviewed'], true);
    });

    test('cancelling moves a booking to Cancelled with the reason', () async {
      final res = await HostApiService.cancelBooking(
          bookingId: 'BK-1002', reason: 'No advance payment by customer');
      expect((res['booking'] as Map)['status'], 'cancelled');
      final cancelled = await bookings('cancelled');
      expect(cancelled.any((b) => b.id == 'BK-1002' && b.cancelReason.isNotEmpty), true);
    });

    test('an offline booking appears under Upcoming', () async {
      final res = await HostApiService.createOfflineBooking({
        'kind': 'event',
        'customerName': 'Test Customer',
        'mobile': '9876543210',
        'total': 8000,
        'advance': 4000,
        'advanceMethod': 'Cash',
      });
      expect(res['success'], true);
      final id = (res['booking'] as Map)['id'];
      expect((await bookings('upcoming')).any((b) => b.id == id && b.due == 4000), true);
    });

    test('unknown booking ids fail with a message', () async {
      final res = await HostApiService.getBooking('nope');
      expect(res['success'], false);
      expect(res['message'], isNotEmpty);
    });
  });

  group('availability and rates', () {
    test('seeded April 2026 has a booked and a blocked day', () async {
      final res = await HostApiService.getAvailability(hall: '', year: 2026, month: 4);
      expect(res['success'], true);
      final days = res['days'] as Map;
      expect(((days['2026-04-17'] as Map)['slot1'] as Map)['state'], 'zaatra');
      expect(((days['2026-04-15'] as Map)['slot1'] as Map)['state'], 'blocked');
    });

    test('blocking works, a booked day cannot be blocked, unblock reverts', () async {
      final ok = await HostApiService.blockDates(
          hall: 'Main Hall 1', dates: ['2026-05-10'], slots: [1, 2], reason: 'Festive');
      expect(ok['success'], true);
      var res = await HostApiService.getAvailability(hall: 'Main Hall 1', year: 2026, month: 5);
      expect((((res['days'] as Map)['2026-05-10'] as Map)['slot1'] as Map)['state'], 'blocked');

      final conflict = await HostApiService.blockDates(
          hall: 'Main Hall 1', dates: ['2026-04-17'], slots: [1], reason: 'Other');
      expect(conflict['success'], false);

      await HostApiService.unblockDates(hall: 'Main Hall 1', dates: ['2026-05-10'], slots: [1, 2]);
      res = await HostApiService.getAvailability(hall: 'Main Hall 1', year: 2026, month: 5);
      expect((((res['days'] as Map)['2026-05-10'] as Map)['slot1'] as Map)['state'], 'available');
    });

    test('slot timings are saved', () async {
      await HostApiService.setSlotTimings(slot1: '07:00 AM - 02:00 PM', slot2: '05:00 PM - 11:00 PM');
      final res = await HostApiService.getAvailability(hall: '', year: 2026, month: 4);
      expect((res['slotTimes'] as Map)['slot1'], '07:00 AM - 02:00 PM');
    });

    test('rate update applies to the whole range and rejects a reversed range', () async {
      final ok = await HostApiService.updateRates(
          hall: 'Main Hall 1', from: '2026-09-03', to: '2026-09-05', slot1: 91000, slot2: 92000);
      expect(ok['daysUpdated'], 3);
      final res = await HostApiService.getRates(hall: 'Main Hall 1', year: 2026, month: 9);
      expect(((res['days'] as Map)['2026-09-04'] as Map)['slot1'], 91000);
      expect(((res['days'] as Map)['2026-09-06'] as Map)['slot1'], isNot(91000));

      final bad = await HostApiService.updateRates(
          hall: 'Main Hall 1', from: '2026-09-05', to: '2026-09-03', slot1: 1, slot2: 1);
      expect(bad['success'], false);
    });
  });

  group('messages', () {
    test('lists and counts', () async {
      final all = await HostApiService.getConversations('all');
      final requests = await HostApiService.getConversations('requests');
      expect(all['allCount'], greaterThanOrEqualTo(requests['requestsCount'] as int));
      expect((requests['conversations'] as List).every((c) => (c as Map)['type'] == 'request'), true);
    });

    test('sending a message appends it', () async {
      final res = await HostApiService.sendMessage(conversationId: 'C-2', text: 'Yes, available');
      final msgs = (res['conversation'] as Map)['messages'] as List;
      expect((msgs.last as Map)['text'], 'Yes, available');
    });

    test('counter offer then accept turns the request into an upcoming booking', () async {
      final counter = await HostApiService.sendCounterOffer(
        conversationId: 'R-2',
        details: {'Event': 'Wedding', 'Time': '6:00 - 18:00', 'Hall': 'main Hall 1'},
        price: 8300,
        taxes: 4000,
      );
      expect(((counter['conversation'] as Map)['request'] as Map)['status'], 'countered');

      final upcomingBefore = (await bookings('upcoming')).length;
      final accept = await HostApiService.respondToRequest(conversationId: 'R-2', action: 'accept');
      expect(accept['success'], true);
      expect((await bookings('upcoming')).length, upcomingBefore + 1);

      final again = await HostApiService.respondToRequest(conversationId: 'R-2', action: 'decline');
      expect(again['success'], false); // already answered
    });

    test('declining closes a request', () async {
      final res = await HostApiService.respondToRequest(conversationId: 'R-1', action: 'decline');
      expect(((res['conversation'] as Map)['request'] as Map)['status'], 'declined');
    });
  });

  group('profile', () {
    test('update persists and notification toggles save', () async {
      await HostApiService.updateHostProfile(name: 'Manohar K', email: 'm@example.com');
      final p = (await HostApiService.getHostProfile())['profile'] as Map;
      expect(p['name'], 'Manohar K');

      await HostApiService.setNotificationPreferences({'promotions': true});
      final prefs = (await HostApiService.getNotificationPreferences())['preferences'] as Map;
      expect(prefs['promotions'], true);
    });
  });
}


********************************************************************************
================================================================================
