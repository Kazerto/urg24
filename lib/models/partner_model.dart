import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerType {
  pharmacy,
  supplier,
  laboratory,
  insurance,
  hospital
}

class PartnerModel {
  final String id;
  final String pharmacyId;
  final String partnerName;
  final String partnerEmail;
  final String partnerPhone;
  final String partnerAddress;
  final PartnerType partnerType;
  final String description;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastContactDate;
  final Map<String, dynamic> additionalData;

  PartnerModel({
    required this.id,
    required this.pharmacyId,
    required this.partnerName,
    required this.partnerEmail,
    required this.partnerPhone,
    required this.partnerAddress,
    required this.partnerType,
    required this.description,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastContactDate,
    this.additionalData = const {},
  });

  factory PartnerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PartnerModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      partnerEmail: data['partnerEmail'] ?? '',
      partnerPhone: data['partnerPhone'] ?? '',
      partnerAddress: data['partnerAddress'] ?? '',
      partnerType: PartnerType.values.firstWhere(
        (type) => type.toString().split('.').last == data['partnerType'],
        orElse: () => PartnerType.supplier,
      ),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastContactDate: data['lastContactDate'] != null 
          ? (data['lastContactDate'] as Timestamp).toDate() 
          : null,
      additionalData: data['additionalData'] ?? {},
    );
  }

  factory PartnerModel.fromMap(Map<String, dynamic> data, String id) {
    return PartnerModel(
      id: id,
      pharmacyId: data['pharmacyId'] ?? '',
      partnerName: data['partnerName'] ?? '',
      partnerEmail: data['partnerEmail'] ?? '',
      partnerPhone: data['partnerPhone'] ?? '',
      partnerAddress: data['partnerAddress'] ?? '',
      partnerType: PartnerType.values.firstWhere(
        (type) => type.toString().split('.').last == data['partnerType'],
        orElse: () => PartnerType.supplier,
      ),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      lastContactDate: data['lastContactDate'] != null 
          ? (data['lastContactDate'] is Timestamp 
              ? (data['lastContactDate'] as Timestamp).toDate()
              : DateTime.parse(data['lastContactDate']))
          : null,
      additionalData: data['additionalData'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'partnerName': partnerName,
      'partnerEmail': partnerEmail,
      'partnerPhone': partnerPhone,
      'partnerAddress': partnerAddress,
      'partnerType': partnerType.toString().split('.').last,
      'description': description,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastContactDate': lastContactDate != null 
          ? Timestamp.fromDate(lastContactDate!) 
          : null,
      'additionalData': additionalData,
    };
  }

  PartnerModel copyWith({
    String? id,
    String? pharmacyId,
    String? partnerName,
    String? partnerEmail,
    String? partnerPhone,
    String? partnerAddress,
    PartnerType? partnerType,
    String? description,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastContactDate,
    Map<String, dynamic>? additionalData,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      partnerName: partnerName ?? this.partnerName,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      partnerAddress: partnerAddress ?? this.partnerAddress,
      partnerType: partnerType ?? this.partnerType,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get partnerTypeDisplay {
    switch (partnerType) {
      case PartnerType.pharmacy:
        return 'Pharmacie';
      case PartnerType.supplier:
        return 'Fournisseur';
      case PartnerType.laboratory:
        return 'Laboratoire';
      case PartnerType.insurance:
        return 'Assurance';
      case PartnerType.hospital:
        return 'Hôpital';
    }
  }

  @override
  String toString() {
    return 'PartnerModel(id: $id, partnerName: $partnerName, partnerType: $partnerType)';
  }
}