import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

  Future<void> _adminLogin() async {
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

        // Vérifier que c'est bien un admin
        if (authProvider.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          await authProvider.signOut();
          throw 'Accès refusé: Vous n\'êtes pas administrateur';
        }

      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo et titre admin
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          child: Container(
                            color: Colors.white,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      const Text(
                        'Accès réservé aux administrateurs',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // Informations par défaut (à supprimer en production)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppColors.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Identifiants par défaut:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: admin@urgence24.com\nMot de passe: admin123',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

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

                // Bouton de connexion admin
                CustomButton(
                  text: 'Connexion Administrateur',
                  onPressed: _isLoading ? null : _adminLogin,
                  isLoading: _isLoading,
                  color: AppColors.primaryColor,
                ),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Message de sécurité
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      Expanded(
                        child: Text(
                          'Cet accès est sécurisé et surveillé. Toute tentative d\'accès non autorisée sera enregistrée.',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12,
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