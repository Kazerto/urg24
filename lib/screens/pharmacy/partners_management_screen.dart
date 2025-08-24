import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/partner_model.dart';
import '../../models/pharmacy_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class PartnersManagementScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PartnersManagementScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PartnersManagementScreen> createState() => _PartnersManagementScreenState();
}

class _PartnersManagementScreenState extends State<PartnersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PartnerModel> allPartners = [];
  List<PartnerModel> pharmacyPartners = [];
  List<PartnerModel> supplierPartners = [];
  List<PartnerModel> laboratoryPartners = [];
  List<PartnerModel> insurancePartners = [];
  List<PartnerModel> hospitalPartners = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadPartners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .where('isActive', isEqualTo: true)
          .orderBy('partnerName')
          .get();

      allPartners = querySnapshot.docs
          .map((doc) => PartnerModel.fromFirestore(doc))
          .toList();

      _categorizePartners();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des partenaires: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _categorizePartners() {
    final filtered = searchQuery.isEmpty
        ? allPartners
        : allPartners.where((partner) =>
            partner.partnerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            partner.partnerEmail.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    pharmacyPartners = filtered.where((p) => p.partnerType == PartnerType.pharmacy).toList();
    supplierPartners = filtered.where((p) => p.partnerType == PartnerType.supplier).toList();
    laboratoryPartners = filtered.where((p) => p.partnerType == PartnerType.laboratory).toList();
    insurancePartners = filtered.where((p) => p.partnerType == PartnerType.insurance).toList();
    hospitalPartners = filtered.where((p) => p.partnerType == PartnerType.hospital).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Partenaires'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPartners,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showPartnerStats,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un partenaire...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    searchQuery = value;
                    _categorizePartners();
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    text: 'Tous',
                    icon: Badge(
                      label: Text(allPartners.length.toString()),
                      child: const Icon(Icons.group),
                    ),
                  ),
                  Tab(
                    text: 'Pharmacies',
                    icon: Badge(
                      label: Text(pharmacyPartners.length.toString()),
                      child: const Icon(Icons.local_pharmacy),
                    ),
                  ),
                  Tab(
                    text: 'Fournisseurs',
                    icon: Badge(
                      label: Text(supplierPartners.length.toString()),
                      child: const Icon(Icons.local_shipping),
                    ),
                  ),
                  Tab(
                    text: 'Laboratoires',
                    icon: Badge(
                      label: Text(laboratoryPartners.length.toString()),
                      child: const Icon(Icons.science),
                    ),
                  ),
                  Tab(
                    text: 'Assurances',
                    icon: Badge(
                      label: Text(insurancePartners.length.toString()),
                      child: const Icon(Icons.security),
                    ),
                  ),
                  Tab(
                    text: 'Hôpitaux',
                    icon: Badge(
                      label: Text(hospitalPartners.length.toString()),
                      child: const Icon(Icons.local_hospital),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPartnersList(allPartners, 'tous les partenaires'),
                _buildPartnersList(pharmacyPartners, 'pharmacies partenaires'),
                _buildPartnersList(supplierPartners, 'fournisseurs'),
                _buildPartnersList(laboratoryPartners, 'laboratoires'),
                _buildPartnersList(insurancePartners, 'assurances'),
                _buildPartnersList(hospitalPartners, 'hôpitaux'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPartnerDialog(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPartnersList(List<PartnerModel> partners, String type) {
    if (partners.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadPartners,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: partners.length,
        itemBuilder: (context, index) {
          final partner = partners[index];
          return _buildPartnerCard(partner);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun $type',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier partenaire',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPartnerDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un partenaire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPartnerDetails(partner),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.partnerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          partner.partnerTypeDisplay,
                          style: TextStyle(
                            color: _getTypeColor(partner.partnerType),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (partner.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Vérifié',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _getTypeIcon(partner.partnerType),
                        color: _getTypeColor(partner.partnerType),
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      partner.partnerEmail,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    partner.partnerPhone,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (partner.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  partner.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (partner.lastContactDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Dernier contact: ${_formatDate(partner.lastContactDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(PartnerType type) {
    switch (type) {
      case PartnerType.pharmacy:
        return Colors.blue;
      case PartnerType.supplier:
        return Colors.orange;
      case PartnerType.laboratory:
        return Colors.purple;
      case PartnerType.insurance:
        return Colors.green;
      case PartnerType.hospital:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(PartnerType type) {
    switch (type) {
      case PartnerType.pharmacy:
        return Icons.local_pharmacy;
      case PartnerType.supplier:
        return Icons.local_shipping;
      case PartnerType.laboratory:
        return Icons.science;
      case PartnerType.insurance:
        return Icons.security;
      case PartnerType.hospital:
        return Icons.local_hospital;
    }
  }

  void _showPartnerDetails(PartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getTypeIcon(partner.partnerType), color: _getTypeColor(partner.partnerType)),
            const SizedBox(width: 8),
            Expanded(child: Text(partner.partnerName)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', partner.partnerTypeDisplay),
              _buildDetailRow('Email', partner.partnerEmail),
              _buildDetailRow('Téléphone', partner.partnerPhone),
              _buildDetailRow('Adresse', partner.partnerAddress),
              _buildDetailRow('Description', partner.description),
              _buildDetailRow('Statut', partner.isVerified ? 'Vérifié' : 'Non vérifié'),
              _buildDetailRow('Ajouté le', _formatDate(partner.createdAt)),
              if (partner.lastContactDate != null)
                _buildDetailRow('Dernier contact', _formatDate(partner.lastContactDate!)),
              if (partner.additionalData.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Informations supplémentaires:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...partner.additionalData.entries.map((entry) =>
                  _buildDetailRow(entry.key, entry.value.toString())),
              ],
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
              _contactPartner(partner);
            },
            child: const Text('Contacter'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditPartnerDialog(partner);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  void _showPartnerStats() {
    final totalPartners = allPartners.length;
    final verifiedPartners = allPartners.where((p) => p.isVerified).length;
    final recentContacts = allPartners.where((p) =>
        p.lastContactDate != null &&
        DateTime.now().difference(p.lastContactDate!).inDays <= 30).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des partenaires'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total partenaires', totalPartners.toString()),
            _buildStatRow('Vérifiés', verifiedPartners.toString()),
            _buildStatRow('Contacts récents (30j)', recentContacts.toString()),
            const Divider(),
            _buildStatRow('Pharmacies', pharmacyPartners.length.toString()),
            _buildStatRow('Fournisseurs', supplierPartners.length.toString()),
            _buildStatRow('Laboratoires', laboratoryPartners.length.toString()),
            _buildStatRow('Assurances', insurancePartners.length.toString()),
            _buildStatRow('Hôpitaux', hospitalPartners.length.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddPartnerDialog() {
    _showPartnerDialog(null);
  }

  void _showEditPartnerDialog(PartnerModel partner) {
    _showPartnerDialog(partner);
  }

  void _showPartnerDialog(PartnerModel? partner) {
    final isEditing = partner != null;
    final nameController = TextEditingController(text: partner?.partnerName ?? '');
    final emailController = TextEditingController(text: partner?.partnerEmail ?? '');
    final phoneController = TextEditingController(text: partner?.partnerPhone ?? '');
    final addressController = TextEditingController(text: partner?.partnerAddress ?? '');
    final descriptionController = TextEditingController(text: partner?.description ?? '');
    PartnerType selectedType = partner?.partnerType ?? PartnerType.supplier;
    bool isVerified = partner?.isVerified ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Modifier le partenaire' : 'Ajouter un partenaire'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Nom du partenaire',
                  prefixIcon: Icons.business,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PartnerType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type de partenaire',
                    prefixIcon: Icon(_getTypeIcon(selectedType)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: PartnerType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getTypeIcon(type), size: 20, color: _getTypeColor(type)),
                          const SizedBox(width: 8),
                          Text(PartnerModel(
                            id: '',
                            pharmacyId: '',
                            partnerName: '',
                            partnerEmail: '',
                            partnerPhone: '',
                            partnerAddress: '',
                            partnerType: type,
                            description: '',
                            createdAt: DateTime.now(),
                          ).partnerTypeDisplay),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneController,
                  label: 'Téléphone',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: addressController,
                  label: 'Adresse',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: descriptionController,
                  label: 'Description',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Partenaire vérifié'),
                  subtitle: const Text('Marquer comme partenaire de confiance'),
                  value: isVerified,
                  onChanged: (value) {
                    setState(() => isVerified = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
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
              onPressed: () => _savePartner(
                partner,
                nameController.text,
                emailController.text,
                phoneController.text,
                addressController.text,
                descriptionController.text,
                selectedType,
                isVerified,
              ),
              child: Text(isEditing ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePartner(
    PartnerModel? partner,
    String name,
    String email,
    String phone,
    String address,
    String description,
    PartnerType type,
    bool isVerified,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      final now = DateTime.now();
      final partnerData = PartnerModel(
        id: partner?.id ?? '',
        pharmacyId: widget.pharmacy.id,
        partnerName: name,
        partnerEmail: email,
        partnerPhone: phone,
        partnerAddress: address,
        partnerType: type,
        description: description,
        isVerified: isVerified,
        createdAt: partner?.createdAt ?? now,
        lastContactDate: partner?.lastContactDate,
        additionalData: partner?.additionalData ?? {},
      );

      if (partner == null) {
        await FirebaseFirestore.instance
            .collection('partners')
            .add(partnerData.toMap());
        _showSuccessSnackBar('Partenaire ajouté avec succès');
      } else {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(partner.id)
            .update(partnerData.toMap());
        _showSuccessSnackBar('Partenaire modifié avec succès');
      }

      Navigator.pop(context);
      await _loadPartners();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    }
  }

  void _contactPartner(PartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contacter ${partner.partnerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Appeler'),
              subtitle: Text(partner.partnerPhone),
              onTap: () {
                Navigator.pop(context);
                _updateLastContact(partner);
                // TODO: Implémenter l'appel téléphonique
                _showSuccessSnackBar('Fonctionnalité d\'appel en cours de développement');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Envoyer un email'),
              subtitle: Text(partner.partnerEmail),
              onTap: () {
                Navigator.pop(context);
                _updateLastContact(partner);
                // TODO: Implémenter l'envoi d'email
                _showSuccessSnackBar('Fonctionnalité d\'email en cours de développement');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLastContact(PartnerModel partner) async {
    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partner.id)
          .update({'lastContactDate': Timestamp.fromDate(DateTime.now())});
      
      await _loadPartners();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du dernier contact: $e');
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