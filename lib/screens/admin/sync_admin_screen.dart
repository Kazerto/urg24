import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class SyncAdminScreen extends StatefulWidget {
  const SyncAdminScreen({super.key});

  @override
  State<SyncAdminScreen> createState() => _SyncAdminScreenState();
}

class _SyncAdminScreenState extends State<SyncAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isSynced = false;

  @override
  void initState() {
    super.initState();
    _checkAdminProfile();
  }

  Future<void> _checkAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _isSynced = doc.exists;
      });
    } catch (e) {
      // Ignore errors during check
    }
  }

  Future<void> _syncAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun utilisateur connecté'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer le profil admin dans Firestore
      Map<String, dynamic> adminData = {
        'uid': user.uid,
        'email': user.email,
        'userType': UserTypes.admin,
        'name': 'Administrateur',
        'fullName': 'Administrateur Système',
        'isVerified': true,
        'isApproved': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(adminData);
      
      setState(() {
        _isSynced = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil admin synchronisé avec succès !'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Synchronisation Admin'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: _isSynced 
                    ? AppColors.successColor.withOpacity(0.1)
                    : AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: _isSynced 
                      ? AppColors.successColor
                      : AppColors.warningColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSynced ? Icons.check_circle : Icons.warning,
                      color: _isSynced 
                        ? AppColors.successColor
                        : AppColors.warningColor,
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: Text(
                        _isSynced 
                          ? 'Profil admin synchronisé'
                          : 'Profil admin non synchronisé',
                        style: TextStyle(
                          color: _isSynced 
                            ? AppColors.successColor
                            : AppColors.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // User info
              const Text(
                'Informations utilisateur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('UID Firebase Auth:', user?.uid ?? 'Non connecté'),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _buildInfoRow('Email:', user?.email ?? 'Non connecté'),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _buildInfoRow('Vérifié:', user?.emailVerified.toString() ?? 'false'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLarge),

              // Explanation
              const Text(
                'Pourquoi synchroniser ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              
              const Text(
                'Cette opération crée votre profil administrateur dans la base de données Firestore. '
                'Cela permet à l\'application de vous reconnaître comme administrateur lors de la connexion.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Sync button
              if (!_isSynced)
                CustomButton(
                  text: 'Synchroniser le profil admin',
                  onPressed: _isLoading ? null : _syncAdminProfile,
                  isLoading: _isLoading,
                  color: AppColors.primaryColor,
                ),

              if (_isSynced)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: const Text(
                    '✅ Profil synchronisé ! Vous pouvez maintenant vous connecter normalement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}