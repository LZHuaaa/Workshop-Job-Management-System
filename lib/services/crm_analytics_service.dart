import '../models/customer.dart';

class CrmAnalyticsService {
  static CrmAnalytics calculateAnalytics(List<Customer> customers) {
    if (customers.isEmpty) {
      return CrmAnalytics.empty();
    }

    // Basic metrics
    final totalCustomers = customers.length;
    final totalRevenue = customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final averageSpend = totalRevenue / totalCustomers;
    final totalVisits = customers.fold(0, (sum, c) => sum + c.visitCount);

    // Customer segmentation
    final vipCustomers = customers.where((c) => c.isVip).length;
    final regularCustomers = customers.where((c) => !c.isVip && c.visitCount > 0).length;
    final newCustomers = customers.where((c) => c.visitCount == 0).length;

    // Retention analysis
    final returningCustomers = customers.where((c) => c.visitCount > 1).length;
    final retentionRate = (returningCustomers / totalCustomers) * 100;

    // Communication analytics
    final allCommunications = customers
        .expand((c) => c.communicationHistory)
        .toList();
    
    final communicationsByType = <String, int>{};
    final communicationsByDirection = <String, int>{};
    
    for (final comm in allCommunications) {
      communicationsByType[comm.type] = (communicationsByType[comm.type] ?? 0) + 1;
      communicationsByDirection[comm.direction] = (communicationsByDirection[comm.direction] ?? 0) + 1;
    }

    // Customer lifecycle analysis
    final now = DateTime.now();
    final activeCustomers = customers.where((c) {
      if (c.lastVisit == null) return false;
      final daysSinceLastVisit = now.difference(c.lastVisit!).inDays;
      return daysSinceLastVisit <= 90; // Active within 90 days
    }).length;

    final dormantCustomers = customers.where((c) {
      if (c.lastVisit == null) return true;
      final daysSinceLastVisit = now.difference(c.lastVisit!).inDays;
      return daysSinceLastVisit > 90 && daysSinceLastVisit <= 365;
    }).length;

    final lostCustomers = customers.where((c) {
      if (c.lastVisit == null) return false;
      final daysSinceLastVisit = now.difference(c.lastVisit!).inDays;
      return daysSinceLastVisit > 365;
    }).length;

    // Growth metrics (simulated monthly data)
    final growthData = _generateGrowthData(customers);

    // Top customers by spend
    final topCustomers = List<Customer>.from(customers)
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    // Communication frequency analysis
    final customersWithCommunications = customers.where((c) => c.communicationHistory.isNotEmpty).length;
    final communicationEngagementRate = (customersWithCommunications / totalCustomers) * 100;

    // Preferred contact methods
    final contactMethodPreferences = <String, int>{};
    for (final customer in customers) {
      final method = customer.preferences.preferredContactMethod;
      contactMethodPreferences[method] = (contactMethodPreferences[method] ?? 0) + 1;
    }

    return CrmAnalytics(
      totalCustomers: totalCustomers,
      totalRevenue: totalRevenue,
      averageSpend: averageSpend,
      totalVisits: totalVisits,
      vipCustomers: vipCustomers,
      regularCustomers: regularCustomers,
      newCustomers: newCustomers,
      retentionRate: retentionRate,
      activeCustomers: activeCustomers,
      dormantCustomers: dormantCustomers,
      lostCustomers: lostCustomers,
      totalCommunications: allCommunications.length,
      communicationsByType: communicationsByType,
      communicationsByDirection: communicationsByDirection,
      communicationEngagementRate: communicationEngagementRate,
      contactMethodPreferences: contactMethodPreferences,
      growthData: growthData,
      topCustomers: topCustomers.take(5).toList(),
    );
  }

  static List<MonthlyGrowthData> _generateGrowthData(List<Customer> customers) {
    final now = DateTime.now();
    final monthlyData = <MonthlyGrowthData>[];

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final customersUpToMonth = customers.where((c) => 
        c.createdAt.isBefore(month.add(const Duration(days: 31)))
      ).length;
      
      final revenue = customers
          .where((c) => c.createdAt.isBefore(month.add(const Duration(days: 31))))
          .fold(0.0, (sum, c) => sum + c.totalSpent);

      monthlyData.add(MonthlyGrowthData(
        month: month,
        customerCount: customersUpToMonth,
        revenue: revenue,
      ));
    }

    return monthlyData;
  }
}

class CrmAnalytics {
  final int totalCustomers;
  final double totalRevenue;
  final double averageSpend;
  final int totalVisits;
  final int vipCustomers;
  final int regularCustomers;
  final int newCustomers;
  final double retentionRate;
  final int activeCustomers;
  final int dormantCustomers;
  final int lostCustomers;
  final int totalCommunications;
  final Map<String, int> communicationsByType;
  final Map<String, int> communicationsByDirection;
  final double communicationEngagementRate;
  final Map<String, int> contactMethodPreferences;
  final List<MonthlyGrowthData> growthData;
  final List<Customer> topCustomers;

  CrmAnalytics({
    required this.totalCustomers,
    required this.totalRevenue,
    required this.averageSpend,
    required this.totalVisits,
    required this.vipCustomers,
    required this.regularCustomers,
    required this.newCustomers,
    required this.retentionRate,
    required this.activeCustomers,
    required this.dormantCustomers,
    required this.lostCustomers,
    required this.totalCommunications,
    required this.communicationsByType,
    required this.communicationsByDirection,
    required this.communicationEngagementRate,
    required this.contactMethodPreferences,
    required this.growthData,
    required this.topCustomers,
  });

  factory CrmAnalytics.empty() {
    return CrmAnalytics(
      totalCustomers: 0,
      totalRevenue: 0.0,
      averageSpend: 0.0,
      totalVisits: 0,
      vipCustomers: 0,
      regularCustomers: 0,
      newCustomers: 0,
      retentionRate: 0.0,
      activeCustomers: 0,
      dormantCustomers: 0,
      lostCustomers: 0,
      totalCommunications: 0,
      communicationsByType: {},
      communicationsByDirection: {},
      communicationEngagementRate: 0.0,
      contactMethodPreferences: {},
      growthData: [],
      topCustomers: [],
    );
  }
}

class MonthlyGrowthData {
  final DateTime month;
  final int customerCount;
  final double revenue;

  MonthlyGrowthData({
    required this.month,
    required this.customerCount,
    required this.revenue,
  });
}
