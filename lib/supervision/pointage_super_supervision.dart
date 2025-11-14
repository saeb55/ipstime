import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';
import '../services/api_pointage.dart';

class PointageSuperSupervisionPage extends StatefulWidget {
  final String token;

  const PointageSuperSupervisionPage({Key? key, required this.token})
      : super(key: key);

  @override
  State<PointageSuperSupervisionPage> createState() =>
      _PointageSuperSupervisionPageState();
}

class _PointageSuperSupervisionPageState
    extends State<PointageSuperSupervisionPage> {
  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  bool _isLoading = false;
  List<Map<String, dynamic>> _pointages = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPointages();
  }

  /// 📦 Charger tous les pointages et compléter les infos manquantes
  Future<void> _loadPointages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiPointage.fetchAllPointages(widget.token);

      for (var p in data) {
        p['username'] ??= 'Employé inconnu';
        if (p['department'] == null ||
            p['department'].toString().trim().isEmpty ||
            p['department'] == 'Non défini') {
          try {
            final dep = await _apiService.getUserDepartmentByUsername(
              p['username'],
              widget.token,
            );
            p['department'] = dep;
          } catch (e) {
            p['department'] = '—';
            debugPrint('⚠️ Erreur département pour ${p['username']} : $e');
          }
        }
      }

      setState(() => _pointages = data);
    } catch (e) {
      debugPrint("❌ Erreur récupération pointages : $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🎨 Carte de pointage stylisée
  Widget _buildPointageCard(Map<String, dynamic> p) {
    final username = p['username'] ?? '-';
    final department = p['department'] ?? '—';
    final date = p['date'] ?? '-';
    final entree = p['check_in'] ?? '-';
    final sortie = p['check_out'] ?? '-';

    final entreeAff = entree != '-' && entree.length >= 16
        ? entree.substring(11, 16)
        : '-';
    final sortieAff = sortie != '-' && sortie.length >= 16
        ? sortie.substring(11, 16)
        : '-';

    final bool complet = entreeAff != '-' && sortieAff != '-';

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne du haut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryDark),
                ),
                Icon(
                  complet ? Icons.check_circle : Icons.timelapse,
                  color: complet ? Colors.green.shade600 : Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Département : $department",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile(Icons.calendar_today, "Date", date),
                _infoTile(Icons.login, "Entrée", entreeAff),
                _infoTile(Icons.logout, "Sortie", sortieAff),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🧩 Petit widget d’information
  Widget _infoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: kPrimaryLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧭 Barre d’outils
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "Supervision du Pointage",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPointages,
            icon: const Icon(Icons.refresh, color: kPrimaryDark),
            tooltip: "Actualiser",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPointages,
              color: kPrimaryLight,
              child: _pointages.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun pointage disponible.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _pointages.length,
                      itemBuilder: (context, i) =>
                          _buildPointageCard(_pointages[i]),
                    ),
            ),
    );
  }
}
