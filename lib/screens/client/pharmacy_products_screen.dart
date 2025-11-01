import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/pharmacy_model.dart';
import '../../models/stock_model.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import 'cart_screen.dart';

class PharmacyProductsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyProductsScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyProductsScreen> createState() => _PharmacyProductsScreenState();
}

class _PharmacyProductsScreenState extends State<PharmacyProductsScreen> {
  List<StockModel> _products = [];
  List<StockModel> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  final List<String> _categories = [
    'Tous',
    'Médicaments',
    'Vitamines',
    'Matériel médical',
    'Hygiène',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      debugPrint('Chargement des produits pour pharmacie ID: ${widget.pharmacy.id}');
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('Nombre de produits trouvés: ${snapshot.docs.length}');

      final List<StockModel> products = snapshot.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .where((product) => product.quantity > 0) // Filtrer côté client
          .toList();

      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des produits: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchQuery.isEmpty ||
            product.medicamentName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Tous' ||
            product.category.toLowerCase() == _selectedCategory.toLowerCase();
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addToCart(StockModel product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Vérifier si on change de pharmacie
    if (cartProvider.cartItems.isNotEmpty && cartProvider.selectedPharmacy?.id != widget.pharmacy.id) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Changer de pharmacie'),
          content: const Text(
            'Vous ne pouvez commander que dans une seule pharmacie à la fois. '
            'Voulez-vous vider votre panier actuel et changer de pharmacie ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.clearCart();
                cartProvider.setSelectedPharmacy(widget.pharmacy);
                cartProvider.addToCart(product);
                _showAddedToCartSnackBar(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('Changer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      cartProvider.setSelectedPharmacy(widget.pharmacy);
      cartProvider.addToCart(product);
      _showAddedToCartSnackBar(product);
    }
  }

  void _showAddedToCartSnackBar(StockModel product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.medicamentName} ajouté au panier'),
        action: SnackBarAction(
          label: 'Voir panier',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pharmacy.pharmacyName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${_filteredProducts.length} produits disponibles',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un médicament...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _filterProducts();
                          },
                          selectedColor: AppColors.primaryColor.withOpacity(0.3),
                          checkmarkColor: AppColors.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppDimensions.paddingMedium),
                        Text('Chargement des produits...'),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            _products.isEmpty ? 'Aucun produit disponible' : 'Aucun produit trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            _products.isEmpty 
                ? 'Cette pharmacie n\'a pas encore ajouté de produits à son catalogue'
                : 'Essayez de modifier vos critères de recherche',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Photo du produit ou icône par défaut
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: product.photoUrl == null || product.photoUrl!.isEmpty
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: product.photoUrl != null && product.photoUrl!.isNotEmpty
                        ? Border.all(color: Colors.grey[300]!)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.photoUrl != null && product.photoUrl!.isNotEmpty
                        ? Image.network(
                            product.photoUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.medication,
                                color: AppColors.primaryColor,
                                size: 40,
                              );
                            },
                          )
                        : Icon(
                            Icons.medication,
                            color: AppColors.primaryColor,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.medicamentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product.description.isNotEmpty)
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ${AppStrings.currency}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      'Stock: ${product.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: product.isLowStock ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final itemInCart = cartProvider.getCartItem(product.id);
                    
                    if (itemInCart != null) {
                      return Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              cartProvider.decrementQuantity(product.id);
                            },
                            icon: const Icon(Icons.remove_circle),
                            color: AppColors.primaryColor,
                          ),
                          Text(
                            '${itemInCart.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              cartProvider.incrementQuantity(product.id);
                            },
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.primaryColor,
                          ),
                        ],
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: () => _addToCart(product),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}