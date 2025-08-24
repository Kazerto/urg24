import 'package:cloud_firestore/cloud_firestore.dart';

class StockModel {
  final String id;
  final String pharmacyId;
  final String medicamentName;
  final String medicamentCode;
  final String category;
  final String description;
  final double price;
  final int quantity;
  final int minQuantity;
  final DateTime expirationDate;
  final String supplier;
  final String batchNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  StockModel({
    required this.id,
    required this.pharmacyId,
    required this.medicamentName,
    required this.medicamentCode,
    required this.category,
    required this.description,
    required this.price,
    required this.quantity,
    required this.minQuantity,
    required this.expirationDate,
    required this.supplier,
    required this.batchNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory StockModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return StockModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      medicamentName: data['medicamentName'] ?? '',
      medicamentCode: data['medicamentCode'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      minQuantity: data['minQuantity'] ?? 0,
      expirationDate: (data['expirationDate'] as Timestamp).toDate(),
      supplier: data['supplier'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory StockModel.fromMap(Map<String, dynamic> data, String id) {
    return StockModel(
      id: id,
      pharmacyId: data['pharmacyId'] ?? '',
      medicamentName: data['medicamentName'] ?? '',
      medicamentCode: data['medicamentCode'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      minQuantity: data['minQuantity'] ?? 0,
      expirationDate: data['expirationDate'] is Timestamp 
          ? (data['expirationDate'] as Timestamp).toDate()
          : DateTime.parse(data['expirationDate']),
      supplier: data['supplier'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'medicamentName': medicamentName,
      'medicamentCode': medicamentCode,
      'category': category,
      'description': description,
      'price': price,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'supplier': supplier,
      'batchNumber': batchNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  StockModel copyWith({
    String? id,
    String? pharmacyId,
    String? medicamentName,
    String? medicamentCode,
    String? category,
    String? description,
    double? price,
    int? quantity,
    int? minQuantity,
    DateTime? expirationDate,
    String? supplier,
    String? batchNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return StockModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicamentName: medicamentName ?? this.medicamentName,
      medicamentCode: medicamentCode ?? this.medicamentCode,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isLowStock => quantity <= minQuantity;
  bool get isExpiringSoon => expirationDate.difference(DateTime.now()).inDays <= 30;

  @override
  String toString() {
    return 'StockModel(id: $id, medicamentName: $medicamentName, quantity: $quantity)';
  }
}