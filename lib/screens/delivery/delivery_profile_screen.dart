import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/delivery_person.dart';
import '../../providers/auth_provider_simple.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_service.dart';

class DeliveryProfileScreen extends StatefulWidget {
  final DeliveryPersonModel deliveryPerson;

  const DeliveryProfileScreen({
    super.key,
    required this.deliveryPerson,
  });

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _agencyController = TextEditingController();

  bool _isSaving = false;
  String? _avatarUrl;
  XFile? _selectedImage;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.deliveryPerson.fullName;
    _phoneController.text = widget.deliveryPerson.phoneNumber;
    _addressController.text = widget.deliveryPerson.address;
    _vehicleTypeController.text = widget.deliveryPerson.vehicleType;
    _plateNumberController.text = widget.deliveryPerson.plateNumber;
    _agencyController.text = widget.deliveryPerson.agency ?? '';
    _avatarUrl = widget.deliveryPerson.profileImageUrl;
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
            userId: widget.deliveryPerson.id,
            userType: 'delivery_person',
            webImage: _webImage,
          );
          debugPrint('✅ Avatar livreur uploadé: $newAvatarUrl');
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
          .collection('users')
          .doc(widget.deliveryPerson.id)
          .update({
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'vehicleType': _vehicleTypeController.text.trim(),
        'plateNumber': _plateNumberController.text.trim(),
        'agency': _agencyController.text.trim().isEmpty ? null : _agencyController.text.trim(),
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
      debugPrint('Erreur sauvegarde profil livreur: $e');
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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _plateNumberController.dispose();
    _agencyController.dispose();
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
      body: SingleChildScrollView(
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
                                Icons.delivery_dining,
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
              const SizedBox(height: AppDimensions.paddingMedium),

              // Statistiques
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    'Note',
                    widget.deliveryPerson.rating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildStatCard(
                    'Livrées',
                    widget.deliveryPerson.completedDeliveries.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total',
                    widget.deliveryPerson.totalDeliveries.toString(),
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ],
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
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

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

              // Informations véhicule
              const Text(
                'Informations véhicule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Type de véhicule',
                  prefixIcon: Icon(Icons.two_wheeler_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Moto, Scooter, Vélo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le type de véhicule est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La plaque d\'immatriculation est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              TextFormField(
                controller: _agencyController,
                decoration: const InputDecoration(
                  labelText: 'Agence (optionnel)',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
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

              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.primaryColor),
                  title: const Text('Email'),
                  subtitle: Text(
                    widget.deliveryPerson.email,
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
                    'Supprimer mon compte livreur',
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
          'En supprimant votre compte livreur :\n'
          '• Vos informations personnelles seront anonymisées\n'
          '• Votre historique de livraisons sera préservé pour les pharmacies\n'
          '• Vous ne pourrez plus vous connecter\n'
          '• Les commandes déjà effectuées resteront dans le système\n\n'
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
      final anonymizedEmail = 'deleted_delivery_${user.uid.substring(0, 8)}@deleted.com';

      // 1. SOFT DELETE - Anonymiser les commandes assignées (garder pour l'historique)
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: widget.deliveryPerson.id)
          .get();

      for (var doc in ordersQuery.docs) {
        await doc.reference.update({
          'deliveryPersonDeleted': true,
          'deliveryPersonName': '[Livreur supprimé]',
          'deliveryPersonPhone': '[Supprimé]',
          'deletedAt': timestamp,
          // Garder deliveryPersonId et le statut pour l'historique
        });
      }

      // 2. SOFT DELETE - Désactiver et anonymiser le compte livreur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': timestamp,
        // Anonymiser les données personnelles (RGPD)
        'fullName': '[Livreur supprimé]',
        'email': anonymizedEmail,
        'phoneNumber': '[Supprimé]',
        'address': '[Supprimé]',
        'profileImageUrl': null,
        'vehicleType': '[Supprimé]',
        'plateNumber': '[Supprimé]',
        'agency': null,
        // Garder les statistiques pour l'historique
        // rating, totalDeliveries, completedDeliveries restent
      });

      // 3. Supprimer le compte Firebase Auth (l'utilisateur ne peut plus se connecter)
      await user.delete();

      // 4. Déconnecter et rediriger
      if (mounted) {
        final authProvider = Provider.of<AuthProviderSimple>(context, listen: false);
        await authProvider.signOut();

        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Votre compte livreur a été supprimé avec succès.\n'
              'Vos données ont été anonymisées.',
            ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
