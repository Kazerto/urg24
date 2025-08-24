import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../user_type_login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productName;
  final String category;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.category,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _sortBy = 'price_low'; // price_low, price_high, distance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.productName),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'price_low',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward),
                    SizedBox(width: 8),
                    Text('Prix croissant'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward),
                    SizedBox(width: 8),
                    Text('Prix décroissant'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 8),
                    Text('Distance'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock')
            .where('medicamentName', isEqualTo: widget.productName)
            .where('category', isEqualTo: widget.category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Produit indisponible',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune pharmacie ne propose ce produit actuellement',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Récupérer et traiter les données des pharmacies
          List<QueryDocumentSnapshot> stockItems = snapshot.data!.docs;
          
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getPharmaciesWithStock(stockItems),
            builder: (context, pharmacySnapshot) {
              if (pharmacySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (pharmacySnapshot.hasError) {
                return const Center(
                  child: Text('Erreur lors du chargement des pharmacies'),
                );
              }

              List<Map<String, dynamic>> pharmacies = pharmacySnapshot.data ?? [];
              
              if (pharmacies.isEmpty) {
                return const Center(
                  child: Text('Aucune pharmacie trouvée'),
                );
              }

              // Trier les pharmacies
              _sortPharmacies(pharmacies);

              return Column(
                children: [
                  // En-tête avec informations produit
                  _buildProductHeader(stockItems.first.data() as Map<String, dynamic>),
                  
                  // Liste des pharmacies
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pharmacies.length,
                      itemBuilder: (context, index) {
                        return _buildPharmacyCard(context, pharmacies[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPharmaciesWithStock(List<QueryDocumentSnapshot> stockItems) async {
    List<Map<String, dynamic>> result = [];
    
    for (var stockDoc in stockItems) {
      Map<String, dynamic> stockData = stockDoc.data() as Map<String, dynamic>;
      String pharmacyId = stockData['pharmacyId']?.toString() ?? '';
      
      if (pharmacyId.isNotEmpty) {
        try {
          DocumentSnapshot pharmacyDoc = await FirebaseFirestore.instance
              .collection('pharmacies')
              .doc(pharmacyId)
              .get();
          
          if (pharmacyDoc.exists) {
            Map<String, dynamic> pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
            
            // Combiner les données pharmacie + stock
            result.add({
              'pharmacyId': pharmacyId,
              'pharmacyName': pharmacyData['pharmacyName'] ?? 'Pharmacie',
              'address': pharmacyData['address'] ?? '',
              'phoneNumber': pharmacyData['phoneNumber'] ?? '',
              'email': pharmacyData['email'] ?? '',
              'rating': pharmacyData['rating'] ?? 0.0,
              'price': stockData['price'] ?? '0',
              'quantity': stockData['quantity'] ?? 0,
              'expiryDate': stockData['expiryDate'],
              'description': stockData['description'] ?? '',
              'imageUrl': stockData['imageUrl'] ?? '',
              'stockId': stockDoc.id,
            });
          }
        } catch (e) {
          debugPrint('Erreur récupération pharmacie $pharmacyId: $e');
        }
      }
    }
    
    return result;
  }

  void _sortPharmacies(List<Map<String, dynamic>> pharmacies) {
    pharmacies.sort((a, b) {
      switch (_sortBy) {
        case 'price_low':
          double priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
          double priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
          return priceA.compareTo(priceB);
        case 'price_high':
          double priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
          double priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
          return priceB.compareTo(priceA);
        case 'distance':
          // Pour l'instant, trier par nom (sans géolocalisation)
          String nameA = a['pharmacyName']?.toString() ?? '';
          String nameB = b['pharmacyName']?.toString() ?? '';
          return nameA.compareTo(nameB);
        default:
          return 0;
      }
    });
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    String name = product['medicamentName']?.toString() ?? widget.productName;
    String description = product['description']?.toString() ?? '';
    String imageUrl = product['imageUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Image du produit
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.medical_services,
                              size: 40,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.medical_services,
                        size: 40,
                        color: Colors.grey[400],
                      ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catégorie: ${widget.category}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pharmacies proposant ce produit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, Map<String, dynamic> pharmacy) {
    String name = pharmacy['pharmacyName']?.toString() ?? 'Pharmacie';
    String address = pharmacy['address']?.toString() ?? '';
    String phone = pharmacy['phoneNumber']?.toString() ?? '';
    double rating = double.tryParse(pharmacy['rating']?.toString() ?? '0') ?? 0;
    double price = double.tryParse(pharmacy['price']?.toString() ?? '0') ?? 0;
    int quantity = int.tryParse(pharmacy['quantity']?.toString() ?? '0') ?? 0;

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
            // En-tête pharmacie
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Prix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      quantity > 0 ? '$quantity disponible${quantity > 1 ? 's' : ''}' : 'Rupture de stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: quantity > 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations supplémentaires
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                ],
                if (rating > 0) ...[
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bouton commander
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: quantity > 0 ? () => _showLoginRequired(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: quantity > 0 ? AppColors.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  quantity > 0 ? 'Commander maintenant' : 'Indisponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Pour passer une commande, vous devez vous connecter ou créer un compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const UserTypeLoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}