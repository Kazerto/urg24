# 🔥 Configuration Firebase Storage - Guide Complet

Ce guide vous explique **étape par étape** ce que vous devez faire sur la Firebase Console pour activer Firebase Storage.

---

## 📋 **ÉTAPES À SUIVRE SUR FIREBASE CONSOLE**

### **ÉTAPE 1 : Accéder à votre projet Firebase**

1. Ouvrez votre navigateur
2. Allez sur : **https://console.firebase.google.com**
3. Connectez-vous avec votre compte Google
4. Cliquez sur votre projet : **`urgence24-1f259`**

---

### **ÉTAPE 2 : Activer Firebase Storage**

1. Dans le menu de gauche, cliquez sur **"Storage"** (icône de dossier)
2. Cliquez sur le bouton **"Get started"** ou **"Commencer"**
3. Une fenêtre popup apparaît avec 2 étapes :

#### **Étape 2a : Règles de sécurité initiales**
- Laissez l'option par défaut sélectionnée :
  ```
  Start in production mode
  ```
- Cliquez sur **"Next"** ou **"Suivant"**

#### **Étape 2b : Localisation du bucket**
- Sélectionnez la région : **`europe-west1 (Belgium)`** (même région que votre Firestore)
- Cliquez sur **"Done"** ou **"Terminé"**

**⏱️ Attendez 30 secondes** que Firebase crée votre bucket de stockage.

---

### **ÉTAPE 3 : Configurer les règles de sécurité**

Une fois Firebase Storage activé, vous verrez l'interface principale.

1. Cliquez sur l'onglet **"Rules"** (Règles) en haut
2. Vous verrez l'éditeur de règles avec un code par défaut
3. **SUPPRIMEZ TOUT** le contenu actuel
4. **COPIEZ-COLLEZ** le contenu du fichier `storage.rules` que j'ai créé pour vous

Le contenu à copier se trouve dans le fichier :
```
Z:\Etude\IAI\De_chez_moi_2025\programmation_mobile\urg24\storage.rules
```

5. Cliquez sur **"Publish"** ou **"Publier"** pour sauvegarder

✅ **Vos règles de sécurité sont maintenant actives !**

---

### **ÉTAPE 4 : Vérifier la configuration**

1. Cliquez sur l'onglet **"Files"** (Fichiers) en haut
2. Vous devriez voir un bucket vide (c'est normal, aucune image n'a encore été uploadée)
3. Le nom de votre bucket devrait être :
   ```
   urgence24-1f259.appspot.com
   ```

---

## 🔐 **ÉTAPE BONUS : Configuration des Custom Claims (Optionnel pour tests)**

Les règles de sécurité utilisent des "custom claims" pour identifier les admins et pharmacies. Pour les tests initiaux, **vous pouvez IGNORER cette étape** car les règles de base fonctionneront.

Si vous voulez activer la sécurité avancée plus tard :

1. Allez dans **"Authentication"** > **"Users"**
2. Utilisez Firebase Admin SDK pour ajouter des custom claims
3. Ou modifiez les règles `storage.rules` pour simplifier (je peux vous aider)

---

## ✅ **VÉRIFICATION FINALE - CHECKLIST**

Cochez ces points pour confirmer que tout est OK :

- [ ] Firebase Storage est activé dans votre projet
- [ ] La région est `europe-west1`
- [ ] Les règles de sécurité du fichier `storage.rules` sont publiées
- [ ] Vous voyez le bucket `urgence24-1f259.appspot.com` dans l'onglet Files

---

## 🧪 **TESTER L'UPLOAD**

Une fois la configuration terminée :

1. Lancez votre application Flutter
2. Connectez-vous comme client
3. Allez dans **"Scanner ordonnance"**
4. Prenez une photo ou sélectionnez une image
5. Cliquez sur **"Envoyer"**

**Si tout fonctionne :**
- ✅ Vous verrez "Ordonnance envoyée avec succès"
- ✅ Dans Firebase Console > Storage > Files, vous verrez un dossier `prescriptions/`
- ✅ L'image apparaîtra avec son URL

**Si ça ne fonctionne pas :**
- ❌ Vérifiez que Firebase Storage est bien activé
- ❌ Vérifiez que les règles sont bien publiées
- ❌ Regardez les logs Flutter pour voir l'erreur exacte

---

## 📊 **MONITORING ET USAGE**

### **Voir les statistiques d'utilisation**

1. Dans Firebase Console > Storage
2. Cliquez sur l'onglet **"Usage"**
3. Vous verrez :
   - **Stockage total utilisé** (max 5 GB gratuit)
   - **Nombre de téléchargements**
   - **Bande passante utilisée** (max ~30 GB/mois gratuit)

### **Voir les fichiers uploadés**

1. Cliquez sur l'onglet **"Files"**
2. Naviguez dans les dossiers :
   - `prescriptions/` - Ordonnances des clients
   - `profiles/` - Photos de profil
   - `medicaments/` - Photos de médicaments
   - `pharmacies/` - Photos de pharmacies

### **Supprimer des fichiers manuellement**

1. Allez dans l'onglet **"Files"**
2. Naviguez jusqu'au fichier
3. Cliquez sur les 3 points à droite du fichier
4. Cliquez sur **"Delete"**

---

## 🚨 **RÈGLES DE SÉCURITÉ EXPLIQUÉES**

Les règles que j'ai créées protègent vos données :

| Dossier | Qui peut LIRE | Qui peut ÉCRIRE | Qui peut SUPPRIMER |
|---------|---------------|-----------------|-------------------|
| `prescriptions/{userId}/` | Propriétaire + Pharmacies + Admin | Propriétaire uniquement | Propriétaire + Admin |
| `profiles/client/{userId}` | Tous (authentifiés) | Propriétaire uniquement | Propriétaire + Admin |
| `profiles/delivery_person/{userId}` | Tous (authentifiés) | Propriétaire uniquement | Propriétaire + Admin |
| `profiles/pharmacy/{pharmacyId}` | Tous (authentifiés) | Propriétaire uniquement | Propriétaire + Admin |
| `medicaments/{pharmacyId}/` | Tous (authentifiés) | Pharmacie propriétaire | Pharmacie + Admin |
| `pharmacies/{pharmacyId}/` | **TOUS** (lecture publique) | Pharmacie propriétaire | Pharmacie + Admin |

**Contraintes sur toutes les images :**
- ✅ Fichier doit être une image (`image/*`)
- ✅ Taille maximum : 10 MB
- ✅ Utilisateur doit être authentifié

---

## 💰 **LIMITES DU PLAN GRATUIT**

Voici ce que vous avez gratuitement avec Firebase Storage :

| Ressource | Limite Gratuite | Dépassement |
|-----------|----------------|-------------|
| Stockage total | **5 GB** | $0.026/GB/mois |
| Téléchargements | **1 GB/jour** (~30 GB/mois) | $0.12/GB |
| Uploads | **20,000/jour** | Gratuit |

**Estimation pour vos tests :**
- 1000 images de 2 MB = 2 GB de stockage ✅ OK
- 100 consultations/jour de 2 MB = 200 MB/jour ✅ OK

---

## 🆘 **DÉPANNAGE**

### **Erreur : "Firebase Storage: User does not have permission to access"**

**Solution :**
1. Vérifiez que les règles `storage.rules` sont bien publiées
2. Vérifiez que l'utilisateur est bien connecté (Firebase Auth)
3. Dans les règles, changez temporairement pour tester :
   ```javascript
   allow read, write: if request.auth != null; // Autorise tous les utilisateurs authentifiés
   ```

### **Erreur : "Firebase Storage has not been configured"**

**Solution :**
1. Vérifiez que Firebase Storage est activé dans la console
2. Attendez 2-3 minutes et réessayez
3. Redémarrez votre application Flutter

### **Erreur : "File too large"**

**Solution :**
- Les images sont limitées à 10 MB par les règles de sécurité
- Réduisez la qualité de l'image dans le code (déjà fait : `imageQuality: 80`)

---

## 📞 **BESOIN D'AIDE ?**

Si vous rencontrez des problèmes :

1. **Vérifiez les logs Flutter** : L'erreur exacte sera affichée
2. **Vérifiez Firebase Console** : Allez dans Storage > Usage pour voir les erreurs
3. **Testez avec des règles permissives** (voir Dépannage ci-dessus)
4. **Contactez-moi** avec le message d'erreur exact

---

## ✅ **RÉCAPITULATIF RAPIDE**

1. ✅ Allez sur https://console.firebase.google.com
2. ✅ Sélectionnez le projet `urgence24-1f259`
3. ✅ Cliquez sur **Storage** > **Get started**
4. ✅ Production mode > europe-west1 > Done
5. ✅ Onglet **Rules** > Coller le contenu de `storage.rules` > Publish
6. ✅ Testez l'upload d'ordonnance dans votre app

**Temps estimé : 5 minutes** ⏱️

---

**Bonne configuration ! 🚀**
