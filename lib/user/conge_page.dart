import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/services/api_conge.dart';
import 'package:intl/intl.dart';

class CongePage extends StatefulWidget {
  final String token;
  final String username;

  const CongePage({
    Key? key,
    required this.token,
    required this.username,
  }) : super(key: key);

  @override
  State<CongePage> createState() => _CongePageState();
}

class _CongePageState extends State<CongePage> with SingleTickerProviderStateMixin {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final TextEditingController _nbJoursController = TextEditingController();
  final TextEditingController _causeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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
    _nbJoursController.dispose();
    _causeController.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null ? "" : DateFormat('yyyy-MM-dd').format(d);

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _dateDebut : _dateFin) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: isDebut ? "Choisir la date de début" : "Choisir la date de fin",
      confirmText: "OK",
      cancelText: "Annuler",
    );

    if (picked == null) return;
    setState(() {
      if (isDebut) {
        _dateDebut = picked;
      } else {
        _dateFin = picked;
      }
      if (_dateDebut != null && _dateFin != null && !_dateDebut!.isAfter(_dateFin!)) {
        final days = _dateFin!.difference(_dateDebut!).inDays + 1;
        _nbJoursController.text = days.toString();
      }
    });
  }

  Future<void> _ajouterConge() async {
    if (_dateDebut == null || _dateFin == null) {
      setState(() => _errorMessage = "Les dates de début et de fin sont obligatoires.");
      return;
    }
    if (_dateDebut!.isAfter(_dateFin!)) {
      setState(() => _errorMessage = "La date de début ne peut pas être après la date de fin.");
      return;
    }
    if (_causeController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Veuillez indiquer la cause du congé.");
      return;
    }

    if (_nbJoursController.text.trim().isEmpty) {
      final days = _dateFin!.difference(_dateDebut!).inDays + 1;
      _nbJoursController.text = days.toString();
    }

    final nbJours = int.tryParse(_nbJoursController.text.trim());
    if (nbJours == null || nbJours <= 0) {
      setState(() => _errorMessage = "Le nombre de jours doit être positif.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiConge.ajouterConge({
      'date_debut': _fmt(_dateDebut),
      'date_fin': _fmt(_dateFin),
      'nb_jours': nbJours,
      'cause': _causeController.text.trim(),
    }, widget.token, widget.username);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _errorMessage = null;
        _dateDebut = _dateFin = null;
        _nbJoursController.clear();
        _causeController.clear();
        // ✅ Notification animée en haut de l'écran (style professionnel)
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
            color: Colors.green.shade600,
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
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Demande de congé envoyée avec succès 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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

      } else {
        _errorMessage = "❌ Erreur lors de l'ajout du congé.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Demande de congé",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kPrimaryDark),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // 📅 Carte formulaire congé
              Card(
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Date de début"),
                      _datePickerField(_dateDebut, () => _pickDate(true)),

                      _label("Date de fin"),
                      _datePickerField(_dateFin, () => _pickDate(false)),

                      _label("Nombre de jours"),
                      _inputField(_nbJoursController, "Ex: 5", TextInputType.number),

                      _label("Cause"),
                      _inputField(_causeController, "Raison du congé", TextInputType.text, maxLines: 3),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _ajouterConge,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isLoading ? "Envoi..." : "Soumettre la demande",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Widgets utilitaires design
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      );

  Widget _datePickerField(DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: kPrimaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? "Sélectionner une date" : DateFormat('yyyy-MM-dd').format(date),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint,
    TextInputType keyboard, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: kPrimaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}
