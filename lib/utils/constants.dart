import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
}

class AppStrings {
  static const String appName = "Delivery App";
  static const String welcome = "Bienvenue";
  static const String login = "Connexion";
  static const String register = "S'inscrire";
  static const String email = "Email";
  static const String password = "Mot de passe";
  static const String confirmPassword = "Confirmer le mot de passe";
  static const String fullName = "Nom complet";
  static const String phoneNumber = "Numéro de téléphone";
  static const String address = "Adresse";
  static const String pharmacyName = "Nom de la pharmacie";
  static const String licenseNumber = "Numéro de licence";
  static const String openingHours = "Horaires d'ouverture";
  static const String agency = "Agence";
  static const String vehicleType = "Type d'engin";
  static const String plateNumber = "Numéro de plaque";
}

class UserTypes {
  static const String pharmacy = "pharmacy";
  static const String client = "client";
  static const String deliveryPerson = "delivery_person";
  static const String admin = "admin";
}

class VehicleTypes {
  static const List<String> types = [
    "Moto",
    "Scooter",
    "Vélo",
    "Voiture",
    "Piéton"
  ];
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double logoSize = 120.0;
}