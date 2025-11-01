import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../utils/constants.dart';
import '../../models/order_model.dart';
import 'pharmacy_selection_screen.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderConfirmationScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isLoading = true;
  bool _orderSaved = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _saveOrderToFirestore();
  }

  Future<void> _saveOrderToFirestore() async {
    try {
      final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Préparer les données de la commande
      final orderData = {
        'orderNumber': widget.orderData['orderNumber'],
        'clientId': authProvider.userData?['id'] ?? '',
        'clientName': authProvider.displayName,
        'clientEmail': authProvider.userData?['email'] ?? '',
        'clientPhone': widget.orderData['phoneNumber'],
        'pharmacyId': widget.orderData['pharmacy']['id'],
        'pharmacyName': widget.orderData['pharmacy']['pharmacyName'],
        'items': widget.orderData['items'],
        'deliveryAddress': widget.orderData['deliveryAddress'],
        'deliveryCoordinates': widget.orderData['deliveryCoordinates'],
        'notes': widget.orderData['notes'] ?? '',
        'subtotal': widget.orderData['subtotal'],
        'deliveryFee': widget.orderData['deliveryFee'],
        'totalAmount': widget.orderData['total'],
        'payment': widget.orderData['payment'],
        'prescriptionUrl': widget.orderData['prescriptionUrl'],
        'prescriptionId': widget.orderData['prescriptionId'],
        'status': 'pending',
        'orderDate': Timestamp.fromDate(DateTime.now()),
        'estimatedDeliveryTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 2)),
        ),
      };

      // Sauvegarder dans Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      setState(() {
        _orderId = docRef.id;
        _orderSaved = true;
        _isLoading = false;
      });

      // Marquer l'ordonnance comme utilisée si une ordonnance est attachée
      if (widget.orderData['prescriptionId'] != null) {
        await _markPrescriptionAsUsed(
          widget.orderData['prescriptionId'],
          docRef.id,
        );
      }

      // Déduire le stock des produits commandés
      await _deductStockFromPharmacy(widget.orderData['items'], widget.orderData['pharmacy']['id']);

      // Vider le panier après confirmation
      cartProvider.clearCart();

    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la commande: $e');
      setState(() {
        _isLoading = false;
        _orderSaved = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading, // Empêche de revenir en arrière pendant le chargement
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmation de commande'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_isLoading,
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _orderSaved
                ? _buildSuccessState()
                : _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          SizedBox(height: AppDimensions.paddingLarge),
          Text(
            'Finalisation de votre commande...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Veuillez patienter, nous enregistrons votre commande.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          _buildSuccessHeader(),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildOrderDetails(),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildPaymentInfo(),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildNextSteps(),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              'Erreur lors de la confirmation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Une erreur est survenue lors de l\'enregistrement de votre commande. Veuillez réessayer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _saveOrderToFirestore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.successColor,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Text(
            'Commande passée avec succès !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.successColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Commande N° ${widget.orderData['orderNumber']}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de la commande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            _buildDetailRow('Pharmacie', widget.orderData['pharmacy']['pharmacyName']),
            _buildDetailRow('Articles', '${widget.orderData['items'].length} produits'),
            _buildDetailRow('Adresse de livraison', widget.orderData['deliveryAddress']),
            _buildDetailRow('Téléphone', widget.orderData['phoneNumber']),
            if (widget.orderData['notes'].toString().isNotEmpty)
              _buildDetailRow('Notes', widget.orderData['notes']),
            
            const Divider(height: 20),
            _buildDetailRow(
              'Montant total', 
              '${widget.orderData['total'].toStringAsFixed(0)} ${AppStrings.currency}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? AppColors.primaryColor : AppColors.textPrimary,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final paymentMethod = widget.orderData['payment']['method'];
    String paymentTitle = '';
    String paymentDetails = '';

    switch (paymentMethod) {
      case 'mobile_money':
        paymentTitle = 'Mobile Money';
        paymentDetails = 'Paiement via ${widget.orderData['payment']['provider'] == 'airtel' ? 'Airtel Money' : 'Moov Money'}';
        break;
      case 'credit_card':
        paymentTitle = 'Carte de crédit';
        paymentDetails = 'Paiement par carte se terminant par ${widget.orderData['payment']['cardNumber'].toString().substring(widget.orderData['payment']['cardNumber'].toString().length - 4)}';
        break;
      case 'cash_on_delivery':
        paymentTitle = 'Paiement à la livraison';
        paymentDetails = 'Vous payerez en espèces à la réception';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode de paiement: $paymentTitle',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              paymentDetails,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSteps() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prochaines étapes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildStepItem('1', 'La pharmacie prépare votre commande', '5-15 minutes'),
            _buildStepItem('2', 'Un livreur prend en charge votre commande', '15-30 minutes'),
            _buildStepItem('3', 'Livraison à votre adresse', '1-2 heures'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String stepNumber, String title, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_orderId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingScreen(orderId: _orderId!),
                  ),
                );
              }
            },
            icon: const Icon(Icons.track_changes, color: Colors.white),
            label: const Text(
              'Suivre ma commande',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Retourner au dashboard puis naviguer vers la sélection de pharmacie
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PharmacySelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text(
              'Continuer mes achats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Marque l'ordonnance comme utilisée dans une commande
  Future<void> _markPrescriptionAsUsed(String prescriptionId, String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({
        'status': 'used_in_order',
        'usedInOrderId': orderId,
        'usedAt': Timestamp.now(),
      });
      debugPrint('Ordonnance $prescriptionId marquée comme utilisée dans commande $orderId');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'ordonnance: $e');
      // Ne pas faire échouer la commande si la mise à jour échoue
    }
  }

  /// Déduit les quantités commandées du stock de la pharmacie
  Future<void> _deductStockFromPharmacy(List<dynamic> items, String pharmacyId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final item in items) {
        final medicamentId = item['medicamentId'];
        final quantityOrdered = item['quantity'] as int;

        // Récupérer le document de stock correspondant
        final stockQuery = await FirebaseFirestore.instance
            .collection('stock')
            .where('medicamentId', isEqualTo: medicamentId)
            .where('pharmacyId', isEqualTo: pharmacyId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (stockQuery.docs.isNotEmpty) {
          final stockDoc = stockQuery.docs.first;
          final stockData = stockDoc.data();
          final currentQuantity = stockData['quantity'] as int;
          final newQuantity = currentQuantity - quantityOrdered;

          // S'assurer que la quantité ne devient pas négative
          final finalQuantity = newQuantity < 0 ? 0 : newQuantity;

          // Ajouter la mise à jour au batch
          batch.update(stockDoc.reference, {
            'quantity': finalQuantity,
            'lastUpdated': Timestamp.now(),
          });

          debugPrint('Stock mis à jour pour ${item['medicamentName']}: $currentQuantity -> $finalQuantity');
        } else {
          debugPrint('Aucun stock trouvé pour le médicament ID: $medicamentId');
        }
      }

      // Exécuter toutes les mises à jour en une seule transaction
      await batch.commit();
      debugPrint('Déduction de stock terminée avec succès');

    } catch (e) {
      debugPrint('Erreur lors de la déduction du stock: $e');
      // Ne pas faire échouer la commande si la déduction de stock échoue
      // On pourrait ajouter une notification à l'admin ici
    }
  }
}