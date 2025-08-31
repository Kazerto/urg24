import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import 'order_details_screen.dart';

class PharmacyOrderManagementScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyOrderManagementScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyOrderManagementScreen> createState() => _PharmacyOrderManagementScreenState();
}

class _PharmacyOrderManagementScreenState extends State<PharmacyOrderManagementScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _statusFilters = [
    {'key': 'all', 'label': 'Toutes', 'count': 0},
    {'key': 'pending', 'label': 'En attente', 'count': 0},
    {'key': 'preparing', 'label': 'En préparation', 'count': 0},
    {'key': 'ready', 'label': 'Prêtes', 'count': 0},
    {'key': 'inDelivery', 'label': 'En livraison', 'count': 0},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      final List<OrderModel> orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Sort client-side to avoid compound index requirement
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      setState(() {
        _orders = orders;
        _updateStatusCounts();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des commandes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateStatusCounts() {
    // Reset counts
    for (var filter in _statusFilters) {
      filter['count'] = 0;
    }

    // Count orders by status
    for (var order in _orders) {
      _statusFilters[0]['count']++; // All orders

      switch (order.status) {
        case OrderStatus.pending:
          _statusFilters[1]['count']++;
          break;
        case OrderStatus.preparing:
          _statusFilters[2]['count']++;
          break;
        case OrderStatus.ready:
          _statusFilters[3]['count']++;
          break;
        case OrderStatus.inDelivery:
          _statusFilters[4]['count']++;
          break;
        default:
          break;
      }
    }
  }

  List<OrderModel> _getFilteredOrders() {
    if (_selectedFilter == 'all') {
      return _orders;
    }

    final OrderStatus targetStatus = OrderStatus.values.firstWhere(
      (status) => status.toString().split('.').last == _selectedFilter,
      orElse: () => OrderStatus.pending,
    );

    return _orders.where((order) => order.status == targetStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des commandes'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedFilter == filter['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter['label']),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primaryColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filter['count']}',
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryColor : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'];
                });
              },
              selectedColor: AppColors.primaryColor.withOpacity(0.3),
              checkmarkColor: AppColors.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _getFilteredOrders();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Aucune commande trouvée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(
                order: order,
                pharmacy: widget.pharmacy,
              ),
            ),
          ).then((_) => _loadOrders()); // Refresh when returning
        },
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Commande ${order.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: AppDimensions.paddingSmall),
              
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingSmall),
              
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingSmall),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} articles',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(order),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  IconButton(
                    onPressed: () {
                      // TODO: Contact client
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en développement')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(OrderModel order) {
    String buttonText;
    VoidCallback? onPressed;
    Color backgroundColor;

    switch (order.status) {
      case OrderStatus.pending:
        buttonText = 'Confirmer';
        backgroundColor = Colors.green;
        onPressed = () => _updateOrderStatus(order, OrderStatus.preparing);
        break;
      case OrderStatus.preparing:
        buttonText = 'Marquer comme prête';
        backgroundColor = Colors.blue;
        onPressed = () => _updateOrderStatus(order, OrderStatus.ready);
        break;
      case OrderStatus.ready:
        buttonText = 'En attente du livreur';
        backgroundColor = Colors.grey;
        onPressed = null;
        break;
      case OrderStatus.inDelivery:
        buttonText = 'En cours de livraison';
        backgroundColor = Colors.orange;
        onPressed = null;
        break;
      case OrderStatus.delivered:
        buttonText = 'Livrée ✓';
        backgroundColor = AppColors.successColor;
        onPressed = null;
        break;
      default:
        buttonText = 'Voir détails';
        backgroundColor = AppColors.primaryColor;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(
                order: order,
                pharmacy: widget.pharmacy,
              ),
            ),
          );
        };
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande ${_getStatusText(newStatus).toLowerCase()}'),
          backgroundColor: AppColors.successColor,
        ),
      );

      _loadOrders(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        return Colors.blue;
      case OrderStatus.delivered:
        return AppColors.successColor;
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}