import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/universal_drawer.dart';
import '../guest/categories_browser_screen.dart';
import 'client_orders_screen.dart';
import 'teleconseil_screen.dart';
import 'prescription_scanner_screen.dart';
import 'my_prescriptions_screen.dart';
import 'pharmacy_selection_screen.dart';
import 'client_profile_screen.dart';
import '../../utils/constants.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Double-tap pour sortir de l'application
        final currentTime = DateTime.now();
        if (_lastBackPress == null || 
            currentTime.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = currentTime;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez encore une fois pour quitter'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
          return false; // Ne pas quitter encore
        }
        return true; // Quitter l'app après le second tap
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,  // Taille optimale pour l'AppBar client
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'Tableau de bord - Client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh dashboard data
            },
          ),
        ],
      ),
      drawer: Consumer<AuthProviderSimple>(
        builder: (context, authProvider, child) {
          return UniversalDrawer(
            userType: 'client',
            userName: authProvider.displayName,
            userEmail: authProvider.userData?['email']?.toString() ?? '',
            userData: authProvider.userData,
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message de bienvenue
              Consumer<AuthProviderSimple>(
                builder: (context, authProvider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: AppColors.primaryColor,
                            size: 50,
                          ),
                          const SizedBox(width: AppDimensions.paddingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bienvenue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Client',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Actions rapides
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              // Grille d'actions
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 600 ? 3 : 2;
                    final itemWidth = (screenWidth - (crossAxisCount - 1) * AppDimensions.paddingMedium) / crossAxisCount;
                    final itemHeight = itemWidth * 0.8; // Ratio adaptatif pour les cartes d'action
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppDimensions.paddingMedium,
                      mainAxisSpacing: AppDimensions.paddingMedium,
                      childAspectRatio: itemWidth / itemHeight,
                      children: [
                    _buildActionCard(
                      icon: Icons.medication,
                      title: 'Commander\nmédicaments',
                      subtitle: 'Nouvelle commande',
                      color: AppColors.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PharmacySelectionScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.history,
                      title: 'Mes\ncommandes',
                      subtitle: 'Historique',
                      color: AppColors.accentColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.headset_mic,
                      title: 'Téléconseil',
                      subtitle: 'Aide & Support',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeleConseilScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.description,
                      title: 'Mes\nordonnances',
                      subtitle: 'Gestion',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyPrescriptionsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.person,
                      title: 'Mon\nprofil',
                      subtitle: 'Paramètres',
                      color: AppColors.textSecondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientProfileScreen(),
                          ),
                        );
                      },
                    ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ), // Ferme WillPopScope
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}