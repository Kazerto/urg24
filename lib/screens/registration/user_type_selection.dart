import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import 'pharmacy_registration.dart';
import 'client_registration.dart';
import 'delivery_registration.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  void _navigateToRegistration(BuildContext context, String userType) {
    Widget screen;
    switch (userType) {
      case UserTypes.pharmacy:
        screen = const PharmacyRegistrationScreen();
        break;
      case UserTypes.client:
        screen = const ClientRegistrationScreen();
        break;
      case UserTypes.deliveryPerson:
        screen = const DeliveryRegistrationScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Type de compte'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Choisissez votre type de compte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sélectionnez le type de compte qui vous correspond',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Option Pharmacie
              _UserTypeCard(
                title: 'Pharmacie',
                subtitle: 'Je suis une pharmacie qui souhaite vendre des médicaments',
                icon: Icons.local_pharmacy,
                color: AppColors.primaryColor,
                onTap: () => _navigateToRegistration(context, UserTypes.pharmacy),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Option Client
              _UserTypeCard(
                title: 'Client',
                subtitle: 'Je souhaite commander des médicaments',
                icon: Icons.person,
                color: AppColors.secondaryColor,
                onTap: () => _navigateToRegistration(context, UserTypes.client),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Option Livreur
              _UserTypeCard(
                title: 'Livreur',
                subtitle: 'Je souhaite livrer des médicaments',
                icon: Icons.delivery_dining,
                color: AppColors.accentColor,
                onTap: () => _navigateToRegistration(context, UserTypes.deliveryPerson),
              ),

              const Spacer(),

              // Bouton retour
              CustomButton(
                text: 'Retour à la connexion',
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}