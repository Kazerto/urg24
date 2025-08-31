import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/pharmacy_model.dart';
import '../../utils/constants.dart';
import 'guest_pharmacy_products_screen.dart';

class GuestPharmacySelectionScreen extends StatefulWidget {
  const GuestPharmacySelectionScreen({super.key});

  @override
  State<GuestPharmacySelectionScreen> createState() => _GuestPharmacySelectionScreenState();
}

class _GuestPharmacySelectionScreenState extends State<GuestPharmacySelectionScreen> {
  List<PharmacyModel> _pharmacies = [];
  List<PharmacyModel> _filteredPharmacies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDistance = 'Toutes';
  Position? _userPosition;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadPharmacies();
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog('Services de localisation désactivés', 
          'Veuillez activer les services de localisation pour voir les pharmacies les plus proches.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog('Permission refusée', 
            'L\'accès à votre position permet de trouver les pharmacies les plus proches.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog('Permission refusée définitivement', 
          'Veuillez activer la localisation dans les paramètres de votre appareil.');
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      debugPrint('Erreur permission localisation: \$e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      setState(() {
        _userPosition = position;
        _locationPermissionGranted = true;
      });
      
      _filterPharmacies();
    } catch (e) {
      debugPrint('Erreur géolocalisation: \$e');
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer sans localisation'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestLocationPermission();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
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
      debugPrint('Erreur chargement pharmacies: \$e');
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
    ) / 1000;
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
        title: const Text('Pharmacies disponibles'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_locationPermissionGranted ? 100 : 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_locationPermissionGranted)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Localisation désactivée',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Activez la localisation pour voir les distances',
                              style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                            ),
                          ),
                          TextButton(
                            onPressed: _requestLocationPermission,
                            child: const Text('Activer', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                child: Row(
                  children: [
                    Icon(
                      _locationPermissionGranted ? Icons.location_on : Icons.location_off, 
                      color: Colors.white70
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(
                      _locationPermissionGranted ? 'Distance:' : 'Distance non disponible',
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
                        onChanged: _locationPermissionGranted ? (String? newValue) {
                          setState(() {
                            _selectedDistance = newValue!;
                          });
                          _filterPharmacies();
                        } : null,
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
                  Text('Chargement des pharmacies...'),
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
            _pharmacies.isEmpty ? 'Aucune pharmacie disponible' : 'Aucune pharmacie trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            _pharmacies.isEmpty
                ? 'Aucune pharmacie n\'est actuellement active'
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
              builder: (context) => GuestPharmacyProductsScreen(pharmacy: pharmacy),
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
                        ? '\${_calculateDistance(pharmacy).toStringAsFixed(1)} km'
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
                            'Voir les médicaments',
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
                          'Explorer',
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