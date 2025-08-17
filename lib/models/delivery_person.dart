import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryPersonModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String? agency;
  final String vehicleType;
  final String plateNumber;
  final bool isVerified;
  final bool isApproved;
  final bool isActive;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? approvedAt;
  final String status;
  final double rating;
  final int totalDeliveries;
  final int completedDeliveries;
  final String? profileImageUrl;
  final String? currentLocation;
  final DateTime? lastActiveAt;

  DeliveryPersonModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.agency,
    required this.vehicleType,
    required this.plateNumber,
    this.isVerified = false,
    this.isApproved = false,
    this.isActive = false,
    this.isAvailable = false,
    required this.createdAt,
    this.verifiedAt,
    this.approvedAt,
    this.status = 'pending_verification',
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.completedDeliveries = 0,
    this.profileImageUrl,
    this.currentLocation,
    this.lastActiveAt,
  });

  // Factory constructor pour créer depuis Firestore
  factory DeliveryPersonModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return DeliveryPersonModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      agency: data['agency'],
      vehicleType: data['vehicleType'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isApproved: data['isApproved'] ?? false,
      isActive: data['isActive'] ?? false,
      isAvailable: data['isAvailable'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending_verification',
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      completedDeliveries: data['completedDeliveries'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
      currentLocation: data['currentLocation'],
      lastActiveAt: data['lastActiveAt'] != null ? (data['lastActiveAt'] as Timestamp).toDate() : null,
    );
  }

  // Factory constructor pour créer depuis Map
  factory DeliveryPersonModel.fromMap(Map<String, dynamic> data, String id) {
    return DeliveryPersonModel(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      agency: data['agency'],
      vehicleType: data['vehicleType'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isApproved: data['isApproved'] ?? false,
      isActive: data['isActive'] ?? false,
      isAvailable: data['isAvailable'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      verifiedAt: data['verifiedAt'] != null 
          ? (data['verifiedAt'] is Timestamp 
              ? (data['verifiedAt'] as Timestamp).toDate()
              : DateTime.parse(data['verifiedAt']))
          : null,
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] is Timestamp 
              ? (data['approvedAt'] as Timestamp).toDate()
              : DateTime.parse(data['approvedAt']))
          : null,
      status: data['status'] ?? 'pending_verification',
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      completedDeliveries: data['completedDeliveries'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
      currentLocation: data['currentLocation'],
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] is Timestamp 
              ? (data['lastActiveAt'] as Timestamp).toDate()
              : DateTime.parse(data['lastActiveAt']))
          : null,
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'agency': agency,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'status': status,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'profileImageUrl': profileImageUrl,
      'currentLocation': currentLocation,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  // CopyWith method pour créer une copie modifiée
  DeliveryPersonModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? agency,
    String? vehicleType,
    String? plateNumber,
    bool? isVerified,
    bool? isApproved,
    bool? isActive,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? verifiedAt,
    DateTime? approvedAt,
    String? status,
    double? rating,
    int? totalDeliveries,
    int? completedDeliveries,
    String? profileImageUrl,
    String? currentLocation,
    DateTime? lastActiveAt,
  }) {
    return DeliveryPersonModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      agency: agency ?? this.agency,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentLocation: currentLocation ?? this.currentLocation,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  // Méthodes helper
  bool get canAcceptDeliveries => isVerified && isApproved && isActive && isAvailable;
  
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@')[0];
  
  String get vehicleInfo => '$vehicleType - $plateNumber';
  
  String get statusDisplayText {
    switch (status) {
      case 'pending_verification':
        return 'En attente de vérification';
      case 'pending_approval':
        return 'En attente d\'approbation';
      case 'active':
        return 'Actif';
      case 'suspended':
        return 'Suspendu';
      case 'blocked':
        return 'Bloqué';
      default:
        return 'Inconnu';
    }
  }

  String get availabilityStatus {
    if (!canAcceptDeliveries) return 'Indisponible';
    return isAvailable ? 'Disponible' : 'Occupé';
  }

  double get successRate {
    if (totalDeliveries == 0) return 0.0;
    return (completedDeliveries / totalDeliveries) * 100;
  }

  @override
  String toString() {
    return 'DeliveryPersonModel(id: $id, fullName: $fullName, email: $email, vehicleType: $vehicleType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DeliveryPersonModel &&
      other.id == id &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode;
  }
}