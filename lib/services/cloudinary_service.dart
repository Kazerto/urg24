import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service de gestion des uploads d'images via Cloudinary
///
/// Configuration requise dans .env ou directement ici :
/// - CLOUDINARY_CLOUD_NAME
/// - CLOUDINARY_UPLOAD_PRESET
class CloudinaryService {
  // ⚠️ CONFIGURATION À REMPLIR APRÈS CRÉATION DU COMPTE CLOUDINARY
  // Allez sur https://cloudinary.com/users/register_free
  // Puis récupérez ces valeurs dans votre dashboard

  static const String _cloudName = 'db0n0qvmy'; // À REMPLACER
  static const String _uploadPreset = 'urgence24_preset'; // À REMPLACER

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Vérifie si Cloudinary est configuré
  bool isConfigured() {
    return _cloudName != 'VOTRE_CLOUD_NAME' &&
           _uploadPreset != 'VOTRE_UPLOAD_PRESET';
  }

  /// Upload d'une ordonnance scannée
  ///
  /// [file] - Image de l'ordonnance
  /// [userId] - ID de l'utilisateur
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de l'image uploadée sur Cloudinary
  Future<String> uploadPrescription({
    required XFile file,
    required String userId,
    Uint8List? webImage,
  }) async {
    try {
      if (!isConfigured()) {
        throw 'Cloudinary n\'est pas configuré. Veuillez remplir _cloudName et _uploadPreset dans cloudinary_service.dart';
      }

      CloudinaryResponse response;

      if (kIsWeb && webImage != null) {
        // Upload depuis bytes (Web)
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            webImage,
            identifier: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
            folder: 'urgence24/prescriptions/$userId',
          ),
        );
      } else {
        // Upload depuis fichier (Mobile)
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'urgence24/prescriptions/$userId',
          ),
        );
      }

      debugPrint('✅ Ordonnance uploadée sur Cloudinary: ${response.secureUrl}');
      return response.secureUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload ordonnance Cloudinary: $e');
      throw 'Erreur lors de l\'upload de l\'ordonnance: $e';
    }
  }

  /// Upload d'une photo de profil
  ///
  /// [file] - Image du profil
  /// [userId] - ID de l'utilisateur
  /// [userType] - Type d'utilisateur (client, delivery_person, pharmacy)
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de l'image uploadée
  Future<String> uploadProfileImage({
    required XFile file,
    required String userId,
    required String userType,
    Uint8List? webImage,
  }) async {
    try {
      if (!isConfigured()) {
        throw 'Cloudinary n\'est pas configuré. Veuillez remplir _cloudName et _uploadPreset';
      }

      CloudinaryResponse response;

      if (kIsWeb && webImage != null) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            webImage,
            identifier: 'profile_${userId}',
            folder: 'urgence24/profiles/$userType',
          ),
        );
      } else {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'urgence24/profiles/$userType',
          ),
        );
      }

      debugPrint('✅ Photo de profil uploadée: ${response.secureUrl}');
      return response.secureUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo de profil: $e');
      throw 'Erreur lors de l\'upload de la photo: $e';
    }
  }

  /// Upload d'une photo de médicament
  ///
  /// [file] - Image du médicament
  /// [pharmacyId] - ID de la pharmacie
  /// [medicamentId] - ID du médicament
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de l'image uploadée
  Future<String> uploadMedicamentPhoto({
    required XFile file,
    required String pharmacyId,
    required String medicamentId,
    Uint8List? webImage,
  }) async {
    try {
      if (!isConfigured()) {
        throw 'Cloudinary n\'est pas configuré';
      }

      CloudinaryResponse response;

      if (kIsWeb && webImage != null) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            webImage,
            identifier: 'medicament_$medicamentId',
            folder: 'urgence24/medicaments/$pharmacyId',
          ),
        );
      } else {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'urgence24/medicaments/$pharmacyId',
          ),
        );
      }

      debugPrint('✅ Photo médicament uploadée: ${response.secureUrl}');
      return response.secureUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo médicament: $e');
      throw 'Erreur lors de l\'upload: $e';
    }
  }

  /// Upload d'une photo de pharmacie
  ///
  /// [file] - Image de la pharmacie
  /// [pharmacyId] - ID de la pharmacie
  /// [webImage] - Données bytes pour le web (optionnel)
  ///
  /// Returns: URL de l'image uploadée
  Future<String> uploadPharmacyPhoto({
    required XFile file,
    required String pharmacyId,
    Uint8List? webImage,
  }) async {
    try {
      if (!isConfigured()) {
        throw 'Cloudinary n\'est pas configuré';
      }

      CloudinaryResponse response;

      if (kIsWeb && webImage != null) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            webImage,
            identifier: 'pharmacy_$pharmacyId',
            folder: 'urgence24/pharmacies',
          ),
        );
      } else {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            folder: 'urgence24/pharmacies',
          ),
        );
      }

      debugPrint('✅ Photo pharmacie uploadée: ${response.secureUrl}');
      return response.secureUrl;

    } catch (e) {
      debugPrint('❌ Erreur upload photo pharmacie: $e');
      throw 'Erreur lors de l\'upload: $e';
    }
  }

  /// Obtenir une URL transformée (thumbnail, resize, etc.)
  ///
  /// Exemple pour créer un thumbnail 300x300 :
  /// ```dart
  /// String thumbnailUrl = getTransformedUrl(
  ///   originalUrl,
  ///   width: 300,
  ///   height: 300,
  ///   crop: 'fill',
  /// );
  /// ```
  String getTransformedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
    String? quality,
  }) {
    String transformation = '/upload/';
    List<String> params = [];

    if (width != null) params.add('w_$width');
    if (height != null) params.add('h_$height');
    if (crop != null) params.add('c_$crop');
    if (quality != null) params.add('q_$quality');

    if (params.isNotEmpty) {
      transformation += params.join(',') + '/';
    }

    return originalUrl.replaceAll('/upload/', transformation);
  }

  /// Supprimer une image (nécessite API key et secret - non disponible côté client)
  ///
  /// Note: La suppression doit être faite via votre backend pour des raisons de sécurité
  /// Pour l'instant, cette méthode retourne juste un warning
  Future<void> deleteImage(String publicId) async {
    debugPrint('⚠️ La suppression d\'images Cloudinary doit être faite depuis un backend sécurisé');
    debugPrint('Public ID à supprimer: $publicId');
    // La suppression nécessite api_key et api_secret qui ne doivent PAS être dans le code client
  }
}
