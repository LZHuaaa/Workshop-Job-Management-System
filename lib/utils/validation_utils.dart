class ValidationUtils {
  // VIN validation - exactly 17 characters, alphanumeric (excluding I, O, Q)
  static String? validateVIN(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter VIN';
    }
    
    final cleanVin = value.trim().toUpperCase();
    
    if (cleanVin.length != 17) {
      return 'VIN must be exactly 17 characters';
    }
    
    // VIN uses all letters and numbers except I, O, Q
    final vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    if (!vinRegex.hasMatch(cleanVin)) {
      return 'VIN contains invalid characters (I, O, Q not allowed)';
    }
    
    return null;
  }
  
  // License plate validation - basic format validation
  static String? validateLicensePlate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter license plate';
    }
    
    final cleanPlate = value.trim().toUpperCase();
    
    if (cleanPlate.length < 2 || cleanPlate.length > 10) {
      return 'License plate must be 2-10 characters';
    }
    
    // Allow letters, numbers, spaces, and hyphens
    final plateRegex = RegExp(r'^[A-Z0-9\s\-]+$');
    if (!plateRegex.hasMatch(cleanPlate)) {
      return 'License plate contains invalid characters';
    }
    
    return null;
  }
  
  // Phone number validation - flexible format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Phone number must be 10-15 digits';
    }
    
    // Allow only digits after cleaning
    final phoneRegex = RegExp(r'^\d+$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Phone number must contain only digits';
    }
    
    return null;
  }
  
  // Email validation - proper regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email address';
    }
    
    final cleanEmail = value.trim().toLowerCase();
    
    // RFC 5322 compliant email regex (simplified)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(cleanEmail)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Year validation
  static String? validateYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter year';
    }
    
    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Year must be a number';
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Year must be between 1900 and ${currentYear + 1}';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }
  
  // Mileage validation
  static String? validateMileage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mileage';
    }
    
    final mileage = int.tryParse(value.trim());
    if (mileage == null) {
      return 'Mileage must be a number';
    }
    
    if (mileage < 0 || mileage > 999999) {
      return 'Mileage must be between 0 and 999,999';
    }
    
    return null;
  }
  
  // Name validation (for make, model, color, customer name)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }

    final cleanName = value.trim();
    if (cleanName.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (cleanName.length > 50) {
      return '$fieldName must be less than 50 characters';
    }

    // Allow letters, numbers, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\-']+$");
    if (!nameRegex.hasMatch(cleanName)) {
      return '$fieldName contains invalid characters';
    }

    return null;
  }

  // Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Password strength checker
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;

    return PasswordStrength(
      score: score,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
    );
  }
}

class PasswordStrength {
  final int score;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  PasswordStrength({
    required this.score,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  double get strengthPercentage => score / 5.0;

  bool get isStrong => score >= 5;

  String get strengthText {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }
}
