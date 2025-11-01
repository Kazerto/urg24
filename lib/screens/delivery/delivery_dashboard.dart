import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_person.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import '../../widgets/universal_drawer.dart';
import '../../providers/auth_provider_simple.dart';
import 'available_deliveries_screen.dart';
import 'my_deliveries_screen.dart';
import 'delivery_profile_screen.dart';

// Wrapper screen that gets delivery person data from provider
class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderSimple>(
      builder: (context, authProvider, child) {
        final userData = authProvider.userData;
        
        if (userData == null) {
          return const Scaffold(
            body: Center(
              child: Text('Erreur: Données utilisateur non trouvées'),
            ),
          );
        }

        // Créer un DeliveryPersonModel à partir des données utilisateur
        DateTime createdAtDateTime;
        try {
          final createdAtValue = userData['createdAt'];
          if (createdAtValue is Timestamp) {
            createdAtDateTime = createdAtValue.toDate();
          } else if (createdAtValue is DateTime) {
            createdAtDateTime = createdAtValue;
          } else {
            createdAtDateTime = DateTime.now();
          }
        } catch (e) {
          createdAtDateTime = DateTime.now();
        }

        final deliveryPerson = DeliveryPersonModel(
          id: userData['uid'] ?? '',
          fullName: userData['fullName'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? '',
          address: userData['address'] ?? '',
          agency: userData['agency'],
          vehicleType: userData['vehicleType'] ?? '',
          plateNumber: userData['plateNumber'] ?? '',
          isVerified: userData['isVerified'] ?? false,
          isApproved: userData['isApproved'] ?? false,
          isActive: userData['status'] == 'active',
          isAvailable: userData['isAvailable'] ?? false,
          createdAt: createdAtDateTime,
          status: userData['status'] ?? 'pending',
          rating: (userData['rating'] ?? 0.0).toDouble(),
          totalDeliveries: userData['totalDeliveries'] ?? 0,
          completedDeliveries: userData['completedDeliveries'] ?? 0,
          profileImageUrl: userData['profileImageUrl'],
          currentLocation: userData['currentLocation'],
        );

        return DeliveryDashboard(deliveryPerson: deliveryPerson);
      },
    );
  }
}

class DeliveryDashboard extends StatefulWidget {
  final DeliveryPersonModel deliveryPerson;

  const DeliveryDashboard({
    super.key,
    required this.deliveryPerson,
  });

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myDeliveries = [];
  bool _isLoading = true;
  bool _isAvailable = false;
  bool _isTogglingAvailability = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.deliveryPerson.isAvailable;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load available orders (ready for pickup)
      final availableOrdersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready')
          .where('deliveryPersonId', isNull: true)
          .limit(10)
          .get();

      final availableOrders = availableOrdersQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Load current deliveries assigned to this delivery person
      final myDeliveriesQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: widget.deliveryPerson.id)
          .where('status', whereIn: ['inDelivery', 'ready'])
          .get();

      final myDeliveries = myDeliveriesQuery.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _availableOrders = availableOrders;
          _myDeliveries = myDeliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Double-tap pour sortir de l'application
        final currentTime = DateTime.now();
        if (_lastBackPress == null || 
            currentTime.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = currentTime;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez encore une fois pour quitter'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
          return false; // Ne pas quitter encore
        }
        return true; // Quitter l'app après le second tap
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord - ${widget.deliveryPerson.fullName}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _isTogglingAvailability
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isAvailable ? Icons.toggle_on : Icons.toggle_off,
                    size: 32,
                    color: _isAvailable ? Colors.greenAccent : Colors.white70,
                  ),
                  onPressed: _toggleAvailability,
                  tooltip: _isAvailable ? 'Disponible - Appuyer pour désactiver' : 'Indisponible - Appuyer pour activer',
                ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      drawer: UniversalDrawer(
        userType: 'delivery',
        userName: widget.deliveryPerson.fullName,
        userEmail: widget.deliveryPerson.email,
        userData: {
          'uid': widget.deliveryPerson.id,
          'id': widget.deliveryPerson.id,
          'fullName': widget.deliveryPerson.fullName,
          'email': widget.deliveryPerson.email,
          'phoneNumber': widget.deliveryPerson.phoneNumber,
          'vehicleType': widget.deliveryPerson.vehicleType,
          'plateNumber': widget.deliveryPerson.plateNumber,
          'agency': widget.deliveryPerson.agency,
          'profileImageUrl': widget.deliveryPerson.profileImageUrl,
          'userType': 'delivery',
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildStatsCards(),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildQuickActions(),
              const SizedBox(height: AppDimensions.paddingLarge),
              if (_myDeliveries.isNotEmpty) ...[
                _buildCurrentDeliveries(),
                const SizedBox(height: AppDimensions.paddingLarge),
              ],
              _buildAvailableOrders(),
            ],
          ),
        ),
      ),
      ), // Ferme WillPopScope
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          gradient: LinearGradient(
            colors: _isAvailable
                ? [Colors.green, Colors.green.withOpacity(0.8)]
                : [Colors.grey, Colors.grey.withOpacity(0.8)],
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isAvailable ? Icons.delivery_dining : Icons.pause_circle_outline,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAvailable ? 'Disponible' : 'Indisponible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isAvailable
                        ? 'Prêt à accepter des livraisons'
                        : 'Mode pause activé',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _isTogglingAvailability
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Switch(
                    value: _isAvailable,
                    onChanged: (value) => _toggleAvailability(),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white30,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Livraisons\nactives',
            _myDeliveries.length.toString(),
            Icons.local_shipping,
            Colors.blue,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: _buildStatCard(
            'Disponibles\najour\'hui',
            _availableOrders.length.toString(),
            Icons.assignment,
            Colors.green,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: _buildStatCard(
            'Total\nlivrées',
            widget.deliveryPerson.completedDeliveries.toString(),
            Icons.check_circle,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 2,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 4),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Livraisons\ndisponibles',
                Icons.assignment_turned_in,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AvailableDeliveriesScreen(
                        deliveryPerson: widget.deliveryPerson,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildActionCard(
                'Mes\nlivraisons',
                Icons.local_shipping,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyDeliveriesScreen(
                        deliveryPerson: widget.deliveryPerson,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Mon\nprofil',
                Icons.person,
                AppColors.textSecondary,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryProfileScreen(
                        deliveryPerson: widget.deliveryPerson,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            const Expanded(child: SizedBox()), // Empty space for symmetry
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCurrentDeliveries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes livraisons en cours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyDeliveriesScreen(
                      deliveryPerson: widget.deliveryPerson,
                    ),
                  ),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        ..._myDeliveries.take(3).map((order) => _buildDeliveryCard(order)).toList(),
      ],
    );
  }

  Widget _buildAvailableOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Livraisons disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AvailableDeliveriesScreen(
                      deliveryPerson: widget.deliveryPerson,
                    ),
                  ),
                );
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        if (_availableOrders.isEmpty && !_isLoading)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    Text(
                      'Aucune livraison disponible',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._availableOrders.take(3).map((order) => _buildOrderCard(order)).toList(),
      ],
    );
  }

  Widget _buildDeliveryCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            order.clientName.isNotEmpty ? order.clientName[0] : 'C',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('Commande ${order.id}'),
        subtitle: Text(
          '${order.clientName} - ${order.deliveryAddress}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.status == OrderStatus.inDelivery ? 'En cours' : 'Prête',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.local_pharmacy,
            color: Colors.green,
          ),
        ),
        title: Text(order.pharmacyName),
        subtitle: Text(
          '${order.deliveryAddress}\n${order.totalAmount.toStringAsFixed(0)} ${AppStrings.currency}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton(
          onPressed: () => _acceptDelivery(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: const Text(
            'Accepter',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAvailability() async {
    if (_isTogglingAvailability) return; // Éviter les doubles clics

    setState(() {
      _isTogglingAvailability = true;
    });

    try {
      final newStatus = !_isAvailable;

      debugPrint('🔄 Changement de disponibilité: $_isAvailable -> $newStatus');

      // Mettre à jour dans la collection 'users' (pas 'delivery_persons')
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.deliveryPerson.id)
          .update({
        'isAvailable': newStatus,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Statut mis à jour dans Firestore');

      // Mettre à jour aussi le provider pour synchroniser
      if (mounted) {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.refreshUserData();
        debugPrint('✅ Provider rafraîchi');
      }

      setState(() {
        _isAvailable = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.check_circle : Icons.pause_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus
                        ? 'Vous êtes maintenant disponible pour les livraisons'
                        : 'Vous êtes maintenant indisponible',
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du changement de disponibilité: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingAvailability = false;
        });
      }
    }
  }

  Future<void> _acceptDelivery(OrderModel order) async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison acceptée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadDashboardData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}