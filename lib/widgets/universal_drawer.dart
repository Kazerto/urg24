import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_simple.dart';
import '../models/pharmacy_model.dart';
import '../utils/constants.dart';

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
    return UserAccountsDrawerHeader(
      accountName: Text(
        userName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: Text(userEmail),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
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
        Icons.settings,
        'Paramètres',
        () => _showSettingsDialog(context),
      ),
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
      const Divider(),
      _buildSectionHeader('Statistiques'),
      _buildMenuItem(
        context,
        Icons.analytics,
        'Rapports',
        () => Navigator.pushNamed(context, '/pharmacy/reports'),
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
        () => Navigator.pushNamed(context, '/client/search'),
      ),
      _buildMenuItem(
        context,
        Icons.history,
        'Mes commandes',
        () => Navigator.pushNamed(context, '/client/orders'),
      ),
      _buildMenuItem(
        context,
        Icons.favorite,
        'Favoris',
        () => Navigator.pushNamed(context, '/client/favorites'),
      ),
    ];
  }

  List<Widget> _buildDeliveryMenuItems(BuildContext context) {
    return [
      const Divider(),
      _buildSectionHeader('Livraisons'),
      _buildMenuItem(
        context,
        Icons.local_shipping,
        'Livraisons en cours',
        () => Navigator.pushNamed(context, '/delivery/active'),
      ),
      _buildMenuItem(
        context,
        Icons.history,
        'Historique',
        () => Navigator.pushNamed(context, '/delivery/history'),
      ),
      _buildMenuItem(
        context,
        Icons.map,
        'Itinéraires',
        () => Navigator.pushNamed(context, '/delivery/routes'),
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
        () => Navigator.pushNamed(context, '/admin/pharmacy-requests'),
      ),
      _buildMenuItem(
        context,
        Icons.delivery_dining,
        'Livreurs',
        () => Navigator.pushNamed(context, '/admin/delivery-approvals'),
      ),
      _buildMenuItem(
        context,
        Icons.notifications,
        'Notifications',
        () => Navigator.pushNamed(context, '/admin/notifications'),
      ),
      _buildMenuItem(
        context,
        Icons.sync,
        'Synchronisation',
        () => Navigator.pushNamed(context, '/admin/sync'),
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
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Fermer le drawer
              Provider.of<AuthProviderSimple>(context, listen: false).signOut();
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}