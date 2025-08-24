import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  
  // Fonctionnalités disponibles selon la plateforme
  static bool get canSendSMS => !kIsWeb;
  static bool get canMakePhoneCalls => !kIsWeb;
  static bool get canUseCamera => !kIsWeb;
  static bool get canAccessContacts => !kIsWeb;
  static bool get canUseGPS => true; // Web peut utiliser la géolocalisation
  static bool get canSendPushNotifications => true; // Les deux supportent
  static bool get canUseBiometrics => !kIsWeb;
  
  // Messages d'erreur pour fonctionnalités non supportées
  static String get smsNotSupported => 
      "L'envoi de SMS n'est pas disponible sur la version web. "
      "Utilisez l'application mobile ou contactez par email.";
      
  static String get callNotSupported => 
      "Les appels téléphoniques ne sont pas disponibles sur la version web. "
      "Utilisez l'application mobile ou appelez directement.";
      
  static String get cameraNotSupported => 
      "L'appareil photo n'est pas disponible sur la version web. "
      "Utilisez l'application mobile pour prendre des photos.";
}