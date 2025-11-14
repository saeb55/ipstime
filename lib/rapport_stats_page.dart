import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_rapport.dart';

class RapportStatsPage extends StatefulWidget {
  final String token;

  const RapportStatsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<RapportStatsPage> createState() => _RapportStatsPageState();
}

class _RapportStatsPageState extends State<RapportStatsPage> {
  bool _loading = true;
  List rapports = [];
  int total = 0;
  int valides = 0;
  int refuses = 0;
  int enAttente = 0;

  static const Color kPrimaryDark = Color(0xFF0D47A1);
  static const Color kPrimaryLight = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _chargerRapports();
  }

  Future<void> _chargerRapports() async {
    try {
      final data = await ApiRapport.listerRapports(widget.token);
      setState(() {
        rapports = data;
        total = data.length;
        valides = data.where((r) => r['status'] == 'validé').length;
        refuses = data.where((r) => r['status'] == 'refusé').length;
        enAttente = data.where((r) => r['status'] == 'en attente').length;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Erreur chargement rapports : $e");
      setState(() => _loading = false);
    }
  }

  double _tauxValidation() {
    if (total == 0) return 0;
    return (valides / total) * 100;
  }

  double _tauxRefus() {
    if (total == 0) return 0;
    return (refuses / total) * 100;
  }

  double _tauxEnAttente() {
    if (total == 0) return 0;
    return (enAttente / total) * 100;
  }

  // 🎨 Couleur selon le statut
  Color _statusColor(String status) {
    switch (status) {
      case 'validé':
        return Colors.green;
      case 'refusé':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "📊 Tableau de bord des rapports",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerRapports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildPieChart(),
                    const SizedBox(height: 25),
                    const Text(
                      "📋 Liste des rapports",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildList(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 🔹 Petites cartes statistiques
  Widget _buildStatCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCard("Total", "$total", Colors.blueAccent),
        _buildCard("Validés", "$valides", Colors.green),
        _buildCard("Refusés", "$refuses", Colors.redAccent),
        _buildCard("En attente", "$enAttente", Colors.orange),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 Graphique circulaire
  Widget _buildPieChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Répartition des statuts",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: PieChart(
              PieChartData(
                borderData: FlBorderData(show: false),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: valides.toDouble(),
                    title: "$valides",
                    radius: 60,
                  ),
                  PieChartSectionData(
                    color: Colors.redAccent,
                    value: refuses.toDouble(),
                    title: "$refuses",
                    radius: 60,
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: enAttente.toDouble(),
                    title: "$enAttente",
                    radius: 60,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Taux de validation : ${_tauxValidation().toStringAsFixed(1)}% • Refus : ${_tauxRefus().toStringAsFixed(1)}% • En attente : ${_tauxEnAttente().toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des rapports
  Widget _buildList() {
    if (rapports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            "Aucun rapport disponible.",
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rapports.length,
      itemBuilder: (context, i) {
        final r = rapports[i];
        final status = r['status'] ?? 'en attente';
        final color = _statusColor(status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 24,
              child: Icon(
                status == 'validé'
                    ? Icons.check_circle
                    : status == 'refusé'
                        ? Icons.cancel
                        : Icons.hourglass_bottom,
                color: color,
                size: 26,
              ),
            ),
            title: Text(
              r['titre'] ?? 'Sans titre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Auteur : ${r['username'] ?? 'Inconnu'}",
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.3),
                ),
                Text(
                  "Date : ${r['date'] ?? ''} • Heure : ${r['heure'] ?? ''}",
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45, height: 1.2),
                ),
                if (r['commentaire'] != null && r['commentaire'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "💬 Commentaire : ${r['commentaire']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
