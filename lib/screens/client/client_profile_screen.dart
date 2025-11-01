import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/auth_provider_simple.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;
  String? _avatarUrl;
  XFile? _selectedImage;
  Uint8List? _webImage;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      _userId = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
          _avatarUrl = data['profileImageUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? newAvatarUrl = _avatarUrl;

      // Upload de l'avatar si une nouvelle image a été sélectionnée
      if (_selectedImage != null) {
        try {
          final cloudinaryService = CloudinaryService();
          newAvatarUrl = await cloudinaryService.uploadProfileImage(
            file: _selectedImage!,
            userId: _userId!,
            userType: 'client',
            webImage: _webImage,
          );
          debugPrint('✅ Avatar uploadé: $newAvatarUrl');
        } catch (e) {
          debugPrint('❌ Erreur upload avatar: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'upload de l\'avatar: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue avec la sauvegarde même si l'avatar échoue
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'profileImageUrl': newAvatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Rafraîchir le provider
      if (mounted) {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.refreshUserData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil mis à jour avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Lire les bytes pour l'affichage web
        final bytes = await image.readAsBytes();

        setState(() {
          _selectedImage = image;
          _webImage = bytes;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer le compte'),
          ],
        ),
        content: const Text(
          'ATTENTION : Cette action est irréversible !\n\n'
          'En supprimant votre compte, vous perdrez :\n'
          '• Toutes vos informations personnelles\n'
          '• L\'historique de vos commandes\n'
          '• Vos ordonnances enregistrées\n\n'
          'Êtes-vous absolument sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, supprimer mon compte'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Afficher un indicateur de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final timestamp = FieldValue.serverTimestamp();
      final anonymizedEmail = 'deleted_${user.uid.substring(0, 8)}@deleted.com';

      // 1. SOFT DELETE - Anonymiser les ordonnances (garder pour l'historique pharmacie)
      final prescriptionsQuery = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in prescriptionsQuery.docs) {
        await doc.reference.update({
          'userDeleted': true,
          'deletedAt': timestamp,
          // Garder l'ordonnance mais marquer comme supprimée
        });
      }

      // 2. SOFT DELETE - Anonymiser les commandes (IMPORTANT pour l'historique)
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('clientEmail', isEqualTo: user.email)
          .get();

      for (var doc in ordersQuery.docs) {
        await doc.reference.update({
          'clientDeleted': true,
          'clientName': '[Utilisateur supprimé]',
          'clientEmail': anonymizedEmail,
          'clientPhone': '[Supprimé]',
          'deletedAt': timestamp,
          // Garder deliveryAddress pour l'historique des livraisons
        });
      }

      // 3. SOFT DELETE - Désactiver et anonymiser le compte utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': timestamp,
        // Anonymiser les données personnelles (RGPD)
        'fullName': '[Utilisateur supprimé]',
        'email': anonymizedEmail,
        'phoneNumber': '[Supprimé]',
        'address': '[Supprimé]',
        'profileImageUrl': null,
      });

      // 4. Supprimer le compte Firebase Auth (l'utilisateur ne peut plus se connecter)
      await user.delete();

      // 5. Déconnecter et rediriger vers l'écran de connexion
      if (mounted) {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.signOut();

        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre compte a été supprimé avec succès.\nVos données ont été anonymisées.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du compte: $e');
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression du compte.\n'
              'Veuillez vous reconnecter et réessayer.\n\n'
              'Erreur: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                              backgroundImage: _webImage != null
                                  ? MemoryImage(_webImage!)
                                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                      ? NetworkImage(_avatarUrl!)
                                      : null) as ImageProvider?,
                              child: (_webImage == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.primaryColor,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Informations personnelles
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Nom complet
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (value.trim().length < 3) {
                          return 'Le nom doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: +223 XX XX XX XX',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le numéro de téléphone est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Adresse
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'adresse est requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Informations de compte
                    const Text(
                      'Informations de compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Email (lecture seule)
                    Consumer<AuthProviderSimple>(
                      builder: (context, authProvider, child) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.email_outlined, color: AppColors.primaryColor),
                            title: const Text('Email'),
                            subtitle: Text(
                              authProvider.userData?['email'] ?? 'Non renseigné',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Non modifiable',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingLarge),

                    // Bouton de sauvegarde
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Enregistrer les modifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),

                    // Bouton de suppression de compte (danger zone)
                    const Divider(height: 40),
                    const Text(
                      'Zone de danger',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteAccountConfirmation,
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text(
                          'Supprimer mon compte',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
