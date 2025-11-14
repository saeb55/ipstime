import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/services/api_auto.dart';
import 'package:intl/intl.dart';

class AutorisationPage extends StatefulWidget {
  final String token;
  final String username;

  const AutorisationPage({
    required this.token,
    required this.username,
    Key? key,
  }) : super(key: key);

  @override
  State<AutorisationPage> createState() => _AutorisationPageState();
}

class _AutorisationPageState extends State<AutorisationPage>
    with SingleTickerProviderStateMixin {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  String _selectedType = 'Maladie';
  final TextEditingController _commentaireController = TextEditingController();

  final Color kPrimaryDark = const Color(0xFF111184);
  final Color kPrimaryLight = const Color(0xFF1565C0);

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
    _commentaireController.dispose();
    super.dispose();
  }

  // 📅 Sélection date
  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "Sélectionnez une date",
      confirmText: "Confirmer",
      cancelText: "Annuler",
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  // ⏰ Sélection heure
  Future<void> _selectHeure(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? (_heureDebut ?? TimeOfDay.now()) : (_heureFin ?? TimeOfDay.now()),
      helpText: "Sélectionnez une heure",
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          _heureDebut = picked;
        } else {
          _heureFin = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? d) =>
      d != null ? DateFormat('yyyy-MM-dd').format(d) : "—";

  // ✅ Ajout d'autorisation
  void _ajouterAutorisation() {
    if (_dateDebut == null || _dateFin == null || _heureDebut == null || _heureFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir toutes les dates et heures."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final data = {
      'type': _selectedType,
      'date_debut': _formatDate(_dateDebut),
      'date_fin': _formatDate(_dateFin),
      'heureDebut': _heureDebut!.format(context),
      'heureFin': _heureFin!.format(context),
      'commentaire': _commentaireController.text,
    };

    ApiAuto.ajouterAutorisation(data, widget.token, widget.username).then((ok) {
      // ✅ Notification animée et élégante après ajout réussi
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
                'Autorisation ajoutée avec succès 🎉',
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

// 🕒 La supprimer après 3 secondes
Future.delayed(const Duration(seconds: 3)).then((_) {
  overlayEntry.remove();
});


      setState(() {
        _dateDebut = null;
        _dateFin = null;
        _heureDebut = null;
        _heureFin = null;
        _selectedType = 'Maladie';
        _commentaireController.clear();
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: kPrimaryDark),
        title: Text(
          "Demande d'autorisation",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // 🧾 Carte formulaire
              Card(
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Type d'autorisation"),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: kPrimaryDark),
                            items: ['Maladie', 'Vacances', 'Congé', 'Autre']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label("Date de début"),
                      _buildPickerField(
                        text: _dateDebut != null ? _formatDate(_dateDebut) : "Sélectionner une date",
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(context, true),
                      ),
                      _label("Date de fin"),
                      _buildPickerField(
                        text: _dateFin != null ? _formatDate(_dateFin) : "Sélectionner une date",
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(context, false),
                      ),
                      _label("Heure de début"),
                      _buildPickerField(
                        text: _heureDebut != null
                            ? _heureDebut!.format(context)
                            : "Sélectionner une heure",
                        icon: Icons.access_time,
                        onTap: () => _selectHeure(context, true),
                      ),
                      _label("Heure de fin"),
                      _buildPickerField(
                        text: _heureFin != null
                            ? _heureFin!.format(context)
                            : "Sélectionner une heure",
                        icon: Icons.access_time,
                        onTap: () => _selectHeure(context, false),
                      ),
                      _label("Commentaire"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentaireController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Ajoutez un commentaire (optionnel)",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kPrimaryLight, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🔘 Bouton principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _ajouterAutorisation,
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            "Envoyer la demande",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
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

  // 🎨 Widgets utilitaires
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 10),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: kPrimaryDark,
            fontSize: 15,
          ),
        ),
      );

  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
            Icon(icon, color: kPrimaryLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
