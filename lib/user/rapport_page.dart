import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_complete_demo/services/api_rapport.dart';
import 'rapport_liste_page.dart'; // ✅ import ajouté

class RapportPage extends StatefulWidget {
  final String token;

  const RapportPage({Key? key, required this.token}) : super(key: key);

  @override
  State<RapportPage> createState() => _RapportPageState();
}

class _RapportPageState extends State<RapportPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _heure;

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
    _titreController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: "Choisir la date du rapport",
      confirmText: "OK",
      cancelText: "Annuler",
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heure ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _heure = picked);
    }
  }

  Future<void> _enregistrerRapport() async {
    if (_titreController.text.trim().isEmpty ||
        _infoController.text.trim().isEmpty ||
        _date == null ||
        _heure == null) {
      setState(() => _errorMessage = "⚠️ Tous les champs sont obligatoires.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(_date!);
    final formattedTime =
        "${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}:00";

    final data = {
      "titre": _titreController.text.trim(),
      "informations": _infoController.text.trim(),
      "date": formattedDate,
      "heure": formattedTime,
    };

    try {
      await ApiRapport.ajouterRapport(data, widget.token);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _titreController.clear();
        _infoController.clear();
        _date = null;
        _heure = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('✅ Rapport ajouté avec succès !'),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "❌ Erreur lors de l’enregistrement : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Nouveau rapport",
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
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // 🧾 Carte rapport
              Card(
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Titre du rapport"),
                      _inputField(_titreController, "Ex: Rapport hebdomadaire"),

                      _label("Informations"),
                      _inputField(_infoController, "Détails du rapport...",
                          maxLines: 4),

                      _label("Date"),
                      _datePickerField(_date, _selectDate),

                      _label("Heure"),
                      _timePickerField(_heure, _selectTime),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : () => _enregistrerRapport(),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading
                                ? "Enregistrement..."
                                : "Enregistrer le rapport",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

              const SizedBox(height: 25),

              // 🟩 Bouton pour accéder à la liste des rapports
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RapportListePage(token: widget.token),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "Voir mes rapports",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // 🌟 Widgets stylés
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

  Widget _inputField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }

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
                date == null
                    ? "Sélectionner une date"
                    : DateFormat('yyyy-MM-dd').format(date),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerField(TimeOfDay? time, VoidCallback onTap) {
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
            const Icon(Icons.access_time, color: kPrimaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                time == null
                    ? "Sélectionner une heure"
                    : "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
