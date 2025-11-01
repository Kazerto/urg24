import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final String id;
  final String userId;
  final String pharmacyId;
  final String pharmacyName;
  final String imageUrl;
  final DateTime uploadedAt;
  final String status; // uploaded, used_in_order
  final String? usedInOrderId;

  PrescriptionModel({
    required this.id,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.imageUrl,
    required this.uploadedAt,
    required this.status,
    this.usedInOrderId,
  });

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PrescriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'uploaded',
      usedInOrderId: data['usedInOrderId'],
    );
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> data, String id) {
    return PrescriptionModel(
      id: id,
      userId: data['userId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      uploadedAt: data['uploadedAt'] is Timestamp
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.parse(data['uploadedAt']),
      status: data['status'] ?? 'uploaded',
      usedInOrderId: data['usedInOrderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'status': status,
      'usedInOrderId': usedInOrderId,
    };
  }

  PrescriptionModel copyWith({
    String? id,
    String? userId,
    String? pharmacyId,
    String? pharmacyName,
    String? imageUrl,
    DateTime? uploadedAt,
    String? status,
    String? usedInOrderId,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      imageUrl: imageUrl ?? this.imageUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      usedInOrderId: usedInOrderId ?? this.usedInOrderId,
    );
  }

  bool get isUsed => status == 'used_in_order' && usedInOrderId != null;
  bool get isAvailable => status == 'uploaded' && usedInOrderId == null;

  @override
  String toString() {
    return 'PrescriptionModel(id: $id, userId: $userId, status: $status)';
  }
}
