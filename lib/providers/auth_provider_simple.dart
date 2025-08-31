import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service_simple.dart';
import '../utils/constants.dart';

class AuthProviderSimple with ChangeNotifier {
  final AuthServiceSimple _authService = AuthServiceSimple();
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _userData != null;
  
  // Types d'utilisateur
  String? get userType => _userData?['userType']?.toString();
  bool get isClient => userType == UserTypes.client;
  bool get isPharmacy => userType == UserTypes.pharmacy;
  bool get isDeliveryPerson => userType == UserTypes.deliveryPerson;
  bool get isAdmin => userType == UserTypes.admin;
  
  // Nom d'affichage
  String get displayName {
    if (_userData == null) return '';
    
    switch (userType) {
      case UserTypes.pharmacy:
        return _userData!['pharmacyName']?.toString() ?? '';
      case UserTypes.admin:
        return _userData!['name']?.toString() ?? 'Administrateur';
      default:
        return _userData!['fullName']?.toString() ?? '';
    }
  }

  AuthProviderSimple() {
    // Écouter les changements d'état d'authentification
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // Vérifier l'authentification persistante au démarrage
  Future<bool> checkPersistedAuth() async {
    try {
      _setLoading(true);
      
      // Attendre que Firebase Auth soit complètement initialisé
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Forcer une vérification de l'état actuel
      await FirebaseAuth.instance.authStateChanges().first;
      
      // Vérifier si un utilisateur est déjà connecté
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('🔍 Aucun utilisateur persisté trouvé après vérification');
        return false;
      }

      debugPrint('🔍 Utilisateur persisté trouvé: ${currentUser.email}');
      
      // Récupérer les données utilisateur depuis Firestore
      Map<String, dynamic>? userData = await _authService.getCurrentUserData(currentUser.uid);
      
      if (userData != null) {
        _user = currentUser;
        _userData = userData;
        notifyListeners();
        debugPrint('✅ Authentification persistante réussie: ${userData['userType']}');
        return true;
      } else {
        debugPrint('⚠️ Données utilisateur non trouvées, déconnexion nécessaire');
        await FirebaseAuth.instance.signOut();
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erreur vérification auth persistante: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user == null) {
      _userData = null;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Inscription
  Future<String> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    _setLoading(true);
    try {
      String verificationCode = await _authService.registerUser(
        email: email,
        password: password,
        userData: userData,
      );
      return verificationCode;
    } finally {
      _setLoading(false);
    }
  }

  // Connexion
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      Map<String, dynamic>? userData = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (userData != null) {
        _userData = userData;
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  // Vérification email
  Future<void> verifyEmail(String code) async {
    _setLoading(true);
    try {
      await _authService.verifyEmail(code);
    } finally {
      _setLoading(false);
    }
  }

  // Renvoyer code de vérification
  Future<String> resendVerificationCode(String email) async {
    _setLoading(true);
    try {
      // Pour simplifier, on génère un nouveau code
      String newCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Sauvegarder le nouveau code (simulation)
      debugPrint('📧 Nouveau code pour $email: $newCode');
      
      return newCode;
    } finally {
      _setLoading(false);
    }
  }

  // Inscription spécifique pharmacie (sauvegarder dans pharmacy_requests avec vérification email)
  Future<String> registerPharmacy(Map<String, dynamic> pharmacyData) async {
    _setLoading(true);
    try {
      // Préparer les données pour la demande de pharmacie
      Map<String, dynamic> requestData = {
        'pharmacyName': pharmacyData['pharmacyName'],
        'email': pharmacyData['email'],
        'phoneNumber': pharmacyData['phoneNumber'],
        'address': pharmacyData['address'],
        'licenseNumber': pharmacyData['licenseNumber'],
        'openingHours': pharmacyData['openingHours'],
        'status': 'pending_verification', // D'abord vérification email
        'isVerified': false,
        'isApproved': false,
        'createdAt': DateTime.now(),
      };

      // Sauvegarder dans pharmacy_requests
      await FirebaseFirestore.instance
          .collection('pharmacy_requests')
          .add(requestData);

      debugPrint('✅ Demande de pharmacie sauvegardée: ${pharmacyData['pharmacyName']}');

      // Sauvegarder le mot de passe temporaire pour pouvoir le retrouver lors de l'approbation
      String tempPassword = 'temp_pharmacy_${pharmacyData['email'].hashCode}';
      
      // Mettre à jour la demande avec le mot de passe temporaire (hashé)
      await FirebaseFirestore.instance
          .collection('pharmacy_requests')
          .where('email', isEqualTo: pharmacyData['email'])
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'tempPasswordHash': tempPassword.hashCode.toString(),
          });
        }
      });

      // Envoyer le code de vérification par email
      String verificationCode = await _authService.registerUser(
        email: pharmacyData['email'],
        password: tempPassword,
        userData: {'userType': 'pharmacy_request', 'email': pharmacyData['email']},
      );

      return verificationCode;
    } finally {
      _setLoading(false);
    }
  }

  // Inscription spécifique livreur (avec compte Firebase Auth et vérification email)
  Future<String> registerDeliveryPerson({
    required String email,
    required String password,
    required Map<String, dynamic> deliveryData,
  }) async {
    _setLoading(true);
    try {
      debugPrint('🔍 Début inscription livreur pour: $email');
      
      // 1. Créer le compte Firebase Auth et récupérer l'UID avant déconnexion
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      String uid = userCredential.user!.uid;
      debugPrint('✅ Compte Firebase Auth créé avec UID: $uid');

      // 2. Ajouter les métadonnées spécifiques aux livreurs
      deliveryData['userType'] = UserTypes.deliveryPerson;
      deliveryData['createdAt'] = DateTime.now();
      deliveryData['status'] = 'pending_verification'; // D'abord vérification email
      deliveryData['isVerified'] = false;
      deliveryData['isApproved'] = false;
      deliveryData['uid'] = uid;
      deliveryData['email'] = email;

      // 3. Sauvegarder dans users via le service d'auth
      String verificationCode = await _authService.registerUser(
        email: email,
        password: password,
        userData: deliveryData,
      );

      debugPrint('✅ Email de vérification envoyé');

      // 4. Sauvegarder aussi dans delivery_persons pour référence admin
      await FirebaseFirestore.instance
          .collection('delivery_persons')
          .add({
            ...deliveryData,
            'firebaseUid': uid,
          });

      debugPrint('✅ Données livreur sauvées dans delivery_persons');

      // 5. Notifier l'admin
      await _authService.notifyAdminDeliveryRequest(deliveryData);

      return verificationCode;
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userData = null;
    notifyListeners();
  }
}