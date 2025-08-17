import 'package:email_validator/email_validator.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!EmailValidator.validate(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    // Validation simple pour les numéros de téléphone gabonais
    if (!RegExp(r'^(\+241|241)?[0-9]{8}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    return null;
  }

  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de licence est requis';
    }
    if (value.length < 5) {
      return 'Le numéro de licence doit contenir au moins 5 caractères';
    }
    return null;
  }

  static String? validatePlateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de plaque est requis';
    }
    if (value.length < 3) {
      return 'Veuillez entrer un numéro de plaque valide';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom complet est requis';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Veuillez entrer votre nom et prénom';
    }
    return null;
  }

  static String? validatePharmacyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom de la pharmacie est requis';
    }
    if (value.length < 3) {
      return 'Le nom de la pharmacie doit contenir au moins 3 caractères';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse est requise';
    }
    if (value.length < 10) {
      return 'Veuillez entrer une adresse complète';
    }
    return null;
  }

  static String? validateOpeningHours(String? value) {
    if (value == null || value.isEmpty) {
      return 'Les horaires d\'ouverture sont requis';
    }
    // Validation simple pour le format "HH:MM - HH:MM"
    if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
      return 'Format: HH:MM - HH:MM (ex: 08:00 - 18:00)';
    }
    return null;
  }
}