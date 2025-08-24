import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/stock_model.dart';
import '../../models/pharmacy_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class StockManagementScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const StockManagementScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<StockModel> stocks = [];
  List<StockModel> filteredStocks = [];
  bool isLoading = false;
  String searchQuery = '';
  String selectedCategory = 'Tous';

  final List<String> categories = [
    'Tous',
    'Médicaments',
    'Vitamines',
    'Antibiotiques',
    'Antalgiques',
    'Matériel médical',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .get();

      List<StockModel> stockList = querySnapshot.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .toList();
      
      // Trier côté client par nom de médicament
      stockList.sort((a, b) => a.medicamentName.compareTo(b.medicamentName));
      
      stocks = stockList;

      _filterStocks();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement du stock: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterStocks() {
    filteredStocks = stocks.where((stock) {
      final matchesSearch = stock.medicamentName
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'Tous' ||
          stock.category == selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Stock'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStocks,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildStockSummary(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStocks.isEmpty
                    ? _buildEmptyState()
                    : _buildStockList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStockDialog(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un médicament...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              searchQuery = value;
              _filterStocks();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      selectedCategory = category;
                      _filterStocks();
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
    );
  }

  Widget _buildStockSummary() {
    final totalProducts = filteredStocks.length;
    final lowStockProducts = filteredStocks.where((s) => s.isLowStock).length;
    final expiringSoon = filteredStocks.where((s) => s.isExpiringSoon).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', totalProducts.toString(), Colors.blue),
          _buildSummaryItem('Stock faible', lowStockProducts.toString(), Colors.orange),
          _buildSummaryItem('Expire bientôt', expiringSoon.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit en stock',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier produit',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddStockDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStocks.length,
      itemBuilder: (context, index) {
        final stock = filteredStocks[index];
        return _buildStockCard(stock);
      },
    );
  }

  Widget _buildStockCard(StockModel stock) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showStockDetails(stock),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stock.medicamentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStockStatusBadge(stock),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    stock.category,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    stock.supplier,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité: ${stock.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          color: stock.isLowStock ? Colors.red : Colors.black,
                          fontWeight: stock.isLowStock ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Prix: ${stock.price.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Expire: ${_formatDate(stock.expirationDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: stock.isExpiringSoon ? Colors.red : Colors.grey[600],
                          fontWeight: stock.isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${stock.medicamentCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockStatusBadge(StockModel stock) {
    if (stock.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Stock faible',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (stock.isExpiringSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Expire bientôt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showStockDetails(StockModel stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stock.medicamentName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Code', stock.medicamentCode),
              _buildDetailRow('Catégorie', stock.category),
              _buildDetailRow('Description', stock.description),
              _buildDetailRow('Quantité', stock.quantity.toString()),
              _buildDetailRow('Quantité minimale', stock.minQuantity.toString()),
              _buildDetailRow('Prix unitaire', '${stock.price.toStringAsFixed(0)} FCFA'),
              _buildDetailRow('Fournisseur', stock.supplier),
              _buildDetailRow('Numéro de lot', stock.batchNumber),
              _buildDetailRow('Date d\'expiration', _formatDate(stock.expirationDate)),
              _buildDetailRow('Ajouté le', _formatDate(stock.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditStockDialog(stock);
            },
            child: const Text('Modifier'),
          ),
        ],
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddStockDialog() {
    _showStockDialog(null);
  }

  void _showEditStockDialog(StockModel stock) {
    _showStockDialog(stock);
  }

  void _showStockDialog(StockModel? stock) {
    final isEditing = stock != null;
    final nameController = TextEditingController(text: stock?.medicamentName ?? '');
    final codeController = TextEditingController(text: stock?.medicamentCode ?? '');
    final categoryController = TextEditingController(text: stock?.category ?? '');
    final descriptionController = TextEditingController(text: stock?.description ?? '');
    final priceController = TextEditingController(text: stock?.price.toString() ?? '');
    final quantityController = TextEditingController(text: stock?.quantity.toString() ?? '');
    final minQuantityController = TextEditingController(text: stock?.minQuantity.toString() ?? '');
    final supplierController = TextEditingController(text: stock?.supplier ?? '');
    final batchController = TextEditingController(text: stock?.batchNumber ?? '');
    DateTime selectedDate = stock?.expirationDate ?? DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Nom du médicament',
                prefixIcon: Icons.medication,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: codeController,
                label: 'Code du médicament',
                prefixIcon: Icons.qr_code,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: categoryController,
                label: 'Catégorie',
                prefixIcon: Icons.category,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descriptionController,
                label: 'Description',
                prefixIcon: Icons.description,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: priceController,
                      label: 'Prix (FCFA)',
                      prefixIcon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: quantityController,
                      label: 'Quantité',
                      prefixIcon: Icons.inventory,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: minQuantityController,
                      label: 'Qté minimale',
                      prefixIcon: Icons.warning,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: supplierController,
                      label: 'Fournisseur',
                      prefixIcon: Icons.business,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: batchController,
                label: 'Numéro de lot',
                prefixIcon: Icons.assignment,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date d\'expiration'),
                subtitle: Text(_formatDate(selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => _saveStock(
              stock,
              nameController.text,
              codeController.text,
              categoryController.text,
              descriptionController.text,
              double.tryParse(priceController.text) ?? 0.0,
              int.tryParse(quantityController.text) ?? 0,
              int.tryParse(minQuantityController.text) ?? 0,
              supplierController.text,
              batchController.text,
              selectedDate,
            ),
            child: Text(isEditing ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStock(
    StockModel? stock,
    String name,
    String code,
    String category,
    String description,
    double price,
    int quantity,
    int minQuantity,
    String supplier,
    String batchNumber,
    DateTime expirationDate,
  ) async {
    if (name.isEmpty || code.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      final now = DateTime.now();
      final stockData = StockModel(
        id: stock?.id ?? '',
        pharmacyId: widget.pharmacy.id,
        medicamentName: name,
        medicamentCode: code,
        category: category,
        description: description,
        price: price,
        quantity: quantity,
        minQuantity: minQuantity,
        expirationDate: expirationDate,
        supplier: supplier,
        batchNumber: batchNumber,
        createdAt: stock?.createdAt ?? now,
        updatedAt: now,
        isActive: true,
      );

      if (stock == null) {
        await FirebaseFirestore.instance
            .collection('stock')
            .add(stockData.toMap());
        _showSuccessSnackBar('Produit ajouté avec succès');
      } else {
        await FirebaseFirestore.instance
            .collection('stock')
            .doc(stock.id)
            .update(stockData.toMap());
        _showSuccessSnackBar('Produit modifié avec succès');
      }

      Navigator.pop(context);
      await _loadStocks();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}