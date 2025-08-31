import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../verification_screen.dart';

class PharmacyRegistrationScreen extends StatefulWidget {
  const PharmacyRegistrationScreen({super.key});

  @override
  State<PharmacyRegistrationScreen> createState() => _PharmacyRegistrationScreenState();
}

class _PharmacyRegistrationScreenState extends State<PharmacyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _openingHoursController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);

        final userData = {
          'pharmacyName': _pharmacyNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'openingHours': _openingHoursController.text.trim(),
          'latitude': _latitudeController.text.isNotEmpty ? double.tryParse(_latitudeController.text.trim()) : null,
          'longitude': _longitudeController.text.isNotEmpty ? double.tryParse(_longitudeController.text.trim()) : null,
          'userType': UserTypes.pharmacy,
          'isVerified': false,
          'isApproved': false,
          'createdAt': DateTime.now(),
        };

        await authProvider.registerPharmacy(userData);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
                userType: UserTypes.pharmacy,
              ),
            ),
          );
        }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'inscription: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.'),
            backgroundColor: AppColors.errorColor,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée'),
              backgroundColor: AppColors.errorColor,
            ),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation refusée de manière permanente. Veuillez l\'activer dans les paramètres.'),
            backgroundColor: AppColors.errorColor,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position récupérée avec succès !'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération de la position: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Inscription Pharmacie'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                const Text(
                  'Inscription de pharmacie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enregistrez votre pharmacie sur notre plateforme',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Nom de la pharmacie
                CustomTextField(
                  controller: _pharmacyNameController,
                  label: AppStrings.pharmacyName,
                  hintText: 'Ex: Pharmacie des Remèdes',
                  prefixIcon: Icons.local_pharmacy_outlined,
                  validator: Validators.validatePharmacyName,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Mot de passe
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  obscureText: !_isPasswordVisible,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Confirmer mot de passe
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return Validators.validatePassword(value);
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Numéro de téléphone
                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.validatePhoneNumber,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Adresse
                CustomTextField(
                  controller: _addressController,
                  label: AppStrings.address,
                  hintText: 'Adresse complète de la pharmacie',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: Validators.validateAddress,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Numéro de licence
                CustomTextField(
                  controller: _licenseNumberController,
                  label: AppStrings.licenseNumber,
                  hintText: 'Numéro d\'autorisation d\'exercer',
                  prefixIcon: Icons.verified_outlined,
                  validator: Validators.validateLicenseNumber,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Horaires d'ouverture
                CustomTextField(
                  controller: _openingHoursController,
                  label: AppStrings.openingHours,
                  hintText: 'Ex: 08:00 - 18:00',
                  prefixIcon: Icons.access_time_outlined,
                  validator: Validators.validateOpeningHours,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Section coordonnées géographiques
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Coordonnées géographiques (optionnel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ces coordonnées permettront aux clients de vous localiser plus facilement',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Bouton pour récupérer la position actuelle
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
                        child: ElevatedButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(
                            _isGettingLocation 
                                ? 'Récupération en cours...' 
                                : 'Utiliser ma position actuelle'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Séparateur avec "OU"
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      
                      // Latitude
                      CustomTextField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        hintText: 'Ex: 6.1319',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.place_outlined,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final lat = double.tryParse(value);
                            if (lat == null || lat < -90 || lat > 90) {
                              return 'Latitude invalide (doit être entre -90 et 90)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Longitude
                      CustomTextField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        hintText: 'Ex: 1.2123',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.place_outlined,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final lng = double.tryParse(value);
                            if (lng == null || lng < -180 || lng > 180) {
                              return 'Longitude invalide (doit être entre -180 et 180)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),

                      // Note d'aide
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Conseil : Utilisez le bouton "Ma position actuelle" si vous êtes actuellement dans votre pharmacie, ou saisissez manuellement les coordonnées obtenues via Google Maps.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Bouton d'inscription
                CustomButton(
                  text: 'Soumettre la demande',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppDimensions.paddingMedium),

                // Note importante pour les pharmacies
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(
                      color: AppColors.warningColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            color: AppColors.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Important',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Votre demande sera examinée par notre équipe d\'administration\n'
                            '• Vous recevrez vos identifiants de connexion par email après validation\n'
                            '• Assurez-vous que toutes les informations sont correctes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.warningColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingMedium),

                // Note sur les documents requis
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Documents à préparer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Copie de la licence pharmaceutique\n'
                            '• Justificatif d\'adresse du local\n'
                            '• Documents d\'identité du responsable\n'
                            '• Autorisation d\'exercer',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}