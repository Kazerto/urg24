import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../utils/constants.dart';
import '../config/email_config.dart';

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

      // Envoyer l'email avec le code de vérification
      await _sendEmailWithCode(email, code);
      
      print('📧 Code de vérification envoyé à $email: $code'); // Log pour debug

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
      Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map);

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
      print('📧 === IDENTIFIANTS PHARMACIE APPROUVÉE ===');
      print('🏥 Pharmacie: $pharmacyName');
      print('📧 Email: $email');
      print('🔑 Mot de passe temporaire: $password');
      print('⚠️  La pharmacie doit utiliser ces identifiants pour se connecter');
      print('💡 Conseil: Demandez à la pharmacie de changer son mot de passe après la première connexion');
      print('==========================================');

      // Simulation d'envoi d'email (pour développement)
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Implémenter l'envoi réel d'email
      /*
      final message = '''
Bonjour $pharmacyName,

Félicitations ! Votre demande d'inscription sur la plateforme Urgence24 a été approuvée.

Vos identifiants de connexion :
- Email : $email  
- Mot de passe temporaire : $password

Instructions :
1. Connectez-vous à l'application avec ces identifiants
2. Changez votre mot de passe lors de votre première connexion
3. Complétez votre profil pharmacie

Bienvenue dans le réseau Urgence24 !

L'équipe Urgence24
      ''';
      
      await _sendEmail(email, 'Compte pharmacie approuvé - Urgence24', message);
      */

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

  // Méthodes privées pour l'envoi d'emails
  
  Future<void> _sendEmailWithCode(String email, String code) async {
    try {
      // Vérifier si la configuration email est disponible
      if (!SecureEmailConfig.isConfigured) {
        print('⚠️ Configuration email non définie, affichage du code en console');
        print('📧 Code de vérification pour $email: $code');
        return;
      }

      // Configuration du serveur SMTP Gmail
      final smtpServer = gmail(SecureEmailConfig.senderEmail, SecureEmailConfig.senderPassword);
      
      // Création du message
      final message = Message()
        ..from = Address(SecureEmailConfig.senderEmail, EmailConfig.senderName)
        ..recipients.add(email)
        ..subject = 'Code de vérification - ${EmailConfig.appName}'
        ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: ${EmailConfig.appColor}; color: white; padding: 20px; text-align: center;">
            <h1>🏥 ${EmailConfig.appName}</h1>
            <p>Livraison de médicaments</p>
          </div>
          
          <div style="padding: 20px; background-color: #f5f5f5;">
            <h2>Code de vérification</h2>
            <p>Bonjour,</p>
            <p>Voici votre code de vérification pour finaliser votre inscription :</p>
            
            <div style="text-align: center; margin: 20px 0;">
              <span style="font-size: 32px; font-weight: bold; color: ${EmailConfig.appColor}; background-color: white; padding: 15px 25px; border-radius: 8px; border: 2px solid ${EmailConfig.appColor};">$code</span>
            </div>
            
            <p style="color: #666;">⏰ Ce code expire dans <strong>${EmailConfig.codeExpirationMinutes} minutes</strong>.</p>
            <p style="color: #666;">Si vous n'avez pas fait cette demande, ignorez ce message.</p>
            
            <hr style="margin: 20px 0; border: none; border-top: 1px solid #ddd;">
            <p style="color: #888; font-size: 12px;">
              Cordialement,<br>
              L'équipe ${EmailConfig.appName}<br>
              Livraison de médicaments 24h/24<br>
              Support: ${EmailConfig.supportEmail}
            </p>
          </div>
        </div>
        ''';

      // Envoi de l'email
      await send(message, smtpServer);
      
    } catch (e) {
      // En cas d'erreur d'envoi, on log et on continue sans bloquer l'inscription
      print('⚠️ Erreur envoi email à $email: $e');
      // On peut aussi afficher le code en console comme fallback
      print('📧 Code de vérification pour $email: $code');
    }
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