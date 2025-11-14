import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/home_admin.dart';
import 'package:flutter_complete_demo/user/autorisation_page.dart';
import '../services/api_auto.dart';

class AdminAutorisation extends StatefulWidget {
  final String token;
  final String username;

  const AdminAutorisation({
    Key? key,
    required this.token,
    required this.username,
  }) : super(key: key);

  @override
  State<AdminAutorisation> createState() => _AdminAutorisationState();
}

class _AdminAutorisationState extends State<AdminAutorisation> {
  late Future<List<Map<String, dynamic>>> _autorisations;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadAutorisations();
  }

  void _loadAutorisations() {
    setState(() {
      _autorisations = ApiAuto.getAutorisations(widget.token);
    });
  }

  Future<void> _changerEtat(int id, bool accepte) async {
    try {
      await ApiAuto.updateAutorisation(widget.token, id, {'accepted': accepte});
      _loadAutorisations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepte
              ? "✅ Autorisation acceptée avec succès"
              : "❌ Autorisation refusée"),
          backgroundColor: accepte ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _deleteAutorisation(int id) async {
    try {
      await ApiAuto.supprimerAutorisation(id, widget.token);
      _loadAutorisations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Autorisation supprimée")),
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
            "Gestion des Autorisations",
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
      username: 'Admin', // ✅ Ajout du paramètre obligatoire
    ),
  ),
)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryDark),
              tooltip: "Actualiser",
              onPressed: _loadAutorisations,
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
          future: _autorisations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }

            final autorisations = snapshot.data ?? [];
            if (autorisations.isEmpty) {
              return const Center(
                child: Text(
                  "Aucune autorisation trouvée.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final enAttente =
                autorisations.where((a) => a['accepted'] == null).toList();
            final historique =
                autorisations.where((a) => a['accepted'] != null).toList()
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
                _buildAutoList(enAttente, true),
                _buildAutoList(historique, false),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 🧱 Liste des autorisations
  Widget _buildAutoList(List<Map<String, dynamic>> list, bool enAttente) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Aucune demande à afficher.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildAutoCard(list[i], enAttente),
    );
  }

  /// 🧾 Carte designée pour chaque autorisation
  Widget _buildAutoCard(Map<String, dynamic> item, bool enAttente) {
    final id = item['id'] as int?;
    final username = item['username'] ?? 'Inconnu';
    final type = item['type'] ?? '—';
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: kPrimaryDark,
                  ),
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
            const SizedBox(height: 6),
            Text("Type : $type",
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const Divider(height: 16),

            // 🔸 Informations
            _infoRow("📅 Début", item['date_debut']),
            _infoRow("📆 Fin", item['date_fin']),
            _infoRow("💬 Commentaire", item['commentaire']),
            _infoRow("📨 Soumis le", item['submitted_at']),
            if (item['decision_at'] != null)
              _infoRow("📑 Décision le", item['decision_at']),
            const SizedBox(height: 8),

            Text(
              "Statut : $decision",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),

            // 🔘 Boutons
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
                  onPressed: id != null ? () => _deleteAutorisation(id) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: kPrimaryLight),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AutorisationPage(
                          token: widget.token,
                          username: item['username'] ?? '',
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
