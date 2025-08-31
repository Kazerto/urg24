import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pharmacy_model.dart';
import '../../models/stock_model.dart';
import '../../utils/constants.dart';
import '../login_screen.dart';

class GuestPharmacyProductsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const GuestPharmacyProductsScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<GuestPharmacyProductsScreen> createState() => _GuestPharmacyProductsScreenState();
}

class _GuestPharmacyProductsScreenState extends State<GuestPharmacyProductsScreen> {
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
      debugPrint('Chargement des produits pour pharmacie ID: \${widget.pharmacy.id}');
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('Nombre de produits trouvés: \${snapshot.docs.length}');

      final List<StockModel> products = snapshot.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .where((product) => product.quantity > 0)
          .toList();

      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des produits: \$e');
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

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Pour commander des médicaments, vous devez vous connecter ou créer un compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer à explorer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
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
              '\${_filteredProducts.length} produits disponibles',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Se connecter pour commander',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre d'information
          Container(
            color: Colors.blue.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous explorez en tant qu\'invité. Connectez-vous pour commander.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Se connecter', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: AppColors.primaryColor,
                    size: 28,
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\${product.price.toStringAsFixed(0)} \${AppStrings.currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stock: \${product.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: product.isLowStock ? Colors.red : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLoginPrompt,
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 12),
                    ),
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}