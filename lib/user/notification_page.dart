import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Ajout obligatoire
import '../services/api_conge.dart';
import '../services/api_auto.dart';

class NotificationPage extends StatefulWidget {
  final String token;
  final String username;

  const NotificationPage({
    Key? key,
    required this.token,
    required this.username,
  }) : super(key: key);

  static const Color kPrimaryDark = Color(0xFF111184);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ Initialisation des formats de date pour le français avant de charger les notifications
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final conges = await ApiConge.listerConges(widget.token);
      final autos = await ApiAuto.getAutorisations(widget.token);

      final List<Map<String, dynamic>> all = [];

      // 🔹 Filtrer les congés du user connecté
      for (var c in conges) {
        if (c['username'] == widget.username &&
            (c['accepted'] == true || c['accepted'] == false)) {
          final accepted = c['accepted'] == true;
          final status = accepted ? "accepté" : "refusé";
          final color = accepted ? Colors.green.shade50 : Colors.red.shade50;
          all.add({
            "title": "Demande de congé $status",
            "message": accepted
                ? "Votre demande de congé du ${c['date_debut']} au ${c['date_fin']} a été approuvée par le service RH."
                : "Votre demande de congé du ${c['date_debut']} au ${c['date_fin']} a été refusée par l'administration.",
            "time": DateTime.tryParse(c['date_debut'] ?? "") ?? DateTime.now(),
            "color": color,
            "accepted": accepted,
          });
        }
      }

      // 🔹 Filtrer les autorisations du user connecté
      for (var a in autos) {
        if (a['username'] == widget.username &&
            (a['accepted'] == true || a['accepted'] == false)) {
          final accepted = a['accepted'] == true;
          final status = accepted ? "acceptée" : "refusée";
          final color = accepted ? Colors.green.shade50 : Colors.red.shade50;
          all.add({
            "title": "Autorisation $status",
            "message": accepted
                ? "Votre autorisation du ${a['date_debut']} au ${a['date_fin']} a été validée par le service RH."
                : "Votre autorisation du ${a['date_debut']} au ${a['date_fin']} a été refusée par l'administration.",
            "time": DateTime.tryParse(a['date_debut'] ?? "") ?? DateTime.now(),
            "color": color,
            "accepted": accepted,
          });
        }
      }

      // 🔸 Trier par date décroissante
      all.sort((a, b) => b['time'].compareTo(a['time']));

      setState(() {
        _notifications = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement : $e")),
      );
    }
  }

  String _formatDate(DateTime date) {
    // ✅ Format de date française
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: NotificationPage.kPrimaryDark),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: NotificationPage.kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    "📭 Aucune notification disponible",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return Card(
                      color: n["color"],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          n["accepted"]
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: n["accepted"]
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          size: 34,
                        ),
                        title: Text(
                          n["title"],
                          style: const TextStyle(
                            color: NotificationPage.kPrimaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${n["message"]}\n📅 ${_formatDate(n["time"])}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
