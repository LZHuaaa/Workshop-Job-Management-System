import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Tests', () {
    group('VIN Validation', () {
      test('should accept valid VIN', () {
        expect(ValidationUtils.validateVIN('1HGBH41JXMN109186'), isNull);
        expect(ValidationUtils.validateVIN('JH4TB2H26CC000000'), isNull);
      });

      test('should reject VIN with wrong length', () {
        expect(ValidationUtils.validateVIN('123456789'), isNotNull);
        expect(ValidationUtils.validateVIN('123456789012345678'), isNotNull);
      });

      test('should reject VIN with invalid characters', () {
        expect(ValidationUtils.validateVIN('1HGBH41JXMN10918I'), isNotNull); // Contains I
        expect(ValidationUtils.validateVIN('1HGBH41JXMN10918O'), isNotNull); // Contains O
        expect(ValidationUtils.validateVIN('1HGBH41JXMN10918Q'), isNotNull); // Contains Q
      });

      test('should reject empty VIN', () {
        expect(ValidationUtils.validateVIN(''), isNotNull);
        expect(ValidationUtils.validateVIN(null), isNotNull);
      });
    });

    group('License Plate Validation', () {
      test('should accept valid license plates', () {
        expect(ValidationUtils.validateLicensePlate('ABC 1234'), isNull);
        expect(ValidationUtils.validateLicensePlate('WXY-789'), isNull);
        expect(ValidationUtils.validateLicensePlate('AB123CD'), isNull);
      });

      test('should reject license plates with invalid length', () {
        expect(ValidationUtils.validateLicensePlate('A'), isNotNull);
        expect(ValidationUtils.validateLicensePlate('ABCDEFGHIJK'), isNotNull);
      });

      test('should reject empty license plate', () {
        expect(ValidationUtils.validateLicensePlate(''), isNotNull);
        expect(ValidationUtils.validateLicensePlate(null), isNotNull);
      });
    });

    group('Phone Number Validation', () {
      test('should accept valid phone numbers', () {
        expect(ValidationUtils.validatePhoneNumber('1234567890'), isNull);
        expect(ValidationUtils.validatePhoneNumber('(555) 123-4567'), isNull);
        expect(ValidationUtils.validatePhoneNumber('+1-555-123-4567'), isNull);
      });

      test('should reject phone numbers with invalid length', () {
        expect(ValidationUtils.validatePhoneNumber('123456789'), isNotNull); // Too short
        expect(ValidationUtils.validatePhoneNumber('1234567890123456'), isNotNull); // Too long
      });

      test('should reject phone numbers with letters', () {
        expect(ValidationUtils.validatePhoneNumber('555-CALL-NOW'), isNotNull);
      });

      test('should reject empty phone number', () {
        expect(ValidationUtils.validatePhoneNumber(''), isNotNull);
        expect(ValidationUtils.validatePhoneNumber(null), isNotNull);
      });
    });

    group('Email Validation', () {
      test('should accept valid emails', () {
        expect(ValidationUtils.validateEmail('test@example.com'), isNull);
        expect(ValidationUtils.validateEmail('user.name+tag@domain.co.uk'), isNull);
      });

      test('should reject invalid emails', () {
        expect(ValidationUtils.validateEmail('invalid-email'), isNotNull);
        expect(ValidationUtils.validateEmail('test@'), isNotNull);
        expect(ValidationUtils.validateEmail('@example.com'), isNotNull);
        expect(ValidationUtils.validateEmail('test..test@example.com'), isNotNull);
      });

      test('should reject empty email', () {
        expect(ValidationUtils.validateEmail(''), isNotNull);
        expect(ValidationUtils.validateEmail(null), isNotNull);
      });
    });

    group('Year Validation', () {
      test('should accept valid years', () {
        expect(ValidationUtils.validateYear('2020'), isNull);
        expect(ValidationUtils.validateYear('1950'), isNull);
        expect(ValidationUtils.validateYear('2024'), isNull);
      });

      test('should reject invalid years', () {
        expect(ValidationUtils.validateYear('1899'), isNotNull); // Too old
        expect(ValidationUtils.validateYear('2030'), isNotNull); // Too new
        expect(ValidationUtils.validateYear('abc'), isNotNull); // Not a number
      });

      test('should reject empty year', () {
        expect(ValidationUtils.validateYear(''), isNotNull);
        expect(ValidationUtils.validateYear(null), isNotNull);
      });
    });

    group('Mileage Validation', () {
      test('should accept valid mileage', () {
        expect(ValidationUtils.validateMileage('50000'), isNull);
        expect(ValidationUtils.validateMileage('0'), isNull);
        expect(ValidationUtils.validateMileage('999999'), isNull);
      });

      test('should reject invalid mileage', () {
        expect(ValidationUtils.validateMileage('-1'), isNotNull); // Negative
        expect(ValidationUtils.validateMileage('1000000'), isNotNull); // Too high
        expect(ValidationUtils.validateMileage('abc'), isNotNull); // Not a number
      });

      test('should reject empty mileage', () {
        expect(ValidationUtils.validateMileage(''), isNotNull);
        expect(ValidationUtils.validateMileage(null), isNotNull);
      });
    });

    group('Name Validation', () {
      test('should accept valid names', () {
        expect(ValidationUtils.validateName('Toyota', 'Make'), isNull);
        expect(ValidationUtils.validateName('John Doe', 'Customer Name'), isNull);
        expect(ValidationUtils.validateName("O'Connor", 'Name'), isNull);
      });

      test('should reject names with invalid length', () {
        expect(ValidationUtils.validateName('A', 'Name'), isNotNull); // Too short
        expect(ValidationUtils.validateName('A' * 51, 'Name'), isNotNull); // Too long
      });

      test('should reject empty names', () {
        expect(ValidationUtils.validateName('', 'Name'), isNotNull);
        expect(ValidationUtils.validateName(null, 'Name'), isNotNull);
      });
    });
  });
}
