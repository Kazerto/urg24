import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import 'pharmacy_requests_screen.dart';
import 'delivery_approvals_screen.dart';
import 'admin_notifications_screen.dart';
import 'email_config_screen.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderSimple>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.errorColor),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue, Administrateur',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez les demandes d\'inscription et supervisez la plateforme',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Statistiques rapides
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Cartes de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pharmacies\nen attente',
                    Icons.local_pharmacy,
                    AppColors.warningColor,
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getPendingPharmacyRequests(),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data?.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: _buildStatCard(
                    'Livreurs\nen attente',
                    Icons.delivery_dining,
                    AppColors.primaryColor,
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getPendingDeliveryPersons(),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data?.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Actions principales
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Boutons d'action
            _buildActionCard(
              'Demandes de pharmacies',
              'Examiner et approuver les nouvelles pharmacies',
              Icons.local_pharmacy,
              AppColors.warningColor,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PharmacyRequestsScreen(),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingMedium),

            _buildActionCard(
              'Approbation livreurs',
              'Valider les comptes des nouveaux livreurs',
              Icons.delivery_dining,
              AppColors.primaryColor,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeliveryApprovalsScreen(),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingMedium),

            _buildActionCard(
              'Notifications',
              'Voir toutes les notifications système',
              Icons.notifications,
              AppColors.secondaryColor,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationsScreen(),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingMedium),

            _buildActionCard(
              'Configuration Email',
              'Configurer SMTP pour envoi d\'emails',
              Icons.email_outlined,
              AppColors.warningColor,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmailConfigScreen(),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Activité récente
            const Text(
              'Activité récente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Liste des activités récentes
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getPendingPharmacyRequests(),
              builder: (context, pharmacySnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getPendingDeliveryPersons(),
                  builder: (context, deliverySnapshot) {
                    List<Widget> activities = [];

                    // Ajouter les demandes de pharmacies récentes
                    if (pharmacySnapshot.hasData) {
                      for (var pharmacy in pharmacySnapshot.data!.take(3)) {
                        activities.add(_buildActivityItem(
                          'Nouvelle demande de pharmacie',
                          pharmacy['pharmacyName'],
                          Icons.local_pharmacy,
                          AppColors.warningColor,
                          pharmacy['createdAt']?.toDate() ?? DateTime.now(),
                        ));
                      }
                    }

                    // Ajouter les demandes de livreurs récentes
                    if (deliverySnapshot.hasData) {
                      for (var delivery in deliverySnapshot.data!.take(3)) {
                        activities.add(_buildActivityItem(
                          'Nouveau livreur en attente',
                          delivery['fullName'],
                          Icons.delivery_dining,
                          AppColors.primaryColor,
                          delivery['createdAt']?.toDate() ?? DateTime.now(),
                        ));
                      }
                    }

                    if (activities.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucune activité récente',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return Column(children: activities);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, Widget countWidget) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          countWidget,
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else {
      return 'Il y a ${diff.inDays}j';
    }
  }
}