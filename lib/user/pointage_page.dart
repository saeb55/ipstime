import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/api_pointage.dart';

class PointagePage extends StatefulWidget {
  final String token;
  const PointagePage({super.key, required this.token});

  @override
  State<PointagePage> createState() => _PointagePageState();
}

class _PointagePageState extends State<PointagePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pointages = [];
  int? _dernierPointageId;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm:ss');

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

    initializeDateFormatting('fr_FR', null).then((_) => _loadPointages());
  }

  Future<void> _loadPointages() async {
    setState(() => _isLoading = true);
    try {
      _pointages = await ApiPointage.fetchPointages(widget.token);
      if (_pointages.isNotEmpty) _dernierPointageId = _pointages.first['id'];
    } catch (e) {
      _showSnack("❌ Erreur : $e", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterPointage(String type) async {
    final now = DateTime.now();
    final formattedTime = timeFormat.format(now);
    Map<String, dynamic> result = {"success": false, "message": ""};

    setState(() => _isLoading = true);

    if (type == "entrée") {
      result = await ApiPointage.ajouterEntree(widget.token, formattedTime);
      if (result["success"]) await _loadPointages();
    } else if (_dernierPointageId != null) {
      result = await ApiPointage.ajouterSortie(
        widget.token,
        _dernierPointageId!,
        formattedTime,
      );
      if (result["success"]) await _loadPointages();
    } else {
      result = {
        "success": false,
        "message":
            "⚠️ Aucun pointage d’entrée trouvé pour enregistrer la sortie."
      };
    }

    setState(() => _isLoading = false);

    _showSnack(
      result["success"]
          ? "✅ ${type == 'entrée' ? 'Entrée' : 'Sortie'} enregistrée à $formattedTime"
          : (result["message"] ?? "⚠️ Une erreur est survenue."),
      success: result["success"],
    );
  }

  void _showSnack(String message, {bool success = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 60,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: success ? Colors.green : Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(success ? Icons.check_circle : Icons.error,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3)).then((_) => entry.remove());
  }

  Widget _buildPointageCard(Map<String, dynamic> p) {
    final date = p['date'] ?? '-';
    final checkIn = p['check_in'] ?? '-';
    final checkOut = p['check_out'] ?? '-';
    final parsedDate = DateTime.tryParse(date);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        shadowColor: kPrimaryLight.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: kPrimaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    parsedDate != null
                        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                            .format(parsedDate)
                        : date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeBox(
                    icon: Icons.login,
                    label: "Entrée",
                    value: checkIn == '-' ? "--:--" : checkIn,
                    color: Colors.green.shade600,
                  ),
                  _buildTimeBox(
                    icon: Icons.logout,
                    label: "Sortie",
                    value: checkOut == '-' ? "--:--" : checkOut,
                    color: Colors.red.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            value.toString().split('.').first,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // 🔙 En-tête stylée
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: kPrimaryLight, size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Suivi de présence",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // 🕒 Liste des pointages
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadPointages,
                        child: _pointages.isEmpty
                            ? const Center(
                                child: Text(
                                  "Aucun pointage trouvé.",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _pointages.length,
                                itemBuilder: (context, i) =>
                                    _buildPointageCard(_pointages[i]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),

      // ✅ Boutons d’action modernes
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              label: "Entrée",
              icon: Icons.login,
              color: Colors.green.shade700,
              onPressed: () => _ajouterPointage("entrée"),
            ),
            _actionButton(
              label: "Sortie",
              icon: Icons.logout,
              color: kPrimaryLight,
              onPressed: () => _ajouterPointage("sortie"),
            ),
          ],
        ),
      ),
    );
  }
}
