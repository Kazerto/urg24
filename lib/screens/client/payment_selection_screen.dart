import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import 'order_confirmation_screen.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PaymentSelectionScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String? _selectedPaymentMethod;
  String? _selectedMobileMoneyProvider;
  String _mobileMoneyNumber = '';
  String _cardNumber = '';
  String _cardHolderName = '';
  String _expiryDate = '';
  String _cvv = '';

  final List<Map<String, String>> _mobileMoneyProviders = [
    {
      'name': 'Airtel Money',
      'code': 'airtel',
      'logo': '📱', // En production, utiliser des images
      'pattern': '+223 XX XX XX XX',
    },
    {
      'name': 'Moov Money',
      'code': 'moov',
      'logo': '💰',
      'pattern': '+223 XX XX XX XX',
    },
  ];

  final List<Map<String, String>> _cardTypes = [
    {
      'name': 'Visa',
      'code': 'visa',
      'logo': '💳',
    },
    {
      'name': 'MasterCard',
      'code': 'mastercard',
      'logo': '💳',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode de paiement'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildPaymentOptions(),
            const SizedBox(height: AppDimensions.paddingLarge),
            if (_selectedPaymentMethod != null) _buildPaymentDetails(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la commande',
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
                const Text('Commande N°:'),
                Text(
                  widget.orderData['orderNumber'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Articles:'),
                Text('${widget.orderData['items'].length}'),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à payer:'),
                Text(
                  '${widget.orderData['total'].toStringAsFixed(0)} ${AppStrings.currency}',
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

  Widget _buildPaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez votre mode de paiement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Mobile Money
        Card(
          child: RadioListTile<String>(
            value: 'mobile_money',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            title: const Row(
              children: [
                Icon(Icons.phone_android, color: Colors.green),
                SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Mobile Money',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: const Text('Airtel Money, Moov Money'),
          ),
        ),
        
        // Carte de crédit
        Card(
          child: RadioListTile<String>(
            value: 'credit_card',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            title: const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Carte de crédit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: const Text('Visa, MasterCard'),
          ),
        ),
        
        // Paiement à la livraison
        Card(
          child: RadioListTile<String>(
            value: 'cash_on_delivery',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            title: const Row(
              children: [
                Icon(Icons.money, color: Colors.orange),
                SizedBox(width: AppDimensions.paddingSmall),
                Text(
                  'Paiement à la livraison',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: const Text('Espèces à la réception'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    switch (_selectedPaymentMethod) {
      case 'mobile_money':
        return _buildMobileMoneyDetails();
      case 'credit_card':
        return _buildCreditCardDetails();
      case 'cash_on_delivery':
        return _buildCashOnDeliveryDetails();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMobileMoneyDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails Mobile Money',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Choix du fournisseur
            const Text('Choisissez votre opérateur:'),
            const SizedBox(height: AppDimensions.paddingSmall),
            ..._mobileMoneyProviders.map((provider) => RadioListTile<String>(
              value: provider['code']!,
              groupValue: _selectedMobileMoneyProvider,
              onChanged: (value) {
                setState(() {
                  _selectedMobileMoneyProvider = value;
                });
              },
              title: Row(
                children: [
                  Text(provider['logo']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(provider['name']!),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            )).toList(),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Numéro de téléphone
            if (_selectedMobileMoneyProvider != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro ${_mobileMoneyProviders.firstWhere((p) => p['code'] == _selectedMobileMoneyProvider)['name']}:',
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  TextField(
                    onChanged: (value) => _mobileMoneyNumber = value,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: _mobileMoneyProviders.firstWhere((p) => p['code'] == _selectedMobileMoneyProvider)['pattern'],
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Vous recevrez un code de confirmation sur votre téléphone pour valider le paiement.'),
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

  Widget _buildCreditCardDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de la carte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Numéro de carte
            TextField(
              onChanged: (value) => _cardNumber = value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Nom du titulaire
            TextField(
              onChanged: (value) => _cardHolderName = value,
              decoration: const InputDecoration(
                labelText: 'Nom du titulaire',
                hintText: 'JOHN DOE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Date d'expiration et CVV
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => _expiryDate = value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: TextField(
                    onChanged: (value) => _cvv = value,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.green),
                  SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: Text('Vos informations de paiement sont sécurisées et cryptées.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashOnDeliveryDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paiement à la livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: AppDimensions.paddingSmall),
                      Text(
                        'Important:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  const Text('• Vous payerez en espèces au moment de la livraison'),
                  const Text('• Préparez le montant exact si possible'),
                  const Text('• Le livreur peut faire la monnaie si nécessaire'),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    'Montant à préparer: ${widget.orderData['total'].toStringAsFixed(0)} ${AppStrings.currency}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
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

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canProceed() ? _confirmPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
        child: Text(
          _selectedPaymentMethod == 'cash_on_delivery' 
              ? 'Confirmer la commande'
              : 'Procéder au paiement',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_selectedPaymentMethod) {
      case 'mobile_money':
        return _selectedMobileMoneyProvider != null && _mobileMoneyNumber.isNotEmpty;
      case 'credit_card':
        return _cardNumber.isNotEmpty && _cardHolderName.isNotEmpty && 
               _expiryDate.isNotEmpty && _cvv.isNotEmpty;
      case 'cash_on_delivery':
        return true;
      default:
        return false;
    }
  }

  void _confirmPayment() {
    final paymentData = <String, dynamic>{
      'method': _selectedPaymentMethod,
    };

    switch (_selectedPaymentMethod) {
      case 'mobile_money':
        paymentData.addAll({
          'provider': _selectedMobileMoneyProvider,
          'phoneNumber': _mobileMoneyNumber,
        });
        break;
      case 'credit_card':
        paymentData.addAll({
          'cardNumber': _cardNumber.replaceAll(' ', ''),
          'cardHolder': _cardHolderName,
          'expiryDate': _expiryDate,
          'cvv': _cvv,
        });
        break;
      case 'cash_on_delivery':
        // Pas d'informations supplémentaires nécessaires
        break;
    }

    final completeOrderData = {
      ...widget.orderData,
      'payment': paymentData,
      'orderDate': DateTime.now().toIso8601String(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          orderData: completeOrderData,
        ),
      ),
    );
  }
}