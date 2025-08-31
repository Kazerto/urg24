import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_person.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';

class AvailableDeliveriesScreen extends StatefulWidget {
  final DeliveryPersonModel deliveryPerson;

  const AvailableDeliveriesScreen({
    super.key,
    required this.deliveryPerson,
  });

  @override
  State<AvailableDeliveriesScreen> createState() => _AvailableDeliveriesScreenState();
}

class _AvailableDeliveriesScreenState extends State<AvailableDeliveriesScreen> {
  List<OrderModel> _availableOrders = [];
  bool _isLoading = true;
  String _sortBy = 'distance'; // distance, amount, time

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Debug: d'abord récupérer toutes les commandes pour voir ce qui existe
      debugPrint('🔍 Recherche de toutes les commandes...');
      final allOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      
      debugPrint('📊 Total commandes trouvées: ${allOrdersSnapshot.docs.length}');
      
      for (var doc in allOrdersSnapshot.docs) {
        final data = doc.data();
        debugPrint('📦 Commande ${doc.id}: status=${data['status']}, deliveryPersonId=${data['deliveryPersonId']}');
      }

      // Maintenant récupérer les commandes disponibles
      // Problème: isNull ne marche pas bien avec Firestore, on filtre côté client
      debugPrint('🔍 Recherche commandes status=ready...');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready')
          .get();

      debugPrint('📊 Commandes avec status=ready trouvées: ${snapshot.docs.length}');

      final List<OrderModel> allReadyOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      debugPrint('📦 Toutes les commandes ready: ${allReadyOrders.length}');
      for (var order in allReadyOrders) {
        debugPrint('📦 Commande ${order.id}: deliveryPersonId="${order.deliveryPersonId}"');
      }

      // Filtrer côté client les commandes sans livreur assigné
      final List<OrderModel> orders = allReadyOrders
          .where((order) => order.deliveryPersonId == null || order.deliveryPersonId!.isEmpty)
          .toList();

      debugPrint('📊 Commandes disponibles après filtrage: ${orders.length}');

      // Trier côté client pour éviter l'index composé
      orders.sort((a, b) {
        if (a.orderDate == null || b.orderDate == null) return 0;
        return a.orderDate!.compareTo(b.orderDate!);
      });

      setState(() {
        _availableOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des livraisons: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraisons disponibles'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'distance',
                child: Text('Trier par distance'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Trier par montant'),
              ),
              const PopupMenuItem(
                value: 'time',
                child: Text('Trier par heure'),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAvailableOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    itemCount: _availableOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_availableOrders[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Text(
            'Aucune livraison disponible',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Revenez plus tard ou activez les notifications\npour être alerté des nouvelles livraisons',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          ElevatedButton.icon(
            onPressed: _loadAvailableOrders,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 4,
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
                      const SizedBox(height: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Client info
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
            
            // Delivery address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livraison:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            
            // Order details
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${order.items.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(
                        '~2.5 km', // TODO: Calculate real distance
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temps estimé',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(
                        '~15 min', // TODO: Calculate real time
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Voir détails'),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptDelivery(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sortOrders() {
    setState(() {
      switch (_sortBy) {
        case 'amount':
          _availableOrders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
          break;
        case 'time':
          _availableOrders.sort((a, b) => a.orderDate.compareTo(b.orderDate));
          break;
        case 'distance':
        default:
          // TODO: Implement distance sorting with real GPS coordinates
          // For now, keep original order
          break;
      }
    });
  }

  Future<void> _acceptDelivery(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter cette livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pharmacie: ${order.pharmacyName}'),
            Text('Client: ${order.clientName}'),
            Text('Montant: ${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}'),
            const SizedBox(height: 8),
            const Text(
              'Voulez-vous accepter cette livraison ?',
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
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .update({
          'deliveryPersonId': widget.deliveryPerson.id,
          'deliveryPersonName': widget.deliveryPerson.fullName,
          'status': 'inDelivery',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison acceptée avec succès'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pop(); // Return to dashboard
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

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails de la commande',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('Commande N°', order.id),
                    _buildDetailRow('Pharmacie', order.pharmacyName),
                    _buildDetailRow('Client', order.clientName),
                    _buildDetailRow('Téléphone', order.clientPhone ?? 'Non renseigné'),
                    _buildDetailRow('Adresse', order.deliveryAddress),
                    _buildDetailRow('Date', _formatDateTime(order.orderDate)),
                    
                    const SizedBox(height: AppDimensions.paddingMedium),
                    const Text(
                      'Articles commandés:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.medicamentName} x${item.quantity}'),
                          ),
                          Text('${item.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}'),
                        ],
                      ),
                    )).toList(),
                    
                    const Divider(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}