import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'guest/categories_browser_screen.dart';

class UserTypeLoginScreen extends StatelessWidget {
  const UserTypeLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo et titre
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: AppDimensions.logoSize + 40,  // Plus grand sans container ni ombre
                      height: AppDimensions.logoSize + 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    const Text(
                      "Choisissez votre type d'accès",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Boutons de sélection
              Expanded(
                child: Column(
                  children: [
                    // Connexion utilisateur standard
                    _buildUserTypeCard(
                      context,
                      title: 'Connexion Utilisateur',
                      subtitle: 'Client, Livreur, Pharmacie',
                      icon: Icons.person,
                      color: AppColors.primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Bouton Explorer sans se connecter
                    _buildUserTypeCard(
                      context,
                      title: 'Explorer les produits',
                      subtitle: 'Parcourir sans se connecter',
                      icon: Icons.explore,
                      color: AppColors.lightBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CategoriesBrowserScreen()),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}