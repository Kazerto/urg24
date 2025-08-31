import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Créer un utilisateur
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      // Collection principale des utilisateurs
      await _db.collection('users').doc(uid).set(userData);

      // Collection spécifique selon le type d'utilisateur
      String userType = userData['userType'];
      switch (userType) {
        case UserTypes.client:
          await _db.collection('clients').doc(uid).set({
            'uid': uid,
            'fullName': userData['fullName'],
            'email': userData['email'],
            'phoneNumber': userData['phoneNumber'],
            'createdAt': userData['createdAt'],
            'isVerified': userData['isVerified'] ?? false,
            'status': userData['status'] ?? 'pending_verification',
          });
          break;

        case UserTypes.deliveryPerson:
          await _db.collection('delivery_persons').doc(uid).set({
            'uid': uid,
            'fullName': userData['fullName'],
            'email': userData['email'],
            'phoneNumber': userData['phoneNumber'],
            'address': userData['address'],
            'agency': userData['agency'],
            'vehicleType': userData['vehicleType'],
            'plateNumber': userData['plateNumber'],
            'createdAt': userData['createdAt'],
            'isVerified': userData['isVerified'] ?? false,
            'isApproved': userData['isApproved'] ?? false,
            'status': userData['status'] ?? 'pending_verification',
            'rating': 0.0,
            'totalDeliveries': 0,
          });
          break;
      }
    } catch (e) {
      throw 'Erreur lors de la création de l\'utilisateur: $e';
    }
  }

  // Créer une demande de pharmacie
  Future<void> createPharmacyRequest(String id, Map<String, dynamic> pharmacyData) async {
    try {
      await _db.collection('pharmacy_requests').doc(id).set({
        'id': id,
        'pharmacyName': pharmacyData['pharmacyName'],
        'email': pharmacyData['email'],
        'phoneNumber': pharmacyData['phoneNumber'],
        'address': pharmacyData['address'],
        'licenseNumber': pharmacyData['licenseNumber'],
        'openingHours': pharmacyData['openingHours'],
        'status': pharmacyData['status'] ?? 'pending_admin_approval',
        'createdAt': pharmacyData['createdAt'],
        'isApproved': false,
      });
    } catch (e) {
      throw 'Erreur lors de la création de la demande de pharmacie: $e';
    }
  }

  // Récupérer les données d'un utilisateur
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        var data = doc.data();
        if (data != null) {
          return Map<String, dynamic>.from(data as Map);
        }
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération des données: $e';
    }
  }

  // Mettre à jour le statut de vérification
  Future<void> updateUserVerificationStatus(String email) async {
    try {
      // Trouver l'utilisateur par email
      QuerySnapshot userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String uid = userQuery.docs.first.id;
        Map<String, dynamic> userData = Map<String, dynamic>.from(userQuery.docs.first.data() as Map);
        String userType = userData['userType'];

        // Mettre à jour le statut principal
        Map<String, dynamic> updateData = {
          'isVerified': true,
          'verifiedAt': DateTime.now(),
        };

        if (userType == UserTypes.client) {
          updateData['status'] = 'active';
        } else if (userType == UserTypes.deliveryPerson) {
          updateData['status'] = 'pending_approval';
        }

        await _db.collection('users').doc(uid).update(updateData);

        // Mettre à jour la collection spécifique
        switch (userType) {
          case UserTypes.client:
            await _db.collection('clients').doc(uid).update(updateData);
            break;
          case UserTypes.deliveryPerson:
            await _db.collection('delivery_persons').doc(uid).update(updateData);
            break;
        }
      }
    } catch (e) {
      throw 'Erreur lors de la mise à jour du statut: $e';
    }
  }

  // Approuver un livreur (pour l'admin)
  Future<void> approveDeliveryPerson(String uid) async {
    try {
      debugPrint('🔍 Début approbation livreur UID: $uid');
      
      Map<String, dynamic> updateData = {
        'isApproved': true,
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour le document principal dans users
      await _db.collection('users').doc(uid).update(updateData);
      debugPrint('✅ Document users mis à jour');

      // Trouver et mettre à jour le document correspondant dans delivery_persons
      QuerySnapshot deliveryPersonDocs = await _db
          .collection('delivery_persons')
          .where('firebaseUid', isEqualTo: uid)
          .limit(1)
          .get();
          
      if (deliveryPersonDocs.docs.isNotEmpty) {
        await deliveryPersonDocs.docs.first.reference.update(updateData);
        debugPrint('✅ Document delivery_persons mis à jour');
      } else {
        debugPrint('⚠️ Aucun document delivery_persons trouvé pour UID: $uid');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur approbation livreur: $e');
      throw 'Erreur lors de l\'approbation: $e';
    }
  }

  // Approuver une pharmacie et créer le compte (pour l'admin)
  Future<void> approvePharmacy(String requestId, String email, String password) async {
    try {
      // Récupérer les données de la demande
      DocumentSnapshot requestDoc = await _db.collection('pharmacy_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw 'Demande non trouvée';
      }

      Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

      // Chercher le compte Firebase Auth existant dans la collection users
      debugPrint('🔍 Recherche du compte existant pour: $email');
      
      QuerySnapshot existingUsers = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .where('userType', isEqualTo: 'pharmacy_request')
          .limit(1)
          .get();
      
      String uid;
      if (existingUsers.docs.isNotEmpty) {
        // Utiliser l'UID existant et mettre à jour le mot de passe
        uid = existingUsers.docs.first.id;
        debugPrint('✅ Compte existant trouvé, UID: $uid');
        
        // Récupérer le mot de passe temporaire utilisé lors de l'inscription
        String tempPassword = 'temp_pharmacy_${email.hashCode}';
        
        // Se connecter avec le mot de passe temporaire pour le changer
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
          // Changer le mot de passe
          await FirebaseAuth.instance.currentUser?.updatePassword(password);
          debugPrint('✅ Mot de passe mis à jour avec succès');
          // Se déconnecter pour ne pas affecter la session admin
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la mise à jour du mot de passe: $e');
          // Continuer avec l'UID existant même si la mise à jour échoue
        }
      } else {
        debugPrint('⚠️ Aucun compte temporaire trouvé, création d\'un nouveau compte');
        // Fallback: créer un nouveau compte si aucun temporaire n'existe
        try {
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          uid = userCredential.user!.uid;
          debugPrint('✅ Nouveau compte créé avec UID: $uid');
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            // Le compte existe mais pas dans notre collection users
            // Il faut le retrouver d'une autre façon
            throw 'Email déjà utilisé. Veuillez supprimer le compte existant d\'abord.';
          }
          throw e;
        }
      }

      // Créer les données utilisateur de la pharmacie
      Map<String, dynamic> pharmacyUserData = {
        'uid': uid,
        'email': email,
        'pharmacyName': requestData['pharmacyName'],
        'phoneNumber': requestData['phoneNumber'],
        'address': requestData['address'],
        'licenseNumber': requestData['licenseNumber'],
        'openingHours': requestData['openingHours'],
        'userType': UserTypes.pharmacy,
        'isVerified': true,
        'isApproved': true,
        'status': 'active',
        'createdAt': requestData['createdAt'],
        'approvedAt': FieldValue.serverTimestamp(),
      };

      // Créer les données spécifiques de la pharmacie pour l'interface
      Map<String, dynamic> pharmacyData = {
        'uid': uid,
        'pharmacyName': requestData['pharmacyName'],
        'email': email,
        'phoneNumber': requestData['phoneNumber'],
        'address': requestData['address'],
        'licenseNumber': requestData['licenseNumber'],
        'openingHours': requestData['openingHours'],
        'isActive': true,
        'rating': 0.0,
        'totalOrders': 0,
        'createdAt': requestData['createdAt'],
        'approvedAt': FieldValue.serverTimestamp(),
      };

      // Sauvegarder dans les collections avec le vrai UID Firebase
      await _db.collection('users').doc(uid).set(pharmacyUserData);
      await _db.collection('pharmacies').doc(uid).set(pharmacyData);

      // Supprimer la demande des demandes en attente
      await _db.collection('pharmacy_requests').doc(requestId).delete();

      debugPrint('✅ Pharmacie ${requestData['pharmacyName']} approuvée avec succès');
      debugPrint('📧 Email: $email');
      debugPrint('🔑 Mot de passe temporaire: $password');

    } catch (e) {
      debugPrint('❌ Erreur lors de l\'approbation: $e');
      throw 'Erreur lors de l\'approbation de la pharmacie: $e';
    }
  }

  // Récupérer toutes les demandes de pharmacies en attente
  Stream<List<Map<String, dynamic>>> getPendingPharmacyRequests() {
    return _db
        .collection('pharmacy_requests')
        .where('status', isEqualTo: 'pending_admin_approval')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          
          // Trier côté client pour éviter l'index composé
          docs.sort((a, b) {
            final aCreated = a['createdAt'];
            final bCreated = b['createdAt'];
            if (aCreated == null || bCreated == null) return 0;
            // Gérer les différents types de Timestamp
            DateTime? dateA, dateB;
            if (aCreated is Timestamp) {
              dateA = aCreated.toDate();
            } else if (aCreated is DateTime) {
              dateA = aCreated;
            }
            if (bCreated is Timestamp) {
              dateB = bCreated.toDate();
            } else if (bCreated is DateTime) {
              dateB = bCreated;
            }
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA); // Plus récent en premier
          });
          
          return docs;
        });
  }

  // Récupérer tous les livreurs en attente d'approbation
  Stream<List<Map<String, dynamic>>> getPendingDeliveryPersons() {
    return _db
        .collection('users')
        .where('userType', isEqualTo: 'delivery_person')
        .where('status', isEqualTo: 'pending_approval')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'uid': doc.id, ...doc.data()})
              .toList();
          
          // Trier côté client pour éviter l'index composé
          docs.sort((a, b) {
            final aCreated = a['createdAt'];
            final bCreated = b['createdAt'];
            if (aCreated == null || bCreated == null) return 0;
            // Gérer les différents types de Timestamp
            DateTime? dateA, dateB;
            if (aCreated is Timestamp) {
              dateA = aCreated.toDate();
            } else if (aCreated is DateTime) {
              dateA = aCreated;
            }
            if (bCreated is Timestamp) {
              dateB = bCreated.toDate();
            } else if (bCreated is DateTime) {
              dateB = bCreated;
            }
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA); // Plus récent en premier
          });
          
          return docs;
        });
  }

  // Récupérer les pharmacies actives
  Stream<List<Map<String, dynamic>>> getActivePharmacies() {
    return _db
        .collection('pharmacies')
        .where('isActive', isEqualTo: true)
        .orderBy('pharmacyName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // Récupérer les livreurs actifs
  Stream<List<Map<String, dynamic>>> getActiveDeliveryPersons() {
    return _db
        .collection('delivery_persons')
        .where('status', isEqualTo: 'active')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList());
  }

  // Récupérer une pharmacie par email
  Future<Map<String, dynamic>?> getPharmacyByEmail(String email) async {
    try {
      final querySnapshot = await _db
          .collection('pharmacies')
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {'id': doc.id, ...doc.data()};
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la pharmacie: $e');
      rethrow;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updateData) async {
    try {
      await _db.collection('users').doc(uid).update(updateData);

      // Mettre à jour aussi dans la collection spécifique si nécessaire
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userType = userData['userType'];

        switch (userType) {
          case UserTypes.client:
            await _db.collection('clients').doc(uid).update(updateData);
            break;
          case UserTypes.deliveryPerson:
            await _db.collection('delivery_persons').doc(uid).update(updateData);
            break;
          case UserTypes.pharmacy:
            await _db.collection('pharmacies').doc(uid).update(updateData);
            break;
        }
      }
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    try {
      // Récupérer le type d'utilisateur
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userType = userData['userType'];

        // Supprimer de la collection spécifique
        switch (userType) {
          case UserTypes.client:
            await _db.collection('clients').doc(uid).delete();
            break;
          case UserTypes.deliveryPerson:
            await _db.collection('delivery_persons').doc(uid).delete();
            break;
          case UserTypes.pharmacy:
            await _db.collection('pharmacies').doc(uid).delete();
            break;
        }
      }

      // Supprimer de la collection principale
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression: $e';
    }
  }

  // Rechercher des utilisateurs
  Future<List<Map<String, dynamic>>> searchUsers(String query, String userType) async {
    try {
      String collection;
      String searchField;

      switch (userType) {
        case UserTypes.pharmacy:
          collection = 'pharmacies';
          searchField = 'pharmacyName';
          break;
        case UserTypes.client:
          collection = 'clients';
          searchField = 'fullName';
          break;
        case UserTypes.deliveryPerson:
          collection = 'delivery_persons';
          searchField = 'fullName';
          break;
        default:
          collection = 'users';
          searchField = 'email';
      }

      QuerySnapshot snapshot = await _db
          .collection(collection)
          .where(searchField, isGreaterThanOrEqualTo: query)
          .where(searchField, isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw 'Erreur lors de la recherche: $e';
    }
  }

  // Supprimer une demande de pharmacie
  Future<void> deletePharmacyRequest(String requestId) async {
    try {
      await _db.collection('pharmacy_requests').doc(requestId).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression de la demande: $e';
    }
  }

  // Initialiser la collection pharmacy_requests si elle n'existe pas
  Future<void> initializePharmacyRequestsCollection() async {
    try {
      // Vérifier si la collection existe
      QuerySnapshot snapshot = await _db.collection('pharmacy_requests').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // La collection n'existe pas, la créer avec un document temporaire
        debugPrint('📋 Création de la collection pharmacy_requests...');
        
        DocumentReference tempDoc = await _db.collection('pharmacy_requests').add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'temp_document',
          'note': 'Document temporaire pour initialiser la collection'
        });
        
        // Supprimer immédiatement le document temporaire
        await tempDoc.delete();
        
        debugPrint('✅ Collection pharmacy_requests initialisée');
      } else {
        debugPrint('✅ Collection pharmacy_requests existe déjà');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de pharmacy_requests: $e');
    }
  }

  // Créer l'administrateur par défaut
  Future<void> createDefaultAdmin() async {
    try {
      String adminEmail = 'admin@urgence24.com';
      
      // UID Firebase Auth connu pour l'admin (obtenu après connexion)
      String adminUID = 'fikLaXOxz2cke4Qs9qBJB8vynuC3'; // UID de Firebase Auth
      
      // Forcer la recréation avec le bon UID
      await _forceCreateAdmin(adminEmail, adminUID);
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'admin: $e');
    }
  }

  // Forcer la création/mise à jour de l'admin avec le bon UID
  Future<void> _forceCreateAdmin(String adminEmail, String adminUID) async {
    try {
      // Nettoyer d'abord tous les anciens admins avec le mauvais UID
      QuerySnapshot oldAdmins = await _db
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .get();

      // Supprimer les anciens documents admin
      for (DocumentSnapshot doc in oldAdmins.docs) {
        if (doc.id != adminUID) {
          await doc.reference.delete();
          debugPrint('🧹 Ancien admin supprimé: ${doc.id}');
        }
      }

      // Créer/mettre à jour l'admin avec le bon UID
      Map<String, dynamic> adminData = {
        'uid': adminUID,
        'email': adminEmail,
        'userType': UserTypes.admin,
        'name': 'Administrateur',
        'fullName': 'Administrateur Système',
        'isVerified': true,
        'isApproved': true,
        'status': 'active',
        'createdAt': DateTime.now(),
      };

      // Utiliser l'UID Firebase Auth comme ID du document
      await _db.collection('users').doc(adminUID).set(adminData, SetOptions(merge: true));
      
      debugPrint('✅ Admin créé/mis à jour avec UID: $adminUID');
      debugPrint('📧 Email: $adminEmail | 🔑 Mot de passe: admin123');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la création forcée de l\'admin: $e');
    }
  }
}