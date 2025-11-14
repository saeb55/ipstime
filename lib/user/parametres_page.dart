import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/user/parametres/changer_motdepasse_page.dart';
import 'package:flutter_complete_demo/user/parametres/gerer_empreinte_page.dart';
import 'package:flutter_complete_demo/user/parametres/modifier_infos_page.dart';

class ParametresPage extends StatefulWidget {
  final String token;

  const ParametresPage({super.key, required this.token});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage>
    with SingleTickerProviderStateMixin {
  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "Paramètres",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gérer votre compte",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Accédez aux paramètres personnels et de sécurité.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 24),

              // 🧩 Section 1 : Profil
              _sectionTitle("Mon profil"),
              _buildSettingCard(
                title: "Modifier mes informations",
                subtitle: "Nom, email, matricule...",
                icon: Icons.person_outline,
                color: Colors.blue.shade50,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModifierInfosPage(token: widget.token),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔐 Section 2 : Sécurité
              _sectionTitle("Sécurité"),
              _buildSettingCard(
                title: "Changer le mot de passe",
                subtitle: "Mettre à jour vos identifiants",
                icon: Icons.lock_outline,
                color: Colors.purple.shade50,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangerMotDePassePage(token: widget.token),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 🧬 Nouvelle option : Gérer la connexion biométrique
_buildSettingCard(
  title: "Gérer la connexion biométrique",
  subtitle: "Activer, désactiver ou tester l’empreinte",
  icon: Icons.fingerprint,
  color: Colors.green.shade50,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GererEmpreintePage(token: widget.token),
    ),
  ),
),

              // 💡 Aide ou footer visuel
              Center(
                child: Text(
                  "Version 1.0.0 • © 2025 YourApp",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧱 Titre de section
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: kPrimaryLight,
        ),
      ),
    );
  }

  // 🪄 Carte de paramètre
  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: kPrimaryLight, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
