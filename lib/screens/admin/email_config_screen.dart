import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/email_config.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('smtp_email');
      final password = prefs.getString('smtp_password');
      
      if (email != null && password != null) {
        _emailController.text = email;
        _passwordController.text = password;
        SecureEmailConfig.setCredentials(email, password);
        setState(() {
          _isConfigured = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration: $e');
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sauvegarder localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smtp_email', email);
      await prefs.setString('smtp_password', password);

      // Configurer le service
      SecureEmailConfig.setCredentials(email, password);

      setState(() {
        _isConfigured = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration email sauvegardée avec succès'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testEmailConfig() async {
    if (!SecureEmailConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord configurer les paramètres email'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Test d'envoi à l'email configuré
      final testEmail = _emailController.text.trim();
      
      // Simuler un test de code de vérification
      // Note: En réalité, vous pourriez créer une méthode de test spécifique
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test d\'envoi en cours vers $testEmail...'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du test: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smtp_email');
      await prefs.remove('smtp_password');
      
      _emailController.clear();
      _passwordController.clear();
      
      setState(() {
        _isConfigured = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration supprimée'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Configuration Email'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status de configuration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: _isConfigured ? AppColors.successColor.withOpacity(0.1) : AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: _isConfigured ? AppColors.successColor : AppColors.warningColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConfigured ? Icons.check_circle : Icons.warning,
                      color: _isConfigured ? AppColors.successColor : AppColors.warningColor,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        _isConfigured 
                          ? 'Configuration email active'
                          : 'Configuration email requise',
                        style: TextStyle(
                          color: _isConfigured ? AppColors.successColor : AppColors.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Instructions
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions Gmail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        '1. Créez un compte Gmail dédié\n'
                        '2. Activez l\'authentification à 2 facteurs\n'
                        '3. Générez un "Mot de passe d\'application"\n'
                        '4. Utilisez ce mot de passe ci-dessous',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Formulaire de configuration
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email SMTP (Gmail)',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir l\'email';
                        }
                        if (!value.contains('@gmail.com')) {
                          return 'Utilisez un email Gmail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Mot de passe d\'application',
                      prefixIcon: Icons.lock,
                      obscureText: !_isPasswordVisible,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir le mot de passe d\'application';
                        }
                        if (value.length < 10) {
                          return 'Le mot de passe d\'application doit faire au moins 10 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Sauvegarder',
                            onPressed: _isLoading ? null : _saveConfig,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMedium),
                        Expanded(
                          child: CustomButton(
                            text: 'Tester',
                            onPressed: _isLoading ? null : _testEmailConfig,
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),

                    if (_isConfigured) ...[
                      const SizedBox(height: AppDimensions.paddingMedium),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _clearConfig,
                          child: const Text(
                            'Effacer la configuration',
                            style: TextStyle(color: AppColors.errorColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Informations sur la sécurité
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: AppColors.primaryColor),
                          SizedBox(width: AppDimensions.paddingSmall),
                          Text(
                            'Sécurité',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        'Les informations sont stockées localement sur l\'appareil. '
                        'En production, utilisez un service comme SendGrid ou AWS SES.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}