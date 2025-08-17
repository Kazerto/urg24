import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String pharmacyName;
  final String email;
  final String phoneNumber;
  final String address;
  final String licenseNumber;
  final String openingHours;
  final bool isActive;
  final bool isApproved;
  final double rating;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String status;

  PharmacyModel({
    required this.id,
    required this.pharmacyName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.licenseNumber,
    required this.openingHours,
    this.isActive = true,
    this.isApproved = false,
    this.rating = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
    this.approvedAt,
    this.status = 'pending_admin_approval',
  });

  // Factory constructor pour créer depuis Firestore
  factory PharmacyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PharmacyModel(
      id: doc.id,
      pharmacyName: data['pharmacyName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      openingHours: data['openingHours'] ?? '',
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending_admin_approval',
    );
  }

  // Factory constructor pour créer depuis Map
  factory PharmacyModel.fromMap(Map<String, dynamic> data, String id) {
    return PharmacyModel(
      id: id,
      pharmacyName: data['pharmacyName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      openingHours: data['openingHours'] ?? '',
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] is Timestamp 
              ? (data['approvedAt'] as Timestamp).toDate()
              : DateTime.parse(data['approvedAt']))
          : null,
      status: data['status'] ?? 'pending_admin_approval',
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'pharmacyName': pharmacyName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'licenseNumber': licenseNumber,
      'openingHours': openingHours,
      'isActive': isActive,
      'isApproved': isApproved,
      'rating': rating,
      'totalOrders': totalOrders,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'status': status,
    };
  }

  // CopyWith method pour créer une copie modifiée
  PharmacyModel copyWith({
    String? id,
    String? pharmacyName,
    String? email,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? openingHours,
    bool? isActive,
    bool? isApproved,
    double? rating,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? status,
  }) {
    return PharmacyModel(
      id: id ?? this.id,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      openingHours: openingHours ?? this.openingHours,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'PharmacyModel(id: $id, pharmacyName: $pharmacyName, email: $email, isActive: $isActive, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PharmacyModel &&
      other.id == id &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode;
  }
}