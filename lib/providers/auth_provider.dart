import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final EmailService _emailService = EmailService();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserData();
    } else {
      _userData = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        _userData = await _firestoreService.getUserData(_user!.uid);
        notifyListeners();
      } catch (e) {
        debugPrint('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  // Inscription Client
  Future<void> registerClient(String email, String password, Map<String, dynamic> userData) async {
    _setLoading(true);

    try {
      // Créer le compte Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter l'UID aux données utilisateur
      userData['uid'] = result.user!.uid;
      userData['status'] = 'pending_verification';

      // Sauvegarder dans Firestore
      await _firestoreService.createUser(result.user!.uid, userData);

      // Envoyer le code de vérification
      await _emailService.sendVerificationCode(email);

      // Déconnecter temporairement jusqu'à la vérification
      await _auth.signOut();

    } catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Inscription Livreur
  Future<void> registerDeliveryPerson(String email, String password, Map<String, dynamic> userData) async {
    _setLoading(true);

    try {
      // Créer le compte Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter l'UID aux données utilisateur
      userData['uid'] = result.user!.uid;
      userData['status'] = 'pending_verification';

      // Sauvegarder dans Firestore
      await _firestoreService.createUser(result.user!.uid, userData);

      // Envoyer le code de vérification
      await _emailService.sendVerificationCode(email);

      // Déconnecter temporairement jusqu'à la vérification
      await _auth.signOut();

    } catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Inscription Pharmacie (sans mot de passe)
  Future<void> registerPharmacy(Map<String, dynamic> userData) async {
    _setLoading(true);

    try {
      // Générer un ID unique pour la pharmacie
      String pharmacyId = FirebaseFirestore.instance.collection('pharmacies').doc().id;
      userData['id'] = pharmacyId;
      userData['status'] = 'pending_admin_approval';

      // Sauvegarder dans Firestore (collection séparée pour les demandes en attente)
      await _firestoreService.createPharmacyRequest(pharmacyId, userData);

      // Notifier l'administrateur
      await _emailService.notifyAdminPharmacyRequest(userData);

    } catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Connexion
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData();

      // Vérifier le statut de l'utilisateur
      if (_userData != null) {
        String status = _userData!['status'] ?? '';

        if (status == 'pending_verification') {
          await _auth.signOut();
          throw 'Veuillez d\'abord vérifier votre email';
        } else if (status == 'pending_approval') {
          await _auth.signOut();
          throw 'Votre compte est en attente d\'approbation';
        } else if (status == 'rejected') {
          await _auth.signOut();
          throw 'Votre demande a été rejetée. Contactez l\'administration';
        }
      }

    } catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Vérification email
  Future<void> verifyEmail(String code) async {
    _setLoading(true);

    try {
      // Vérifier le code avec le service email
      String email = await _emailService.verifyCode(code);

      // Mettre à jour le statut dans Firestore
      await _firestoreService.updateUserVerificationStatus(email);

      // Si c'est un client, activer le compte immédiatement
      // Si c'est un livreur, marquer comme "pending_approval"

    } catch (e) {
      throw 'Code de vérification invalide';
    } finally {
      _setLoading(false);
    }
  }

  // Renvoyer le code de vérification
  Future<void> resendVerificationCode(String email) async {
    _setLoading(true);

    try {
      await _emailService.sendVerificationCode(email);
    } catch (e) {
      throw 'Erreur lors du renvoi du code';
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Utilitaires
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
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
        default:
          return 'Erreur d\'authentification: ${e.message}';
      }
    }
    return e.toString();
  }

  // Getters pour le type d'utilisateur
  String? get userType => _userData?['userType'];
  bool get isClient => userType == UserTypes.client;
  bool get isPharmacy => userType == UserTypes.pharmacy;
  bool get isDeliveryPerson => userType == UserTypes.deliveryPerson;
  bool get isAdmin => userType == UserTypes.admin;

  // Vérifier si l'utilisateur est vérifié
  bool get isVerified => _userData?['isVerified'] == true;
  bool get isApproved => _userData?['isApproved'] == true;

  String get displayName {
    if (_userData == null) return '';

    switch (userType) {
      case UserTypes.pharmacy:
        return _userData!['pharmacyName'] ?? '';
      case UserTypes.client:
      case UserTypes.deliveryPerson:
        return _userData!['fullName'] ?? '';
      case UserTypes.admin:
        return _userData!['name'] ?? 'Administrateur';
      default:
        return '';
    }
  }
}