import '../models/inventory_usage.dart';


class InventoryUsageService {
  static final InventoryUsageService _instance = InventoryUsageService._internal();
  factory InventoryUsageService() => _instance;
  InventoryUsageService._internal();

  // In-memory storage for demo purposes
  final List<InventoryUsage> _usageRecords = [];

  // Sample data for demonstration
  void _initializeSampleData() {
    if (_usageRecords.isNotEmpty) return;

    final now = DateTime.now();
    _usageRecords.addAll([
      InventoryUsage(
        id: 'usage_1',
        itemId: '1',
        itemName: 'Engine Oil Filter',
        itemCategory: 'Filters',
        quantityUsed: 2,
        unitPrice: 12.99,
        totalCost: 25.98,
        usageType: UsageType.service,
        status: UsageStatus.verified,
        usageDate: now.subtract(const Duration(days: 2)),
        usedBy: 'Lim Wei Ming',
        customerId: 'c1',
        customerName: 'Ahmad bin Abdullah',
        vehicleId: 'v1',
        vehiclePlate: 'WA 1234 A',
        jobId: 'job_1',
        serviceRecordId: 's1',
        purpose: 'Oil change service',
        notes: 'Regular maintenance',
        location: 'Bay 1',
        createdAt: now.subtract(const Duration(days: 2)),
        verifiedAt: now.subtract(const Duration(days: 1)),
        verifiedBy: 'Manager',
      ),
      InventoryUsage(
        id: 'usage_2',
        itemId: '2',
        itemName: 'Brake Pads - Front',
        itemCategory: 'Brakes',
        quantityUsed: 1,
        unitPrice: 89.99,
        totalCost: 89.99,
        usageType: UsageType.replacement,
        status: UsageStatus.verified,
        usageDate: now.subtract(const Duration(days: 5)),
        usedBy: 'Siti Nurhaliza binti Hassan',
        customerId: 'c2',
        customerName: 'Lim Chee Keong',
        vehicleId: 'v2',
        vehiclePlate: 'KL 5678 B',
        jobId: 'job_2',
        serviceRecordId: 's2',
        purpose: 'Brake pad replacement',
        notes: 'Customer complained of squeaking',
        location: 'Bay 2',
        createdAt: now.subtract(const Duration(days: 5)),
        verifiedAt: now.subtract(const Duration(days: 4)),
        verifiedBy: 'Manager',
      ),
      InventoryUsage(
        id: 'usage_3',
        itemId: '3',
        itemName: 'Synthetic Motor Oil 5W-30',
        itemCategory: 'Fluids',
        quantityUsed: 5,
        unitPrice: 24.99,
        totalCost: 124.95,
        usageType: UsageType.service,
        status: UsageStatus.recorded,
        usageDate: now.subtract(const Duration(hours: 6)),
        usedBy: 'Ahmad Faiz bin Rahman',
        customerId: 'c3',
        customerName: 'Tan Mei Ling',
        vehicleId: 'v3',
        vehiclePlate: 'JB 9012 C',
        jobId: 'job_3',
        purpose: 'Engine oil change',
        notes: 'Premium synthetic oil requested',
        location: 'Bay 3',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      InventoryUsage(
        id: 'usage_4',
        itemId: '4',
        itemName: 'Air Filter',
        itemCategory: 'Filters',
        quantityUsed: 1,
        unitPrice: 18.99,
        totalCost: 18.99,
        usageType: UsageType.maintenance,
        status: UsageStatus.verified,
        usageDate: now.subtract(const Duration(days: 7)),
        usedBy: 'Lim Wei Ming',
        customerId: 'c1',
        customerName: 'Ahmad bin Abdullah',
        vehicleId: 'v1',
        vehiclePlate: 'WA 1234 A',
        jobId: 'job_4',
        serviceRecordId: 's3',
        purpose: 'Air filter replacement',
        notes: 'Scheduled maintenance',
        location: 'Bay 1',
        createdAt: now.subtract(const Duration(days: 7)),
        verifiedAt: now.subtract(const Duration(days: 6)),
        verifiedBy: 'Manager',
      ),
      InventoryUsage(
        id: 'usage_5',
        itemId: '5',
        itemName: 'Spark Plugs (Set of 4)',
        itemCategory: 'Engine',
        quantityUsed: 1,
        unitPrice: 32.99,
        totalCost: 32.99,
        usageType: UsageType.replacement,
        status: UsageStatus.verified,
        usageDate: now.subtract(const Duration(days: 10)),
        usedBy: 'Ahmad Faiz bin Rahman',
        customerId: 'c4',
        customerName: 'Wong Siew Mei',
        vehicleId: 'v4',
        vehiclePlate: 'PG 3456 D',
        jobId: 'job_5',
        serviceRecordId: 's4',
        purpose: 'Spark plug replacement',
        notes: 'Engine misfiring issue',
        location: 'Bay 2',
        createdAt: now.subtract(const Duration(days: 10)),
        verifiedAt: now.subtract(const Duration(days: 9)),
        verifiedBy: 'Manager',
      ),
      InventoryUsage(
        id: 'usage_6',
        itemId: '2',
        itemName: 'Brake Pads - Front',
        itemCategory: 'Brakes',
        quantityUsed: 2,
        unitPrice: 89.99,
        totalCost: 179.98,
        usageType: UsageType.replacement,
        status: UsageStatus.disputed,
        usageDate: now.subtract(const Duration(days: 3)),
        usedBy: 'Ahmad Faiz bin Rahman',
        customerId: 'c5',
        customerName: 'Raj Kumar',
        vehicleId: 'v5',
        vehiclePlate: 'SG 7890 E',
        jobId: 'job_6',
        serviceRecordId: 's5',
        purpose: 'Brake pad replacement',
        notes: 'Customer claims only one set was needed',
        location: 'Bay 3',
        createdAt: now.subtract(const Duration(days: 3)),
        verifiedAt: now.subtract(const Duration(days: 2)),
        verifiedBy: 'Manager',
      ),
    ]);
  }

  // Get all usage records
  List<InventoryUsage> getAllUsageRecords() {
    _initializeSampleData();
    return List.from(_usageRecords);
  }

  // Get usage records with filtering
  List<InventoryUsage> getUsageRecords({
    String? itemId,
    String? category,
    UsageType? usageType,
    UsageStatus? status,
    String? usedBy,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    _initializeSampleData();
    
    var filtered = _usageRecords.where((usage) {
      if (itemId != null && usage.itemId != itemId) return false;
      if (category != null && usage.itemCategory != category) return false;
      if (usageType != null && usage.usageType != usageType) return false;
      if (status != null && usage.status != status) return false;
      if (usedBy != null && !usage.usedBy.toLowerCase().contains(usedBy.toLowerCase())) return false;
      if (customerId != null && usage.customerId != customerId) return false;
      if (startDate != null && usage.usageDate.isBefore(startDate)) return false;
      if (endDate != null && usage.usageDate.isAfter(endDate)) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return usage.itemName.toLowerCase().contains(query) ||
               usage.purpose.toLowerCase().contains(query) ||
               usage.usedBy.toLowerCase().contains(query) ||
               (usage.customerName?.toLowerCase().contains(query) ?? false) ||
               (usage.vehiclePlate?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    // Sort by usage date (newest first)
    filtered.sort((a, b) => b.usageDate.compareTo(a.usageDate));
    return filtered;
  }

  // Record new usage
  Future<InventoryUsage> recordUsage(InventoryUsage usage) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    _usageRecords.add(usage);
    return usage;
  }

  // Update usage record
  Future<InventoryUsage> updateUsage(InventoryUsage usage) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _usageRecords.indexWhere((u) => u.id == usage.id);
    if (index != -1) {
      _usageRecords[index] = usage;
    }
    return usage;
  }

  // Verify usage record
  Future<InventoryUsage> verifyUsage(String usageId, String verifiedBy) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _usageRecords.indexWhere((u) => u.id == usageId);
    if (index != -1) {
      final updatedUsage = _usageRecords[index].copyWith(
        status: UsageStatus.verified,
        verifiedAt: DateTime.now(),
        verifiedBy: verifiedBy,
      );
      _usageRecords[index] = updatedUsage;
      return updatedUsage;
    }
    throw Exception('Usage record not found');
  }

  // Dispute usage record
  Future<InventoryUsage> disputeUsage(String usageId, String disputedBy, String reason) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _usageRecords.indexWhere((u) => u.id == usageId);
    if (index != -1) {
      final updatedUsage = _usageRecords[index].copyWith(
        status: UsageStatus.disputed,
        verifiedAt: DateTime.now(),
        verifiedBy: disputedBy,
        notes: '${_usageRecords[index].notes ?? ''}\n\nDISPUTE REASON: $reason'.trim(),
      );
      _usageRecords[index] = updatedUsage;
      return updatedUsage;
    }
    throw Exception('Usage record not found');
  }

  // Undispute usage record (change back to recorded)
  Future<InventoryUsage> undisputeUsage(String usageId, String undisputedBy) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _usageRecords.indexWhere((u) => u.id == usageId);
    if (index != -1) {
      // Remove dispute reason from notes
      String? updatedNotes = _usageRecords[index].notes;
      if (updatedNotes != null && updatedNotes.contains('DISPUTE REASON:')) {
        final disputeIndex = updatedNotes.indexOf('\n\nDISPUTE REASON:');
        if (disputeIndex != -1) {
          updatedNotes = updatedNotes.substring(0, disputeIndex).trim();
          if (updatedNotes.isEmpty) updatedNotes = null;
        }
      }

      final updatedUsage = _usageRecords[index].copyWith(
        status: UsageStatus.recorded,
        verifiedAt: null,
        verifiedBy: null,
        notes: updatedNotes,
      );
      _usageRecords[index] = updatedUsage;
      return updatedUsage;
    }
    throw Exception('Usage record not found');
  }

  // Delete usage record
  Future<bool> deleteUsage(String usageId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _usageRecords.indexWhere((u) => u.id == usageId);
    if (index != -1) {
      _usageRecords.removeAt(index);
      return true;
    }
    return false;
  }

  // Get usage by item
  List<InventoryUsage> getUsageByItem(String itemId) {
    _initializeSampleData();
    return _usageRecords.where((usage) => usage.itemId == itemId).toList();
  }

  // Get usage by employee
  List<InventoryUsage> getUsageByEmployee(String employeeName) {
    _initializeSampleData();
    return _usageRecords.where((usage) => 
        usage.usedBy.toLowerCase().contains(employeeName.toLowerCase())).toList();
  }

  // Get usage by customer
  List<InventoryUsage> getUsageByCustomer(String customerId) {
    _initializeSampleData();
    return _usageRecords.where((usage) => usage.customerId == customerId).toList();
  }

  // Get usage analytics for an item
  UsageAnalytics? getItemUsageAnalytics(String itemId) {
    _initializeSampleData();
    final itemUsages = _usageRecords.where((usage) => usage.itemId == itemId).toList();
    
    if (itemUsages.isEmpty) return null;

    final totalQuantity = itemUsages.fold<int>(0, (sum, usage) => sum + usage.quantityUsed);
    final totalCost = itemUsages.fold<double>(0, (sum, usage) => sum + usage.totalCost);
    final usageByType = <UsageType, int>{};
    final usageByEmployee = <String, int>{};

    for (final usage in itemUsages) {
      usageByType[usage.usageType] = (usageByType[usage.usageType] ?? 0) + 1;
      usageByEmployee[usage.usedBy] = (usageByEmployee[usage.usedBy] ?? 0) + usage.quantityUsed;
    }

    itemUsages.sort((a, b) => a.usageDate.compareTo(b.usageDate));
    final firstUsage = itemUsages.first.usageDate;
    final lastUsage = itemUsages.last.usageDate;
    
    final monthsDiff = (lastUsage.difference(firstUsage).inDays / 30.44).ceil();
    final averageUsagePerMonth = monthsDiff > 0 ? totalQuantity / monthsDiff : totalQuantity.toDouble();

    return UsageAnalytics(
      itemId: itemId,
      itemName: itemUsages.first.itemName,
      category: itemUsages.first.itemCategory,
      totalQuantityUsed: totalQuantity,
      totalCost: totalCost,
      usageCount: itemUsages.length,
      firstUsage: firstUsage,
      lastUsage: lastUsage,
      averageUsagePerMonth: averageUsagePerMonth,
      usageByType: usageByType,
      usageByEmployee: usageByEmployee,
    );
  }

  // Get usage summary for a period
  UsageSummary getUsageSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    _initializeSampleData();
    final periodUsages = _usageRecords.where((usage) =>
        usage.usageDate.isAfter(startDate) && usage.usageDate.isBefore(endDate)).toList();

    final totalQuantity = periodUsages.fold<int>(0, (sum, usage) => sum + usage.quantityUsed);
    final totalCost = periodUsages.fold<double>(0, (sum, usage) => sum + usage.totalCost);
    
    final usageByCategory = <String, int>{};
    final usageByType = <UsageType, int>{};
    final usageByEmployee = <String, int>{};
    final itemUsageCount = <String, int>{};

    for (final usage in periodUsages) {
      usageByCategory[usage.itemCategory] = (usageByCategory[usage.itemCategory] ?? 0) + usage.quantityUsed;
      usageByType[usage.usageType] = (usageByType[usage.usageType] ?? 0) + 1;
      usageByEmployee[usage.usedBy] = (usageByEmployee[usage.usedBy] ?? 0) + usage.quantityUsed;
      itemUsageCount[usage.itemName] = (itemUsageCount[usage.itemName] ?? 0) + usage.quantityUsed;
    }

    final topUsedItems = itemUsageCount.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);

    final mostActiveEmployees = usageByEmployee.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5);

    return UsageSummary(
      periodStart: startDate,
      periodEnd: endDate,
      totalUsageRecords: periodUsages.length,
      totalQuantityUsed: totalQuantity,
      totalCost: totalCost,
      usageByCategory: usageByCategory,
      usageByType: usageByType,
      usageByEmployee: usageByEmployee,
      topUsedItems: topUsedItems.map((e) => e.key).toList(),
      mostActiveEmployees: mostActiveEmployees.map((e) => e.key).toList(),
    );
  }
}
