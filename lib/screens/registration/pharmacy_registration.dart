import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _openingHoursController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final userData = {
          'pharmacyName': _pharmacyNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'openingHours': _openingHoursController.text.trim(),
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