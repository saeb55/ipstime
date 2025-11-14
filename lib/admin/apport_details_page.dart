import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';
import 'package:flutter_complete_demo/services/api_mail.dart'; // ✅ API Mail

class RapportDetailsPage extends StatefulWidget {
  final Map rapport;
  final String token;

  const RapportDetailsPage({
    Key? key,
    required this.rapport,
    required this.token,
  }) : super(key: key);

  @override
  State<RapportDetailsPage> createState() => _RapportDetailsPageState();
}

class _RapportDetailsPageState extends State<RapportDetailsPage> {
  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  final ApiService apiService = ApiService();
  final ApiMailService mailService = ApiMailService();

  String auteur = "Utilisateur inconnu";
  String auteurEmail = "";
  bool _isSending = false;

  final TextEditingController explicationCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerAuteurEtEmail();
  }

  /// 🔹 Charge le nom et l’adresse email de l’auteur
  Future<void> _chargerAuteurEtEmail() async {
    final userField = widget.rapport['user'];
    if (userField is Map && userField['username'] != null) {
      auteur = userField['username'];
    } else if (widget.rapport['username'] != null) {
      auteur = widget.rapport['username'];
    } else if (userField is int) {
      auteur = "User #$userField";
    }

    try {
      final users = await apiService.getUsers(widget.token);
      final auteurData = users.firstWhere(
        (u) => u['username'] == auteur,
        orElse: () => {},
      );

      setState(() {
        auteurEmail = auteurData['email'] ?? "";
        emailCtrl.text = auteurEmail;
      });
    } catch (e) {
      setState(() {
        auteurEmail = "";
        emailCtrl.text = "";
      });
      print("⚠️ Erreur récupération auteur : $e");
    }
  }

  /// 🔹 Ouvre la boîte de dialogue d’envoi
  Future<void> _ouvrirFenetreEnvoi() async {
    if (auteurEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Adresse email non disponible."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            "Envoyer un message à l’auteur",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                readOnly: true, // ✅ l’admin ne change pas l’adresse
                decoration: const InputDecoration(
                  labelText: "Adresse email de l’auteur",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: explicationCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Message à envoyer",
                  hintText: "Rédigez ici votre réponse RH...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              onPressed: _isSending
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _envoyerRapport(emailCtrl.text.trim());
                    },
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text("Envoyer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryLight,
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✉️ Envoi via backend Django
  Future<void> _envoyerRapport(String destinataire) async {
    setState(() => _isSending = true);

    final titre = widget.rapport['titre'] ?? 'Sans titre';
    final info = widget.rapport['informations'] ?? '—';
    final explication = explicationCtrl.text.trim();

    final message = '''
Bonjour $auteur,

La Direction des Ressources Humaines a examiné votre rapport.

🧾 Titre : $titre
📄 Contenu : $info

🗒️ Réponse RH :
$explication

Bien cordialement,
Direction des Ressources Humaines
''';

    final success = await mailService.sendMail(
      token: widget.token,
      destinataire: destinataire,
      sujet: "Direction RH - Réponse à votre rapport : $titre",
      message: message,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Email envoyé via le serveur Django."),
          backgroundColor: Colors.green,
        ),
      );
      explicationCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Échec de l’envoi de l’email."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final rapport = widget.rapport;
    final titre = rapport['titre'] ?? 'Sans titre';
    final info = rapport['informations'] ?? '—';
    final date = rapport['date'] ?? '';
    final heure = rapport['heure'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "Détails du rapport",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.person, "Auteur : $auteur"),
              _infoRow(Icons.email, "Email : ${auteurEmail.isEmpty ? "Non défini" : auteurEmail}"),
              _infoRow(Icons.calendar_today, "Date : $date  •  Heure : $heure"),
              const Divider(height: 30, thickness: 1.2),
              const Text(
                "Informations du rapport :",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryLight,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    info,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _ouvrirFenetreEnvoi,
                  icon: const Icon(Icons.email, color: Colors.white),
                  label: Text(
                    _isSending
                        ? "Envoi en cours..."
                        : "Rédiger un message à l’auteur",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Petite méthode utilitaire pour afficher des infos
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
