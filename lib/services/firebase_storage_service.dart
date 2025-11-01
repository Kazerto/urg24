import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service de gestion du stockage Firebase Storage
/// Gère l'upload, la suppression et la récupération d'images
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload d'une ordonnance scannée
  ///
  /// [file] - Image de l'ordonnance (XFile pour web/mobile)
  /// [userId] - ID de l'utilisateur qui upload
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de téléchargement de l'image uploadée
  Future<String> uploadPrescription({
    required XFile file,
    required String userId,
    Uint8List? webImage,
  }) async {
    try {
      // Générer un nom unique pour le fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'prescription_${userId}_$timestamp.jpg';
      final ref = _storage.ref('prescriptions/$userId/$fileName');

      // Upload selon la plateforme
      UploadTask uploadTask;

      if (kIsWeb && webImage != null) {
        // Web: utiliser les bytes
        uploadTask = ref.putData(
          webImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': timestamp.toString(),
              'type': 'prescription',
            },
          ),
        );
      } else {
        // Mobile: utiliser le fichier
        uploadTask = ref.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': timestamp.toString(),
              'type': 'prescription',
            },
          ),
        );
      }

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Ordonnance uploadée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload ordonnance: $e');
      throw 'Erreur lors de l\'upload de l\'ordonnance: $e';
    }
  }

  /// Upload d'une photo de profil (client, livreur, pharmacie)
  ///
  /// [file] - Image du profil
  /// [userId] - ID de l'utilisateur
  /// [userType] - Type d'utilisateur (client, delivery_person, pharmacy)
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de téléchargement de l'image uploadée
  Future<String> uploadProfileImage({
    required XFile file,
    required String userId,
    required String userType,
    Uint8List? webImage,
  }) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final ref = _storage.ref('profiles/$userType/$fileName');

      UploadTask uploadTask;

      if (kIsWeb && webImage != null) {
        uploadTask = ref.putData(
          webImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'profile',
              'userType': userType,
            },
          ),
        );
      } else {
        uploadTask = ref.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'profile',
              'userType': userType,
            },
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Photo de profil uploadée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo de profil: $e');
      throw 'Erreur lors de l\'upload de la photo de profil: $e';
    }
  }

  /// Upload d'une photo de médicament
  ///
  /// [file] - Image du médicament
  /// [pharmacyId] - ID de la pharmacie
  /// [medicamentId] - ID du médicament
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de téléchargement de l'image uploadée
  Future<String> uploadMedicamentPhoto({
    required XFile file,
    required String pharmacyId,
    required String medicamentId,
    Uint8List? webImage,
  }) async {
    try {
      final fileName = 'medicament_$medicamentId.jpg';
      final ref = _storage.ref('medicaments/$pharmacyId/$fileName');

      UploadTask uploadTask;

      if (kIsWeb && webImage != null) {
        uploadTask = ref.putData(
          webImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'pharmacyId': pharmacyId,
              'medicamentId': medicamentId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'medicament',
            },
          ),
        );
      } else {
        uploadTask = ref.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'pharmacyId': pharmacyId,
              'medicamentId': medicamentId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'medicament',
            },
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Photo médicament uploadée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo médicament: $e');
      throw 'Erreur lors de l\'upload de la photo du médicament: $e';
    }
  }

  /// Upload d'une photo de pharmacie
  ///
  /// [file] - Image de la pharmacie
  /// [pharmacyId] - ID de la pharmacie
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de téléchargement de l'image uploadée
  Future<String> uploadPharmacyPhoto({
    required XFile file,
    required String pharmacyId,
    Uint8List? webImage,
  }) async {
    try {
      final fileName = 'pharmacy_$pharmacyId.jpg';
      final ref = _storage.ref('pharmacies/$pharmacyId/$fileName');

      UploadTask uploadTask;

      if (kIsWeb && webImage != null) {
        uploadTask = ref.putData(
          webImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'pharmacyId': pharmacyId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'pharmacy',
            },
          ),
        );
      } else {
        uploadTask = ref.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'pharmacyId': pharmacyId,
              'uploadedAt': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'pharmacy',
            },
          ),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Photo pharmacie uploadée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo pharmacie: $e');
      throw 'Erreur lors de l\'upload de la photo de la pharmacie: $e';
    }
  }

  /// Supprimer une image depuis Firebase Storage
  ///
  /// [url] - URL complète de l'image à supprimer
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint('✅ Image supprimée: $url');
    } catch (e) {
      debugPrint('❌ Erreur suppression image: $e');
      throw 'Erreur lors de la suppression de l\'image: $e';
    }
  }

  /// Supprimer toutes les ordonnances d'un utilisateur
  ///
  /// [userId] - ID de l'utilisateur
  Future<void> deletePrescriptions(String userId) async {
    try {
      final ref = _storage.ref('prescriptions/$userId');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }

      debugPrint('✅ Toutes les ordonnances de $userId supprimées');
    } catch (e) {
      debugPrint('❌ Erreur suppression ordonnances: $e');
      throw 'Erreur lors de la suppression des ordonnances: $e';
    }
  }

  /// Obtenir la progression de l'upload
  ///
  /// Utilisez cette méthode pour afficher une barre de progression
  ///
  /// Exemple:
  /// ```dart
  /// final uploadTask = storageService.getUploadTask(...);
  /// uploadTask.snapshotEvents.listen((snapshot) {
  ///   final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  ///   print('Progress: ${progress * 100}%');
  /// });
  /// ```
  Stream<TaskSnapshot> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents;
  }
}
