import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pharmacy_model.dart';
import '../../models/prescription_model.dart';
import '../../utils/constants.dart';

class PharmacyPrescriptionsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyPrescriptionsScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyPrescriptionsScreen> createState() => _PharmacyPrescriptionsScreenState();
}

class _PharmacyPrescriptionsScreenState extends State<PharmacyPrescriptionsScreen> {
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;
  String _selectedFilter = 'mes_ordonnances'; // 'mes_ordonnances' ou 'toutes'
  String _statusFilter = 'tous'; // 'tous', 'uploaded', 'used_in_order'

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('prescriptions');

      // Filtrer par pharmacie ou tout voir
      if (_selectedFilter == 'mes_ordonnances') {
        query = query.where('pharmacyId', isEqualTo: widget.pharmacy.id);
      }

      // Filtrer par statut si nécessaire
      if (_statusFilter != 'tous') {
        query = query.where('status', isEqualTo: _statusFilter);
      }

      final querySnapshot = await query.get();

      // Trier côté client
      final prescriptions = querySnapshot.docs
          .map((doc) => PrescriptionModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      setState(() {
        _prescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement ordonnances: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordonnances reçues'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prescriptions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPrescriptions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          itemCount: _prescriptions.length,
                          itemBuilder: (context, index) {
                            return _buildPrescriptionCard(_prescriptions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Filtre mes ordonnances / toutes
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'mes_ordonnances',
                      label: Text('Mes ordonnances'),
                      icon: Icon(Icons.local_pharmacy, size: 16),
                    ),
                    ButtonSegment(
                      value: 'toutes',
                      label: Text('Toutes'),
                      icon: Icon(Icons.visibility, size: 16),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                    _loadPrescriptions();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          // Filtre par statut
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusFilterChip('Tous', 'tous'),
                _buildStatusFilterChip('Disponibles', 'uploaded'),
                _buildStatusFilterChip('Utilisées', 'used_in_order'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = value;
          });
          _loadPrescriptions();
        },
        selectedColor: AppColors.primaryColor.withOpacity(0.3),
        checkmarkColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Text(
            'Aucune ordonnance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            _selectedFilter == 'mes_ordonnances'
                ? 'Aucune ordonnance n\'a été envoyée à votre pharmacie'
                : 'Aucune ordonnance dans le système',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    final isForThisPharmacy = prescription.pharmacyId == widget.pharmacy.id;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPrescriptionDetail(prescription),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              // Miniature de l'ordonnance
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isForThisPharmacy
                        ? AppColors.primaryColor
                        : Colors.grey[300]!,
                    width: isForThisPharmacy ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    prescription.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.description,
                        size: 40,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordonnance du ${_formatDate(prescription.uploadedAt)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_selectedFilter == 'toutes')
                      Row(
                        children: [
                          Icon(
                            Icons.local_pharmacy,
                            size: 14,
                            color: isForThisPharmacy
                                ? AppColors.primaryColor
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              prescription.pharmacyName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isForThisPharmacy
                                    ? AppColors.primaryColor
                                    : Colors.grey[600],
                                fontWeight: isForThisPharmacy
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_selectedFilter == 'toutes')
                      const SizedBox(height: 4),
                    Text(
                      'Uploadée à ${_formatTime(prescription.uploadedAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(prescription),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PrescriptionModel prescription) {
    if (prescription.isUsed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Utilisée',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Disponible',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showPrescriptionDetail(PrescriptionModel prescription) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Détails ordonnance'),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  prescription.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text('Impossible de charger l\'image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_pharmacy, size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Pharmacie: ${prescription.pharmacyName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploadée le ${_formatDate(prescription.uploadedAt)} à ${_formatTime(prescription.uploadedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(prescription),
                  if (prescription.isUsed) ...  [
                    const SizedBox(height: 8),
                    Text(
                      'Utilisée dans la commande ${prescription.usedInOrderId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
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
}
