import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'product_detail_screen.dart';

class ProductsBrowserScreen extends StatefulWidget {
  final String category;

  const ProductsBrowserScreen({
    super.key,
    required this.category,
  });

  @override
  State<ProductsBrowserScreen> createState() => _ProductsBrowserScreenState();
}

class _ProductsBrowserScreenState extends State<ProductsBrowserScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price_low, price_high

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.category),
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
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Nom A-Z'),
                  ],
                ),
              ),
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher dans ${widget.category}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stock')
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
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun produit disponible',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun médicament dans cette catégorie',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer et trier les produits
                List<QueryDocumentSnapshot> products = snapshot.data!.docs;
                
                // Filtrer par recherche
                if (_searchQuery.isNotEmpty) {
                  products = products.where((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String name = data['medicamentName']?.toString().toLowerCase() ?? '';
                    String description = data['description']?.toString().toLowerCase() ?? '';
                    String query = _searchQuery.toLowerCase();
                    return name.contains(query) || description.contains(query);
                  }).toList();
                }

                // Trier les produits
                products.sort((a, b) {
                  Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                  Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                  
                  switch (_sortBy) {
                    case 'price_low':
                      double priceA = double.tryParse(dataA['price']?.toString() ?? '0') ?? 0;
                      double priceB = double.tryParse(dataB['price']?.toString() ?? '0') ?? 0;
                      return priceA.compareTo(priceB);
                    case 'price_high':
                      double priceA = double.tryParse(dataA['price']?.toString() ?? '0') ?? 0;
                      double priceB = double.tryParse(dataB['price']?.toString() ?? '0') ?? 0;
                      return priceB.compareTo(priceA);
                    case 'name':
                    default:
                      String nameA = dataA['medicamentName']?.toString() ?? '';
                      String nameB = dataB['medicamentName']?.toString() ?? '';
                      return nameA.compareTo(nameB);
                  }
                });

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez avec d\'autres termes de recherche',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> product = products[index].data() as Map<String, dynamic>;
                    return _buildProductCard(context, product, products[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product, String productId) {
    String name = product['medicamentName']?.toString() ?? 'Produit sans nom';
    String description = product['description']?.toString() ?? '';
    double price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    String imageUrl = product['imageUrl']?.toString() ?? '';
    int quantity = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
    DateTime? expiryDate;
    
    if (product['expiryDate'] != null) {
      if (product['expiryDate'] is Timestamp) {
        expiryDate = (product['expiryDate'] as Timestamp).toDate();
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productName: name,
                category: widget.category,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              
              // Informations du produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${price.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (quantity > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Rupture',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
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
}