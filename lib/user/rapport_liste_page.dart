import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_rapport.dart';

class RapportListePage extends StatefulWidget {
  final String token;

  const RapportListePage({Key? key, required this.token}) : super(key: key);

  @override
  State<RapportListePage> createState() => _RapportListePageState();
}

class _RapportListePageState extends State<RapportListePage> {
  bool _loading = true;
  List rapports = []; // ✅ type générique pour éviter erreur de cast

  @override
  void initState() {
    super.initState();
    _chargerRapports();
  }

  /// 🔹 Charger les rapports depuis l’API
  Future<void> _chargerRapports() async {
    setState(() => _loading = true);
    try {
      final data = await ApiRapport.listerRapports(widget.token);
      setState(() {
        rapports = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Erreur lors du chargement : $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📋 Mes rapports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerRapports,
              child: rapports.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          "Aucun rapport trouvé.",
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: rapports.length,
                      itemBuilder: (context, i) {
                        final r = rapports[i];
                        final titre = r['titre'] ?? 'Sans titre';
                        final info = r['informations'] ?? 'Aucune information';
                        final date = r['date'] ?? '';
                        final heure = r['heure'] ?? '';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.description_outlined,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  info,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.black45),
                                    const SizedBox(width: 5),
                                    Text(
                                      date.isNotEmpty
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(DateTime.parse(date))
                                          : '-',
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.black45),
                                    const SizedBox(width: 5),
                                    Text(
                                      heure.isNotEmpty ? heure : "-",
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
