/// Service for decoding VIN numbers to extract vehicle information
class VinDecoderService {
  // World Manufacturer Identifier (WMI) codes - first 3 characters
  static const Map<String, String> _wmiCodes = {
    // Toyota
    '4T1': 'Toyota',
    '5TD': 'Toyota',
    'JTD': 'Toyota',
    'JTK': 'Toyota',
    'JTM': 'Toyota',
    'JTN': 'Toyota',
    
    // Honda
    '1HG': 'Honda',
    '2HG': 'Honda',
    '3HG': 'Honda',
    'JHM': 'Honda',
    'SHH': 'Honda',
    
    // Ford
    '1FA': 'Ford',
    '1FB': 'Ford',
    '1FC': 'Ford',
    '1FD': 'Ford',
    '1FM': 'Ford',
    '1FT': 'Ford',
    '3FA': 'Ford',
    
    // Chevrolet
    '1G1': 'Chevrolet',
    '1GC': 'Chevrolet',
    '1GN': 'Chevrolet',
    '2G1': 'Chevrolet',
    '3G1': 'Chevrolet',
    
    // BMW
    'WBA': 'BMW',
    'WBS': 'BMW',
    'WBY': 'BMW',
    '4US': 'BMW',
    '5UX': 'BMW',
    
    // Mercedes-Benz
    'WDD': 'Mercedes-Benz',
    'WDC': 'Mercedes-Benz',
    'WDF': 'Mercedes-Benz',
    '4JG': 'Mercedes-Benz',
    '55S': 'Mercedes-Benz',
    
    // Audi
    'WAU': 'Audi',
    'WA1': 'Audi',
    
    // Volkswagen
    'WVW': 'Volkswagen',
    '3VW': 'Volkswagen',
    '1VW': 'Volkswagen',
    
    // Nissan
    '1N4': 'Nissan',
    '1N6': 'Nissan',
    'JN1': 'Nissan',
    'JN8': 'Nissan',
    
    // Hyundai
    'KMH': 'Hyundai',
    'KMF': 'Hyundai',
    
    // Kia
    'KNA': 'Kia',
    'KND': 'Kia',
    
    // Mazda
    'JM1': 'Mazda',
    'JM3': 'Mazda',
    '4F2': 'Mazda',
    
    // Subaru
    'JF1': 'Subaru',
    'JF2': 'Subaru',
    '4S3': 'Subaru',
    '4S4': 'Subaru',
    
    // Lexus
    'JTH': 'Lexus',
    '2T2': 'Lexus',
    '58A': 'Lexus',
    
    // Acura
    '19U': 'Acura',
    'JH4': 'Acura',
    
    // Proton (Malaysia)
    'MHR': 'Proton',
    'PL1': 'Proton',
  };

  // Model year encoding (10th character)
  // Note: Letters repeat every 30 years, so we need to handle the cycle
  static int _getModelYear(String yearChar) {
    const firstCycle = {
      'A': 1980, 'B': 1981, 'C': 1982, 'D': 1983, 'E': 1984, 'F': 1985,
      'G': 1986, 'H': 1987, 'J': 1988, 'K': 1989, 'L': 1990, 'M': 1991,
      'N': 1992, 'P': 1993, 'R': 1994, 'S': 1995, 'T': 1996, 'V': 1997,
      'W': 1998, 'X': 1999, 'Y': 2000,
    };

    const numberCycle = {
      '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005,
      '6': 2006, '7': 2007, '8': 2008, '9': 2009,
    };

    const secondCycle = {
      'A': 2010, 'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014, 'F': 2015,
      'G': 2016, 'H': 2017, 'J': 2018, 'K': 2019, 'L': 2020, 'M': 2021,
      'N': 2022, 'P': 2023, 'R': 2024, 'S': 2025, 'T': 2026, 'V': 2027,
      'W': 2028, 'X': 2029, 'Y': 2030,
    };

    // Check number cycle first (2001-2009)
    if (numberCycle.containsKey(yearChar)) {
      return numberCycle[yearChar]!;
    }

    // For letters, assume second cycle (2010+) for recent vehicles
    if (secondCycle.containsKey(yearChar)) {
      return secondCycle[yearChar]!;
    }

    // Fallback to first cycle (1980-2000)
    return firstCycle[yearChar] ?? 0;
  }

  /// Decode VIN to extract vehicle information
  static VinDecodeResult decodeVin(String vin) {
    if (vin.length != 17) {
      return VinDecodeResult(
        isValid: false,
        error: 'VIN must be exactly 17 characters',
      );
    }

    final cleanVin = vin.toUpperCase().trim();
    
    // Validate VIN format
    final vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    if (!vinRegex.hasMatch(cleanVin)) {
      return VinDecodeResult(
        isValid: false,
        error: 'VIN contains invalid characters',
      );
    }

    try {
      // Extract WMI (World Manufacturer Identifier) - first 3 characters
      final wmi = cleanVin.substring(0, 3);
      final make = _wmiCodes[wmi];

      // Extract model year - 10th character
      final yearChar = cleanVin[9];
      final year = _getModelYear(yearChar);

      // Extract basic info
      return VinDecodeResult(
        isValid: true,
        vin: cleanVin,
        make: make,
        year: year,
        wmi: wmi,
        vds: cleanVin.substring(3, 9), // Vehicle Descriptor Section
        vis: cleanVin.substring(9), // Vehicle Identifier Section
      );
    } catch (e) {
      return VinDecodeResult(
        isValid: false,
        error: 'Failed to decode VIN: ${e.toString()}',
      );
    }
  }

  /// Get suggested models based on make (basic implementation)
  static List<String> getSuggestedModels(String make) {
    switch (make.toLowerCase()) {
      case 'toyota':
        return ['Camry', 'Corolla', 'RAV4', 'Highlander', 'Prius', 'Sienna', 'Tacoma', 'Tundra'];
      case 'honda':
        return ['Civic', 'Accord', 'CR-V', 'Pilot', 'Odyssey', 'Ridgeline', 'Passport', 'HR-V'];
      case 'ford':
        return ['F-150', 'Escape', 'Explorer', 'Mustang', 'Edge', 'Expedition', 'Ranger', 'Bronco'];
      case 'chevrolet':
        return ['Silverado', 'Equinox', 'Malibu', 'Traverse', 'Tahoe', 'Suburban', 'Camaro', 'Corvette'];
      case 'bmw':
        return ['3 Series', '5 Series', '7 Series', 'X3', 'X5', 'X7', 'Z4', 'i3'];
      case 'mercedes-benz':
        return ['C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE', 'GLS', 'A-Class', 'CLA'];
      case 'audi':
        return ['A3', 'A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7', 'Q8'];
      case 'volkswagen':
        return ['Jetta', 'Passat', 'Tiguan', 'Atlas', 'Golf', 'Beetle', 'Arteon', 'ID.4'];
      case 'nissan':
        return ['Altima', 'Sentra', 'Rogue', 'Pathfinder', 'Armada', 'Frontier', 'Titan', 'Leaf'];
      case 'hyundai':
        return ['Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'Palisade', 'Kona', 'Ioniq', 'Genesis'];
      case 'kia':
        return ['Forte', 'Optima', 'Sportage', 'Sorento', 'Telluride', 'Soul', 'Stinger', 'EV6'];
      case 'mazda':
        return ['Mazda3', 'Mazda6', 'CX-3', 'CX-5', 'CX-9', 'MX-5 Miata', 'CX-30', 'CX-50'];
      case 'subaru':
        return ['Impreza', 'Legacy', 'Outback', 'Forester', 'Ascent', 'WRX', 'BRZ', 'Crosstrek'];
      case 'lexus':
        return ['ES', 'IS', 'GS', 'LS', 'NX', 'RX', 'GX', 'LX'];
      case 'acura':
        return ['ILX', 'TLX', 'RLX', 'RDX', 'MDX', 'NSX', 'Integra', 'TLX Type S'];
      case 'proton':
        return ['Saga', 'Persona', 'Iriz', 'Exora', 'X50', 'X70', 'Perdana', 'Suprima S'];
      default:
        return [];
    }
  }

  /// Validate VIN checksum (9th character)
  static bool validateVinChecksum(String vin) {
    if (vin.length != 17) return false;

    const weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];
    const values = {
      'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
      'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9, 'S': 2,
      'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
      '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9
    };

    int sum = 0;
    for (int i = 0; i < 17; i++) {
      if (i == 8) continue; // Skip check digit position
      final char = vin[i];
      final value = values[char] ?? 0;
      sum += value * weights[i];
    }

    final checkDigit = sum % 11;
    final expectedChar = checkDigit == 10 ? 'X' : checkDigit.toString();
    
    return vin[8] == expectedChar;
  }
}

class VinDecodeResult {
  final bool isValid;
  final String? error;
  final String? vin;
  final String? make;
  final int? year;
  final String? wmi; // World Manufacturer Identifier
  final String? vds; // Vehicle Descriptor Section
  final String? vis; // Vehicle Identifier Section

  VinDecodeResult({
    required this.isValid,
    this.error,
    this.vin,
    this.make,
    this.year,
    this.wmi,
    this.vds,
    this.vis,
  });

  @override
  String toString() {
    if (!isValid) return 'Invalid VIN: $error';
    return 'VIN: $vin, Make: $make, Year: $year';
  }
}
