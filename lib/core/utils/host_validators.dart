/// Shared form validators for the host module.
///
/// Each returns `null` when the value is valid, otherwise the error message to
/// show under the field (compatible with `TextFormField.validator`).
class HostValidators {
  HostValidators._();

  static final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _mobileRe = RegExp(r'^[6-9]\d{9}$');
  // GSTIN: 2-digit state code, 10-char PAN, entity digit, 'Z', checksum char.
  static final RegExp _gstRe =
      RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  static final RegExp _panRe = RegExp(r'^[A-Z]{5}\d{4}[A-Z]$');
  static final RegExp _postalRe = RegExp(r'^\d{6}$');

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    return _emailRe.hasMatch(v) ? null : 'Enter a valid email address';
  }

  /// Indian 10-digit mobile number.
  static String? mobile(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Mobile number is required';
    return _mobileRe.hasMatch(v) ? null : 'Enter a valid 10-digit mobile number';
  }

  static String? gstNumber(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'GST number is required';
    return _gstRe.hasMatch(v) ? null : 'Enter a valid 15-character GST number';
  }

  static String? panNumber(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'PAN number is required';
    return _panRe.hasMatch(v) ? null : 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
  }

  static String? postalCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Postal code is required';
    return _postalRe.hasMatch(v) ? null : 'Enter a valid 6-digit postal code';
  }

  /// Positive whole or decimal amount, e.g. a price.
  static String? amount(String? value, [String field = 'Amount']) {
    final v = value?.replaceAll(',', '').trim() ?? '';
    if (v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid $field';
    return null;
  }
}


********************************************************************************
================================================================================
