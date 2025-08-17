import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Déconnexion
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userData = null;
    notifyListeners();
  }
}