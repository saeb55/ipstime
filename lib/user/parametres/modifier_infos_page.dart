import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';

class ModifierInfosPage extends StatefulWidget {
  final String token;

  const ModifierInfosPage({super.key, required this.token});

  @override
  State<ModifierInfosPage> createState() => _ModifierInfosPageState();
}

class _ModifierInfosPageState extends State<ModifierInfosPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _matriculeCtrl = TextEditingController();

  bool _isLoading = false;
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
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService().me(widget.token);
      _emailCtrl.text = user['email'] ?? '';
      _firstNameCtrl.text = user['first_name'] ?? '';
      _lastNameCtrl.text = user['last_name'] ?? '';
      _matriculeCtrl.text = user['matricule'] ?? '';
    } catch (e) {
      _showSnack("❌ Erreur lors du chargement : $e", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sauvegarderInfos() async {
    final email = _emailCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final matricule = _matriculeCtrl.text.trim();

    if (email.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _showSnack("⚠️ Tous les champs sont obligatoires", success: false);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnack("⚠️ Email invalide", success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await ApiService().updateUserInfo(
        token: widget.token,
        email: email,
        firstName: firstName,
        lastName: lastName,
        matricule: matricule,
      );

      if (ok) {
        _showSnack("✅ Informations mises à jour avec succès !");
      } else {
        _showSnack("❌ Erreur lors de la mise à jour", success: false);
      }
    } catch (e) {
      _showSnack("⚠️ $e", success: false);
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


  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          "Modifier mes informations",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadUserInfo,
            icon: const Icon(Icons.refresh),
            tooltip: "Recharger",
            color: kPrimaryDark,
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 6,
                  shadowColor: kPrimaryLight.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Informations personnelles",
                          style: TextStyle(
                              color: kPrimaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        _field(label: "Prénom", controller: _firstNameCtrl),
                        _field(label: "Nom", controller: _lastNameCtrl),
                        _field(
                          label: "Email",
                          controller: _emailCtrl,
                          type: TextInputType.emailAddress,
                        ),
                        _field(
                            label: "Matricule",
                            controller: _matriculeCtrl,
                            type: TextInputType.text),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _sauvegarderInfos,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              _isLoading
                                  ? "Mise à jour en cours..."
                                  : "Sauvegarder les modifications",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryLight,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
