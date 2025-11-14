import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/admin/apport_details_page.dart';
import '../services/api_rapport.dart';

class AdminRapport extends StatefulWidget {
  final String token;
  final String username;

  const AdminRapport({
    Key? key,
    required this.token,
    required this.username,
  }) : super(key: key);

  @override
  State<AdminRapport> createState() => _AdminRapportState();
}

class _AdminRapportState extends State<AdminRapport> {
  bool _loading = true;
  List rapports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerRapports();
  }

  /// 🔹 Charge les rapports depuis le backend
  Future<void> _chargerRapports() async {
    try {
      final data = await ApiRapport.listerRapports(widget.token);
      setState(() {
        rapports = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur : $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "📊 Tous les rapports",
          style: TextStyle(
            color: Color(0xFF111184),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF111184)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : rapports.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun rapport trouvé.",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _chargerRapports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rapports.length,
                        itemBuilder: (context, index) {
                          final rapport = rapports[index];
                          final titre = rapport['titre'] ?? 'Sans titre';
                          final info = rapport['informations'] ?? '';
                          final date = rapport['date'] ?? '';
                          final heure = rapport['heure'] ?? '';

                          // ✅ Gestion du nom de l’auteur
                          final userField = rapport['user'];
                          String auteur = 'Utilisateur inconnu';
                          if (userField is Map && userField['username'] != null) {
                            auteur = userField['username'];
                          } else if (rapport['username'] != null) {
                            auteur = rapport['username'];
                          } else if (userField is int) {
                            auteur = "User #$userField";
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RapportDetailsPage(
                                    rapport: rapport,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.description_outlined,
                                            color: Color(0xFF1565C0)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            titre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      info.isNotEmpty
                                          ? info
                                          : "Aucune information disponible.",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "👤 $auteur",
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 13),
                                        ),
                                        Text(
                                          "📅 $date   🕒 $heure",
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
