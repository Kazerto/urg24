import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/client/client_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'providers/auth_provider_simple.dart';
import 'services/firestore_service.dart';
import 'config/email_config.dart';
import 'utils/constants.dart';
import 'utils/firestore_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Test de connexion Firestore
  bool firestoreOk = await FirestoreTest.testConnection();
  if (firestoreOk) {
    debugPrint('🚀 Firestore configuré correctement');
    
    // Créer l'admin par défaut
    final firestoreService = FirestoreService();
    await firestoreService.createDefaultAdmin();
  } else {
    debugPrint('⚠️ Problème de configuration Firestore');
  }
  
  // Charger la configuration email sauvegardée
  await _loadEmailConfig();
  
  runApp(const DeliveryApp());
}

// Charger la configuration email sauvegardée
Future<void> _loadEmailConfig() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('smtp_email');
    final password = prefs.getString('smtp_password');
    
    if (email != null && password != null) {
      SecureEmailConfig.setCredentials(email, password);
      debugPrint('📧 Configuration email chargée');
    } else {
      debugPrint('⚠️ Aucune configuration email trouvée');
    }
  } catch (e) {
    debugPrint('❌ Erreur lors du chargement de la configuration email: $e');
  }
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviderSimple()),
      ],
      child: MaterialApp(
        title: 'Delivery App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryColor,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
        routes: {
          '/client-dashboard': (context) => const ClientDashboard(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}