import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/inventory_usage.dart';
import '../services/inventory_service.dart';

class InventoryUsageDataPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final InventoryService _inventoryService = InventoryService();
  static final Random _random = Random();

  // Malaysian employee names
  static const List<String> _employeeNames = [
    'Lim Wei Ming',
    'Ahmad bin Razak', 
    'Siti Nurhaliza binti Hassan',
    'Raj Kumar a/l Suresh',
    'Tan Chee Keong',
    'Wong Ah Beng',
    'Murugan a/l Selvam',
    'Fatimah binti Abdullah',
    'Ahmad Faiz bin Rahman',
  ];

  // Malaysian customer names
  static const List<String> _customerNames = [
    'Ahmad bin Abdullah',
    'Tan Mei Ling', 
    'Priya d/o Raman',
    'Lim Chee Keong',
    'Wong Siew Mei',
    'Raj Kumar',
    'Siti Aminah binti Hassan',
    'Chen Wei Liang',
    'Kavitha a/p Suresh',
    'Muhammad Hafiz bin Omar',
  ];

  // Vehicle plates
  static const List<String> _vehiclePlates = [
    'WA 1234 A',
    'KL 5678 B', 
    'JB 9012 C',
    'PG 3456 D',
    'SG 7890 E',
    'NS 2468 F',
    'MLK 1357 G',
    'TRG 9753 H',
    'PHG 8642 J',
    'KTN 1928 K',
  ];

  // Service purposes
  static const List<String> _servicePurposes = [
    'Regular maintenance service',
    'Oil change service',
    'Brake pad replacement',
    'Air filter replacement', 
    'Spark plug replacement',
    'Battery replacement',
    'Coolant system service',
    'Transmission service',
    'Suspension repair',
    'Engine diagnostic',
    'Electrical system repair',
    'Exhaust system repair',
  ];

  /// Populate inventory usage collection with realistic data that matches inventory
  static Future<void> populateInventoryUsage({int usageRecordCount = 25}) async {
    try {
      print('🔄 Starting inventory usage data population...');

      // Clear existing usage data first
      await clearAllUsageRecords();

      // Get actual inventory items from Firebase
      final inventoryItems = await _getInventoryItems();
      if (inventoryItems.isEmpty) {
        throw Exception('No inventory items found. Please populate inventory first.');
      }

      print('📦 Found ${inventoryItems.length} inventory items');
      print('🔄 Generating usage records with exact inventory data...');

      // Generate usage records using exact inventory data
      final usageRecords = _generateUsageRecords(inventoryItems, usageRecordCount);

      // Populate Firebase
      await _populateUsageRecords(usageRecords);

      print('✅ Successfully populated ${usageRecords.length} usage records with correct inventory data');
    } catch (e) {
      print('❌ Error populating inventory usage data: $e');
      rethrow;
    }
  }

  /// Get inventory items from Firebase
  static Future<List<InventoryItem>> _getInventoryItems() async {
    final snapshot = await _firestore.collection('inventory').get();
    final items = <InventoryItem>[];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final item = _mapToInventoryItem(data);
        items.add(item);
      } catch (e) {
        print('Error mapping inventory item ${doc.id}: $e');
      }
    }

    return items;
  }

  /// Generate realistic usage records based on actual inventory items
  static List<InventoryUsage> _generateUsageRecords(
      List<InventoryItem> inventoryItems, int count) {
    final usageRecords = <InventoryUsage>[];
    final now = DateTime.now();

    print('🔧 Generating $count usage records from ${inventoryItems.length} inventory items...');

    for (int i = 0; i < count; i++) {
      // Select random inventory item
      final item = inventoryItems[_random.nextInt(inventoryItems.length)];

      // Generate realistic usage data
      final usageDate = now.subtract(Duration(days: _random.nextInt(30)));
      final quantityUsed = _random.nextInt(5) + 1; // 1-5 items
      final totalCost = item.unitPrice * quantityUsed;

      print('📝 Creating usage record ${i + 1}: ${item.name} (${item.category}) - ${item.unitPrice}');

      final usageRecord = InventoryUsage(
        id: 'usage_${DateTime.now().millisecondsSinceEpoch}_${i + 1}', // Unique ID
        itemId: item.id, // Use exact inventory item ID
        itemName: item.name, // Use exact inventory item name
        itemCategory: item.category, // Use exact inventory category
        quantityUsed: quantityUsed,
        unitPrice: item.unitPrice, // Use exact inventory unit price
        totalCost: totalCost, // Calculate based on exact unit price
        usageType: _getRandomUsageType(),
        status: _getRandomStatus(),
        usageDate: usageDate,
        usedBy: _employeeNames[_random.nextInt(_employeeNames.length)],
        customerId: 'customer_${_random.nextInt(10) + 1}',
        customerName: _customerNames[_random.nextInt(_customerNames.length)],
        vehicleId: 'vehicle_${_random.nextInt(10) + 1}',
        vehiclePlate: _vehiclePlates[_random.nextInt(_vehiclePlates.length)],
        jobId: 'job_${DateTime.now().millisecondsSinceEpoch}_${i + 1}',
        serviceRecordId: 'service_${DateTime.now().millisecondsSinceEpoch}_${i + 1}',
        purpose: _servicePurposes[_random.nextInt(_servicePurposes.length)],
        notes: _random.nextBool() ? _getRandomNotes() : null,
        location: 'Bay ${_random.nextInt(5) + 1}',
        createdAt: usageDate,
        verifiedAt: _random.nextBool() ? usageDate.add(Duration(hours: _random.nextInt(24))) : null,
        verifiedBy: _random.nextBool() ? 'Manager' : null,
      );

      usageRecords.add(usageRecord);
    }

    print('✅ Generated ${usageRecords.length} usage records with exact inventory data');
    return usageRecords;
  }

  /// Get random usage type
  static UsageType _getRandomUsageType() {
    final types = UsageType.values;
    return types[_random.nextInt(types.length)];
  }

  /// Get random status with realistic distribution
  static UsageStatus _getRandomStatus() {
    final rand = _random.nextDouble();
    if (rand < 0.6) return UsageStatus.verified;
    if (rand < 0.8) return UsageStatus.recorded;
    if (rand < 0.95) return UsageStatus.disputed;
    return UsageStatus.cancelled;
  }

  /// Get random notes
  static String _getRandomNotes() {
    const notes = [
      'Customer requested premium parts',
      'Urgent repair needed',
      'Scheduled maintenance',
      'Warranty replacement',
      'Customer complaint resolved',
      'Quality check passed',
      'Installation completed successfully',
      'Follow-up service required',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  /// Populate usage records to Firebase
  static Future<void> _populateUsageRecords(List<InventoryUsage> usageRecords) async {
    print('📝 Populating usage records...');
    final batch = _firestore.batch();

    for (final usage in usageRecords) {
      final docRef = _firestore.collection('inventory_usage').doc(usage.id);
      batch.set(docRef, _usageToMap(usage));
    }

    await batch.commit();
    print('✅ ${usageRecords.length} usage records added to Firestore');
  }

  /// Map Firestore data to InventoryItem
  static InventoryItem _mapToInventoryItem(Map<String, dynamic> data) {
    return InventoryItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      currentStock: data['currentStock'] ?? 0,
      minStock: data['minStock'] ?? 0,
      maxStock: data['maxStock'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      supplier: data['supplier'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      lastRestocked: data['lastRestocked'] != null
          ? (data['lastRestocked'] is Timestamp
              ? (data['lastRestocked'] as Timestamp).toDate()
              : DateTime.parse(data['lastRestocked']))
          : null,
      imageUrl: data['imageUrl'],
      pendingOrderRequest: data['pendingOrderRequest'] ?? false,
      orderRequestDate: data['orderRequestDate'] != null
          ? (data['orderRequestDate'] is Timestamp
              ? (data['orderRequestDate'] as Timestamp).toDate()
              : DateTime.parse(data['orderRequestDate']))
          : null,
      orderRequestId: data['orderRequestId'],
    );
  }

  /// Convert InventoryUsage to Firestore map
  static Map<String, dynamic> _usageToMap(InventoryUsage usage) {
    return {
      'id': usage.id,
      'itemId': usage.itemId,
      'itemName': usage.itemName,
      'itemCategory': usage.itemCategory,
      'quantityUsed': usage.quantityUsed,
      'unitPrice': usage.unitPrice,
      'totalCost': usage.totalCost,
      'usageType': usage.usageType.name,
      'status': usage.status.name,
      'usageDate': Timestamp.fromDate(usage.usageDate),
      'usedBy': usage.usedBy,
      'customerId': usage.customerId,
      'customerName': usage.customerName,
      'vehicleId': usage.vehicleId,
      'vehiclePlate': usage.vehiclePlate,
      'jobId': usage.jobId,
      'serviceRecordId': usage.serviceRecordId,
      'purpose': usage.purpose,
      'notes': usage.notes,
      'location': usage.location,
      'createdAt': Timestamp.fromDate(usage.createdAt),
      'verifiedAt': usage.verifiedAt != null
          ? Timestamp.fromDate(usage.verifiedAt!)
          : null,
      'verifiedBy': usage.verifiedBy,
    };
  }

  /// Clear all usage records (for testing)
  static Future<void> clearAllUsageRecords() async {
    print('🗑️ Clearing all usage records...');
    final collection = _firestore.collection('inventory_usage');
    final snapshot = await collection.get();

    if (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ Cleared ${snapshot.docs.length} usage records');
    } else {
      print('✅ No usage records to clear');
    }
  }

  /// Force repopulate inventory usage with correct data
  static Future<void> forceRepopulateWithCorrectData({int usageRecordCount = 25}) async {
    try {
      print('🔄 Force repopulating inventory usage with correct data...');

      // Clear all existing data
      await clearAllUsageRecords();

      // Repopulate with correct data
      await populateInventoryUsage(usageRecordCount: usageRecordCount);

      print('✅ Force repopulation completed successfully!');
    } catch (e) {
      print('❌ Error during force repopulation: $e');
      rethrow;
    }
  }
}
