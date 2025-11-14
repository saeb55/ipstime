import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/home_admin.dart';
import '../services/api_conge.dart';
import '../user/conge_page.dart';

class AdminConge extends StatefulWidget {
  final String token;
  final String username;

  const AdminConge({Key? key, required this.token, required this.username})
      : super(key: key);

  @override
  State<AdminConge> createState() => _AdminCongeState();
}

class _AdminCongeState extends State<AdminConge> {
  late Future<List<dynamic>> _conges;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadConges();
  }

  void _loadConges() {
    setState(() {
      _conges = ApiConge.listerConges(widget.token);
    });
  }

  Future<void> _changerEtat(int id, bool accepte) async {
    try {
      await ApiConge.modifierConge(id, accepte, widget.token);
      _loadConges();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepte ? "✅ Congé accepté avec succès" : "❌ Congé refusé",
          ),
          backgroundColor: accepte ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _deleteConge(int id) async {
    try {
      await ApiConge.supprimerConge(id, widget.token);
      _loadConges();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Congé supprimé")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
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
            "Gestion des Congés",
            style: TextStyle(
              color: kPrimaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => HomeAdmin(
      token: widget.token,
      username: 'Admin', // ✅ paramètre ajouté
    ),
  ),
)),

          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryDark),
              tooltip: "Actualiser",
              onPressed: _loadConges,
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
        body: FutureBuilder<List<dynamic>>(
          future: _conges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }

            final conges = snapshot.data ?? [];
            if (conges.isEmpty) {
              return const Center(
                child: Text(
                  "Aucun congé trouvé.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final enAttente =
                conges.where((c) => c['accepted'] == null).toList();
            final historique =
                conges.where((c) => c['accepted'] != null).toList()
                  ..sort((a, b) {
                    final dateA =
                        DateTime.tryParse(a['decision_at'] ?? '') ??
                            DateTime(2000);
                    final dateB =
                        DateTime.tryParse(b['decision_at'] ?? '') ??
                            DateTime(2000);
                    return dateB.compareTo(dateA);
                  });

            return TabBarView(
              children: [
                _buildCongeList(enAttente, true),
                _buildCongeList(historique, false),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 🧱 Liste de congés
  Widget _buildCongeList(List<dynamic> list, bool enAttente) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Aucun congé à afficher.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildCongeCard(list[i], enAttente),
    );
  }

  /// 🧾 Carte stylisée d’un congé
  Widget _buildCongeCard(Map<String, dynamic> item, bool enAttente) {
    final id = item['id'] as int?;
    final username = (item['username'] != null &&
            item['username'].toString().trim().isNotEmpty)
        ? item['username']
        : 'Inconnu';

    final accepted = item['accepted'];
    final decision = accepted == true
        ? 'Accepté'
        : accepted == false
            ? 'Refusé'
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
            // 🔹 En-tête employé + statut
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
            const Divider(height: 20),

            // 🔸 Détails du congé
            _infoRow("📅 Début", item['date_debut']),
            _infoRow("📆 Fin", item['date_fin']),
            _infoRow("📝 Cause", item['cause']),
            _infoRow("📨 Soumis le", item['submitted_at']),
            if (item['decision_at'] != null)
              _infoRow("📑 Décision le", item['decision_at']),
            const SizedBox(height: 8),
            Text("Statut : $decision",
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),

            const SizedBox(height: 12),

            // 🔘 Boutons d’action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (enAttente) ...[
                  ElevatedButton.icon(
                    onPressed: id != null ? () => _changerEtat(id, true) : null,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Accepter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 18),
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
                          vertical: 10, horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: id != null ? () => _deleteConge(id!) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: kPrimaryLight),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CongePage(
                          token: widget.token,
                          username: username,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
