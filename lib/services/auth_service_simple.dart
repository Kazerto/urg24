import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'safe_firestore_helper.dart';
import 'email_service.dart';

class AuthServiceSimple {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService();

  // Inscription simple avec gestion d'erreur améliorée
  Future<String> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      debugPrint('🔍 Début inscription pour: $email');
      
      // 1. Créer le compte Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      debugPrint('✅ Compte Firebase Auth créé: $uid');

      // 2. Préparer les données utilisateur de manière sécurisée
      Map<String, dynamic> safeUserData = SafeFirestoreHelper.createSafeUserData(
        uid: uid,
        email: email,
        userType: userData['userType'].toString(),
        fullName: userData['fullName']?.toString(),
        phoneNumber: userData['phoneNumber']?.toString(),
        additionalData: userData,
      );

      debugPrint('💾 Sauvegarde dans Firestore...');

      // 3. Sauvegarder dans Firestore avec gestion d'erreur
      await _firestore.collection('users').doc(uid).set(safeUserData);
      
      debugPrint('✅ Données sauvegardées dans Firestore');

      // 4. Envoyer le code de vérification par email
      await _emailService.sendVerificationCode(email);
      String verificationCode = 'envoyé par email'; // Le code est maintenant géré par EmailService

      // 5. Mettre à jour le statut à pending_verification
      await _firestore.collection('users').doc(uid).update({
        'status': 'pending_verification',
        'emailVerificationSent': true,
        'emailSentAt': FieldValue.serverTimestamp(),
      });

      // 6. Déconnecter temporairement
      await _auth.signOut();
      
      return verificationCode;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _getAuthErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firestore: ${e.code} - ${e.message}');
      throw 'Erreur de base de données: ${e.message}';
    } catch (e) {
      debugPrint('❌ Erreur générale: $e');
      throw 'Erreur inattendue: $e';
    }
  }

  // Connexion simple
  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔍 Tentative de connexion pour: $email');

      // 1. Connexion Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      debugPrint('✅ Connexion Firebase Auth réussie: $uid');

      // 2. Récupérer les données utilisateur de manière sécurisée
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'Aucun profil utilisateur trouvé';
      }

      Map<String, dynamic> userData = SafeFirestoreHelper.safeDocumentData(userDoc);
      
      if (userData.isEmpty) {
        debugPrint('❌ Impossible de lire les données utilisateur');
        await _auth.signOut();
        throw 'Erreur de lecture du profil utilisateur';
      }

      debugPrint('✅ Données utilisateur récupérées: ${userData['userType']}');

      // 3. Vérifier le statut selon le type d'utilisateur
      String status = userData['status']?.toString() ?? '';
      String userType = userData['userType']?.toString() ?? '';
      bool isVerified = userData['isVerified'] == true;
      
      debugPrint('🔍 Statut utilisateur: $status, Vérifié: $isVerified, Type: $userType');
      
      // Vérification email obligatoire pour tous les types d'utilisateur
      if (status == 'pending_verification' && !isVerified) {
        await _auth.signOut();
        if (userType == 'pharmacy_request') {
          throw 'Votre demande de pharmacie doit d\'abord être vérifiée par email. Vérifiez votre boîte email.';
        }
        throw 'Compte non vérifié. Vérifiez votre email avec le code reçu.';
      }
      
      // Vérification du statut pour les différents types d'utilisateur
      if (userType == 'client') {
        // Les clients peuvent se connecter dès que leur email est vérifié
        if (!isVerified) {
          await _auth.signOut();
          throw 'Compte non vérifié. Vérifiez votre email avec le code reçu.';
        }
      } else if (userType == 'delivery_person' || userType == 'pharmacy') {
        // Livreurs et pharmacies ont besoin d'approbation admin après vérification email
        if (status == 'pending_approval' || status == 'pending_admin_approval') {
          await _auth.signOut();
          if (userType == 'pharmacy') {
            throw 'Votre compte pharmacie est en attente d\'approbation par l\'administration.';
          } else {
            throw 'Votre compte livreur est en attente d\'approbation par l\'administration.';
          }
        }
        
        if (status != 'active') {
          await _auth.signOut();
          throw 'Compte non actif. Contactez l\'administration.';
        }
      } else if (userType == 'pharmacy_request') {
        await _auth.signOut();
        throw 'Votre demande de pharmacie est en cours de traitement. Vous recevrez une confirmation par email une fois approuvée par l\'administration.';
      }
      
      // Vérification finale du statut actif pour tous sauf clients vérifiés
      if (userType != 'client' && status != 'active') {
        await _auth.signOut();
        throw 'Compte non actif. Contactez l\'administration.';
      }

      return userData;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur connexion Firebase Auth: ${e.code}');
      throw _getAuthErrorMessage(e);
    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firestore connexion: ${e.code}');
      throw 'Erreur de base de données: ${e.message}';
    } catch (e) {
      debugPrint('❌ Erreur connexion générale: $e');
      if (e.toString().contains('Compte')) {
        rethrow;
      }
      throw 'Erreur de connexion: $e';
    }
  }

  // Vérification email
  Future<void> verifyEmail(String code) async {
    try {
      debugPrint('🔍 Vérification code: $code');

      // 1. Utiliser le service d'email pour vérifier le code
      String email = await _emailService.verifyCode(code);
      debugPrint('✅ Code valide pour: $email');

      // 2. Trouver l'utilisateur
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Utilisateur non trouvé';
      }

      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = SafeFirestoreHelper.safeDocumentData(userDoc);

      // 3. Mettre à jour le statut selon le type d'utilisateur
      String newStatus = 'active'; // Client peut se connecter directement
      
      if (userData['userType'] == 'delivery_person') {
        newStatus = 'pending_approval'; // Livreur doit être approuvé par admin
        
        // Notifier l'admin du nouveau livreur vérifié
        try {
          await notifyAdminDeliveryRequest(userData);
        } catch (e) {
          debugPrint('Erreur notification admin livreur: $e');
        }
      } else if (userData['userType'] == 'pharmacy') {
        newStatus = 'pending_approval'; // Pharmacie doit être approuvée par admin
        
        // Notifier l'admin de la nouvelle pharmacie vérifiée
        try {
          await notifyAdminPharmacyRequest(userData);
        } catch (e) {
          debugPrint('Erreur notification admin: $e');
        }
      } else if (userData['userType'] == 'pharmacy_request') {
        // Cas spécial : demande de pharmacie, mettre à jour dans pharmacy_requests
        await _verifyPharmacyRequest(email);
        return;
      } else if (userData['userType'] == 'client') {
        newStatus = 'active'; // Client peut se connecter immédiatement après vérification
      }

      await userDoc.reference.update({
        'isVerified': true,
        'status': newStatus,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Email vérifié, statut: $newStatus');

    } catch (e) {
      debugPrint('❌ Erreur vérification: $e');
      if (e.toString().contains('Code') || e.toString().contains('Utilisateur')) {
        rethrow;
      }
      throw 'Erreur lors de la vérification: $e';
    }
  }

  // Vérifier une demande de pharmacie
  Future<void> _verifyPharmacyRequest(String email) async {
    try {
      // Trouver la demande de pharmacie par email
      QuerySnapshot requestQuery = await _firestore
          .collection('pharmacy_requests')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending_verification')
          .limit(1)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        DocumentSnapshot requestDoc = requestQuery.docs.first;
        
        // Mettre à jour le statut vers pending_admin_approval
        await requestDoc.reference.update({
          'isVerified': true,
          'status': 'pending_admin_approval',
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Demande de pharmacie vérifiée pour: $email');
      } else {
        debugPrint('❌ Aucune demande de pharmacie trouvée pour: $email');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de la demande: $e');
    }
  }

  // Notifier l'admin d'une nouvelle demande de pharmacie
  Future<void> notifyAdminPharmacyRequest(Map<String, dynamic> pharmacyData) async {
    try {
      await _emailService.notifyAdminPharmacyRequest(pharmacyData);
    } catch (e) {
      debugPrint('Erreur notification admin pharmacie: $e');
      // Ne pas bloquer l'inscription pour un problème de notification
    }
  }

  // Notifier l'admin d'une nouvelle demande de livreur
  Future<void> notifyAdminDeliveryRequest(Map<String, dynamic> deliveryData) async {
    try {
      // Pour l'instant, juste un log - à implémenter selon vos besoins
      debugPrint('📧 Notification admin: Nouveau livreur ${deliveryData['fullName']}');
      
      // Sauvegarder notification pour l'admin
      await _firestore.collection('admin_notifications').add({
        'type': 'delivery_request',
        'title': 'Nouvelle demande de livreur',
        'message': 'Le livreur ${deliveryData['fullName']} a fait une demande d\'inscription',
        'deliveryPersonName': deliveryData['fullName'],
        'email': deliveryData['email'],
        'createdAt': DateTime.now(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Erreur notification admin livreur: $e');
      // Ne pas bloquer l'inscription pour un problème de notification
    }
  }

  // Messages d'erreur Firebase Auth
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'invalid-credential':
        return 'Identifiants invalides';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Stream d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Récupérer les données de l'utilisateur actuel (pour auth persistante)
  Future<Map<String, dynamic>?> getCurrentUserData(String uid) async {
    try {
      debugPrint('🔍 Récupération données utilisateur: $uid');
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        debugPrint('❌ Aucun document utilisateur trouvé pour UID: $uid');
        return null;
      }

      Map<String, dynamic> userData = SafeFirestoreHelper.safeDocumentData(userDoc);
      
      if (userData.isEmpty) {
        debugPrint('❌ Impossible de lire les données utilisateur');
        return null;
      }

      // Vérifier que l'utilisateur est actif
      String status = userData['status']?.toString() ?? '';
      if (status != 'active') {
        debugPrint('⚠️ Utilisateur non actif, statut: $status');
        return null;
      }

      debugPrint('✅ Données utilisateur récupérées: ${userData['userType']}');
      return userData;
      
    } catch (e) {
      debugPrint('❌ Erreur récupération données utilisateur: $e');
      return null;
    }
  }
}