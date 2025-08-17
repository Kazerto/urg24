import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String status;
  final String? profileImageUrl;
  final String? address;
  final int totalOrders;
  final double rating;

  ClientModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.isVerified = false,
    this.isActive = false,
    required this.createdAt,
    this.verifiedAt,
    this.status = 'pending_verification',
    this.profileImageUrl,
    this.address,
    this.totalOrders = 0,
    this.rating = 0.0,
  });

  // Factory constructor pour créer depuis Firestore
  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ClientModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending_verification',
      profileImageUrl: data['profileImageUrl'],
      address: data['address'],
      totalOrders: data['totalOrders'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }

  // Factory constructor pour créer depuis Map
  factory ClientModel.fromMap(Map<String, dynamic> data, String id) {
    return ClientModel(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      verifiedAt: data['verifiedAt'] != null 
          ? (data['verifiedAt'] is Timestamp 
              ? (data['verifiedAt'] as Timestamp).toDate()
              : DateTime.parse(data['verifiedAt']))
          : null,
      status: data['status'] ?? 'pending_verification',
      profileImageUrl: data['profileImageUrl'],
      address: data['address'],
      totalOrders: data['totalOrders'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'status': status,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'totalOrders': totalOrders,
      'rating': rating,
    };
  }

  // CopyWith method pour créer une copie modifiée
  ClientModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? verifiedAt,
    String? status,
    String? profileImageUrl,
    String? address,
    int? totalOrders,
    double? rating,
  }) {
    return ClientModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
    );
  }

  // Méthodes helper
  bool get canPlaceOrders => isVerified && isActive && status == 'active';
  
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@')[0];
  
  String get statusDisplayText {
    switch (status) {
      case 'pending_verification':
        return 'En attente de vérification';
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

  @override
  String toString() {
    return 'ClientModel(id: $id, fullName: $fullName, email: $email, isVerified: $isVerified, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ClientModel &&
      other.id == id &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode;
  }
}