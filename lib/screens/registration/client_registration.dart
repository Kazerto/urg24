import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_simple.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../verification_screen.dart';

class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() => _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'userType': UserTypes.client,
        };

        String verificationCode = await authProvider.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          userData: userData,
        );
        
        debugPrint('Code de vérification: $verificationCode');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
                userType: UserTypes.client,
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
        title: const Text('Inscription Client'),
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
                  'Créer un compte client',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Remplissez vos informations pour créer votre compte',
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
                  text: 'S\'inscrire',
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
                          'Un code de vérification sera envoyé à votre email après l\'inscription.',
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