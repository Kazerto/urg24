# ☁️ Configuration Cloudinary - Guide Ultra Simple (3 étapes)

Cloudinary est **BEAUCOUP plus simple** que Firebase Storage. Pas de problème de région, pas de bucket à créer. Juste 3 étapes ! 🚀

---

## 📋 **ÉTAPE 1 : Créer un compte Cloudinary (2 minutes)**

### 1. Ouvrez votre navigateur
Allez sur : **https://cloudinary.com/users/register_free**

### 2. Remplissez le formulaire d'inscription
- **Email** : Votre email
- **Password** : Choisissez un mot de passe
- **Cloud name** : Choisissez un nom unique (exemple: `urgence24`, `urgence24app`, etc.)
  - ⚠️ **IMPORTANT** : Notez bien ce nom, vous en aurez besoin !

### 3. Validez votre email
- Vérifiez votre boîte mail
- Cliquez sur le lien de confirmation

### 4. Connectez-vous
Une fois votre email validé, connectez-vous à : **https://console.cloudinary.com**

✅ **Compte créé ! Passez à l'étape 2**

---

## 🔑 **ÉTAPE 2 : Récupérer vos clés d'API (1 minute)**

Une fois connecté au dashboard Cloudinary :

### 1. Vous êtes sur la page "Dashboard"
Vous devriez voir :
- **Product Environment Credentials**
- **Cloud name** : `votre_cloud_name`
- **API Key** : `123456789012345`
- **API Secret** : `xxxxxxxxxxxxx`

### 2. Créer un "Upload Preset" (présélection d'upload)

**Option A : Via l'interface (Recommandé)**
1. Cliquez sur l'icône **⚙️ Settings** (roue crantée en haut à droite)
2. Dans le menu de gauche, cliquez sur **"Upload"**
3. Scrollez jusqu'à **"Upload presets"**
4. Cliquez sur **"Add upload preset"**
5. Configurez :
   - **Upload preset name** : `urgence24_preset` (ou autre nom de votre choix)
   - **Signing Mode** : **Unsigned** ✅ (très important !)
   - **Folder** : Laissez vide (sera géré par le code)
   - **Access mode** : Public (par défaut)
6. Cliquez sur **"Save"**

**Option B : Utiliser le preset par défaut**
- Cloudinary crée automatiquement un preset "unsigned" nommé : `ml_default`
- Vous pouvez utiliser celui-ci directement !

### 3. Notez vos informations

Vous aurez besoin de :
- ✅ **Cloud name** : `votre_cloud_name` (exemple: `urgence24`)
- ✅ **Upload preset** : `urgence24_preset` ou `ml_default`

📝 **Gardez ces 2 informations, vous allez les copier dans le code !**

---

## 💻 **ÉTAPE 3 : Configurer le code Flutter (1 minute)**

### 1. Ouvrez le fichier du service Cloudinary

Allez dans :
```
lib/services/cloudinary_service.dart
```

### 2. Remplacez les valeurs aux lignes 12-13

**AVANT (actuellement) :**
```dart
static const String _cloudName = 'VOTRE_CLOUD_NAME'; // À REMPLACER
static const String _uploadPreset = 'VOTRE_UPLOAD_PRESET'; // À REMPLACER
```

**APRÈS (avec vos vraies valeurs) :**
```dart
static const String _cloudName = 'urgence24'; // Votre Cloud name
static const String _uploadPreset = 'urgence24_preset'; // Votre Upload preset
```

### 3. Sauvegardez le fichier

**C'est tout ! ✅**

---

## 🧪 **TESTER L'UPLOAD**

### 1. Installez les packages
```bash
flutter pub get
```

### 2. Lancez l'application
```bash
flutter run
```

### 3. Testez l'upload d'ordonnance
1. Connectez-vous comme client
2. Allez dans **"Scanner ordonnance"**
3. Prenez une photo ou sélectionnez une image
4. Cliquez sur **"Envoyer"**

**Si tout fonctionne :**
- ✅ Vous verrez "Ordonnance envoyée avec succès"
- ✅ L'image sera uploadée sur Cloudinary
- ✅ Dans Cloudinary Dashboard > Media Library, vous verrez l'image dans `urgence24/prescriptions/`

**Si ça ne fonctionne pas :**
- ❌ Vérifiez que vous avez bien remplacé `_cloudName` et `_uploadPreset`
- ❌ Vérifiez que le preset est en mode **"Unsigned"**
- ❌ Regardez les logs Flutter pour voir l'erreur exacte

---

## 📂 **VOIR VOS IMAGES UPLOADÉES**

### Dans le Dashboard Cloudinary

1. Allez sur : **https://console.cloudinary.com**
2. Cliquez sur **"Media Library"** (dans le menu de gauche)
3. Vous verrez vos dossiers :
   - `urgence24/prescriptions/` - Ordonnances
   - `urgence24/profiles/` - Photos de profil
   - `urgence24/medicaments/` - Photos de médicaments
   - `urgence24/pharmacies/` - Photos de pharmacies

### Supprimer une image

1. Cliquez sur l'image
2. Cliquez sur l'icône **🗑️ Poubelle**
3. Confirmez la suppression

---

## 💰 **PLAN GRATUIT - CE QUE VOUS AVEZ**

| Ressource | Gratuit | Équivalent |
|-----------|---------|------------|
| **Stockage** | 25 GB | ~12,500 images de 2 MB |
| **Bande passante** | 25 GB/mois | ~12,500 téléchargements |
| **Transformations** | 25,000 credits/mois | Resize, crop, etc. |
| **Vidéos** | 1 GB stockage | Si besoin plus tard |

**C'est LARGEMENT suffisant pour vos tests et même pour démarrer en production ! 🎉**

---

## 🎨 **BONUS : Transformations d'images**

Cloudinary permet de transformer les images via l'URL. Exemples :

### Créer un thumbnail 300x300
```dart
final cloudinaryService = CloudinaryService();
String originalUrl = 'https://res.cloudinary.com/.../image.jpg';

String thumbnail = cloudinaryService.getTransformedUrl(
  originalUrl,
  width: 300,
  height: 300,
  crop: 'fill',
);
// Result: https://res.cloudinary.com/.../w_300,h_300,c_fill/image.jpg
```

### Optimiser la qualité
```dart
String optimized = cloudinaryService.getTransformedUrl(
  originalUrl,
  quality: 'auto',
);
// Cloudinary choisit automatiquement la meilleure qualité
```

### Convertir en WebP (format moderne)
L'URL peut être modifiée pour changer le format :
```dart
String webpUrl = originalUrl.replaceAll('.jpg', '.webp');
// Cloudinary convertit automatiquement !
```

---

## 🔒 **SÉCURITÉ**

### Upload Preset "Unsigned" - C'est sécurisé ?

✅ **OUI**, car :
- Vous contrôlez QUI peut uploader via Firebase Auth
- Les uploads se font uniquement depuis votre app
- Cloudinary limite le nombre d'uploads/mois
- Vous pouvez activer des restrictions (taille max, formats autorisés, etc.)

### Pour plus de sécurité plus tard

Vous pouvez :
1. Passer en mode **"Signed"** (nécessite un backend)
2. Ajouter des **Upload restrictions** dans Settings > Upload
3. Activer **Moderation** (détection contenu inapproprié)

Mais pour vos tests, **Unsigned est parfait** !

---

## 📊 **MONITORING**

### Voir l'utilisation de votre quota

1. Allez sur **https://console.cloudinary.com**
2. Sur le Dashboard, vous verrez :
   - **Storage used** : Espace utilisé / 25 GB
   - **Bandwidth used** : Bande passante utilisée ce mois
   - **Transformations** : Credits utilisés / 25,000

### Alertes

Cloudinary vous enverra un email si vous approchez des limites.

---

## 🆘 **DÉPANNAGE**

### Erreur : "Cloudinary n'est pas configuré"

**Solution :**
- Ouvrez `lib/services/cloudinary_service.dart`
- Vérifiez que vous avez bien remplacé `VOTRE_CLOUD_NAME` et `VOTRE_UPLOAD_PRESET`

### Erreur : "Upload failed: 401 Unauthorized"

**Solution :**
- Vérifiez que le **Upload Preset** existe dans Cloudinary
- Vérifiez qu'il est en mode **"Unsigned"**
- Le nom doit être EXACTEMENT le même (sensible à la casse)

### Erreur : "Upload failed: 400 Bad Request"

**Solution :**
- Vérifiez que le **Cloud Name** est correct
- Pas d'espaces, pas de caractères spéciaux

### Les images n'apparaissent pas dans Media Library

**Solution :**
- Attendez 10-30 secondes, le dashboard Cloudinary peut mettre du temps à rafraîchir
- Cliquez sur le bouton **"Refresh"** (🔄) dans Media Library
- Vérifiez que l'upload a vraiment réussi (regardez les logs Flutter)

---

## ✅ **CHECKLIST FINALE**

- [ ] Compte Cloudinary créé sur https://cloudinary.com
- [ ] Email vérifié et connecté au dashboard
- [ ] **Cloud name** récupéré (exemple: `urgence24`)
- [ ] **Upload preset** créé en mode "Unsigned" (ou utilisé `ml_default`)
- [ ] Valeurs remplacées dans `lib/services/cloudinary_service.dart` (lignes 12-13)
- [ ] `flutter pub get` exécuté
- [ ] Application testée avec upload d'ordonnance
- [ ] Image visible dans Cloudinary Media Library

---

## 📞 **BESOIN D'AIDE ?**

Si vous rencontrez des problèmes :

1. **Vérifiez les logs Flutter** : L'erreur exacte sera affichée
2. **Vérifiez le dashboard Cloudinary** : Media Library > Logs
3. **Contactez-moi** avec :
   - Le message d'erreur exact
   - Votre Cloud name (sans problème de le partager, c'est public)
   - Une capture d'écran du code dans `cloudinary_service.dart`

---

## 🎉 **RÉCAPITULATIF ULTRA-RAPIDE**

**3 étapes, 5 minutes chrono :**

1. ✅ Créer compte sur https://cloudinary.com
2. ✅ Récupérer Cloud Name + créer Upload Preset (unsigned)
3. ✅ Remplacer les valeurs dans `lib/services/cloudinary_service.dart`

```dart
static const String _cloudName = 'urgence24'; // Votre valeur
static const String _uploadPreset = 'urgence24_preset'; // Votre valeur
```

4. ✅ `flutter pub get`
5. ✅ Tester ! 🚀

---

**C'est BEAUCOUP plus simple que Firebase Storage, n'est-ce pas ? 😄**

Bonne configuration !
