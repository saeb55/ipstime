import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';

class ChangerMotDePassePage extends StatefulWidget {
  final String token;

  const ChangerMotDePassePage({super.key, required this.token});

  @override
  State<ChangerMotDePassePage> createState() => _ChangerMotDePassePageState();
}

class _ChangerMotDePassePageState extends State<ChangerMotDePassePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ancienCtrl = TextEditingController();
  final TextEditingController _nouveauCtrl = TextEditingController();
  final TextEditingController _confirmerCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureAncien = true;
  bool _obscureNouveau = true;
  bool _obscureConfirmer = true;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmerCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _changerMotDePasse() async {
    final ancien = _ancienCtrl.text.trim();
    final nouveau = _nouveauCtrl.text.trim();
    final confirmer = _confirmerCtrl.text.trim();

    if (ancien.isEmpty || nouveau.isEmpty || confirmer.isEmpty) {
      _showSnack("Veuillez remplir tous les champs.", success: false);
      return;
    }
    if (nouveau != confirmer) {
      _showSnack("Les mots de passe ne correspondent pas.", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().changePassword(widget.token, ancien, nouveau, confirmer);
      _showSnack("✅ Mot de passe modifié avec succès !");
      _ancienCtrl.clear();
      _nouveauCtrl.clear();
      _confirmerCtrl.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      final msg = e.toString().replaceFirst("Exception: ", "");
      _showSnack("❌ $msg", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

 void _showSnack(String message, {bool success = true}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 600),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: success ? Colors.green.shade600 : Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // ✅ Afficher la notification
  overlay.insert(overlayEntry);

  // 🕒 Supprimer la notification après 3 secondes
  Future.delayed(const Duration(seconds: 3)).then((_) {
    overlayEntry.remove();
  });
}


  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "Changer le mot de passe",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shadowColor: kPrimaryLight.withOpacity(0.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sécurité du compte",
                    style: TextStyle(
                      color: kPrimaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔑 Champs
                  _passwordField(
                    controller: _ancienCtrl,
                    label: "Ancien mot de passe",
                    obscure: _obscureAncien,
                    toggle: () =>
                        setState(() => _obscureAncien = !_obscureAncien),
                  ),
                  _passwordField(
                    controller: _nouveauCtrl,
                    label: "Nouveau mot de passe",
                    obscure: _obscureNouveau,
                    toggle: () =>
                        setState(() => _obscureNouveau = !_obscureNouveau),
                  ),
                  _passwordField(
                    controller: _confirmerCtrl,
                    label: "Confirmer le mot de passe",
                    obscure: _obscureConfirmer,
                    toggle: () =>
                        setState(() => _obscureConfirmer = !_obscureConfirmer),
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _changerMotDePasse,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.lock_outline, color: Colors.white),
                      label: Text(
                        _isLoading
                            ? "Mise à jour en cours..."
                            : "Enregistrer les modifications",
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
