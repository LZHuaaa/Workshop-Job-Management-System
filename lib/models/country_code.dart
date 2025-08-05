class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  @override
  String toString() => '$flag $dialCode';

  String get displayName => '$flag $name ($dialCode)';
}

class CountryCodeService {
  static const List<CountryCode> countries = [
    CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    CountryCode(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    CountryCode(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    CountryCode(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
    CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
    CountryCode(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
    CountryCode(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
    CountryCode(name: 'Finland', code: 'FI', dialCode: '+358', flag: '🇫🇮'),
    CountryCode(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    CountryCode(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    CountryCode(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
    CountryCode(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
    CountryCode(name: 'Peru', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
    CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    CountryCode(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
    CountryCode(name: 'Morocco', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
    CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
    CountryCode(name: 'Israel', code: 'IL', dialCode: '+972', flag: '🇮🇱'),
    CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryCode(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
    CountryCode(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
    CountryCode(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    CountryCode(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
    CountryCode(name: 'Jordan', code: 'JO', dialCode: '+962', flag: '🇯🇴'),
    CountryCode(name: 'Lebanon', code: 'LB', dialCode: '+961', flag: '🇱🇧'),
    CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    CountryCode(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇰'),
    CountryCode(name: 'Myanmar', code: 'MM', dialCode: '+95', flag: '🇲🇲'),
    CountryCode(name: 'Cambodia', code: 'KH', dialCode: '+855', flag: '🇰🇭'),
    CountryCode(name: 'Laos', code: 'LA', dialCode: '+856', flag: '🇱🇦'),
    CountryCode(name: 'Brunei', code: 'BN', dialCode: '+673', flag: '🇧🇳'),
    CountryCode(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
    CountryCode(name: 'Fiji', code: 'FJ', dialCode: '+679', flag: '🇫🇯'),
  ];

  static CountryCode get defaultCountry => countries.first; // Malaysia

  static CountryCode? findByDialCode(String dialCode) {
    try {
      return countries.firstWhere((country) => country.dialCode == dialCode);
    } catch (e) {
      return null;
    }
  }

  static CountryCode? findByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  static List<CountryCode> searchCountries(String query) {
    if (query.isEmpty) return countries;
    
    final lowerQuery = query.toLowerCase();
    return countries.where((country) {
      return country.name.toLowerCase().contains(lowerQuery) ||
             country.dialCode.contains(query) ||
             country.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
