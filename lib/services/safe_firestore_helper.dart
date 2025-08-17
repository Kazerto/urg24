import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SafeFirestoreHelper {
  static Map<String, dynamic> safeDocumentData(DocumentSnapshot doc) {
    try {
      if (!doc.exists || doc.data() == null) {
        return {};
      }

      var rawData = doc.data();
      debugPrint('🔍 Type de données brutes: ${rawData.runtimeType}');
      debugPrint('🔍 Données brutes: $rawData');

      // Conversion sécurisée
      if (rawData is Map) {
        return _convertToSafeMap(rawData);
      }
      
      return {};
    } catch (e) {
      debugPrint('❌ Erreur conversion document: $e');
      return {};
    }
  }

  static Map<String, dynamic> _convertToSafeMap(dynamic data) {
    Map<String, dynamic> result = {};
    
    if (data is Map) {
      data.forEach((key, value) {
        String safeKey = key.toString();
        result[safeKey] = _convertToSafeValue(value);
      });
    }
    
    return result;
  }

  static dynamic _convertToSafeValue(dynamic value) {
    if (value == null) return null;
    
    // Types primitifs sûrs
    if (value is String || value is int || value is double || value is bool) {
      return value;
    }
    
    // Timestamp Firebase
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // FieldValue (pas de conversion nécessaire, Firestore le gère)
    if (value.toString().contains('FieldValue')) {
      return DateTime.now(); // Fallback
    }
    
    // Listes
    if (value is List) {
      return value.map((item) => _convertToSafeValue(item)).toList();
    }
    
    // Maps imbriquées
    if (value is Map) {
      return _convertToSafeMap(value);
    }
    
    // Pour tout le reste, convertir en string
    return value.toString();
  }

  static List<Map<String, dynamic>> safeQuerySnapshot(QuerySnapshot snapshot) {
    List<Map<String, dynamic>> result = [];
    
    for (var doc in snapshot.docs) {
      var safeData = safeDocumentData(doc);
      if (safeData.isNotEmpty) {
        safeData['id'] = doc.id; // Ajouter l'ID du document
        result.add(safeData);
      }
    }
    
    return result;
  }

  // Créer des données sûres pour l'écriture
  static Map<String, dynamic> createSafeUserData({
    required String uid,
    required String email,
    required String userType,
    String? fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) {
    Map<String, dynamic> safeData = {
      'uid': uid,
      'email': email,
      'userType': userType,
      'isVerified': false,
      'status': 'pending_verification',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null && fullName.isNotEmpty) {
      safeData['fullName'] = fullName;
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      safeData['phoneNumber'] = phoneNumber;
    }

    // Ajouter des données supplémentaires de manière sûre
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          safeData[key] = _convertToSafeValue(value);
        }
      });
    }

    return safeData;
  }
}