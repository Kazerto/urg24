import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import '../../models/prescription_model.dart';
import 'payment_selection_screen.dart';
import 'simple_address_selection_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  String? _selectedDeliveryAddress;
  double _deliveryFee = 2000; // Frais de livraison par défaut
  Map<String, dynamic>? _selectedMapAddress;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _savedAddresses = [
    'Maison - 123 Rue de la République, Bamako',
    'Bureau - Avenue de l\'Indépendance, Bamako',
    'École - Quartier du Fleuve, Bamako',
  ];

  // Gestion des ordonnances
  List<PrescriptionModel> _availablePrescriptions = [];
  PrescriptionModel? _selectedPrescription;
  bool _isLoadingPrescriptions = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateState);
    _notesController.addListener(_updateState);
    _loadAvailablePrescriptions();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  Future<void> _loadAvailablePrescriptions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingPrescriptions = false);
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'uploaded')
          .get();

      // Trier côté client pour éviter l'index composite
      final prescriptions = querySnapshot.docs
          .map((doc) => PrescriptionModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt)); // Tri décroissant

      setState(() {
        _availablePrescriptions = prescriptions;
        _isLoadingPrescriptions = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement ordonnances disponibles: $e');
      setState(() => _isLoadingPrescriptions = false);
    }
  }

  Future<void> _selectAddressOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleAddressSelectionScreen(
          initialAddress: _selectedMapAddress?['address'],
          initialLatitude: _selectedMapAddress?['latitude'],
          initialLongitude: _selectedMapAddress?['longitude'],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMapAddress = result;
        _selectedDeliveryAddress = 'map';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Récapitulatif de commande'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) {
            return const Center(
              child: Text('Votre panier est vide'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderNumber(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildPharmacyInfo(cartProvider),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildOrderItems(cartProvider),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildDeliveryAddress(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildContactInfo(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildPrescriptionSelection(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildOrderNotes(),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildPricingSummary(cartProvider),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildProceedButton(cartProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderNumber() {
    final orderNumber = 'CMD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Numéro de commande',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  orderNumber,
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
    );
  }

  Widget _buildPharmacyInfo(CartProvider cartProvider) {
    final pharmacy = cartProvider.selectedPharmacy!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pharmacie sélectionnée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.pharmacyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pharmacy.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        pharmacy.phoneNumber,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Articles commandés (${cartProvider.itemCount})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...cartProvider.itemsList.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.unitPrice.toStringAsFixed(0)} ${AppStrings.currency} x ${item.quantity}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adresse de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Adresses sauvegardées
            ..._savedAddresses.map((address) => RadioListTile<String>(
              title: Text(address),
              value: address,
              groupValue: _selectedDeliveryAddress,
              onChanged: (value) {
                setState(() {
                  _selectedDeliveryAddress = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            )).toList(),
            
            // Option carte
            RadioListTile<String>(
              title: Row(
                children: [
                  const Text('Choisir ma position'),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.my_location,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ],
              ),
              value: 'map',
              groupValue: _selectedDeliveryAddress,
              onChanged: (value) {
                _selectAddressOnMap();
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Affichage de l'adresse sélectionnée sur la carte
            if (_selectedDeliveryAddress == 'map' && _selectedMapAddress != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Adresse sélectionnée:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedMapAddress!['address'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordonnées: ${_selectedMapAddress!['latitude'].toStringAsFixed(6)}, ${_selectedMapAddress!['longitude'].toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _selectAddressOnMap,
                      icon: const Icon(Icons.edit_location, size: 16),
                      label: const Text('Modifier la position'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: 'Ex: +223 XX XX XX XX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ordonnance (optionnel)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Optionnel',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            const Text(
              'Joindre une ordonnance à votre commande si nécessaire',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            if (_isLoadingPrescriptions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availablePrescriptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucune ordonnance disponible',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Option "Aucune ordonnance"
                  RadioListTile<PrescriptionModel?>(
                    title: const Text('Pas d\'ordonnance pour cette commande'),
                    value: null,
                    groupValue: _selectedPrescription,
                    onChanged: (value) {
                      setState(() {
                        _selectedPrescription = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  // Liste des ordonnances disponibles
                  ..._availablePrescriptions.map((prescription) {
                    return RadioListTile<PrescriptionModel?>(
                      title: Text('Ordonnance du ${_formatDate(prescription.uploadedAt)}'),
                      subtitle: Text('Uploadée à ${_formatTime(prescription.uploadedAt)}'),
                      value: prescription,
                      groupValue: _selectedPrescription,
                      onChanged: (value) {
                        setState(() {
                          _selectedPrescription = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            prescription.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.description,
                                size: 30,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildOrderNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes pour la commande (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Instructions spéciales, allergies, etc.',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary(CartProvider cartProvider) {
    final subtotal = cartProvider.totalAmount;
    final total = subtotal + _deliveryFee;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détail des coûts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total produits:'),
                Text('${subtotal.toStringAsFixed(0)} ${AppStrings.currency}'),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frais de livraison:'),
                Text('${_deliveryFee.toStringAsFixed(0)} ${AppStrings.currency}'),
              ],
            ),
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
                  '${total.toStringAsFixed(0)} ${AppStrings.currency}',
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
    );
  }

  Widget _buildProceedButton(CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canProceed() ? () => _proceedToPayment(cartProvider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
        child: const Text(
          'Choisir le mode de paiement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    return _selectedDeliveryAddress != null &&
           (_selectedDeliveryAddress != 'map' || _selectedMapAddress != null) &&
           _phoneController.text.isNotEmpty;
  }

  void _proceedToPayment(CartProvider cartProvider) {
    // Préparer l'adresse de livraison selon le type sélectionné
    String deliveryAddress;
    Map<String, double>? deliveryCoordinates;
    
    if (_selectedDeliveryAddress == 'map' && _selectedMapAddress != null) {
      deliveryAddress = _selectedMapAddress!['address'];
      deliveryCoordinates = {
        'latitude': _selectedMapAddress!['latitude'],
        'longitude': _selectedMapAddress!['longitude'],
      };
    } else {
      deliveryAddress = _selectedDeliveryAddress!;
    }

    final orderData = {
      'pharmacy': cartProvider.selectedPharmacy!.toMap(),
      'items': cartProvider.itemsList.map((item) => item.toMap()).toList(),
      'deliveryAddress': deliveryAddress,
      'deliveryCoordinates': deliveryCoordinates,
      'phoneNumber': _phoneController.text,
      'notes': _notesController.text,
      'subtotal': cartProvider.totalAmount,
      'deliveryFee': _deliveryFee,
      'total': cartProvider.totalAmount + _deliveryFee,
      'orderNumber': 'CMD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'prescriptionUrl': _selectedPrescription?.imageUrl,
      'prescriptionId': _selectedPrescription?.id,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionScreen(orderData: orderData),
      ),
    );
  }
}