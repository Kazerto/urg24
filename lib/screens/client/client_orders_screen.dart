import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  List<OrderModel> orders = [];
  bool isLoading = true;
  String filter = 'all'; // all, pending, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
      final clientEmail = authProvider.userData?['email']?.toString() ?? '';

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('clientEmail', isEqualTo: clientEmail)
          .get();

      List<OrderModel> ordersList = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Trier par date de commande décroissante
      ordersList.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      setState(() {
        orders = ordersList;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des commandes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<OrderModel> get filteredOrders {
    switch (filter) {
      case 'pending':
        return orders.where((order) => 
          order.status == OrderStatus.pending || 
          order.status == OrderStatus.confirmed ||
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.inDelivery
        ).toList();
      case 'completed':
        return orders.where((order) => order.status == OrderStatus.delivered).toList();
      case 'cancelled':
        return orders.where((order) => order.status == OrderStatus.cancelled).toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes commandes'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: filter == 'all' ? AppColors.primaryColor : null),
                    const SizedBox(width: 8),
                    const Text('Toutes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: filter == 'pending' ? Colors.orange : null),
                    const SizedBox(width: 8),
                    const Text('En cours'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: filter == 'completed' ? Colors.green : null),
                    const SizedBox(width: 8),
                    const Text('Livrées'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cancelled',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: filter == 'cancelled' ? Colors.red : null),
                    const SizedBox(width: 8),
                    const Text('Annulées'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'pending':
        message = 'Aucune commande en cours';
        icon = Icons.hourglass_empty;
        break;
      case 'completed':
        message = 'Aucune commande livrée';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'Aucune commande annulée';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Aucune commande trouvée';
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour actualiser',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut et date
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Commande #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Pharmacie et date
            Row(
              children: [
                Icon(Icons.local_pharmacy, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.pharmacyName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.orderDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Articles
            Text(
              'Articles (${order.items.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('• ${item.medicamentName}', style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    'x${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )),
            
            if (order.items.length > 3)
              Text(
                '... et ${order.items.length - 3} autres articles',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Total et actions
            Row(
              children: [
                Text(
                  'Total: ${order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                if (order.status == OrderStatus.pending)
                  TextButton(
                    onPressed: () {
                      // TODO: Permettre l'annulation
                      _showCancelDialog(order);
                    },
                    child: const Text('Annuler'),
                  ),
                TextButton(
                  onPressed: () {
                    // TODO: Voir les détails
                    _showOrderDetails(order);
                  },
                  child: const Text('Détails'),
                ),
              ],
            ),
          ],
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
        return Colors.green[700]!;
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
        return 'Préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.inDelivery:
        return 'Livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter l'annulation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Annulation en cours...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Détails de la commande',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.receipt),
                      title: const Text('Numéro de commande'),
                      subtitle: Text('#${order.id}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_pharmacy),
                      title: const Text('Pharmacie'),
                      subtitle: Text(order.pharmacyName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date de commande'),
                      subtitle: Text(_formatDate(order.orderDate)),
                    ),
                    const Divider(),
                    const Text(
                      'Articles commandés',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ...order.items.map((item) => ListTile(
                      title: Text(item.medicamentName),
                      subtitle: Text('Quantité: ${item.quantity}'),
                      trailing: Text('${item.price.toStringAsFixed(2)}€'),
                    )),
                    const Divider(),
                    ListTile(
                      title: const Text(
                        'Total',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${order.totalAmount.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
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
    );
  }
}