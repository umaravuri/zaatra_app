/// A booking as seen by the host (stay or event). Shaped like the API payload.
class HostBooking {
  final String id; // internal id, e.g. BK-1001
  final String confirmId; // shown to the host, e.g. 125487
  final String kind; // 'stay' | 'event'
  final String propertyName;
  final String unitName; // 'Deluxe room' / 'Main Hall 1'
  final String source; // 'Direct Booking' | 'Zaatra'
  final String status; // 'upcoming' | 'active' | 'completed' | 'cancelled'
  final String customerName;
  final String mobile;
  final String eventType; // events only
  final int guests;
  final String bookingDate;
  final String startText; // e.g. '10th Oct 2026 , 10:00 AM'
  final String endText;
  final String checkInLabel; // e.g. 'March 22 Check in 11:00 AM'
  final double total;
  final double advance;
  final String advanceMethod;
  final double paid;
  final double due;
  final String balanceDueOn;
  final bool otp1Done; // check-in OTP confirmed
  final bool otp2Done; // check-out / completion OTP confirmed
  final bool reviewed;
  final String cancelReason;
  final String reference; // e.g. 4565

  const HostBooking({
    required this.id,
    required this.confirmId,
    required this.kind,
    required this.propertyName,
    required this.unitName,
    this.source = 'Direct Booking',
    required this.status,
    required this.customerName,
    this.mobile = '',
    this.eventType = '',
    this.guests = 0,
    this.bookingDate = '',
    this.startText = '',
    this.endText = '',
    this.checkInLabel = '',
    required this.total,
    this.advance = 0,
    this.advanceMethod = '',
    this.paid = 0,
    this.due = 0,
    this.balanceDueOn = '',
    this.otp1Done = false,
    this.otp2Done = false,
    this.reviewed = false,
    this.cancelReason = '',
    this.reference = '',
  });

  bool get isEvent => kind == 'event';

  /// Label for the badge on an Active booking.
  String get otpBadge => status != 'active' ? '' : (otp1Done ? 'OTP 2 Due' : 'OTP 1 Due');

  factory HostBooking.fromMap(Map<String, dynamic> m) {
    double n(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    return HostBooking(
      id: '${m['id'] ?? ''}',
      confirmId: '${m['confirmId'] ?? ''}',
      kind: '${m['kind'] ?? 'stay'}',
      propertyName: '${m['propertyName'] ?? ''}',
      unitName: '${m['unitName'] ?? ''}',
      source: '${m['source'] ?? 'Direct Booking'}',
      status: '${m['status'] ?? 'upcoming'}',
      customerName: '${m['customerName'] ?? ''}',
      mobile: '${m['mobile'] ?? ''}',
      eventType: '${m['eventType'] ?? ''}',
      guests: (m['guests'] is num) ? (m['guests'] as num).toInt() : int.tryParse('${m['guests'] ?? ''}') ?? 0,
      bookingDate: '${m['bookingDate'] ?? ''}',
      startText: '${m['startText'] ?? ''}',
      endText: '${m['endText'] ?? ''}',
      checkInLabel: '${m['checkInLabel'] ?? ''}',
      total: n(m['total']),
      advance: n(m['advance']),
      advanceMethod: '${m['advanceMethod'] ?? ''}',
      paid: n(m['paid']),
      due: n(m['due']),
      balanceDueOn: '${m['balanceDueOn'] ?? ''}',
      otp1Done: m['otp1Done'] == true,
      otp2Done: m['otp2Done'] == true,
      reviewed: m['reviewed'] == true,
      cancelReason: '${m['cancelReason'] ?? ''}',
      reference: '${m['reference'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'confirmId': confirmId,
        'kind': kind,
        'propertyName': propertyName,
        'unitName': unitName,
        'source': source,
        'status': status,
        'customerName': customerName,
        'mobile': mobile,
        'eventType': eventType,
        'guests': guests,
        'bookingDate': bookingDate,
        'startText': startText,
        'endText': endText,
        'checkInLabel': checkInLabel,
        'total': total,
        'advance': advance,
        'advanceMethod': advanceMethod,
        'paid': paid,
        'due': due,
        'balanceDueOn': balanceDueOn,
        'otp1Done': otp1Done,
        'otp2Done': otp2Done,
        'reviewed': reviewed,
        'cancelReason': cancelReason,
        'reference': reference,
      };
}


********************************************************************************
================================================================================
