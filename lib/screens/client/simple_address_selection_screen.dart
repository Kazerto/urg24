import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/constants.dart';

class SimpleAddressSelectionScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const SimpleAddressSelectionScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SimpleAddressSelectionScreen> createState() => _SimpleAddressSelectionScreenState();
}

class _SimpleAddressSelectionScreenState extends State<SimpleAddressSelectionScreen> {
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _detectedAddress;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog('Services de localisation désactivés', 
          'Veuillez activer les services de localisation dans les paramètres de votre appareil.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Permission refusée', 
            'L\'accès à la localisation est nécessaire pour obtenir votre position actuelle.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Permission refusée définitivement', 
          'Veuillez activer la localisation dans les paramètres de votre appareil.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      await _getAddressFromCoordinates(position.latitude, position.longitude);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actuelle détectée avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Erreur géolocalisation: \$e');
      _showErrorDialog('Erreur de localisation', 
        'Impossible d\'obtenir votre position. Vérifiez que la localisation est activée.');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.name,
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.country
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        setState(() {
          _detectedAddress = address.isNotEmpty ? address : 'Adresse non trouvée';
        });
      }
    } catch (e) {
      debugPrint('Erreur géocodage: \$e');
      setState(() {
        _detectedAddress = 'Erreur lors de la recherche d\'adresse';
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmAddress() {
    String finalAddress;
    
    // Utiliser l'adresse détectée si disponible, sinon l'adresse saisie
    if (_detectedAddress != null && _detectedAddress!.isNotEmpty && _detectedAddress != 'Adresse non trouvée') {
      finalAddress = _detectedAddress!;
    } else if (_addressController.text.isNotEmpty) {
      finalAddress = _addressController.text;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une adresse ou utiliser votre position actuelle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = {
      'address': finalAddress,
      'latitude': _latitude,
      'longitude': _longitude,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Utilisez "Position actuelle" pour une livraison à votre emplacement\n'
                      '• Ou saisissez manuellement l\'adresse de livraison souhaitée',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingLarge),

            // Section Position actuelle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Option 1: Position actuelle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location, color: Colors.white),
                        label: Text(
                          _isLoadingLocation ? 'Détection en cours...' : 'Utiliser ma position actuelle',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          ),
                        ),
                      ),
                    ),
                    
                    // Affichage de l'adresse détectée
                    if (_detectedAddress != null) ...[
                      const SizedBox(height: AppDimensions.paddingMedium),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.green[700], size: 16),
                                const SizedBox(width: 4),
                                const Text(
                                  'Position détectée:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_detectedAddress!, style: const TextStyle(fontSize: 14)),
                            if (_latitude != null && _longitude != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Coordonnées: \${_latitude!.toStringAsFixed(6)}, \${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Section Adresse manuelle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Option 2: Saisir l\'adresse manuellement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Exemple: Quartier Ouaga 2000, près de la banque UBA',
                        labelText: 'Adresse complète',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium,
                          vertical: AppDimensions.paddingMedium,
                        ),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      'Soyez précis pour faciliter la livraison (quartier, points de repère, etc.)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge * 2),

            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmAddress,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Confirmer cette adresse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}