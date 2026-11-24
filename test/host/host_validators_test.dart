import 'package:flutter_test/flutter_test.dart';
import 'package:zaatra_app/core/utils/host_validators.dart';

void main() {
  group('HostValidators.required', () {
    test('rejects null, empty and whitespace', () {
      expect(HostValidators.required(null, 'Name'), 'Name is required');
      expect(HostValidators.required('', 'Name'), 'Name is required');
      expect(HostValidators.required('   ', 'Name'), 'Name is required');
    });
    test('accepts text', () => expect(HostValidators.required('x'), isNull));
  });

  group('HostValidators.email', () {
    test('accepts a normal address', () => expect(HostValidators.email('a@b.co'), isNull));
    test('rejects bad addresses', () {
      expect(HostValidators.email(''), isNotNull);
      expect(HostValidators.email('abc'), isNotNull);
      expect(HostValidators.email('a@b'), isNotNull);
      expect(HostValidators.email('a b@c.com'), isNotNull);
    });
  });

  group('HostValidators.mobile', () {
    test('accepts 10 digits starting 6-9', () => expect(HostValidators.mobile('9876543210'), isNull));
    test('rejects others', () {
      expect(HostValidators.mobile('1234567890'), isNotNull);
      expect(HostValidators.mobile('98765'), isNotNull);
      expect(HostValidators.mobile(''), isNotNull);
    });
  });

  group('HostValidators.gstNumber / panNumber', () {
    test('valid GSTIN passes (case-insensitive)', () {
      expect(HostValidators.gstNumber('22AAAAA0000A1Z5'), isNull);
      expect(HostValidators.gstNumber('22aaaaa0000a1z5'), isNull);
    });
    test('invalid GSTIN fails', () {
      expect(HostValidators.gstNumber('22AAAAA0000A1Z'), isNotNull);
      expect(HostValidators.gstNumber(''), isNotNull);
    });
    test('PAN', () {
      expect(HostValidators.panNumber('ABCDE1234F'), isNull);
      expect(HostValidators.panNumber('abcde1234f'), isNull);
      expect(HostValidators.panNumber('ABCD1234F'), isNotNull);
      expect(HostValidators.panNumber(''), isNotNull);
    });
  });

  group('HostValidators.postalCode / amount', () {
    test('postal code is 6 digits', () {
      expect(HostValidators.postalCode('500081'), isNull);
      expect(HostValidators.postalCode('5000'), isNotNull);
    });
    test('amount must be a positive number', () {
      expect(HostValidators.amount('1,45,000'), isNull);
      expect(HostValidators.amount('0'), isNotNull);
      expect(HostValidators.amount('abc'), isNotNull);
      expect(HostValidators.amount(''), isNotNull);
    });
  });
}


********************************************************************************
================================================================================
