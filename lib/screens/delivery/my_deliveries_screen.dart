import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_person.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';

class MyDeliveriesScreen extends StatefulWidget {
  final DeliveryPersonModel deliveryPerson;

  const MyDeliveriesScreen({
    super.key,
    required this.deliveryPerson,
  });

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel> _activeDeliveries = [];
  List<OrderModel> _completedDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyDeliveries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyDeliveries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Active deliveries (in delivery)
      final activeQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: widget.deliveryPerson.id)
          .where('status', isEqualTo: 'inDelivery')
          .get();

      // Completed deliveries
      final completedQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: widget.deliveryPerson.id)
          .where('status', isEqualTo: 'delivered')
          .get();

      final activeDeliveries = activeQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Trier par date croissante (plus ancien en premier)
      activeDeliveries.sort((a, b) {
        if (a.orderDate == null || b.orderDate == null) return 0;
        return a.orderDate!.compareTo(b.orderDate!);
      });

      final completedDeliveries = completedQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Trier par date décroissante (plus récent en premier) et limiter à 20
      completedDeliveries.sort((a, b) {
        if (a.orderDate == null || b.orderDate == null) return 0;
        return b.orderDate!.compareTo(a.orderDate!);
      });
      
      // Limiter à 20 éléments
      final limitedCompletedDeliveries = completedDeliveries.take(20).toList();

      if (mounted) {
        setState(() {
          _activeDeliveries = activeDeliveries;
          _completedDeliveries = limitedCompletedDeliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des livraisons: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livraisons'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyDeliveries,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'En cours (${_activeDeliveries.length})',
              icon: const Icon(Icons.local_shipping),
            ),
            Tab(
              text: 'Terminées (${_completedDeliveries.length})',
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveDeliveries(),
                _buildCompletedDeliveries(),
              ],
            ),
    );
  }

  Widget _buildActiveDeliveries() {
    if (_activeDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'Aucune livraison en cours',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Acceptez de nouvelles livraisons depuis\nl\'onglet "Livraisons disponibles"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _activeDeliveries.length,
        itemBuilder: (context, index) {
          return _buildActiveDeliveryCard(_activeDeliveries[index]);
        },
      ),
    );
  }

  Widget _buildCompletedDeliveries() {
    if (_completedDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'Aucune livraison terminée',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _completedDeliveries.length,
        itemBuilder: (context, index) {
          return _buildCompletedDeliveryCard(_completedDeliveries[index]);
        },
      ),
    );
  }

  Widget _buildActiveDeliveryCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          gradient: LinearGradient(
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
                          order.pharmacyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          'Commande ${order.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EN COURS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Client and phone
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _callClient(order.clientPhone),
                    icon: const Icon(Icons.phone, color: Colors.green),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingSmall),
              
              // Address and maps
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openMaps(order.deliveryAddress),
                    icon: const Icon(Icons.map, color: Colors.blue),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Order info
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${order.items.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Articles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Montant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          _getDeliveryDuration(order.orderDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsDelivered(order),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Marquer comme livrée',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedDeliveryCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
                        order.pharmacyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Commande ${order.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVRÉE',
                    style: TextStyle(
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
                Text(order.clientName),
                const Spacer(),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.successColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.orderDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (order.deliveryDate != null) ...[
                  const Text(' → '),
                  Text(
                    _formatDateTime(order.deliveryDate!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDelivered(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${order.clientName}'),
            Text('Adresse: ${order.deliveryAddress}'),
            Text('Montant: ${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}'),
            const SizedBox(height: 16),
            const Text(
              'Confirmez-vous que cette commande a été livrée au client ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
            ),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        debugPrint('🚛 Marquage livraison comme livrée...');
        debugPrint('📦 Commande ID: ${order.id}');
        debugPrint('🚴 Livreur ID: ${widget.deliveryPerson.id}');

        // Update order status
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .update({
          'status': 'delivered',
          'deliveryDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Statut commande mis à jour');

        // Update delivery person stats in users collection
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.deliveryPerson.id)
              .update({
            'completedDeliveries': FieldValue.increment(1),
            'totalDeliveries': FieldValue.increment(1),
            'lastDeliveryAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Statistiques livreur mises à jour');
        } catch (statsError) {
          debugPrint('⚠️ Erreur mise à jour stats livreur: $statsError');
          // Continue même si les stats ne s'updatent pas
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison confirmée avec succès'),
              backgroundColor: Colors.green,
            ),
          );

          _loadMyDeliveries(); // Refresh data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _callClient(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
    }
  }

  Future<void> _openMaps(String address) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application de cartes')),
      );
    }
  }

  String _getDeliveryDuration(DateTime orderDate) {
    final duration = DateTime.now().difference(orderDate);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inHours}h${duration.inMinutes % 60}m';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}