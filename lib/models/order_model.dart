import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  inDelivery,
  delivered,
  cancelled
}

class OrderItem {
  final String medicamentId;
  final String medicamentName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.medicamentId,
    required this.medicamentName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      medicamentId: data['medicamentId'] ?? '',
      medicamentName: data['medicamentName'] ?? '',
      quantity: data['quantity'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicamentId': medicamentId,
      'medicamentName': medicamentName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class OrderModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String pharmacyId;
  final String pharmacyName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final DateTime orderDate;
  final DateTime? confirmationDate;
  final DateTime? deliveryDate;
  final String? notes;
  final String? prescriptionUrl;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.deliveryPersonId,
    this.deliveryPersonName,
    required this.orderDate,
    this.confirmationDate,
    this.deliveryDate,
    this.notes,
    this.prescriptionUrl,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return OrderModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryPersonId: data['deliveryPersonId'],
      deliveryPersonName: data['deliveryPersonName'],
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      confirmationDate: data['confirmationDate'] != null 
          ? (data['confirmationDate'] as Timestamp).toDate() 
          : null,
      deliveryDate: data['deliveryDate'] != null 
          ? (data['deliveryDate'] as Timestamp).toDate() 
          : null,
      notes: data['notes'],
      prescriptionUrl: data['prescriptionUrl'],
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryPersonId: data['deliveryPersonId'],
      deliveryPersonName: data['deliveryPersonName'],
      orderDate: data['orderDate'] is Timestamp 
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.parse(data['orderDate']),
      confirmationDate: data['confirmationDate'] != null 
          ? (data['confirmationDate'] is Timestamp 
              ? (data['confirmationDate'] as Timestamp).toDate()
              : DateTime.parse(data['confirmationDate']))
          : null,
      deliveryDate: data['deliveryDate'] != null 
          ? (data['deliveryDate'] is Timestamp 
              ? (data['deliveryDate'] as Timestamp).toDate()
              : DateTime.parse(data['deliveryDate']))
          : null,
      notes: data['notes'],
      prescriptionUrl: data['prescriptionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'orderDate': Timestamp.fromDate(orderDate),
      'confirmationDate': confirmationDate != null 
          ? Timestamp.fromDate(confirmationDate!) 
          : null,
      'deliveryDate': deliveryDate != null 
          ? Timestamp.fromDate(deliveryDate!) 
          : null,
      'notes': notes,
      'prescriptionUrl': prescriptionUrl,
    };
  }

  OrderModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? pharmacyId,
    String? pharmacyName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    String? deliveryAddress,
    String? deliveryPersonId,
    String? deliveryPersonName,
    DateTime? orderDate,
    DateTime? confirmationDate,
    DateTime? deliveryDate,
    String? notes,
    String? prescriptionUrl,
  }) {
    return OrderModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      deliveryPersonName: deliveryPersonName ?? this.deliveryPersonName,
      orderDate: orderDate ?? this.orderDate,
      confirmationDate: confirmationDate ?? this.confirmationDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      prescriptionUrl: prescriptionUrl ?? this.prescriptionUrl,
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, clientName: $clientName, status: $status, totalAmount: $totalAmount)';
  }
}