import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/universal_drawer.dart';
import '../guest/categories_browser_screen.dart';
import 'client_orders_screen.dart';
import '../../utils/constants.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Tableau de bord - Client'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
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
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.paddingMedium,
                  mainAxisSpacing: AppDimensions.paddingMedium,
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
                            builder: (context) => const CategoriesBrowserScreen(),
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
                      icon: Icons.local_pharmacy,
                      title: 'Pharmacies\npartenaires',
                      subtitle: 'Près de vous',
                      color: AppColors.successColor,
                      onTap: () {
                        // TODO: Naviguer vers les pharmacies
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité en développement'),
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
                        // TODO: Naviguer vers le profil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité en développement'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}