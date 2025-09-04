import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/universal_drawer.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/stock_model.dart';
import '../../utils/constants.dart';
import 'pharmacy_order_management_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyDashboard({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  int totalOrders = 0;
  int pendingOrders = 0;
  int totalStock = 0;
  int lowStockItems = 0;
  double totalRevenue = 0.0;
  List<OrderModel> recentOrders = [];
  List<StockModel> lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadOrderStats(),
      _loadStockStats(),
      _loadRecentOrders(),
      _loadLowStockProducts(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadOrderStats() async {
    try {
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      totalOrders = ordersQuery.docs.length;
      pendingOrders = ordersQuery.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      totalRevenue = ordersQuery.docs
          .where((doc) => doc.data()['status'] == 'delivered')
          .fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0));
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques de commandes: $e');
    }
  }

  Future<void> _loadStockStats() async {
    try {
      final stockQuery = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .get();

      totalStock = stockQuery.docs.length;
      lowStockItems = stockQuery.docs
          .where((doc) {
            final data = doc.data();
            return (data['quantity'] ?? 0) <= (data['minQuantity'] ?? 0);
          })
          .length;
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques de stock: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .limit(5)
          .get();

      List<OrderModel> orders = ordersQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Trier côté client pour éviter l'index composé
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      
      recentOrders = orders;
    } catch (e) {
      debugPrint('Erreur lors du chargement des commandes récentes: $e');
    }
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final stockQuery = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .get();

      lowStockProducts = stockQuery.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .where((stock) => stock.isLowStock)
          .take(5)
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des produits en rupture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Fermer l'application au lieu de revenir aux écrans de login
        return true; // Permet la sortie de l'app
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord - ${widget.pharmacy.pharmacyName}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: UniversalDrawer(
        userType: 'pharmacy',
        userName: widget.pharmacy.pharmacyName,
        userEmail: widget.pharmacy.email,
        userData: widget.pharmacy.toMap(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildStatsCards(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildRecentOrdersSection(),
              const SizedBox(height: 20),
              _buildLowStockSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context, 
            '/pharmacy/stock',
            arguments: {'pharmacy': widget.pharmacy},
          ).then((_) => _loadDashboardData()); // Refresh data when returning
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un médicament',
      ),
      ), // Ferme WillPopScope
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez efficacement votre pharmacie ${widget.pharmacy.pharmacyName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculer le nombre de colonnes selon la largeur d'écran
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 2;
            final itemWidth = (screenWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
            final itemHeight = itemWidth * 0.85; // Ratio adaptatif
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: itemWidth / itemHeight,
              children: [
                _buildStatCard(
                  'Commandes totales',
                  totalOrders.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Commandes en attente',
                  pendingOrders.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Produits en stock',
                  totalStock.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
                _buildStatCard(
                  'Stock faible',
                  lowStockItems.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // TODO: Section chiffre d'affaires temporairement commentée
        // _buildRevenueCard(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculer les tailles en fonction de la largeur disponible
          final cardWidth = constraints.maxWidth;
          final iconSize = (cardWidth * 0.25).clamp(24.0, 40.0);
          final valueFontSize = (cardWidth * 0.15).clamp(18.0, 28.0);
          final titleFontSize = (cardWidth * 0.08).clamp(10.0, 14.0);
          
          return Container(
            padding: EdgeInsets.all(cardWidth * 0.08),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  flex: 2,
                  child: Icon(icon, size: iconSize, color: color),
                ),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // TODO: Section chiffre d'affaires temporairement commentée
  /*
  Widget _buildRevenueCard() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.purple.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(Icons.monetization_on, size: 40, color: Colors.purple),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chiffre d\'affaires',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${totalRevenue.toStringAsFixed(0)} ${AppStrings.currency}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 4 : 3;
            final itemWidth = (screenWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
            final itemHeight = itemWidth; // Actions carrées
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: itemWidth / itemHeight,
              children: [
            _buildQuickActionCard(
              'Stock',
              Icons.inventory,
              Colors.blue,
              () => Navigator.pushNamed(
                context, 
                '/pharmacy/stock',
                arguments: {'pharmacy': widget.pharmacy}
              ),
            ),
            _buildQuickActionCard(
              'Commandes',
              Icons.receipt_long,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PharmacyOrderManagementScreen(pharmacy: widget.pharmacy),
                ),
              ),
            ),
            _buildQuickActionCard(
              'Partenaires',
              Icons.group,
              Colors.purple,
              () => Navigator.pushNamed(
                context, 
                '/pharmacy/partners',
                arguments: {'pharmacy': widget.pharmacy}
              ),
            ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Commandes récentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/pharmacy/orders'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentOrders.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Aucune commande récente',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            : Column(
                children: recentOrders
                    .map((order) => _buildOrderCard(order))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stock faible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/pharmacy/stock'),
              child: const Text('Gérer le stock'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        lowStockProducts.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Aucun produit en rupture',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            : Column(
                children: lowStockProducts
                    .map((product) => _buildLowStockCard(product))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Text(
            order.clientName.isNotEmpty ? order.clientName[0] : 'C',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        title: Text(order.clientName),
        subtitle: Text(
          '${order.items.length} articles - ${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getStatusText(order.status),
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDate(order.orderDate),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockCard(StockModel stock) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text(stock.medicamentName),
        subtitle: Text('Stock: ${stock.quantity} / Min: ${stock.minQuantity}'),
        trailing: TextButton(
          onPressed: () {
            // TODO: Naviger vers la gestion du stock spécifique
          },
          child: const Text('Réapprovisionner'),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.inDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.inDelivery:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}