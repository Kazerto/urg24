import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('users');

      // Appliquer le filtre si nécessaire
      if (_selectedFilter != 'all') {
        query = query.where('userType', isEqualTo: _selectedFilter);
      }

      final snapshot = await query.get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();

      // Trier par date de création (les plus récents en premier)
      users.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildStatsCards(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tous', Icons.people),
            const SizedBox(width: 8),
            _buildFilterChip('client', 'Clients', Icons.person),
            const SizedBox(width: 8),
            _buildFilterChip('pharmacy', 'Pharmacies', Icons.local_pharmacy),
            const SizedBox(width: 8),
            _buildFilterChip('delivery', 'Livreurs', Icons.delivery_dining),
            const SizedBox(width: 8),
            _buildFilterChip('admin', 'Admins', Icons.admin_panel_settings),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadUsers();
      },
      selectedColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalUsers = _users.length;
    final clients = _users.where((u) => u['userType'] == 'client').length;
    final pharmacies = _users.where((u) => u['userType'] == 'pharmacy').length;
    final deliveries = _users.where((u) => u['userType'] == 'delivery').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', totalUsers, Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Clients', clients, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Pharmacies', pharmacies, Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Livreurs', deliveries, Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userType = user['userType'] ?? 'unknown';
    final fullName = user['fullName'] ?? user['pharmacyName'] ?? 'Sans nom';
    final email = user['email'] ?? '';
    final phoneNumber = user['phoneNumber'] ?? '';
    final isActive = user['isActive'] ?? false;
    final isDeleted = user['isDeleted'] ?? false;
    final createdAt = user['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getUserTypeColor(userType).withOpacity(0.2),
                    child: Icon(
                      _getUserTypeIcon(userType),
                      color: _getUserTypeColor(userType),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isDeleted ? TextDecoration.lineThrough : null,
                            color: isDeleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildUserTypeBadge(userType),
                      const SizedBox(height: 4),
                      if (isDeleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SUPPRIMÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Actif' : 'Inactif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    phoneNumber.isNotEmpty ? phoneNumber : 'Non renseigné',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (createdAt != null) ...[
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt.toDate()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              if (userType == 'pharmacy') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Licence: ${user['licenseNumber'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (userType == 'delivery') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.two_wheeler, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${user['vehicleType'] ?? 'N/A'} - ${user['plateNumber'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildUserTypeBadge(String userType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getUserTypeColor(userType),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getUserTypeLabel(userType),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'client':
        return Icons.person;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'delivery':
        return Icons.delivery_dining;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'client':
        return Colors.green;
      case 'pharmacy':
        return Colors.orange;
      case 'delivery':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType.toLowerCase()) {
      case 'client':
        return 'Client';
      case 'pharmacy':
        return 'Pharmacie';
      case 'delivery':
        return 'Livreur';
      case 'admin':
        return 'Admin';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getUserTypeColor(user['userType']).withOpacity(0.2),
                      child: Icon(
                        _getUserTypeIcon(user['userType']),
                        color: _getUserTypeColor(user['userType']),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['fullName'] ?? user['pharmacyName'] ?? 'Sans nom',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildUserTypeBadge(user['userType']),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow('Email', user['email'] ?? 'N/A', Icons.email),
                _buildDetailRow('Téléphone', user['phoneNumber'] ?? 'N/A', Icons.phone),
                _buildDetailRow('Adresse', user['address'] ?? 'N/A', Icons.location_on),

                if (user['userType'] == 'pharmacy') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Informations pharmacie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Nom commercial', user['pharmacyName'] ?? 'N/A', Icons.store),
                  _buildDetailRow('N° Licence', user['licenseNumber'] ?? 'N/A', Icons.verified),
                  _buildDetailRow('Horaires', user['openingHours'] ?? 'N/A', Icons.access_time),
                  _buildDetailRow('Approuvée', user['isApproved'] ? 'Oui' : 'Non', Icons.check_circle),
                ],

                if (user['userType'] == 'delivery') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Informations livreur',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Type véhicule', user['vehicleType'] ?? 'N/A', Icons.two_wheeler),
                  _buildDetailRow('Plaque', user['plateNumber'] ?? 'N/A', Icons.badge),
                  _buildDetailRow('Agence', user['agency'] ?? 'Indépendant', Icons.business),
                  _buildDetailRow('Vérifié', user['isVerified'] ? 'Oui' : 'Non', Icons.verified_user),
                  _buildDetailRow('Approuvé', user['isApproved'] ? 'Oui' : 'Non', Icons.check_circle),
                  _buildDetailRow('Note', '${user['rating'] ?? 0}/5', Icons.star),
                  _buildDetailRow('Livraisons', '${user['completedDeliveries'] ?? 0}/${user['totalDeliveries'] ?? 0}', Icons.local_shipping),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Statut',
                  (user['isDeleted'] ?? false) ? 'Supprimé' : ((user['isActive'] ?? false) ? 'Actif' : 'Inactif'),
                  Icons.info,
                ),
                if (user['createdAt'] != null)
                  _buildDetailRow(
                    'Date création',
                    _formatDate((user['createdAt'] as Timestamp).toDate()),
                    Icons.calendar_today,
                  ),
                if (user['deletedAt'] != null)
                  _buildDetailRow(
                    'Date suppression',
                    _formatDate((user['deletedAt'] as Timestamp).toDate()),
                    Icons.delete,
                  ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleUserStatus(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (user['isActive'] ?? false)
                              ? Colors.orange
                              : Colors.green,
                        ),
                        icon: Icon(
                          (user['isActive'] ?? false) ? Icons.block : Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          (user['isActive'] ?? false) ? 'Désactiver' : 'Activer',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final currentStatus = user['isActive'] ?? false;
    final newStatus = !currentStatus;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['uid'])
          .update({'isActive': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Utilisateur ${newStatus ? 'activé' : 'désactivé'} avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadUsers(); // Recharger la liste
    } catch (e) {
      debugPrint('Erreur lors de la modification du statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
