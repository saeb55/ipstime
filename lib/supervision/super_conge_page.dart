import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';
import '../services/api_conge.dart';
import '../login_page.dart';

class SuperCongePage extends StatefulWidget {
  final String token;

  const SuperCongePage({Key? key, required this.token}) : super(key: key);

  @override
  State<SuperCongePage> createState() => _SuperCongePageState();
}

class _SuperCongePageState extends State<SuperCongePage> {
  late Future<List<Map<String, dynamic>>> _congesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _chargerConges();
  }

  void _chargerConges() {
    setState(() {
      _congesFuture = _fetchConges();
    });
  }

  /// 📦 Récupération des congés + département
  Future<List<Map<String, dynamic>>> _fetchConges() async {
    try {
      final conges = await ApiConge.listerConges(widget.token);

      for (var c in conges) {
        c['username'] ??= 'Employé inconnu';
        if (c['department'] == null ||
            c['department'].toString().trim().isEmpty) {
          try {
            final dep = await _apiService.getUserDepartmentByUsername(
              c['username'],
              widget.token,
            );
            c['department'] = dep;
          } catch (_) {
            c['department'] = '—';
          }
        }
      }

      return conges;
    } catch (e) {
      print("❌ Erreur récupération congés : $e");
      return [];
    }
  }

  /// 🔄 Modifier l’état d’un congé
  Future<void> _changerEtat(int id, bool accepte) async {
    try {
      final success = await ApiConge.modifierConge(id, accepte, widget.token);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepte
                  ? "✅ Congé accepté avec succès"
                  : "❌ Congé refusé avec succès",
            ),
          ),
        );
        _chargerConges();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  /// 🗑️ Supprimer un congé
  Future<void> _supprimerConge(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le congé"),
        content: const Text("Voulez-vous vraiment supprimer ce congé ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiConge.supprimerConge(id, widget.token);
        _chargerConges();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Congé supprimé")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur suppression : $e")),
        );
      }
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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text(
            "Supervision - Congés",
            style: TextStyle(color: Color(0xFF111184), fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
          iconTheme: const IconThemeData(color: Color(0xFF111184)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: "Déconnexion",
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF111184),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF111184),
            tabs: [
              Tab(text: "En attente"),
              Tab(text: "Historique"),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _congesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Erreur : ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)),
              );
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

            final enAttente = conges.where((c) => c['accepted'] == null).toList();
            final historique = conges.where((c) => c['accepted'] != null).toList();

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

  /// 🧱 Liste des congés
  Widget _buildCongeList(List<Map<String, dynamic>> conges, bool enAttente) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: conges.length,
      itemBuilder: (context, index) {
        final item = conges[index];
        return _buildCongeCard(item, enAttente);
      },
    );
  }

  /// 🧾 Carte d’un congé
  Widget _buildCongeCard(Map<String, dynamic> item, bool enAttente) {
    final id = item['id'] as int?;
    final username = item['username'] ?? 'Employé inconnu';
    final department = item['department'] ?? '—';
    final accepted = item['accepted'];

    final decision = accepted == true
        ? 'Accepté ✅'
        : accepted == false
            ? 'Refusé ❌'
            : 'En attente ⏳';
    final color = accepted == true
        ? Colors.green
        : accepted == false
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const Icon(Icons.beach_access, color: Color(0xFF1565C0), size: 40),
        title: Text(
          "$username — $department",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Début : ${item['date_debut'] ?? '—'}"),
            Text("Fin : ${item['date_fin'] ?? '—'}"),
            Text("Cause : ${item['cause'] ?? '—'}"),
            Text("Soumis le : ${item['submitted_at'] ?? '—'}"),
            if (!enAttente)
              Text("Décision le : ${item['decision_at'] ?? '—'}"),
            Text("Statut : $decision", style: TextStyle(color: color)),
          ],
        ),
        trailing: enAttente
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: id != null ? () => _changerEtat(id, true) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: id != null ? () => _changerEtat(id, false) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: id != null ? () => _supprimerConge(id!) : null,
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: id != null ? () => _supprimerConge(id!) : null,
              ),
      ),
    );
  }
}
