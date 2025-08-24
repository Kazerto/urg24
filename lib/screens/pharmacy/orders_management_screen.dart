import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../models/pharmacy_model.dart';
import '../../utils/constants.dart';

class OrdersManagementScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const OrdersManagementScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel> allOrders = [];
  List<OrderModel> pendingOrders = [];
  List<OrderModel> confirmedOrders = [];
  List<OrderModel> preparingOrders = [];
  List<OrderModel> readyOrders = [];
  List<OrderModel> completedOrders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      List<OrderModel> orders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Trier côté client pour éviter l'index composé
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      
      allOrders = orders;

      _categorizeOrders();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des commandes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _categorizeOrders() {
    pendingOrders = allOrders.where((order) => order.status == OrderStatus.pending).toList();
    confirmedOrders = allOrders.where((order) => order.status == OrderStatus.confirmed).toList();
    preparingOrders = allOrders.where((order) => order.status == OrderStatus.preparing).toList();
    readyOrders = allOrders.where((order) => order.status == OrderStatus.ready).toList();
    completedOrders = allOrders.where((order) => 
        order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled).toList();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showOrderStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'En attente',
              icon: Badge(
                label: Text(pendingOrders.length.toString()),
                child: const Icon(Icons.pending),
              ),
            ),
            Tab(
              text: 'Confirmées',
              icon: Badge(
                label: Text(confirmedOrders.length.toString()),
                child: const Icon(Icons.check_circle_outline),
              ),
            ),
            Tab(
              text: 'Préparation',
              icon: Badge(
                label: Text(preparingOrders.length.toString()),
                child: const Icon(Icons.construction),
              ),
            ),
            Tab(
              text: 'Prêtes',
              icon: Badge(
                label: Text(readyOrders.length.toString()),
                child: const Icon(Icons.done_all),
              ),
            ),
            Tab(
              text: 'Terminées',
              icon: Badge(
                label: Text(completedOrders.length.toString()),
                child: const Icon(Icons.history),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(pendingOrders, OrderStatus.pending),
                _buildOrdersList(confirmedOrders, OrderStatus.confirmed),
                _buildOrdersList(preparingOrders, OrderStatus.preparing),
                _buildOrdersList(readyOrders, OrderStatus.ready),
                _buildOrdersList(completedOrders, null),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, OrderStatus? currentStatus) {
    if (orders.isEmpty) {
      return _buildEmptyState(currentStatus);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, currentStatus);
        },
      ),
    );
  }

  Widget _buildEmptyState(OrderStatus? status) {
    String message;
    IconData icon;
    
    switch (status) {
      case OrderStatus.pending:
        message = 'Aucune commande en attente';
        icon = Icons.pending;
        break;
      case OrderStatus.confirmed:
        message = 'Aucune commande confirmée';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.preparing:
        message = 'Aucune commande en préparation';
        icon = Icons.construction;
        break;
      case OrderStatus.ready:
        message = 'Aucune commande prête';
        icon = Icons.done_all;
        break;
      default:
        message = 'Aucune commande terminée';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderStatus? currentStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientPhone,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} articles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Commandé le ${_formatDateTime(order.orderDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (order.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (currentStatus != null) ...[
                const SizedBox(height: 12),
                _buildActionButtons(order, currentStatus),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmée';
        break;
      case OrderStatus.preparing:
        color = Colors.purple;
        text = 'Préparation';
        break;
      case OrderStatus.ready:
        color = Colors.green;
        text = 'Prête';
        break;
      case OrderStatus.inDelivery:
        color = Colors.teal;
        text = 'En livraison';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Livrée';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Annulée';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, OrderStatus currentStatus) {
    List<Widget> buttons = [];

    switch (currentStatus) {
      case OrderStatus.pending:
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.confirmed),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(order),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Refuser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;
      case OrderStatus.confirmed:
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
              icon: const Icon(Icons.construction, size: 16),
              label: const Text('Préparer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;
      case OrderStatus.preparing:
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Marquer prête'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;
      case OrderStatus.ready:
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showDeliveryDialog(order),
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text('Assigner livreur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;
      case OrderStatus.inDelivery:
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.delivered),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Marquer livrée'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        // Pas de boutons pour les commandes terminées
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commande #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderDetailSection('Client', [
                'Nom: ${order.clientName}',
                'Téléphone: ${order.clientPhone}',
                'Adresse: ${order.deliveryAddress}',
              ]),
              const SizedBox(height: 16),
              _buildOrderDetailSection('Commande', [
                'Date: ${_formatDateTime(order.orderDate)}',
                'Statut: ${_getStatusText(order.status)}',
                'Total: ${order.totalAmount.toStringAsFixed(0)} FCFA',
              ]),
              const SizedBox(height: 16),
              _buildOrderDetailSection('Articles', 
                order.items.map((item) => 
                  '${item.medicamentName} x${item.quantity} - ${item.totalPrice.toStringAsFixed(0)} FCFA'
                ).toList()
              ),
              if (order.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildOrderDetailSection('Notes', [order.notes!]),
              ],
              if (order.prescriptionUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildOrderDetailSection('Ordonnance', ['Disponible']),
              ],
              if (order.deliveryPersonName?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildOrderDetailSection('Livreur', [order.deliveryPersonName!]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item),
        )),
      ],
    );
  }

  void _showOrderStats() {
    final totalOrders = allOrders.length;
    final totalRevenue = allOrders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des commandes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total commandes', totalOrders.toString()),
            _buildStatRow('Chiffre d\'affaires', '${totalRevenue.toStringAsFixed(0)} FCFA'),
            _buildStatRow('Valeur moyenne', '${averageOrderValue.toStringAsFixed(0)} FCFA'),
            _buildStatRow('En attente', pendingOrders.length.toString()),
            _buildStatRow('Confirmées', confirmedOrders.length.toString()),
            _buildStatRow('En préparation', preparingOrders.length.toString()),
            _buildStatRow('Prêtes', readyOrders.length.toString()),
            _buildStatRow('Terminées', completedOrders.length.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order, OrderStatus.cancelled);
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un livreur'),
        content: const Text('Fonctionnalité en cours de développement.\nLa commande sera marquée comme en livraison.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order, OrderStatus.inDelivery);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      final updatedOrder = order.copyWith(
        status: newStatus,
        confirmationDate: newStatus == OrderStatus.confirmed ? DateTime.now() : order.confirmationDate,
        deliveryDate: newStatus == OrderStatus.delivered ? DateTime.now() : order.deliveryDate,
      );

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update(updatedOrder.toMap());

      _showSuccessSnackBar('Statut de la commande mis à jour');
      await _loadOrders();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}