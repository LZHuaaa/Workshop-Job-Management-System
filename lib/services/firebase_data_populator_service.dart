import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart' as sr;
import '../data/sample_data_generator.dart';
import 'customer_service.dart';
import 'vehicle_service.dart';
import 'service_record_service.dart';
import 'inventory_usage_data_populator.dart';

class FirebaseDataPopulatorService {
  static final FirebaseDataPopulatorService _instance =
      FirebaseDataPopulatorService._internal();
  factory FirebaseDataPopulatorService() => _instance;
  FirebaseDataPopulatorService._internal();

  final CustomerService _customerService = CustomerService();
  final VehicleService _vehicleService = VehicleService();
  final ServiceRecordService _serviceRecordService = ServiceRecordService();
  final Random _random = Random();

  // Malaysian sample data
  final List<Map<String, dynamic>> _malaysianCustomers = [
    {
      'firstName': 'Ahmad',
      'lastName': 'bin Abdullah',
      'email': 'ahmad.abdullah@email.com',
      'phone': '012-345-6789',
      'address': 'No. 15, Jalan Bukit Bintang',
      'city': 'Kuala Lumpur',
      'state': 'Wilayah Persekutuan',
      'zipCode': '50200',
    },
    {
      'firstName': 'Tan',
      'lastName': 'Mei Ling',
      'email': 'tan.meiling@email.com',
      'phone': '013-987-6543',
      'address': 'No. 88, Jalan Gurney',
      'city': 'George Town',
      'state': 'Penang',
      'zipCode': '10250',
    },
    {
      'firstName': 'Priya',
      'lastName': 'd/o Raman',
      'email': 'priya.raman@email.com',
      'phone': '014-456-7890',
      'address': 'No. 23, Jalan Sultan',
      'city': 'Petaling Jaya',
      'state': 'Selangor',
      'zipCode': '46200',
    },
    {
      'firstName': 'Muhammad',
      'lastName': 'bin Hassan',
      'email': 'muhammad.hassan@email.com',
      'phone': '015-234-5678',
      'address': 'No. 42, Jalan Duta',
      'city': 'Ipoh',
      'state': 'Perak',
      'zipCode': '30000',
    },
    {
      'firstName': 'Lim',
      'lastName': 'Chong Wei',
      'email': 'lim.chongwei@email.com',
      'phone': '016-789-0123',
      'address': 'No. 67, Jalan Ampang',
      'city': 'Kuala Lumpur',
      'state': 'Wilayah Persekutuan',
      'zipCode': '50450',
    },
    {
      'firstName': 'Fatima',
      'lastName': 'binti Omar',
      'email': 'fatima.omar@email.com',
      'phone': '017-345-6789',
      'address': 'No. 12, Jalan Mahkota',
      'city': 'Melaka',
      'state': 'Melaka',
      'zipCode': '75000',
    },
    {
      'firstName': 'Raj',
      'lastName': 'Kumar',
      'email': 'raj.kumar@email.com',
      'phone': '018-876-5432',
      'address': 'No. 89, Jalan Tunku Abdul Rahman',
      'city': 'Johor Bahru',
      'state': 'Johor',
      'zipCode': '80000',
    },
    {
      'firstName': 'Siti',
      'lastName': 'Nurhaliza',
      'email': 'siti.nurhaliza@email.com',
      'phone': '019-123-4567',
      'address': 'No. 56, Jalan Raja Laut',
      'city': 'Kuala Lumpur',
      'state': 'Wilayah Persekutuan',
      'zipCode': '50350',
    },
  ];

  final List<Map<String, dynamic>> _malaysianVehicles = [
    {
      'make': 'Proton',
      'models': ['Saga', 'Persona', 'Iriz', 'X50', 'X70', 'Exora']
    },
    {
      'make': 'Perodua',
      'models': ['Myvi', 'Axia', 'Bezza', 'Aruz', 'Alza', 'Viva']
    },
    {
      'make': 'Honda',
      'models': ['City', 'Civic', 'Accord', 'CR-V', 'HR-V', 'Jazz']
    },
    {
      'make': 'Toyota',
      'models': ['Vios', 'Camry', 'Corolla', 'Hilux', 'Fortuner', 'Innova']
    },
    {
      'make': 'Nissan',
      'models': ['Almera', 'Teana', 'X-Trail', 'Navara', 'Livina']
    },
    {
      'make': 'Mercedes-Benz',
      'models': ['C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE']
    },
    {
      'make': 'BMW',
      'models': ['3 Series', '5 Series', 'X3', 'X5', 'i3']
    },
  ];

  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Red',
    'Blue',
    'Grey',
    'Gold',
    'Maroon'
  ];

  final List<String> _mechanics = [
    'Lim Wei Ming',
    'Ahmad bin Hassan',
    'Raj Kumar',
    'Muhammad Faiz bin Omar',
    'Siti Nurhaliza',
    'Tan Cheng Lock',
    'Priya Sharma',
  ];

  final List<String> _serviceTypes = [
    'Oil Change',
    'Brake Service',
    'Transmission Service',
    'Engine Repair',
    'Air Conditioning Service',
    'Tire Replacement',
    'Battery Replacement',
    'General Inspection',
    'Suspension Repair',
    'Exhaust System Repair',
  ];

  final List<List<String>> _servicesPerformed = [
    ['Oil Change', 'Oil Filter Replacement', 'Basic Inspection'],
    ['Brake Pad Replacement', 'Brake Fluid Flush', 'Brake Inspection'],
    ['ATF Change', 'Transmission Filter', 'Transmission Inspection'],
    ['Engine Diagnostics', 'Spark Plug Replacement', 'Engine Tune-up'],
    ['AC Gas Refill', 'AC Filter Replacement', 'AC System Check'],
    ['Tire Mounting', 'Wheel Balancing', 'Tire Pressure Check'],
    ['Battery Testing', 'Terminal Cleaning', 'Charging System Check'],
    ['Multi-point Inspection', 'Fluid Level Check', 'Belt Inspection'],
    ['Shock Absorber Replacement', 'Spring Inspection', 'Alignment Check'],
    ['Muffler Replacement', 'Exhaust Pipe Repair', 'Emissions Test'],
  ];

  // Populate Firebase with sample data
  Future<void> populateFirebaseWithSampleData({
    int customerCount = 8,
    int vehicleCount = 12,
    int serviceRecordCount = 25,
  }) async {
    try {
      print('Starting Firebase data population...');

      // Step 1: Create customers
      print('Creating customers...');
      final customers = await _createSampleCustomers(customerCount);

      // Step 2: Create vehicles
      print('Creating vehicles...');
      final vehicles = await _createSampleVehicles(vehicleCount, customers);

      // Step 3: Create service records
      print('Creating service records...');
      await _createSampleServiceRecords(
          serviceRecordCount, customers, vehicles);

      print('Firebase data population completed successfully!');
    } catch (e) {
      print('Error populating Firebase data: $e');
      rethrow;
    }
  }

  Future<List<Customer>> _createSampleCustomers(int count) async {
    final customers = <Customer>[];

    for (int i = 0; i < count && i < _malaysianCustomers.length; i++) {
      final customerData = _malaysianCustomers[i];

      final customer = Customer(
        id: '', // Firebase will generate
        firstName: customerData['firstName'],
        lastName: customerData['lastName'],
        email: customerData['email'],
        phone: customerData['phone'],
        address: customerData['address'],
        city: customerData['city'],
        state: customerData['state'],
        zipCode: customerData['zipCode'],
        createdAt:
            DateTime.now().subtract(Duration(days: _random.nextInt(365))),
        lastVisit: _random.nextBool()
            ? DateTime.now().subtract(Duration(days: _random.nextInt(120)))
            : null,
        totalSpent: _random.nextDouble() * 2000 + 100,
        visitCount: _random.nextInt(15) + 1,
        preferences: CustomerPreferences(
          preferredContactMethod: [
            'phone',
            'email',
            'text'
          ][_random.nextInt(3)],
          receivePromotions: _random.nextBool(),
          receiveReminders: true,
          preferredMechanic: _random.nextBool()
              ? _mechanics[_random.nextInt(_mechanics.length)]
              : null,
          preferredServiceTime: _random.nextBool()
              ? ['morning', 'afternoon', 'evening'][_random.nextInt(3)]
              : null,
        ),
        notes: _random.nextBool()
            ? 'Loyal customer, always on time for appointments'
            : null,
      );

      final customerId = await _customerService.createCustomer(customer);
      customers.add(customer.copyWith(id: customerId));
    }

    return customers;
  }

  Future<List<Vehicle>> _createSampleVehicles(
      int count, List<Customer> customers) async {
    final vehicles = <Vehicle>[];

    for (int i = 0; i < count; i++) {
      final customer = customers[_random.nextInt(customers.length)];
      final vehicleData =
          _malaysianVehicles[_random.nextInt(_malaysianVehicles.length)];
      final model =
          vehicleData['models'][_random.nextInt(vehicleData['models'].length)];

      final vehicle = Vehicle(
        id: '', // Firebase will generate
        make: vehicleData['make'],
        model: model,
        year: 2015 + _random.nextInt(9), // 2015-2023
        licensePlate: _generateMalaysianLicensePlate(),
        vin: _generateVIN(),
        color: _colors[_random.nextInt(_colors.length)],
        mileage: 10000 + _random.nextInt(150000),
        customerId: customer.id,
        customerName: customer.fullName,
        customerPhone: customer.phone,
        customerEmail: customer.email,
        createdAt:
            DateTime.now().subtract(Duration(days: _random.nextInt(200))),
        lastServiceDate: _random.nextBool()
            ? DateTime.now().subtract(Duration(days: _random.nextInt(120)))
            : null,
        notes: _random.nextBool() ? 'Regular maintenance customer' : null,
      );

      final vehicleId = await _vehicleService.createVehicle(vehicle);
      vehicles.add(vehicle.copyWith(id: vehicleId));
    }

    return vehicles;
  }

  Future<void> _createSampleServiceRecords(
      int count, List<Customer> customers, List<Vehicle> vehicles) async {
    for (int i = 0; i < count; i++) {
      final customer = customers[_random.nextInt(customers.length)];
      final vehicle =
          vehicles.where((v) => v.customerId == customer.id).isNotEmpty
              ? vehicles.where((v) => v.customerId == customer.id).first
              : vehicles[_random.nextInt(vehicles.length)];

      final serviceTypeIndex = _random.nextInt(_serviceTypes.length);
      final serviceType = _serviceTypes[serviceTypeIndex];
      final servicesPerformed = _servicesPerformed[serviceTypeIndex];

      final serviceRecord = sr.ServiceRecord(
        id: '', // Firebase will generate
        customerId: customer.id,
        vehicleId: vehicle.id,
        serviceDate:
            DateTime.now().subtract(Duration(days: _random.nextInt(365))),
        serviceType: serviceType,
        description: 'Professional ${serviceType.toLowerCase()} service',
        servicesPerformed: servicesPerformed,
        cost: 50.0 + _random.nextDouble() * 500,
        mechanicName: _mechanics[_random.nextInt(_mechanics.length)],
        status: sr.ServiceStatus.completed,
        nextServiceDue:
            DateTime.now().add(Duration(days: 30 + _random.nextInt(120))),
        mileage: vehicle.mileage + _random.nextInt(5000),
        partsReplaced: _random.nextBool()
            ? [servicesPerformed.first.split(' ').first]
            : [],
        notes: _random.nextBool()
            ? 'Service completed successfully, no issues found'
            : '',
      );

      await _serviceRecordService.createServiceRecord(serviceRecord);
    }
  }

  String _generateMalaysianLicensePlate() {
    // Malaysian license plate format: ABC 1234 or A 123 BC
    final formats = [
      () {
        // Format: ABC 1234
        final letters = String.fromCharCodes(
            List.generate(3, (index) => _random.nextInt(26) + 65));
        final numbers = _random.nextInt(9000) + 1000;
        return '$letters $numbers';
      },
      () {
        // Format: A 123 BC
        final letter1 = String.fromCharCode(_random.nextInt(26) + 65);
        final numbers = _random.nextInt(900) + 100;
        final letters2 = String.fromCharCodes(
            List.generate(2, (index) => _random.nextInt(26) + 65));
        return '$letter1 $numbers $letters2';
      },
    ];

    return formats[_random.nextInt(formats.length)]();
  }

  String _generateVIN() {
    const chars = 'ABCDEFGHJKLMNPRSTUVWXYZ123456789';
    return String.fromCharCodes(Iterable.generate(
        17, (_) => chars.codeUnitAt(_random.nextInt(chars.length))));
  }

  // Check if database already has data
  Future<bool> isDatabaseEmpty() async {
    try {
      final customers = await _customerService.getAllCustomers();
      return customers.isEmpty;
    } catch (e) {
      return true;
    }
  }

  // Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      print('Clearing all Firebase data...');

      // Get all data
      final customers = await _customerService.getAllCustomers();
      final vehicles = await _vehicleService.getAllVehicles();
      final serviceRecords = await _serviceRecordService.getAllServiceRecords();

      // Delete service records first (to avoid constraint violations)
      for (final record in serviceRecords) {
        await _serviceRecordService.deleteServiceRecord(record.id);
      }

      // Delete vehicles
      for (final vehicle in vehicles) {
        await _vehicleService.deleteVehicle(vehicle.id);
      }

      // Delete customers
      for (final customer in customers) {
        await _customerService.deleteCustomer(customer.id);
      }

      print('All Firebase data cleared successfully!');
    } catch (e) {
      print('Error clearing Firebase data: $e');
      rethrow;
    }
  }

  // Initialize sample data if database is empty
  Future<void> initializeIfEmpty() async {
    try {
      if (await isDatabaseEmpty()) {
        print('Database is empty, populating with sample data...');
        await populateFirebaseWithSampleData();
      } else {
        print('Database already contains data, skipping population.');

        // Only populate usage data if the usage collection is empty
        await _initializeUsageDataIfEmpty();
      }
    } catch (e) {
      print('Error initializing sample data: $e');
      rethrow;
    }
  }

  // Initialize usage data only if the collection is empty (first-time setup)
  Future<void> _initializeUsageDataIfEmpty() async {
    try {
      final usageSnapshot = await FirebaseFirestore.instance
          .collection('inventory_usage')
          .limit(1)
          .get();

      if (usageSnapshot.docs.isEmpty) {
        print('📝 Usage collection is empty, populating with initial data...');
        await InventoryUsageDataPopulator.populateInventoryUsage(
          usageRecordCount: 25,
        );
        print('✅ Initial usage data populated successfully!');
      } else {
        print('📝 Usage collection already has data, preserving existing records');
      }
    } catch (e) {
      print('⚠️ Could not check/initialize usage data: $e');
    }
  }
}
