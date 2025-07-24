class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final List<String> vehicleIds;
  final List<CommunicationLog> communicationHistory;
  final CustomerPreferences preferences;
  final double totalSpent;
  final int visitCount;
  final String? notes;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    required this.createdAt,
    this.lastVisit,
    this.vehicleIds = const [],
    this.communicationHistory = const [],
    required this.preferences,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    this.notes,
  });

  String get fullName => '$firstName $lastName';
  String get fullAddress {
    if (address == null) return '';
    return '$address${city != null ? ', $city' : ''}${state != null ? ', $state' : ''}${zipCode != null ? ' $zipCode' : ''}';
  }

  bool get isVip => totalSpent > 1000 || visitCount > 10;

  int get daysSinceLastVisit {
    if (lastVisit == null) return 0;
    return DateTime.now().difference(lastVisit!).inDays;
  }

  Customer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    DateTime? createdAt,
    DateTime? lastVisit,
    List<String>? vehicleIds,
    List<CommunicationLog>? communicationHistory,
    CustomerPreferences? preferences,
    double? totalSpent,
    int? visitCount,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      communicationHistory: communicationHistory ?? this.communicationHistory,
      preferences: preferences ?? this.preferences,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      notes: notes ?? this.notes,
    );
  }
}

class CustomerPreferences {
  final String preferredContactMethod; // 'phone', 'email', 'text'
  final bool receivePromotions;
  final bool receiveReminders;
  final String? preferredMechanic;
  final String? preferredServiceTime; // 'morning', 'afternoon', 'evening'

  CustomerPreferences({
    this.preferredContactMethod = 'phone',
    this.receivePromotions = true,
    this.receiveReminders = true,
    this.preferredMechanic,
    this.preferredServiceTime,
  });

  CustomerPreferences copyWith({
    String? preferredContactMethod,
    bool? receivePromotions,
    bool? receiveReminders,
    String? preferredMechanic,
    String? preferredServiceTime,
  }) {
    return CustomerPreferences(
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      receivePromotions: receivePromotions ?? this.receivePromotions,
      receiveReminders: receiveReminders ?? this.receiveReminders,
      preferredMechanic: preferredMechanic ?? this.preferredMechanic,
      preferredServiceTime: preferredServiceTime ?? this.preferredServiceTime,
    );
  }
}

class CommunicationLog {
  final String id;
  final DateTime date;
  final String type; // 'call', 'email', 'text', 'in-person'
  final String subject;
  final String content;
  final String direction; // 'inbound', 'outbound'
  final String? staffMember;

  CommunicationLog({
    required this.id,
    required this.date,
    required this.type,
    required this.subject,
    required this.content,
    required this.direction,
    this.staffMember,
  });

  CommunicationLog copyWith({
    String? id,
    DateTime? date,
    String? type,
    String? subject,
    String? content,
    String? direction,
    String? staffMember,
  }) {
    return CommunicationLog(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      direction: direction ?? this.direction,
      staffMember: staffMember ?? this.staffMember,
    );
  }
}
