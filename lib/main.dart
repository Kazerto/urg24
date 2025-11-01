import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/client/client_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/pharmacy_requests_screen.dart';
import 'screens/admin/delivery_approvals_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/email_config_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/pharmacy/pharmacy_dashboard.dart';
import 'screens/pharmacy/stock_management_screen.dart';
import 'screens/pharmacy/orders_management_screen.dart';
import 'screens/pharmacy/partners_management_screen.dart';
import 'providers/auth_provider_simple.dart';
import 'providers/cart_provider.dart';
import 'services/firestore_service.dart';
import 'config/email_config.dart';
import 'utils/constants.dart';
import 'utils/firestore_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration Firebase pour web
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD8rP_wBobhMVNxp-JPsVt0JDrYRPSL84U",
        authDomain: "urgence24-1f259.firebaseapp.com",
        databaseURL: "https://urgence24-1f259-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "urgence24-1f259",
        storageBucket: "urgence24-1f259.firebasestorage.app",
        messagingSenderId: "978563578729",
        appId: "1:978563578729:web:6a6d8bebb248154ddc1bf8",
        measurementId: "G-XT5NDLEG6G",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  // Démarrer l'application immédiatement après Firebase
  runApp(const DeliveryApp());
  
  // Effectuer les initialisations lourdes en arrière-plan
  _initializeAppInBackground();
}

// Fonction pour initialiser l'application en arrière-plan
Future<void> _initializeAppInBackground() async {
  // Test de connexion Firestore et initialisation (seulement sur mobile)
  if (!kIsWeb) {
    try {
      bool firestoreOk = await FirestoreTest.testConnection();
      if (firestoreOk) {
        debugPrint('🚀 Firestore configuré correctement');
        
        // Initialiser les collections et créer l'admin par défaut en arrière-plan
        final firestoreService = FirestoreService();
        await firestoreService.initializePharmacyRequestsCollection();
        await firestoreService.createDefaultAdmin();
      } else {
        debugPrint('⚠️ Problème de configuration Firestore');
      }
      
      // Charger la configuration email sauvegardée
      await _loadEmailConfig();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation en arrière-plan: $e');
    }
  } else {
    debugPrint('🌐 Application web démarrée');
  }
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
          '/admin/pharmacy-requests': (context) => const PharmacyRequestsScreen(),
          '/admin/delivery-approvals': (context) => const DeliveryApprovalsScreen(),
          '/admin/notifications': (context) => const AdminNotificationsScreen(),
          '/admin/email-config': (context) => const EmailConfigScreen(),
          '/admin/users': (context) => const AdminUsersScreen(),
        },
        onGenerateRoute: (settings) {
          // Routes dynamiques pour les pharmacies
          if (settings.name?.startsWith('/pharmacy') == true) {
            final args = settings.arguments as Map<String, dynamic>?;
            final pharmacy = args?['pharmacy'];

            if (pharmacy == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Erreur: Données de pharmacie manquantes')),
                ),
              );
            }

            switch (settings.name) {
              case '/pharmacy-dashboard':
                return MaterialPageRoute(
                  builder: (_) => PharmacyDashboard(pharmacy: pharmacy),
                );
              case '/pharmacy/stock':
                return MaterialPageRoute(
                  builder: (_) => StockManagementScreen(pharmacy: pharmacy),
                );
              case '/pharmacy/orders':
                return MaterialPageRoute(
                  builder: (_) => OrdersManagementScreen(pharmacy: pharmacy),
                );
              case '/pharmacy/partners':
                return MaterialPageRoute(
                  builder: (_) => PartnersManagementScreen(pharmacy: pharmacy),
                );
            }
          }

          // Routes admin - placeholders pour les non implémentées
          if (settings.name?.startsWith('/admin') == true) {
            switch (settings.name) {
              case '/admin/analytics':
              case '/admin/backup':
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text('Fonctionnalité en développement'),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.construction, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 24),
                          Text(
                            'Cette fonctionnalité sera bientôt disponible',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
            }
          }

          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}