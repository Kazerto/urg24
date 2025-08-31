import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class TeleConseilScreen extends StatelessWidget {
  const TeleConseilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléconseil - Aide & Support'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildContactSection(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildFAQSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal,
              Colors.teal.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.headset_mic,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Comment pouvons-nous vous aider ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            const Text(
              'Notre équipe support est là pour vous accompagner dans vos démarches de santé.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contactez notre support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Numéro de téléphone
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.phone,
              color: Colors.green,
              size: 30,
            ),
            title: const Text(
              'Appelez-nous',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('+223 XX XX XX XX'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _makePhoneCall('+223XXXXXXXX'),
          ),
        ),
        
        const SizedBox(height: AppDimensions.paddingSmall),
        
        // Email
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.email,
              color: Colors.blue,
              size: 30,
            ),
            title: const Text(
              'Envoyez-nous un email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('support@urgence24.ml'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _sendEmail('support@urgence24.ml'),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions fréquentes (FAQ)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        _buildFAQItem(
          question: 'Comment passer une commande ?',
          answer: 'Pour passer une commande :\n'
              '1. Sélectionnez une pharmacie partenaire\n'
              '2. Parcourez les médicaments disponibles\n'
              '3. Ajoutez les produits à votre panier\n'
              '4. Vérifiez votre commande et choisissez le mode de paiement\n'
              '5. Confirmez votre commande',
          icon: Icons.shopping_cart,
          color: AppColors.primaryColor,
        ),
        
        _buildFAQItem(
          question: 'Puis-je suivre ma commande ?',
          answer: 'Oui ! Vous pouvez suivre votre commande en temps réel :\n'
              '• Commande reçue par la pharmacie\n'
              '• Préparée par la pharmacie\n'
              '• Prise en charge par le livreur\n'
              '• En cours de livraison\n'
              '• Livrée\n\n'
              'Accédez au suivi via "Mes commandes" sur votre tableau de bord.',
          icon: Icons.track_changes,
          color: Colors.orange,
        ),
        
        _buildFAQItem(
          question: 'Quels sont les modes de paiement acceptés ?',
          answer: 'Nous acceptons plusieurs modes de paiement :\n\n'
              '📱 Mobile Money :\n'
              '  • Airtel Money\n'
              '  • Moov Money\n\n'
              '💳 Carte de crédit :\n'
              '  • Visa\n'
              '  • MasterCard\n\n'
              '💵 Paiement à la livraison :\n'
              '  • Espèces à la réception',
          icon: Icons.payment,
          color: Colors.green,
        ),
        
        _buildFAQItem(
          question: 'Que se passe-t-il si mon ordonnance est rejetée ?',
          answer: 'Si votre ordonnance est rejetée :\n\n'
              '1. Vous recevrez une notification expliquant la raison du rejet\n'
              '2. Les motifs peuvent être :\n'
              '   • Ordonnance illisible\n'
              '   • Ordonnance expirée\n'
              '   • Informations manquantes\n\n'
              '3. Vous pourrez :\n'
              '   • Reprendre une photo plus claire\n'
              '   • Contacter notre support\n'
              '   • Consulter votre médecin pour une nouvelle ordonnance',
          icon: Icons.warning,
          color: Colors.red,
        ),
        
        _buildFAQItem(
          question: 'Comment scanner mon ordonnance ?',
          answer: 'Pour scanner votre ordonnance :\n\n'
              '1. Utilisez la fonction "Scanner ordonnance"\n'
              '2. Assurez-vous d\'avoir un bon éclairage\n'
              '3. Placez l\'ordonnance sur une surface plane\n'
              '4. Cadrez correctement le document\n'
              '5. Prenez la photo en veillant à la netteté\n\n'
              'Conseils :\n'
              '• Évitez les reflets\n'
              '• Vérifiez que le texte est lisible\n'
              '• Prenez plusieurs photos si nécessaire',
          icon: Icons.camera_alt,
          color: Colors.indigo,
        ),
        
        _buildFAQItem(
          question: 'Combien de temps prend la livraison ?',
          answer: 'Les délais de livraison varient selon :\n\n'
              '🏙️ Zone urbaine : 30 minutes - 2 heures\n'
              '🏘️ Zone périurbaine : 1 - 4 heures\n'
              '🚚 Livraison express : 15 - 45 minutes (supplément)\n\n'
              'Facteurs influençant le délai :\n'
              '• Disponibilité des médicaments\n'
              '• Distance de la pharmacie\n'
              '• Conditions de circulation\n'
              '• Disponibilité des livreurs',
          icon: Icons.local_shipping,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Text(
              answer,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Urgence24 - Demande d\'aide',
        'body': 'Bonjour,\n\nJ\'ai besoin d\'aide concernant :\n\n[Décrivez votre problème ici]\n\nMerci pour votre assistance.\n',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}