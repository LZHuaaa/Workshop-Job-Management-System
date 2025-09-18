import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_record.dart';

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
  final List<ServiceRecord> serviceHistory;
  final CustomerPreferences preferences;
  final double totalSpent;
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
    this.serviceHistory = const [],
    required this.preferences,
    this.totalSpent = 0.0,
    this.notes,
  });

  String get fullName => '$firstName $lastName';
  String get fullAddress {
    if (address == null) return '';
    return '$address${city != null ? ', $city' : ''}${state != null ? ', $state' : ''}${zipCode != null ? ' $zipCode' : ''}';
  }

  // Computed property: visitCount based on service history
  int get visitCount => serviceHistory.length;

  bool get isVip => totalSpent > 1000 || visitCount > 10;

  int get daysSinceLastVisit {
    if (lastVisit == null) return 0;
    return DateTime.now().difference(lastVisit!).inDays;
  }

  // Firestore serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'createdAt': createdAt.toIso8601String(),
      'lastVisit': lastVisit?.toIso8601String(),
      'vehicleIds': vehicleIds,
      'communicationHistory':
          communicationHistory.map((comm) => comm.toMap()).toList(),
      'serviceHistory':
          serviceHistory.map((service) => service.toMap()).toList(),
      'preferences': preferences.toMap(),
      'totalSpent': totalSpent,
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      createdAt: _parseDateTime(map['createdAt']),
      lastVisit:
          map['lastVisit'] != null ? _parseDateTime(map['lastVisit']) : null,
      vehicleIds: List<String>.from(map['vehicleIds'] ?? []),
      communicationHistory: (map['communicationHistory'] as List?)
              ?.map((comm) => CommunicationLog.fromMap(comm))
              .toList() ??
          [],
      serviceHistory: (map['serviceHistory'] as List?)
              ?.map((service) => ServiceRecord.fromMap(service))
              .toList() ??
          [],
      preferences: CustomerPreferences.fromMap(map['preferences'] ?? {}),
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    // Fallback to current time if we can't parse
    return DateTime.now();
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
    List<ServiceRecord>? serviceHistory,
    CustomerPreferences? preferences,
    double? totalSpent,
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
      serviceHistory: serviceHistory ?? this.serviceHistory,
      preferences: preferences ?? this.preferences,
      totalSpent: totalSpent ?? this.totalSpent,
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

  Map<String, dynamic> toMap() {
    return {
      'preferredContactMethod': preferredContactMethod,
      'receivePromotions': receivePromotions,
      'receiveReminders': receiveReminders,
      'preferredMechanic': preferredMechanic,
      'preferredServiceTime': preferredServiceTime,
    };
  }

  factory CustomerPreferences.fromMap(Map<String, dynamic> map) {
    return CustomerPreferences(
      preferredContactMethod: map['preferredContactMethod'] ?? 'phone',
      receivePromotions: map['receivePromotions'] ?? true,
      receiveReminders: map['receiveReminders'] ?? true,
      preferredMechanic: map['preferredMechanic'],
      preferredServiceTime: map['preferredServiceTime'],
    );
  }

  CustomerPreferences copyWith({
    String? preferredContactMethod,
    bool? receivePromotions,
    bool? receiveReminders,
    String? preferredMechanic,
    String? preferredServiceTime,
  }) {
    return CustomerPreferences(
      preferredContactMethod:
          preferredContactMethod ?? this.preferredContactMethod,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'subject': subject,
      'content': content,
      'direction': direction,
      'staffMember': staffMember,
    };
  }

  factory CommunicationLog.fromMap(Map<String, dynamic> map) {
    return CommunicationLog(
      id: map['id'] ?? '',
      date: Customer._parseDateTime(map['date']),
      type: map['type'] ?? '',
      subject: map['subject'] ?? '',
      content: map['content'] ?? '',
      direction: map['direction'] ?? '',
      staffMember: map['staffMember'],
    );
  }

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
