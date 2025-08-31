import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_simple.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../models/pharmacy_model.dart';
import '../services/firestore_service.dart';
import 'registration/user_type_selection.dart';
import 'client/client_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'admin/sync_admin_screen.dart';
import 'pharmacy/pharmacy_dashboard.dart';
import 'delivery/delivery_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateToPharmacyDashboard(AuthProviderSimple authProvider) async {
    try {
      // Récupérer les données de la pharmacie depuis Firestore
      final firestoreService = FirestoreService();
      final pharmacyData = await firestoreService.getPharmacyByEmail(authProvider.userData!['email']);
      
      if (pharmacyData != null) {
        final pharmacy = PharmacyModel.fromMap(pharmacyData, pharmacyData['id'] ?? '');
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PharmacyDashboard(pharmacy: pharmacy),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Données de pharmacie introuvables'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Navigation selon le type d'utilisateur
        if (mounted) {
          final userType = authProvider.userType;
          switch (userType) {
            case 'client':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ClientDashboard()),
              );
              break;
            case 'admin':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
              break;
            case 'pharmacy':
              await _navigateToPharmacyDashboard(authProvider);
              break;
            case 'delivery_person':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DeliveryDashboardScreen()),
              );
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Type d\'utilisateur non reconnu'),
                  backgroundColor: AppColors.errorColor,
                ),
              );
          }
        }

      } catch (e) {
        // Vérifier si l'erreur concerne un profil admin non trouvé
        if (e.toString().contains('Aucun profil utilisateur trouvé') && 
            _emailController.text.trim() == 'admin@urgence24.com') {
          // Rediriger vers l'écran de synchronisation admin
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SyncAdminScreen()),
          );
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserTypeSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      const Text(
                        'Connectez-vous à votre compte',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Champ email
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Champ mot de passe
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Bouton de connexion
                CustomButton(
                  text: 'Se connecter',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Lien vers l'inscription
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Vous n\'avez pas de compte ?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToRegistration,
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}