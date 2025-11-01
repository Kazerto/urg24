import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Widget réutilisable pour l'upload d'images
///
/// Permet de sélectionner une image depuis la caméra ou la galerie
/// et affiche un aperçu de l'image sélectionnée
class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String? currentImageUrl;
  final Function(XFile file, Uint8List? webImage) onImageSelected;
  final double height;
  final double width;
  final bool showCamera;
  final bool showGallery;

  const ImageUploadWidget({
    super.key,
    required this.title,
    this.currentImageUrl,
    required this.onImageSelected,
    this.height = 200,
    this.width = double.infinity,
    this.showCamera = true,
    this.showGallery = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  XFile? _selectedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _buildImagePreview(),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    // Si une nouvelle image est sélectionnée
    if (_selectedImage != null || _webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: kIsWeb && _webImage != null
            ? Image.memory(_webImage!, fit: BoxFit.cover)
            : !kIsWeb && _selectedImage != null
                ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                : Container(),
      );
    }

    // Si une image existe déjà (URL)
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Image.network(
          widget.currentImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, size: 48, color: Colors.red),
            );
          },
        ),
      );
    }

    // Aucune image
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image,
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
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.showCamera)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                'Caméra',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
              ),
            ),
          ),
        if (widget.showCamera && widget.showGallery)
          const SizedBox(width: AppDimensions.paddingMedium),
        if (widget.showGallery)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text(
                'Galerie',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
              ),
            ),
          ),
        if (_selectedImage != null || _webImage != null) ...[
          const SizedBox(width: AppDimensions.paddingMedium),
          IconButton(
            onPressed: _isLoading ? null : _clearImage,
            icon: const Icon(Icons.clear, color: Colors.red),
            tooltip: 'Supprimer',
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Pour le web, lire les bytes
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }

        // Notifier le parent
        widget.onImageSelected(image, _webImage);
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
    });
  }
}
