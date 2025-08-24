import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../verification_screen.dart';

class DeliveryRegistrationScreen extends StatefulWidget {
  const DeliveryRegistrationScreen({super.key});

  @override
  State<DeliveryRegistrationScreen> createState() => _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState extends State<DeliveryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _agencyController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedVehicleType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _agencyController.dispose();
    _plateNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un type d\'engin'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);

        final userData = {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'agency': _agencyController.text.trim().isEmpty ? null : _agencyController.text.trim(),
          'vehicleType': _selectedVehicleType,
          'plateNumber': _plateNumberController.text.trim(),
          'userType': UserTypes.deliveryPerson,
          'isVerified': false,
          'isApproved': false,
          'createdAt': DateTime.now(),
        };

        await authProvider.registerDeliveryPerson(userData);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
                userType: UserTypes.deliveryPerson,
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
        title: const Text('Inscription Livreur'),
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
                  'Devenir livreur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remplissez vos informations pour rejoindre notre équipe',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Nom complet
                CustomTextField(
                  controller: _fullNameController,
                  label: AppStrings.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateFullName,
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

                // Adresse complète
                CustomTextField(
                  controller: _addressController,
                  label: AppStrings.address,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: Validators.validateAddress,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Agence (optionnel)
                CustomTextField(
                  controller: _agencyController,
                  label: '${AppStrings.agency} (optionnel)',
                  hintText: 'Ex: Agence Libreville Centre',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Type d'engin
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.vehicleType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: InputDecoration(
                        hintText: 'Sélectionnez votre engin',
                        prefixIcon: const Icon(Icons.directions_bike, color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium,
                          vertical: AppDimensions.paddingMedium,
                        ),
                      ),
                      items: VehicleTypes.types.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedVehicleType = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un type d\'engin';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Numéro de plaque
                CustomTextField(
                  controller: _plateNumberController,
                  label: AppStrings.plateNumber,
                  hintText: 'Ex: AB-123-CD',
                  prefixIcon: Icons.confirmation_number_outlined,
                  validator: Validators.validatePlateNumber,
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Mot de passe
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
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
                  label: AppStrings.confirmPassword,
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Bouton d'inscription
                CustomButton(
                  text: 'S\'inscrire comme livreur',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppDimensions.paddingMedium),

                // Note de vérification
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Après vérification de votre email, votre compte sera examiné par notre équipe avant activation.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
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