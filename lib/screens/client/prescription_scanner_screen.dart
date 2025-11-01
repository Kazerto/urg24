import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_service.dart';

class PrescriptionScannerScreen extends StatefulWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  State<PrescriptionScannerScreen> createState() => _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState extends State<PrescriptionScannerScreen> {
  XFile? _image;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _uploadedUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner ordonnance'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_image != null || _webImage != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _processImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionSection(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildImageSection(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildActionButtons(),
            if (_isLoading) _buildLoadingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Pour une meilleure qualité de scan :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildInstructionItem('📷', 'Assurez-vous d\'avoir un bon éclairage'),
            _buildInstructionItem('📄', 'Placez l\'ordonnance sur une surface plane'),
            _buildInstructionItem('🎯', 'Cadrez correctement le document'),
            _buildInstructionItem('✨', 'Évitez les reflets et les ombres'),
            _buildInstructionItem('🔍', 'Vérifiez que le texte est lisible'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Container(
        width: double.infinity,
        height: 300,
        child: (_image != null || _webImage != null)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                child: kIsWeb && _webImage != null
                    ? Image.memory(
                        _webImage!,
                        fit: BoxFit.cover,
                      )
                    : !kIsWeb && _image != null
                        ? Image.file(
                            File(_image!.path),
                            fit: BoxFit.cover,
                          )
                        : Container(),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    Text(
                      'Aucune image sélectionnée',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      'Utilisez les boutons ci-dessous pour ajouter une photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Prendre une photo',
                  style: TextStyle(color: Colors.white),
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
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text(
                  'Choisir depuis la galerie',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_image != null || _webImage != null) ...[
          const SizedBox(height: AppDimensions.paddingMedium),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearImage,
                  icon: const Icon(Icons.clear),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _processImage,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Envoyer',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Card(
      margin: const EdgeInsets.only(top: AppDimensions.paddingLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Envoi de l\'ordonnance en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            if (_uploadProgress > 0)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Veuillez patienter pendant que nous téléchargeons votre document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1600,
      );

      if (image != null) {
        setState(() {
          _image = image;
        });

        // Pour le web, nous devons lire les bytes
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }
      }
    } catch (e) {
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

  void _clearImage() {
    setState(() {
      _image = null;
      _webImage = null;
      _uploadedUrl = null;
      _uploadProgress = 0.0;
    });
  }

  Future<void> _processImage() async {
    if (_image == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une image d\'abord'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier que l'utilisateur est connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour envoyer une ordonnance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload vers Cloudinary
      final url = await _cloudinaryService.uploadPrescription(
        file: _image!,
        userId: user.uid,
        webImage: _webImage,
      );

      setState(() {
        _uploadedUrl = url;
        _uploadProgress = 1.0;
      });

      debugPrint('✅ Ordonnance uploadée avec succès sur Cloudinary: $url');

      // Sauvegarder l'ordonnance dans Firestore
      await FirebaseFirestore.instance.collection('prescriptions').add({
        'userId': user.uid,
        'imageUrl': url,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'uploaded', // uploaded, used_in_order
        'usedInOrderId': null,
      });

      debugPrint('✅ Ordonnance sauvegardée dans Firestore');

      if (mounted) {
        _showUploadResult();
      }
    } catch (e) {
      debugPrint('❌ Erreur upload ordonnance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUploadResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordonnance envoyée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text('Votre ordonnance a été envoyée avec succès !'),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prochaines étapes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text('• Une pharmacie partenaire va analyser votre ordonnance'),
                  Text('• Vous recevrez une notification sous 30 minutes'),
                  Text('• Les médicaments disponibles vous seront proposés'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearImage();
            },
            child: const Text('Envoyer une autre'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour au dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text(
              'Retour au tableau de bord',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}