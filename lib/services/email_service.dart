import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class EmailService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Générer un code de vérification à 6 chiffres
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Envoyer un code de vérification
  Future<void> sendVerificationCode(String email) async {
    try {
      String code = _generateVerificationCode();

      // Sauvegarder le code dans Firestore avec une expiration
      await _db.collection('verification_codes').doc(email).set({
        'code': code,
        'email': email,
        'createdAt': DateTime.now(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 15)), // Expire dans 15 minutes
        'isUsed': false,
      });

      // Dans une vraie application, vous enverriez l'email ici
      // Pour la démo, nous pouvons stocker le code ou l'afficher dans les logs
      print('Code de vérification pour $email: $code'); // À supprimer en production

      // TODO: Intégrer un service d'email comme SendGrid, AWS SES, etc.
      // await _sendEmailWithCode(email, code);

    } catch (e) {
      throw 'Erreur lors de l\'envoi du code de vérification: $e';
    }
  }

  // Vérifier un code
  Future<String> verifyCode(String code) async {
    try {
      // Rechercher le code dans Firestore
      QuerySnapshot query = await _db
          .collection('verification_codes')
          .where('code', isEqualTo: code)
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw 'Code de vérification invalide';
      }

      DocumentSnapshot doc = query.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Vérifier l'expiration
      DateTime expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw 'Code de vérification expiré';
      }

      // Marquer le code comme utilisé
      await doc.reference.update({'isUsed': true, 'usedAt': DateTime.now()});

      return data['email'];
    } catch (e) {
      if (e.toString().contains('Code de vérification')) {
        rethrow;
      }
      throw 'Erreur lors de la vérification du code: $e';
    }
  }

  // Notifier l'administrateur d'une nouvelle demande de pharmacie
  Future<void> notifyAdminPharmacyRequest(Map<String, dynamic> pharmacyData) async {
    try {
      // Dans une vraie application, vous enverriez un email à l'admin
      print('Nouvelle demande de pharmacie: ${pharmacyData['pharmacyName']}');

      // Sauvegarder la notification pour l'admin
      await _db.collection('admin_notifications').add({
        'type': 'pharmacy_request',
        'title': 'Nouvelle demande de pharmacie',
        'message': 'La pharmacie ${pharmacyData['pharmacyName']} a fait une demande d\'inscription',
        'pharmacyId': pharmacyData['id'],
        'pharmacyName': pharmacyData['pharmacyName'],
        'email': pharmacyData['email'],
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      // TODO: Envoyer email à l'admin
      // await _sendAdminNotificationEmail(pharmacyData);

    } catch (e) {
      throw 'Erreur lors de la notification à l\'administrateur: $e';
    }
  }

  // Envoyer les identifiants à une pharmacie approuvée
  Future<void> sendPharmacyCredentials(String email, String pharmacyName, String password) async {
    try {
      // Dans une vraie application, vous enverriez un email sécurisé
      print('Identifiants pour $pharmacyName ($email): mot de passe = $password');

      // TODO: Envoyer email avec les identifiants
      // await _sendCredentialsEmail(email, pharmacyName, password);

    } catch (e) {
      throw 'Erreur lors de l\'envoi des identifiants: $e';
    }
  }

  // Notifier un livreur de l'approbation de son compte
  Future<void> notifyDeliveryPersonApproval(String email, String fullName) async {
    try {
      print('Compte livreur approuvé pour $fullName ($email)');

      // TODO: Envoyer email de notification
      // await _sendApprovalEmail(email, fullName);

    } catch (e) {
      throw 'Erreur lors de la notification d\'approbation: $e';
    }
  }

  // Supprimer les codes expirés (à appeler périodiquement)
  Future<void> cleanupExpiredCodes() async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot expiredCodes = await _db
          .collection('verification_codes')
          .where('expiresAt', isLessThan: now)
          .get();

      // Supprimer les codes expirés
      WriteBatch batch = _db.batch();
      for (DocumentSnapshot doc in expiredCodes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

    } catch (e) {
      print('Erreur lors du nettoyage des codes expirés: $e');
    }
  }

  // Méthodes privées pour l'envoi d'emails (à implémenter avec un service tiers)

  /*
  Future<void> _sendEmailWithCode(String email, String code) async {
    // Implémentation avec SendGrid, AWS SES, etc.
    // Exemple de template d'email :

    String subject = 'Code de vérification - Delivery App';
    String body = '''
    Bonjour,

    Votre code de vérification est : $code

    Ce code expire dans 15 minutes.

    Si vous n'avez pas fait cette demande, ignorez ce message.

    Cordialement,
    L'équipe Delivery App
    ''';

    // Envoyer l'email via le service choisi
  }

  Future<void> _sendAdminNotificationEmail(Map<String, dynamic> pharmacyData) async {
    // Email pour notifier l'admin d'une nouvelle demande de pharmacie
  }

  Future<void> _sendCredentialsEmail(String email, String pharmacyName, String password) async {
    // Email sécurisé avec les identifiants de connexion
  }

  Future<void> _sendApprovalEmail(String email, String fullName) async {
    // Email de notification d'approbation pour les livreurs
  }
  */

  // Récupérer les notifications admin
  Stream<List<Map<String, dynamic>>> getAdminNotifications() {
    return _db
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList());
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('admin_notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour de la notification: $e';
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('admin_notifications').doc(notificationId).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression de la notification: $e';
    }
  }

  // Envoyer une notification de rejet
  Future<void> sendRejectionNotification(String email, String reason, String userType) async {
    try {
      print('Demande rejetée pour $email ($userType): $reason');

      // TODO: Envoyer email de rejet avec la raison
      // await _sendRejectionEmail(email, reason, userType);

    } catch (e) {
      throw 'Erreur lors de l\'envoi de la notification de rejet: $e';
    }
  }

  // Statistiques des codes de vérification
  Future<Map<String, int>> getVerificationStats() async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);

      QuerySnapshot todayCodes = await _db
          .collection('verification_codes')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      QuerySnapshot usedCodes = await _db
          .collection('verification_codes')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('isUsed', isEqualTo: true)
          .get();

      return {
        'total_sent_today': todayCodes.docs.length,
        'total_used_today': usedCodes.docs.length,
        'success_rate': todayCodes.docs.isNotEmpty
            ? ((usedCodes.docs.length / todayCodes.docs.length) * 100).round()
            : 0,
      };
    } catch (e) {
      return {
        'total_sent_today': 0,
        'total_used_today': 0,
        'success_rate': 0,
      };
    }
  }
}