import 'dart:math';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart' as sr;
import '../models/job_appointment.dart';
import '../models/invoice.dart';
import '../models/inventory_item.dart';
import '../models/order_request.dart';

class SampleDataGenerator {
  static final Random _random = Random();

  // Malaysian vehicle makes and models
  static const List<Map<String, dynamic>> _malaysianVehicles = [
    {
      'make': 'Proton',
      'models': ['Saga', 'Persona', 'Iriz', 'X50', 'X70', 'Exora', 'Perdana']
    },
    {
      'make': 'Perodua',
      'models': ['Myvi', 'Axia', 'Bezza', 'Aruz', 'Alza', 'Viva']
    },
    {
      'make': 'Honda',
      'models': ['City', 'Civic', 'Accord', 'CR-V', 'HR-V', 'Jazz', 'Pilot']
    },
    {
      'make': 'Toyota',
      'models': [
        'Vios',
        'Camry',
        'Corolla',
        'Hilux',
        'Fortuner',
        'Innova',
        'Rush'
      ]
    },
    {
      'make': 'Nissan',
      'models': [
        'Almera',
        'Teana',
        'X-Trail',
        'Navara',
        'Livina',
        'Grand Livina'
      ]
    },
    {
      'make': 'Mazda',
      'models': ['CX-5', 'CX-3', 'Mazda3', 'Mazda6', 'BT-50', 'CX-9']
    },
    {
      'make': 'Mitsubishi',
      'models': ['ASX', 'Outlander', 'Triton', 'Lancer', 'Pajero']
    },
    {
      'make': 'Hyundai',
      'models': ['Elantra', 'Tucson', 'Santa Fe', 'i10', 'i30', 'Kona']
    },
    {
      'make': 'Kia',
      'models': ['Cerato', 'Sportage', 'Sorento', 'Picanto', 'Rio', 'Seltos']
    },
    {
      'make': 'Volkswagen',
      'models': ['Polo', 'Vento', 'Passat', 'Tiguan', 'Golf']
    },
  ];

  // Malaysian names (mix of Malay, Chinese, Indian, and other ethnicities)
  static const List<String> _malaysianFirstNames = [
    // Malay names
    'Ahmad', 'Ali', 'Hassan', 'Ibrahim', 'Ismail', 'Omar', 'Yusof', 'Zainab',
    'Fatimah', 'Khadijah',
    'Siti', 'Nur', 'Aishah', 'Aminah', 'Halimah', 'Rohani', 'Noraini', 'Azizah',
    'Rashid', 'Kamal',
    // Chinese names
    'Wei Ming', 'Mei Ling', 'Chong Wei', 'Li Hua', 'Xin Yi', 'Jun Hao',
    'Hui Min', 'Zi Qing', 'Kai Wen', 'Yu Xuan',
    'Ah Kow', 'Ah Lian', 'Beng', 'Chuan', 'Eng', 'Hock', 'Keng', 'Leng', 'Meng',
    'Peng',
    // Indian names
    'Raj', 'Suresh', 'Ravi', 'Kumar', 'Devi', 'Priya', 'Sanjay', 'Deepa',
    'Anita', 'Kavitha',
    'Murugan', 'Selvam', 'Ganesan', 'Lakshmi', 'Kamala', 'Radha', 'Shanti',
    'Vani', 'Mala', 'Usha',
    // Other ethnicities
    'David', 'Michael', 'John', 'Peter', 'Mary', 'Susan', 'Jennifer', 'Lisa',
    'Karen', 'Nancy',
  ];

  static const List<String> _malaysianLastNames = [
    // Malay surnames
    'bin Abdullah', 'bin Ahmad', 'bin Ali', 'bin Hassan', 'bin Ibrahim',
    'bin Ismail', 'bin Omar', 'bin Yusof',
    'binti Abdullah', 'binti Ahmad', 'binti Ali', 'binti Hassan',
    'binti Ibrahim', 'binti Ismail',
    // Chinese surnames
    'Tan', 'Lim', 'Lee', 'Ng', 'Wong', 'Ong', 'Teo', 'Goh', 'Koh', 'Yap',
    'Chin', 'Chong', 'Chua', 'Sia',
    // Indian surnames
    'a/l Suresh', 'a/l Ravi', 'a/l Kumar', 'a/l Murugan', 'a/l Selvam',
    'a/l Ganesan',
    'a/p Devi', 'a/p Lakshmi', 'a/p Kamala', 'a/p Radha', 'a/p Shanti',
    // Other surnames
    'Johnson', 'Williams', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore',
    'Taylor', 'Anderson', 'Thomas',
  ];

  // Malaysian states
  static const List<String> _malaysianStates = [
    'Selangor',
    'Kuala Lumpur',
    'Johor',
    'Penang',
    'Perak',
    'Kedah',
    'Kelantan',
    'Terengganu',
    'Pahang',
    'Negeri Sembilan',
    'Melaka',
    'Sabah',
    'Sarawak',
    'Perlis',
    'Putrajaya',
    'Labuan'
  ];

  // Malaysian cities by state
  static const Map<String, List<String>> _malaysianCities = {
    'Selangor': [
      'Shah Alam',
      'Petaling Jaya',
      'Subang Jaya',
      'Klang',
      'Kajang',
      'Ampang',
      'Puchong',
      'Seri Kembangan'
    ],
    'Kuala Lumpur': [
      'Kuala Lumpur',
      'Cheras',
      'Kepong',
      'Setapak',
      'Wangsa Maju',
      'Bangsar',
      'Mont Kiara'
    ],
    'Johor': [
      'Johor Bahru',
      'Skudai',
      'Kulai',
      'Pontian',
      'Batu Pahat',
      'Muar',
      'Kluang',
      'Segamat'
    ],
    'Penang': [
      'George Town',
      'Butterworth',
      'Bukit Mertajam',
      'Nibong Tebal',
      'Balik Pulau',
      'Tanjung Bungah'
    ],
    'Perak': [
      'Ipoh',
      'Taiping',
      'Teluk Intan',
      'Kampar',
      'Kuala Kangsar',
      'Parit Buntar',
      'Sitiawan'
    ],
  };

  // Malaysian license plate formats
  static const List<String> _licensePlateFormats = [
    'ABC 1234',
    'WXY 123A',
    'KL 5678 B',
    'JHR 9012 C',
    'PNG 3456 D',
    'PRK 7890 E',
    'KDH 2345 F',
    'KTN 6789 G',
    'TRG 0123 H',
    'PHG 4567 J',
    'NSN 8901 K',
    'MLK 2345 L',
  ];

  // Common automotive services in Malaysia
  static const List<String> _serviceTypes = [
    'Oil Change',
    'Brake Service',
    'Transmission Service',
    'Engine Tune-up',
    'Air Conditioning Service',
    'Tire Rotation',
    'Wheel Alignment',
    'Battery Replacement',
    'Radiator Service',
    'Suspension Repair',
    'Exhaust System Repair',
    'Electrical System Check',
    'Fuel System Cleaning',
    'Timing Belt Replacement',
    'Clutch Repair',
    'Power Steering Service',
    'Cooling System Flush',
    'Spark Plug Replacement',
    'Air Filter Replacement',
    'Cabin Filter Replacement',
    'Brake Pad Replacement',
    'Oil Filter Change',
    'Differential Service',
    'CV Joint Repair',
    'Alternator Repair',
    'Starter Motor Repair',
    'Water Pump Replacement',
    'Thermostat Replacement',
    'Fuel Pump Replacement',
    'Oxygen Sensor Replacement'
  ];

  // Common parts used in Malaysian workshops
  static const List<String> _commonParts = [
    'Engine Oil',
    'Oil Filter',
    'Air Filter',
    'Cabin Filter',
    'Brake Pads',
    'Brake Fluid',
    'Transmission Fluid',
    'Coolant',
    'Spark Plugs',
    'Battery',
    'Alternator',
    'Starter Motor',
    'Water Pump',
    'Thermostat',
    'Radiator',
    'Timing Belt',
    'Serpentine Belt',
    'CV Joint',
    'Shock Absorbers',
    'Struts',
    'Brake Rotors',
    'Brake Calipers',
    'Fuel Filter',
    'Fuel Pump',
    'Oxygen Sensor',
    'Catalytic Converter',
    'Muffler',
    'Exhaust Pipe',
    'Power Steering Fluid',
    'Windshield Wipers',
    'Headlight Bulbs',
    'Tail Light Bulbs',
    'Fuses',
    'Relays'
  ];

  // Malaysian mechanic names
  static const List<String> _mechanicNames = [
    'Lim Wei Ming',
    'Ahmad bin Razak',
    'Raj Kumar a/l Suresh',
    'Tan Chee Keong',
    'Siti Nurhaliza binti Hassan',
    'Wong Ah Beng',
    'Murugan a/l Selvam',
    'Fatimah binti Abdullah',
    'Lee Chong Wei',
    'Ravi a/l Kumar',
    'Ng Boon Huat',
    'Zainab binti Omar',
    'David Lim',
    'Priya a/p Devi',
    'Chen Wei Liang',
    'Aminah binti Yusof',
    'Kumar a/l Ganesan',
    'Lim Goh Tong',
    'Salmah binti Ibrahim',
    'Peter Tan'
  ];

  // Generate random Malaysian phone number
  static String _generatePhoneNumber() {
    final prefixes = [
      '012',
      '013',
      '014',
      '016',
      '017',
      '018',
      '019',
      '011',
      '015'
    ];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final number = _random.nextInt(9000000) + 1000000; // 7-digit number
    return '$prefix-${number.toString().substring(0, 3)}-${number.toString().substring(3)}';
  }

  // Generate random Malaysian license plate
  static String _generateLicensePlate() {
    final formats = [
      () {
        final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final state = [
          'WA',
          'KL',
          'JHR',
          'PNG',
          'PRK',
          'KDH',
          'KTN',
          'TRG',
          'PHG',
          'NSN',
          'MLK'
        ][_random.nextInt(11)];
        final number = _random.nextInt(9000) + 1000;
        final letter = letters[_random.nextInt(letters.length)];
        return '$state $number $letter';
      },
      () {
        final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final letter1 = letters[_random.nextInt(letters.length)];
        final letter2 = letters[_random.nextInt(letters.length)];
        final letter3 = letters[_random.nextInt(letters.length)];
        final number = _random.nextInt(9000) + 1000;
        return '$letter1$letter2$letter3 $number';
      }
    ];
    return formats[_random.nextInt(formats.length)]();
  }

  // Generate random VIN
  static String _generateVIN() {
    const chars = 'ABCDEFGHJKLMNPRSTUVWXYZ1234567890';
    return List.generate(17, (index) => chars[_random.nextInt(chars.length)])
        .join();
  }

  // Generate random Malaysian address
  static String _generateAddress(String state, String city) {
    final streetNumbers = [
      'No. ${_random.nextInt(999) + 1}',
      '${_random.nextInt(99) + 1}-${_random.nextInt(99) + 1}'
    ];
    final streetTypes = [
      'Jalan',
      'Lorong',
      'Persiaran',
      'Lebuh',
      'Jalan Taman'
    ];
    final streetNames = [
      'Bukit Bintang',
      'Raja Chulan',
      'Ampang',
      'Cheras',
      'Kepong',
      'Setapak',
      'Bangsar',
      'Damansara',
      'Petaling',
      'Subang',
      'Shah Alam',
      'Klang',
      'Kajang',
      'Puchong',
      'Seri Kembangan',
      'Cyberjaya',
      'Putrajaya',
      'Gombak',
      'Selayang',
      'Rawang'
    ];

    final streetNumber = streetNumbers[_random.nextInt(streetNumbers.length)];
    final streetType = streetTypes[_random.nextInt(streetTypes.length)];
    final streetName = streetNames[_random.nextInt(streetNames.length)];

    return '$streetNumber, $streetType $streetName';
  }

  // Generate random email
  static String _generateEmail(String firstName, String lastName) {
    final domains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'email.com'
    ];
    final cleanFirstName =
        firstName.toLowerCase().replaceAll(' ', '').replaceAll('/', '');
    final cleanLastName = lastName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('/', '')
        .replaceAll('bin ', '')
        .replaceAll('binti ', '')
        .replaceAll('a/l ', '')
        .replaceAll('a/p ', '');
    final domain = domains[_random.nextInt(domains.length)];
    final separator = _random.nextBool() ? '.' : '';
    return '$cleanFirstName$separator$cleanLastName@$domain';
  }

  // Generate random color
  static String _generateColor() {
    const colors = [
      'White',
      'Black',
      'Silver',
      'Grey',
      'Red',
      'Blue',
      'Green',
      'Yellow',
      'Orange',
      'Brown',
      'Gold',
      'Maroon'
    ];
    return colors[_random.nextInt(colors.length)];
  }

  // Generate customers
  static List<Customer> generateCustomers(int count) {
    final customers = <Customer>[];

    for (int i = 0; i < count; i++) {
      final firstName =
          _malaysianFirstNames[_random.nextInt(_malaysianFirstNames.length)];
      final lastName =
          _malaysianLastNames[_random.nextInt(_malaysianLastNames.length)];
      final state = _malaysianStates[_random.nextInt(_malaysianStates.length)];
      final cities = _malaysianCities[state] ?? ['$state City'];
      final city = cities[_random.nextInt(cities.length)];
      final address = _generateAddress(state, city);
      final email = _generateEmail(firstName, lastName);
      final phone = _generatePhoneNumber();

      final customer = Customer(
        id: 'customer_${i + 1}',
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        city: city,
        state: state,
        zipCode: '${_random.nextInt(90000) + 10000}',
        createdAt:
            DateTime.now().subtract(Duration(days: _random.nextInt(730))),
        lastVisit: _random.nextBool()
            ? DateTime.now().subtract(Duration(days: _random.nextInt(90)))
            : null,
        vehicleIds: [], // Will be populated when vehicles are created
        communicationHistory: [],
        serviceHistory: [],
        preferences: CustomerPreferences(
          preferredContactMethod: [
            'phone',
            'email',
            'text'
          ][_random.nextInt(3)],
          receivePromotions: _random.nextBool(),
          receiveReminders: _random.nextBool(),
          preferredMechanic: _random.nextBool()
              ? _mechanicNames[_random.nextInt(_mechanicNames.length)]
              : null,
          preferredServiceTime: [
            'morning',
            'afternoon',
            'evening'
          ][_random.nextInt(3)],
        ),
        totalSpent: _random.nextDouble() * 5000 + 500, // RM 500 - RM 5500
        visitCount: _random.nextInt(20) + 1,
        notes: _random.nextBool()
            ? 'Regular customer, prefers ${_serviceTypes[_random.nextInt(_serviceTypes.length)]}'
            : null,
      );

      customers.add(customer);
    }

    return customers;
  }

  // Generate vehicles
  static List<Vehicle> generateVehicles(
      List<Customer> customers, int vehiclesPerCustomer) {
    final vehicles = <Vehicle>[];
    int vehicleCounter = 1;

    for (final customer in customers) {
      final numVehicles = _random.nextInt(vehiclesPerCustomer) + 1;

      for (int i = 0; i < numVehicles; i++) {
        final vehicleData =
            _malaysianVehicles[_random.nextInt(_malaysianVehicles.length)];
        final make = vehicleData['make'] as String;
        final models = vehicleData['models'] as List<String>;
        final model = models[_random.nextInt(models.length)];
        final year = DateTime.now().year -
            _random.nextInt(15); // Cars from last 15 years
        final licensePlate = _generateLicensePlate();
        final vin = _generateVIN();
        final color = _generateColor();
        final mileage = _random.nextInt(200000) + 5000; // 5k - 205k km

        final vehicle = Vehicle(
          id: 'vehicle_$vehicleCounter',
          make: make,
          model: model,
          year: year,
          licensePlate: licensePlate,
          vin: vin,
          color: color,
          mileage: mileage,
          customerId: customer.id,
          customerName: customer.fullName,
          customerPhone: customer.phone,
          customerEmail: customer.email,
          createdAt:
              customer.createdAt.add(Duration(days: _random.nextInt(30))),
          lastServiceDate: _random.nextBool()
              ? DateTime.now().subtract(Duration(days: _random.nextInt(180)))
              : null,
          serviceHistory: [], // Will be populated separately
          photos: [], // Empty for now
          notes: _random.nextBool()
              ? 'Customer notes: ${_random.nextBool() ? "Prefers original parts" : "Budget-conscious"}'
              : null,
        );

        vehicles.add(vehicle);
        vehicleCounter++;
      }
    }

    return vehicles;
  }

  // Generate service records
  static List<sr.ServiceRecord> generateServiceRecords(
      List<Vehicle> vehicles, int maxRecordsPerVehicle) {
    final serviceRecords = <sr.ServiceRecord>[];
    int recordCounter = 1;

    for (final vehicle in vehicles) {
      final numRecords = _random.nextInt(maxRecordsPerVehicle) + 1;

      for (int i = 0; i < numRecords; i++) {
        final serviceType =
            _serviceTypes[_random.nextInt(_serviceTypes.length)];
        final mechanicName =
            _mechanicNames[_random.nextInt(_mechanicNames.length)];
        final serviceDate = DateTime.now()
            .subtract(Duration(days: _random.nextInt(365) + (i * 30)));
        final serviceMileage = vehicle.mileage - _random.nextInt(50000);

        // Generate parts used based on service type
        final partsUsed = <String>[];
        if (serviceType.contains('Oil')) {
          partsUsed.addAll(['Engine Oil', 'Oil Filter']);
        } else if (serviceType.contains('Brake')) {
          partsUsed.addAll(['Brake Pads', 'Brake Fluid']);
        } else if (serviceType.contains('Air')) {
          partsUsed.add('Air Filter');
        } else {
          // Random parts for other services
          final numParts = _random.nextInt(3) + 1;
          for (int j = 0; j < numParts; j++) {
            final part = _commonParts[_random.nextInt(_commonParts.length)];
            if (!partsUsed.contains(part)) {
              partsUsed.add(part);
            }
          }
        }

        final laborHours = _random.nextDouble() * 4 + 0.5; // 0.5 - 4.5 hours
        final partsCost = partsUsed.length *
            (_random.nextDouble() * 100 + 20); // RM 20-120 per part
        final laborCost = laborHours * 80; // RM 80 per hour
        final totalCost = partsCost + laborCost;

        final serviceRecord = sr.ServiceRecord(
          id: 'service_$recordCounter',
          customerId: vehicle.customerId,
          vehicleId: vehicle.id,
          serviceDate: serviceDate,
          serviceType: serviceType,
          description:
              'Professional $serviceType performed by certified technician',
          servicesPerformed: [serviceType],
          cost: totalCost,
          mechanicName: mechanicName,
          status: sr.ServiceStatus.completed,
          nextServiceDue: serviceDate
              .add(Duration(days: 90 + _random.nextInt(90))), // 3-6 months
          mileage: serviceMileage,
          partsReplaced: partsUsed,
          notes: _random.nextBool()
              ? 'Service completed successfully. Customer satisfied.'
              : '',
        );

        serviceRecords.add(serviceRecord);
        recordCounter++;
      }
    }

    return serviceRecords;
  }

  // Generate job appointments
  static List<JobAppointment> generateJobAppointments(
      List<Vehicle> vehicles, int count) {
    final appointments = <JobAppointment>[];

    for (int i = 0; i < count; i++) {
      final vehicle = vehicles[_random.nextInt(vehicles.length)];
      final serviceType = _serviceTypes[_random.nextInt(_serviceTypes.length)];
      final mechanicName =
          _mechanicNames[_random.nextInt(_mechanicNames.length)];

      // Generate appointment time (past, present, or future)
      final daysOffset = _random.nextInt(60) - 30; // -30 to +30 days
      final startTime = DateTime.now().add(Duration(days: daysOffset));
      final duration = _random.nextInt(4) + 1; // 1-4 hours
      final endTime = startTime.add(Duration(hours: duration));

      final status = daysOffset < -1
          ? JobStatus.completed
          : daysOffset < 0
              ? JobStatus.inProgress
              : JobStatus.scheduled;

      final appointment = JobAppointment(
        id: 'appointment_${i + 1}',
        vehicleInfo:
            '${vehicle.year} ${vehicle.make} ${vehicle.model} - ${vehicle.licensePlate}',
        customerName: vehicle.customerName,
        mechanicName: mechanicName,
        startTime: startTime,
        endTime: endTime,
        serviceType: serviceType,
        status: status,
        notes:
            _random.nextBool() ? 'Customer requested specific time slot' : null,
        partsNeeded: _random.nextBool()
            ? [_commonParts[_random.nextInt(_commonParts.length)]]
            : null,
        estimatedCost: _random.nextDouble() * 500 + 100, // RM 100-600
      );

      appointments.add(appointment);
    }

    return appointments;
  }

  // Generate invoices
  static List<Invoice> generateInvoices(
      List<sr.ServiceRecord> serviceRecords, int count) {
    final invoices = <Invoice>[];

    for (int i = 0; i < count && i < serviceRecords.length; i++) {
      final serviceRecord = serviceRecords[i];
      final issueDate = serviceRecord.serviceDate.add(Duration(days: 1));
      final dueDate =
          issueDate.add(Duration(days: 30)); // 30 days payment terms

      // Generate invoice items based on service record
      final items = <InvoiceItem>[];

      // Labor item
      final laborHours = _random.nextDouble() * 4 + 0.5;
      items.add(InvoiceItem(
        id: 'item_${i}_1',
        description: 'Labor - ${serviceRecord.serviceType}',
        quantity: laborHours,
        unitPrice: 80.0, // RM 80 per hour
        tax: 6.0, // 6% SST
      ));

      // Parts items
      for (int j = 0; j < serviceRecord.partsReplaced.length; j++) {
        final part = serviceRecord.partsReplaced[j];
        final unitPrice = _random.nextDouble() * 100 + 20; // RM 20-120
        items.add(InvoiceItem(
          id: 'item_${i}_${j + 2}',
          description: part,
          quantity: 1.0,
          unitPrice: unitPrice,
          tax: 6.0, // 6% SST
        ));
      }

      final invoice = Invoice(
        id: 'invoice_${i + 1}',
        customerId: serviceRecord.customerId,
        customerName:
            'Customer ${serviceRecord.customerId}', // Will be updated with actual name
        vehicleId: serviceRecord.vehicleId,
        jobId: serviceRecord.id,
        issueDate: issueDate,
        dueDate: dueDate,
        items: items,
        status: _random.nextBool() ? InvoiceStatus.paid : InvoiceStatus.pending,
        notes: _random.nextBool() ? 'Payment terms: 30 days net' : null,
      );

      invoices.add(invoice);
    }

    return invoices;
  }

  // Generate inventory items
  static List<InventoryItem> generateInventoryItems(int count) {
    final inventoryItems = <InventoryItem>[];

    for (int i = 0; i < count; i++) {
      final part = _commonParts[i % _commonParts.length];
      final category = _getPartCategory(part);
      final currentStock = _random.nextInt(100) + 10;
      final minStock = _random.nextInt(20) + 5;
      final maxStock = currentStock + _random.nextInt(50) + 20;

      final inventoryItem = InventoryItem(
        id: 'inventory_${i + 1}',
        name: part,
        category: category,
        currentStock: currentStock,
        minStock: minStock,
        maxStock: maxStock,
        unitPrice: _random.nextDouble() * 200 + 10, // RM 10-210
        supplier: _getRandomSupplier(),
        location:
            'Shelf ${String.fromCharCode(65 + _random.nextInt(10))}-${_random.nextInt(20) + 1}',
        description: 'High quality $part for automotive use',
        lastRestocked: _random.nextBool()
            ? DateTime.now().subtract(Duration(days: _random.nextInt(90)))
            : null,
        imageUrl: null,
        pendingOrderRequest: currentStock < minStock,
        orderRequestDate: currentStock < minStock
            ? DateTime.now().subtract(Duration(days: _random.nextInt(7)))
            : null,
        orderRequestId: currentStock < minStock ? 'order_${i + 1}' : null,
      );

      inventoryItems.add(inventoryItem);
    }

    return inventoryItems;
  }

  // Generate order requests
  static List<OrderRequest> generateOrderRequests(
      List<InventoryItem> inventoryItems, int count) {
    final orderRequests = <OrderRequest>[];
    final lowStockItems = inventoryItems
        .where((item) => item.currentStock < item.minStock)
        .toList();

    for (int i = 0; i < count && i < lowStockItems.length; i++) {
      final item = lowStockItems[i];
      final quantity = item.maxStock - item.currentStock;
      final unitPrice = item.unitPrice * 0.8; // Wholesale price
      final totalAmount = quantity * unitPrice;

      final orderRequest = OrderRequest(
        id: 'order_${i + 1}',
        itemId: item.id,
        itemName: item.name,
        supplier: item.supplier,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        status: [
          OrderRequestStatus.pending,
          OrderRequestStatus.approved
        ][_random.nextInt(2)],
        requestDate:
            DateTime.now().subtract(Duration(days: _random.nextInt(14))),
        responseDate: _random.nextBool()
            ? DateTime.now().subtract(Duration(days: _random.nextInt(7)))
            : null,
        responseNote:
            _random.nextBool() ? 'Approved for immediate delivery' : null,
        requestedBy: _mechanicNames[_random.nextInt(_mechanicNames.length)],
      );

      orderRequests.add(orderRequest);
    }

    return orderRequests;
  }

  // Helper method to get part category
  static String _getPartCategory(String part) {
    if (part.contains('Oil') || part.contains('Filter'))
      return 'Fluids & Filters';
    if (part.contains('Brake')) return 'Brake System';
    if (part.contains('Engine') ||
        part.contains('Spark') ||
        part.contains('Timing')) return 'Engine Parts';
    if (part.contains('Battery') ||
        part.contains('Alternator') ||
        part.contains('Starter')) return 'Electrical';
    if (part.contains('Suspension') ||
        part.contains('Shock') ||
        part.contains('Strut')) return 'Suspension';
    if (part.contains('Exhaust') ||
        part.contains('Muffler') ||
        part.contains('Catalytic')) return 'Exhaust System';
    if (part.contains('Light') ||
        part.contains('Bulb') ||
        part.contains('Fuse')) return 'Lighting & Electrical';
    return 'General Parts';
  }

  // Helper method to get random supplier
  static String _getRandomSupplier() {
    const suppliers = [
      'Proton Parts Sdn Bhd',
      'Perodua Genuine Parts',
      'Honda Malaysia Parts',
      'Toyota Parts Malaysia',
      'Nissan Parts Centre',
      'Mazda Parts Supply',
      'Mitsubishi Motors Parts',
      'Hyundai Parts Malaysia',
      'Kia Parts Centre',
      'Universal Auto Parts',
      'Malaysian Auto Supply',
      'KL Auto Parts',
      'Selangor Parts Distributor',
      'JB Auto Components',
      'Penang Car Parts'
    ];
    return suppliers[_random.nextInt(suppliers.length)];
  }
}
