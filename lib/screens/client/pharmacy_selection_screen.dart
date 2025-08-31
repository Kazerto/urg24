import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../models/pharmacy_model.dart';
import '../../utils/constants.dart';
import 'pharmacy_products_screen.dart';

class PharmacySelectionScreen extends StatefulWidget {
  const PharmacySelectionScreen({super.key});

  @override
  State<PharmacySelectionScreen> createState() => _PharmacySelectionScreenState();
}

class _PharmacySelectionScreenState extends State<PharmacySelectionScreen> {
  List<PharmacyModel> _pharmacies = [];
  List<PharmacyModel> _filteredPharmacies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDistance = 'Toutes';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPharmacies();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Services de localisation désactivés.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permissions de localisation refusées');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permissions de localisation refusées de manière permanente');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      setState(() {
        _userPosition = position;
      });
      
      _filterPharmacies();
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la position: $e');
    }
  }

  Future<void> _loadPharmacies() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where('isActive', isEqualTo: true)
          .get();

      final List<PharmacyModel> pharmacies = snapshot.docs
          .map((doc) => PharmacyModel.fromFirestore(doc))
          .toList();

      setState(() {
        _pharmacies = pharmacies;
        _filteredPharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des pharmacies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(PharmacyModel pharmacy) {
    if (_userPosition == null || pharmacy.latitude == null || pharmacy.longitude == null) {
      return 0.0;
    }
    
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      pharmacy.latitude!,
      pharmacy.longitude!,
    ) / 1000; // Convertir en kilomètres
  }

  void _filterPharmacies() {
    setState(() {
      List<PharmacyModel> filtered = _pharmacies.where((pharmacy) {
        final matchesSearch = _searchQuery.isEmpty ||
            pharmacy.pharmacyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            pharmacy.address.toLowerCase().contains(_searchQuery.toLowerCase());
        
        bool matchesDistance = true;
        if (_selectedDistance != 'Toutes' && _userPosition != null) {
          final distance = _calculateDistance(pharmacy);
          switch (_selectedDistance) {
            case 'Moins de 1 km':
              matchesDistance = distance <= 1.0;
              break;
            case 'Moins de 5 km':
              matchesDistance = distance <= 5.0;
              break;
            case 'Moins de 10 km':
              matchesDistance = distance <= 10.0;
              break;
          }
        }
        
        return matchesSearch && matchesDistance;
      }).toList();
      
      // Trier par distance si on a la position de l'utilisateur
      if (_userPosition != null) {
        filtered.sort((a, b) {
          final distanceA = _calculateDistance(a);
          final distanceB = _calculateDistance(b);
          return distanceA.compareTo(distanceB);
        });
      }
      
      _filteredPharmacies = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une pharmacie'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterPharmacies();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher une pharmacie...',
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(
                      _userPosition != null ? 'Distance:' : 'Localisation désactivée',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDistance,
                        dropdownColor: AppColors.primaryColor,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        items: [
                          'Toutes',
                          'Moins de 1 km',
                          'Moins de 5 km',
                          'Moins de 10 km',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDistance = newValue!;
                          });
                          _filterPharmacies();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppDimensions.paddingMedium),
                  Text('Chargement des pharmacies partenaires...'),
                ],
              ),
            )
          : _filteredPharmacies.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPharmacies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    itemCount: _filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      return _buildPharmacyCard(_filteredPharmacies[index]);
                    },
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
            Icons.local_pharmacy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            _pharmacies.isEmpty 
                ? 'Aucune pharmacie disponible' 
                : 'Aucune pharmacie trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            _pharmacies.isEmpty
                ? 'Les pharmacies doivent être approuvées par l\'administrateur avant d\'apparaître ici'
                : 'Essayez de modifier vos critères de recherche',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          ElevatedButton.icon(
            onPressed: _loadPharmacies,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(PharmacyModel pharmacy) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyProductsScreen(pharmacy: pharmacy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
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
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.pharmacyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pharmacy.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ouverte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pharmacy.phoneNumber,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userPosition != null && pharmacy.latitude != null && pharmacy.longitude != null
                        ? '${_calculateDistance(pharmacy).toStringAsFixed(1)} km'
                        : 'Distance inconnue',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Médicaments disponibles',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Choisir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}