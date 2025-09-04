import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'products_browser_screen.dart';

class CategoriesBrowserScreen extends StatelessWidget {
  const CategoriesBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Explorer les produits'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                    Icons.category_outlined,
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
                    'Les pharmacies n\'ont pas encore ajouté de produits',
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

          // Extraire les catégories uniques des produits
          Set<String> categoriesSet = {};
          Map<String, int> categoryCount = {};
          Map<String, String> categoryImages = {};
          
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String category = data['category']?.toString() ?? 'Autres';
            String imageUrl = data['imageUrl']?.toString() ?? '';
            
            categoriesSet.add(category);
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
            
            // Garder la première image trouvée pour la catégorie
            if (categoryImages[category] == null && imageUrl.isNotEmpty) {
              categoryImages[category] = imageUrl;
            }
          }

          List<String> categories = categoriesSet.toList()..sort();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégories disponibles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parcourez les médicaments par catégorie',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final crossAxisCount = screenWidth > 600 ? 3 : 2;
                      final itemWidth = (screenWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                      final itemHeight = itemWidth * 0.85;
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: itemWidth / itemHeight,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      String category = categories[index];
                      int productCount = categoryCount[category] ?? 0;
                      String imageUrl = categoryImages[category] ?? '';
                      
                      return _buildCategoryCard(
                        context,
                        category: category,
                        productCount: productCount,
                        imageUrl: imageUrl,
                      );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String category,
    required int productCount,
    required String imageUrl,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductsBrowserScreen(category: category),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                AppColors.lightBlue.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône ou image de catégorie
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getCategoryIcon(category),
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(category),
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$productCount produit${productCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'antalgiques':
      case 'antidouleur':
        return Icons.healing;
      case 'antibiotiques':
        return Icons.medication;
      case 'vitamines':
        return Icons.favorite;
      case 'digestif':
        return Icons.restaurant;
      case 'respiratoire':
        return Icons.air;
      case 'dermatologie':
        return Icons.face;
      case 'cardiologie':
        return Icons.favorite_border;
      case 'ophtalmologie':
        return Icons.visibility;
      case 'pédiatrie':
        return Icons.child_care;
      default:
        return Icons.medical_services;
    }
  }
}