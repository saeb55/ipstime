import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RapportDetailPage extends StatelessWidget {
  final Map<String, dynamic> rapport;
  final String token;
  final Future<void> Function() onRefresh;

  const RapportDetailPage({
    Key? key,
    required this.rapport,
    required this.token,
    required this.onRefresh,
  }) : super(key: key);

  static const Color kPrimaryDark = Color(0xFF0D47A1);
  static const Color kPrimaryLight = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    final titre = rapport['titre'] ?? 'Sans titre';
    final infos = rapport['informations'] ?? 'Aucune information disponible';
    final date = rapport['date'] ?? '';
    final heure = rapport['heure'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "📄 Détail du rapport",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF4F8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧾 Titre
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark,
                  ),
                ),
                const SizedBox(height: 16),

                // 📅 Date et heure
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: kPrimaryLight, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      date.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(date))
                          : "-",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.access_time,
                        color: kPrimaryLight, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      heure.isNotEmpty ? heure : "-",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 📝 Informations
                const Text(
                  "📝 Détails du rapport :",
                  style: TextStyle(
                    color: kPrimaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  infos,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // 🔙 Bouton retour
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onRefresh();
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      "Retour à la liste",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
