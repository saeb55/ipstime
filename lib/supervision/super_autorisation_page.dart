import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';
import '../services/api_auto.dart';
import '../login_page.dart';

class SuperAutorisationPage extends StatefulWidget {
  final String token;

  const SuperAutorisationPage({Key? key, required this.token})
      : super(key: key);

  @override
  State<SuperAutorisationPage> createState() => _SuperAutorisationPageState();
}

class _SuperAutorisationPageState extends State<SuperAutorisationPage> {
  late Future<List<Map<String, dynamic>>> _autosFuture;
  final ApiService _apiService = ApiService();

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _chargerInfosEtAutos();
  }

  void _chargerInfosEtAutos() {
    setState(() {
      _autosFuture = _fetchAutorisations();
    });
  }

  /// 📦 Charger toutes les autorisations avec ajout du département
  Future<List<Map<String, dynamic>>> _fetchAutorisations() async {
    try {
      final autos = await ApiAuto.getAutorisations(widget.token);

      for (var a in autos) {
        a['username'] ??= 'Employé inconnu';

        if (a['department'] == null ||
            a['department'].toString().trim().isEmpty ||
            a['department'] == 'Non défini') {
          try {
            final dep = await _apiService.getUserDepartmentByUsername(
              a['username'],
              widget.token,
            );
            a['department'] = dep;
          } catch (e) {
            a['department'] = '—';
          }
        }
      }

      return autos;
    } catch (e) {
      debugPrint("❌ Erreur autorisations : $e");
      return [];
    }
  }

  /// 🔄 Changer l’état d’une autorisation
  Future<void> _changerEtat(int id, bool accepte) async {
    try {
      final success = await ApiAuto.updateAutorisation(
        widget.token,
        id,
        {'accepted': accepte},
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepte
                  ? "✅ Autorisation acceptée avec succès"
                  : "❌ Autorisation refusée",
            ),
            backgroundColor: accepte ? Colors.green : Colors.redAccent,
          ),
        );
        _chargerInfosEtAutos();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: kPrimaryDark),
          title: const Text(
            "Supervision - Autorisations",
            style: TextStyle(
                color: kPrimaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryDark),
              tooltip: "Actualiser",
              onPressed: _chargerInfosEtAutos,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Déconnexion",
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: kPrimaryDark,
            labelColor: kPrimaryDark,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: "En attente"),
              Tab(text: "Historique"),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _autosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text("Erreur : ${snapshot.error}",
                      style: const TextStyle(fontSize: 16)));
            }

            final autos = snapshot.data ?? [];
            if (autos.isEmpty) {
              return const Center(
                child: Text(
                  "Aucune autorisation trouvée.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final enAttente = autos.where((a) => a['accepted'] == null).toList();
            final historique =
                autos.where((a) => a['accepted'] != null).toList()
                  ..sort((a, b) {
                    final dateA = DateTime.tryParse(a['decision_at'] ?? '') ??
                        DateTime(2000);
                    final dateB = DateTime.tryParse(b['decision_at'] ?? '') ??
                        DateTime(2000);
                    return dateB.compareTo(dateA);
                  });

            return TabBarView(
              children: [
                _buildAutoList(enAttente, true),
                _buildAutoList(historique, false),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 🧱 Liste d’autorisations stylisée
  Widget _buildAutoList(List<Map<String, dynamic>> autos, bool enAttente) {
    if (autos.isEmpty) {
      return const Center(
        child: Text(
          "Aucune demande à afficher.",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: autos.length,
      itemBuilder: (context, i) => _buildAutoCard(autos[i], enAttente),
    );
  }

  /// 🧾 Carte d’autorisation — version moderne
  Widget _buildAutoCard(Map<String, dynamic> item, bool enAttente) {
    final id = item['id'] as int?;
    final username = item['username'] ?? 'Employé inconnu';
    final department = item['department'] ?? '—';
    final accepted = item['accepted'];

    final decision = accepted == true
        ? 'Acceptée'
        : accepted == false
            ? 'Refusée'
            : 'En attente';

    final color = accepted == true
        ? Colors.green.shade600
        : accepted == false
            ? Colors.redAccent
            : Colors.orangeAccent;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- En-tête employé ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: kPrimaryDark),
                ),
                Icon(
                  accepted == true
                      ? Icons.check_circle
                      : accepted == false
                          ? Icons.cancel
                          : Icons.timelapse,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Département : $department",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const Divider(height: 20),

            // --- Détails ---
            _infoRow("📅 Du", item['date_debut']),
            _infoRow("📆 Au", item['date_fin']),
            _infoRow("📝 Cause", item['cause']),
            _infoRow("📨 Soumis le", item['submitted_at']),
            if (item['decision_at'] != null)
              _infoRow("📑 Décision le", item['decision_at']),
            const SizedBox(height: 6),
            Text("Statut : $decision",
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),

            // --- Boutons action ---
            if (enAttente) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: id != null ? () => _changerEtat(id, true) : null,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Accepter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: id != null ? () => _changerEtat(id, false) : null,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text("Refuser"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// 🧩 Ligne d’information
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label : ${value ?? '—'}",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}
