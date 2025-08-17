import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreTest {
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Test de connexion Firestore...');
      
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Test d'écriture simple
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test de connexion',
        'success': true,
      });
      
      debugPrint('✅ Écriture Firestore réussie');
      
      // Test de lecture
      DocumentSnapshot doc = await firestore.collection('test').doc('connection').get();
      
      if (doc.exists) {
        debugPrint('✅ Lecture Firestore réussie');
        debugPrint('📄 Données: ${doc.data()}');
        
        // Nettoyer le test
        await firestore.collection('test').doc('connection').delete();
        debugPrint('🧹 Nettoyage terminé');
        
        return true;
      } else {
        debugPrint('❌ Document non trouvé');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erreur test Firestore: $e');
      return false;
    }
  }
}