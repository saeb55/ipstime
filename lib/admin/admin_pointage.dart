import 'package:flutter/material.dart';
import '../services/api_pointage.dart';

class AdminPointage extends StatefulWidget {
  final String token;
  const AdminPointage({super.key, required this.token});

  @override
  State<AdminPointage> createState() => _AdminPointageState();
}

class _AdminPointageState extends State<AdminPointage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pointages = [];

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kBackground = Color(0xFFF5F8FB);

  @override
  void initState() {
    super.initState();
    _loadPointages();
  }

  Future<void> _loadPointages() async {
    setState(() => _isLoading = true);
    try {
      _pointages = await ApiPointage.fetchAllPointages(widget.token);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _supprimerPointage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer le pointage"),
        content: const Text("Voulez-vous vraiment supprimer ce pointage ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiPointage.deletePointage(widget.token, id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pointage supprimé avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPointages();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur suppression : $e")),
        );
      }
    }
  }

  Future<void> _modifierPointage(Map<String, dynamic> pointage) async {
    final entreeCtrl = TextEditingController(
        text: pointage['check_in']?.substring(11, 16) ?? '');
    final sortieCtrl = TextEditingController(
        text: pointage['check_out']?.substring(11, 16) ?? '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Modifier le pointage"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField("Heure d'entrée (HH:MM)", entreeCtrl, Icons.login),
            const SizedBox(height: 10),
            _inputField("Heure de sortie (HH:MM)", sortieCtrl, Icons.logout),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiPointage.updatePointage(
          widget.token,
          pointage['id'],
          entreeCtrl.text,
          sortieCtrl.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pointage mis à jour avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPointages();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur : $e")));
      } finally {
        entreeCtrl.dispose();
        sortieCtrl.dispose();
      }
    }
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryDark),
        filled: true,
        fillColor: kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Gestion du Pointage",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: kPrimaryDark),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPointages,
              child: _pointages.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun pointage disponible",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pointages.length,
                      itemBuilder: (context, index) {
                        final p = _pointages[index];
                        final username = p['username'] ?? '-';
                        final date = p['date'] ?? '-';
                        final entree = p['check_in'] ?? '-';
                        final sortie = p['check_out'] ?? '-';

                        final entreeAff = entree != '-' && entree.length >= 16
                            ? entree.substring(11, 16)
                            : "-";
                        final sortieAff = sortie != '-' && sortie.length >= 16
                            ? sortie.substring(11, 16)
                            : "-";

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryDark,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _timeBadge("Entrée", entreeAff, Colors.green),
                                    _timeBadge("Sortie", sortieAff, Colors.blue),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.orange),
                                      onPressed: () => _modifierPointage(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _supprimerPointage(p['id']),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _timeBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: color),
          const SizedBox(width: 6),
          Text("$label : ",
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
