/// Which Trip Shared card applies to a ride.
///
/// The three stage names match the card variants on the Trip Shared screen:
/// `before_ride`, `during_ride` and `summary` (completed).
class TripStage {
  TripStage._();

  static const String beforeRide = 'before_ride';
  static const String duringRide = 'during_ride';
  static const String summary = 'summary';

  /// Maps a raw ride status (or an already-normalised stage name) to a stage.
  ///
  /// Whole-word matching, so e.g. `inactive`, `not_started` or `incomplete` are
  /// not mistaken for started / complete. Returns `null` when the status is
  /// cancelled (a cancelled ride has no card to open) or not recognised.
  static String? resolve(String? status) {
    final raw = (status ?? '').trim().toLowerCase();
    if (raw.isEmpty) return null;
    if (raw == beforeRide || raw == duringRide || raw == summary) return raw;

    final words = raw.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).toSet();
    bool has(List<String> w) => w.any(words.contains);

    if (has(['cancel', 'cancelled', 'canceled', 'denied', 'declined', 'rejected'])) return null;
    if (has(['completed', 'complete', 'finished', 'ended', 'done'])) return summary;
    if (words.contains('not') || words.contains('yet')) return beforeRide; // e.g. not_started
    if (has(['active', 'ongoing', 'started', 'boarding', 'live']) ||
        (words.contains('in') && words.contains('progress')) ||
        words.contains('inprogress') ||
        (words.contains('on') && words.contains('way'))) {
      return duringRide;
    }
    if (has(['upcoming', 'scheduled', 'pending', 'confirmed', 'published', 'open', 'new', 'requested'])) {
      return beforeRide;
    }
    return null;
  }

  /// First recognisable status in a ride / trip payload.
  static String? fromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final key in ['rideStatus', 'tripStatus', 'status', 'stage']) {
      final stage = resolve(data[key]?.toString());
      if (stage != null) return stage;
    }
    return null;
  }

  /// True when the ride is cancelled (no trip card should be offered).
  static bool isCancelled(Map<String, dynamic>? data) {
    if (data == null) return false;
    for (final key in ['rideStatus', 'tripStatus', 'status']) {
      final raw = (data[key] ?? '').toString().toLowerCase();
      if (RegExp(r'cancel').hasMatch(raw)) return true;
    }
    return false;
  }
}