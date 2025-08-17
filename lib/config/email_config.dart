class EmailConfig {
  // Configuration SMTP Gmail
  // IMPORTANT: En production, ces valeurs doivent être dans des variables d'environnement
  // ou un fichier de configuration sécurisé
  
  static const String senderEmail = 'urgence24.noreply@gmail.com'; // À remplacer par votre email
  static const String senderPassword = 'votre_mot_de_passe_app_ici'; // À remplacer par le mot de passe d'application
  static const String senderName = 'Urgence24 - Livraison de médicaments';
  
  // Configuration du serveur SMTP
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const bool useSSL = false;
  static const bool useTLS = true;
  
  // Template d'email
  static const String appName = 'Urgence24';
  static const String appColor = '#2196F3';
  static const String supportEmail = 'support@urgence24.com';
  
  // Durée d'expiration des codes de vérification (en minutes)
  static const int codeExpirationMinutes = 15;
}

// Classe pour gérer les credentials de manière sécurisée
class SecureEmailConfig {
  // Cette classe peut être utilisée pour charger les configurations
  // depuis des variables d'environnement ou des fichiers sécurisés
  
  static String? _senderEmail;
  static String? _senderPassword;
  
  static void setCredentials(String email, String password) {
    _senderEmail = email;
    _senderPassword = password;
  }
  
  static String get senderEmail => _senderEmail ?? EmailConfig.senderEmail;
  static String get senderPassword => _senderPassword ?? EmailConfig.senderPassword;
  
  static bool get isConfigured => 
    _senderEmail != null && _senderPassword != null &&
    _senderPassword != 'votre_mot_de_passe_app_ici';
}