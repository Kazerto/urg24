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

      // 5. Déconnecter temporairement
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

      // 3. Vérifier le statut
      String status = userData['status']?.toString() ?? '';
      
      if (status == 'pending_verification') {
        await _auth.signOut();
        throw 'Compte non vérifié. Vérifiez votre email.';
      }
      
      if (status == 'pending_approval') {
        await _auth.signOut();
        throw 'Compte en attente d\'approbation par l\'administration.';
      }
      
      if (status != 'active') {
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

      // 3. Mettre à jour le statut
      String newStatus = 'active';
      if (userData['userType'] == 'delivery_person') {
        newStatus = 'pending_approval';
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
}