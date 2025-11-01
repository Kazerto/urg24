import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/pharmacy_model.dart';
import '../../providers/auth_provider_simple.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_service.dart';

class PharmacyProfileScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyProfileScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isSaving = false;
  String? _avatarUrl;
  XFile? _selectedImage;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.pharmacy.phoneNumber;
    _addressController.text = widget.pharmacy.address;
    _openingHoursController.text = widget.pharmacy.openingHours;
    _licenseController.text = widget.pharmacy.licenseNumber;
    _avatarUrl = widget.pharmacy.profileImageUrl;
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
            userId: widget.pharmacy.id,
            userType: 'pharmacy',
            webImage: _webImage,
          );
          debugPrint('✅ Avatar pharmacie uploadé: $newAvatarUrl');
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
        }
      }

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacy.id)
          .update({
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'profileImageUrl': newAvatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour aussi dans users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.pharmacy.id)
          .update({
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
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
        Navigator.pop(context, true); // Retourne true pour indiquer une mise à jour
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde profil pharmacie: $e');
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

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil de la pharmacie'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Photo section
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
                                Icons.local_pharmacy,
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

              // Nom de la pharmacie (lecture seule)
              const Text(
                'Informations générales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.business, color: AppColors.primaryColor),
                  title: const Text('Nom de la pharmacie'),
                  subtitle: Text(
                    widget.pharmacy.pharmacyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Informations modifiables
              const Text(
                'Informations de contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Informations d'exploitation
              const Text(
                'Informations d\'exploitation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              // Horaires d'ouverture
              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Horaires d\'ouverture',
                  prefixIcon: Icon(Icons.access_time_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Lun-Ven: 8h-20h, Sam: 8h-18h',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Les horaires sont requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              // Numéro de licence
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de licence',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le numéro de licence est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Email (lecture seule)
              const Text(
                'Informations de compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.primaryColor),
                  title: const Text('Email'),
                  subtitle: Text(
                    widget.pharmacy.email,
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
                    'Supprimer le compte de la pharmacie',
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
          'En supprimant le compte de votre pharmacie, vous perdrez :\n'
          '• Toutes vos informations\n'
          '• Votre stock de médicaments\n'
          '• L\'historique des commandes\n'
          '• Les ordonnances reçues\n\n'
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
            child: const Text('Oui, supprimer le compte'),
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
      final anonymizedEmail = 'deleted_pharmacy_${widget.pharmacy.id.substring(0, 8)}@deleted.com';

      // 1. SOFT DELETE - Désactiver le stock (garder pour l'historique)
      final stockQuery = await FirebaseFirestore.instance
          .collection('stock')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      for (var doc in stockQuery.docs) {
        await doc.reference.update({
          'isActive': false,
          'pharmacyDeleted': true,
          'deletedAt': timestamp,
        });
      }

      // 2. SOFT DELETE - Marquer les ordonnances (garder pour l'historique client)
      final prescriptionsQuery = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      for (var doc in prescriptionsQuery.docs) {
        await doc.reference.update({
          'pharmacyDeleted': true,
          'pharmacyName': '[Pharmacie fermée]',
          'deletedAt': timestamp,
        });
      }

      // 3. SOFT DELETE - Anonymiser les commandes (IMPORTANT pour l'historique)
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('pharmacyId', isEqualTo: widget.pharmacy.id)
          .get();

      for (var doc in ordersQuery.docs) {
        await doc.reference.update({
          'pharmacyDeleted': true,
          'pharmacyName': '[Pharmacie fermée]',
          'deletedAt': timestamp,
        });
      }

      // 4. SOFT DELETE - Désactiver et anonymiser le compte pharmacie
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacy.id)
          .update({
        'isDeleted': true,
        'isActive': false,
        'isApproved': false,
        'deletedAt': timestamp,
        // Anonymiser les données
        'pharmacyName': '[Pharmacie fermée]',
        'email': anonymizedEmail,
        'phoneNumber': '[Supprimé]',
        'address': '[Supprimé]',
        'licenseNumber': '[Supprimé]',
        'profileImageUrl': null,
      });

      // 5. SOFT DELETE - Désactiver le compte utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': timestamp,
        'email': anonymizedEmail,
        'phoneNumber': '[Supprimé]',
        'address': '[Supprimé]',
        'profileImageUrl': null,
      });

      // 6. Supprimer le compte Firebase Auth (ne peut plus se connecter)
      await user.delete();

      // 7. Déconnecter et rediriger
      if (mounted) {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.signOut();

        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le compte de la pharmacie a été désactivé.\nLes données ont été anonymisées.'),
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
}
