import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_simple.dart';
import '../screens/user_type_login_screen.dart';
import '../screens/client/client_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/pharmacy/pharmacy_dashboard.dart';
import '../models/pharmacy_model.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Vérifier l'authentification persistante après l'animation
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    try {
      final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
      
      // Attendre l'animation et laisser du temps à Firebase de s'initialiser
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('🔍 Splash: Vérification de l\'authentification persistante...');
      
      // Vérifier l'authentification persistante
      bool isAuthenticated = await authProvider.checkPersistedAuth();
      
      debugPrint('🔍 Splash: Résultat auth persistante: $isAuthenticated');
      
      if (!mounted) return;
      
      if (isAuthenticated && authProvider.userData != null) {
        // Utilisateur déjà connecté, naviguer vers le dashboard approprié
        _navigateToDashboard(authProvider.userType ?? '');
      } else {
        // Pas d'utilisateur connecté, aller à la page de connexion
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserTypeLoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification auth: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserTypeLoginScreen()),
        );
      }
    }
  }
  
  void _navigateToDashboard(String userType) {
    Widget destinationScreen;
    
    switch (userType.toLowerCase()) {
      case 'client':
        destinationScreen = const ClientDashboard();
        break;
      case 'admin':
        destinationScreen = const AdminDashboardScreen();
        break;
      case 'pharmacy':
        // Pour la pharmacie, il faut convertir les données en PharmacyModel
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        final userData = authProvider.userData!;
        final pharmacy = PharmacyModel.fromMap(userData, userData['uid'] ?? '');
        destinationScreen = PharmacyDashboard(pharmacy: pharmacy);
        break;
      default:
        // Type d'utilisateur non reconnu, retourner à la connexion
        destinationScreen = const UserTypeLoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de l'application
              Container(
                width: AppDimensions.logoSize,
                height: AppDimensions.logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: AppDimensions.logoSize,
                    height: AppDimensions.logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              // Nom de l'application
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              // Sous-titre
              const Text(
                "Livraison de médicaments",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}