import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_simple.dart';
import '../models/pharmacy_model.dart';
import '../models/delivery_person.dart';
import '../utils/constants.dart';
// Client screens
import '../screens/client/pharmacy_selection_screen.dart';
import '../screens/client/client_orders_screen.dart';
import '../screens/client/client_profile_screen.dart';
// Delivery screens
import '../screens/delivery/available_deliveries_screen.dart';
import '../screens/delivery/my_deliveries_screen.dart';
import '../screens/delivery/delivery_profile_screen.dart';
// Pharmacy screens
import '../screens/pharmacy/pharmacy_profile_screen.dart';

class UniversalDrawer extends StatelessWidget {
  final String userType;
  final String userName;
  final String userEmail;
  final Map<String, dynamic>? userData;

  const UniversalDrawer({
    super.key,
    required this.userType,
    required this.userName,
    required this.userEmail,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildUserHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(context),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final profileImageUrl = userData?['profileImageUrl'] as String?;

    // Debug: afficher l'URL de l'image de profil
    debugPrint('🖼️ Profile image URL pour $userName: $profileImageUrl');

    return UserAccountsDrawerHeader(
      accountName: Text(
        userName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: Text(userEmail),
      currentAccountPicture: _buildProfileAvatar(profileImageUrl),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl) {
    // Si l'URL existe et n'est pas vide, essayer de charger l'image
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            profileImageUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Erreur chargement image profil: $error');
              // En cas d'erreur, afficher l'initiale
              return _buildInitialAvatar();
            },
          ),
        ),
      );
    }

    // Pas d'URL, afficher l'initiale
    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    List<Widget> items = [];

    items.add(_buildMenuItem(
      context,
      Icons.dashboard,
      'Tableau de bord',
      () => _navigateToRoute(context, _getDashboardRoute()),
    ));

    switch (userType.toLowerCase()) {
      case 'pharmacy':
        items.addAll(_buildPharmacyMenuItems(context));
        break;
      case 'client':
        items.addAll(_buildClientMenuItems(context));
        break;
      case 'delivery':
        items.addAll(_buildDeliveryMenuItems(context));
        break;
      case 'admin':
        items.addAll(_buildAdminMenuItems(context));
        break;
    }

    items.addAll([
      const Divider(),
      _buildMenuItem(
        context,
        Icons.help,
        'Aide',
        () => _showHelpDialog(context),
      ),
    ]);

    return items;
  }

  List<Widget> _buildPharmacyMenuItems(BuildContext context) {
    final pharmacy = _getPharmacyFromData();

    return [
      const Divider(),
      _buildSectionHeader('Gestion'),
      _buildMenuItem(
        context,
        Icons.inventory,
        'Stock',
        () => _navigateToRoute(context, '/pharmacy/stock'),
      ),
      _buildMenuItem(
        context,
        Icons.receipt_long,
        'Commandes',
        () => _navigateToRoute(context, '/pharmacy/orders'),
      ),
      _buildMenuItem(
        context,
        Icons.group,
        'Partenaires',
        () => _navigateToRoute(context, '/pharmacy/partners'),
      ),
      _buildMenuItem(
        context,
        Icons.person,
        'Mon profil',
        () {
          Navigator.pop(context);
          if (pharmacy != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PharmacyProfileScreen(pharmacy: pharmacy),
              ),
            );
          }
        },
      ),
      const Divider(),
      _buildSectionHeader('Statistiques'),
      _buildMenuItem(
        context,
        Icons.analytics,
        'Rapports',
        () {
          Navigator.pop(context);
          _showComingSoonDialog(context, 'Rapports');
        },
      ),
    ];
  }

  List<Widget> _buildClientMenuItems(BuildContext context) {
    return [
      const Divider(),
      _buildSectionHeader('Services'),
      _buildMenuItem(
        context,
        Icons.search,
        'Rechercher pharmacies',
        () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PharmacySelectionScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        Icons.history,
        'Mes commandes',
        () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientOrdersScreen()),
          );
        },
      ),
      _buildMenuItem(
        context,
        Icons.favorite,
        'Favoris',
        () {
          Navigator.pop(context);
          _showComingSoonDialog(context, 'Favoris');
        },
      ),
      _buildMenuItem(
        context,
        Icons.person,
        'Mon profil',
        () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientProfileScreen()),
          );
        },
      ),
    ];
  }

  List<Widget> _buildDeliveryMenuItems(BuildContext context) {
    final deliveryPerson = _getDeliveryPersonFromData();

    return [
      const Divider(),
      _buildSectionHeader('Livraisons'),
      _buildMenuItem(
        context,
        Icons.local_shipping,
        'Livraisons disponibles',
        () {
          Navigator.pop(context);
          if (deliveryPerson != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AvailableDeliveriesScreen(deliveryPerson: deliveryPerson),
              ),
            );
          }
        },
      ),
      _buildMenuItem(
        context,
        Icons.history,
        'Mes livraisons',
        () {
          Navigator.pop(context);
          if (deliveryPerson != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyDeliveriesScreen(deliveryPerson: deliveryPerson),
              ),
            );
          }
        },
      ),
      _buildMenuItem(
        context,
        Icons.person,
        'Mon profil',
        () {
          Navigator.pop(context);
          if (deliveryPerson != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryProfileScreen(deliveryPerson: deliveryPerson),
              ),
            );
          }
        },
      ),
    ];
  }

  List<Widget> _buildAdminMenuItems(BuildContext context) {
    return [
      const Divider(),
      _buildSectionHeader('Administration'),
      _buildMenuItem(
        context,
        Icons.local_pharmacy,
        'Demandes pharmacies',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/pharmacy-requests');
        },
      ),
      _buildMenuItem(
        context,
        Icons.delivery_dining,
        'Livreurs',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/delivery-approvals');
        },
      ),
      _buildMenuItem(
        context,
        Icons.notifications,
        'Notifications',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/notifications');
        },
      ),
      _buildMenuItem(
        context,
        Icons.email,
        'Configuration Email',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/email-config');
        },
      ),
      const Divider(),
      _buildSectionHeader('Gestion'),
      _buildMenuItem(
        context,
        Icons.people,
        'Utilisateurs',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/users');
        },
      ),
      _buildMenuItem(
        context,
        Icons.analytics,
        'Statistiques',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/analytics');
        },
      ),
      _buildMenuItem(
        context,
        Icons.backup,
        'Sauvegarde',
        () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/backup');
        },
      ),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () => _logout(context),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getDashboardRoute() {
    switch (userType.toLowerCase()) {
      case 'pharmacy':
        return '/pharmacy-dashboard';
      case 'client':
        return '/client-dashboard';
      case 'admin':
        return '/admin-dashboard';
      case 'delivery':
        return '/delivery-dashboard';
      default:
        return '/';
    }
  }

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pop(context); // Fermer le drawer
    if (ModalRoute.of(context)?.settings.name != route) {
      // Pour les routes de pharmacie, passer les arguments nécessaires
      if (route.startsWith('/pharmacy') && userType.toLowerCase() == 'pharmacy') {
        Navigator.pushReplacementNamed(
          context, 
          route,
          arguments: _getPharmacyArguments(),
        );
      } else {
        Navigator.pushReplacementNamed(context, route);
      }
    }
  }
  
  Map<String, dynamic>? _getPharmacyArguments() {
    if (userData != null && userType.toLowerCase() == 'pharmacy') {
      // Convertir les données en PharmacyModel
      PharmacyModel pharmacy = PharmacyModel.fromMap(userData!, userData!['uid'] ?? '');
      return {'pharmacy': pharmacy};
    }
    return null;
  }

  PharmacyModel? _getPharmacyFromData() {
    if (userData != null && userType.toLowerCase() == 'pharmacy') {
      try {
        return PharmacyModel.fromMap(userData!, userData!['uid'] ?? '');
      } catch (e) {
        debugPrint('Erreur lors de la conversion des données de la pharmacie: $e');
        return null;
      }
    }
    return null;
  }

  DeliveryPersonModel? _getDeliveryPersonFromData() {
    if (userData != null && userType.toLowerCase() == 'delivery') {
      try {
        return DeliveryPersonModel.fromMap(userData!, userData!['uid'] ?? '');
      } catch (e) {
        debugPrint('Erreur lors de la conversion des données du livreur: $e');
        return null;
      }
    }
    return null;
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('La fonctionnalité "$feature" sera bientôt disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.pop(context); // Fermer le drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: const Text('Fonctionnalité en cours de développement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    Navigator.pop(context); // Fermer le drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour obtenir de l\'aide:'),
            SizedBox(height: 8),
            Text('• Consultez la documentation'),
            Text('• Contactez le support technique'),
            Text('• Email: support@urgence24.com'),
            Text('• Téléphone: +237 123 456 789'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Fermer le drawer
              
              // Déconnexion
              await Provider.of<AuthProviderSimple>(context, listen: false).signOut();
              
              // Redirection vers la page d'accueil
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // Route vers la page d'accueil (SplashScreen)
                  (route) => false, // Supprimer toutes les routes précédentes
                );
              }
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}