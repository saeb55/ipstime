import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/admin/admin_autorisation.dart';
import 'package:flutter_complete_demo/admin/admin_conge.dart';
import 'package:flutter_complete_demo/admin/admin_parametres.dart';
import 'package:flutter_complete_demo/admin/admin_pointage.dart';
import '../login_page.dart';
import '../services/api_auto.dart';
import '../services/api_conge.dart';
import 'package:flutter_complete_demo/admin/admin_rapport.dart';

class HomeAdmin extends StatefulWidget {
  final String token;
  final String username;

  const HomeAdmin({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  List<Map<String, dynamic>> autorisationsAcceptees = [];
  List<Map<String, dynamic>> congesAcceptees = [];

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final autorisations = await ApiAuto.getAutorisations(widget.token);
      final conges = await ApiConge.listerConges(widget.token) ?? [];

      setState(() {
        autorisationsAcceptees =
            autorisations.where((a) => a['accepted'] == true).toList();
        congesAcceptees =
            conges.where((c) => c['accepted'] == true).toList();
      });
    } catch (e) {
      print("Erreur chargement HomeAdmin: $e");
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded,
                  color: Color(0xFF1565C0), size: 48),
              const SizedBox(height: 14),
              const Text(
                "Déconnexion",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF111184)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Souhaitez-vous vraiment vous déconnecter ?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: const Text("Annuler"),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: const Text("Se déconnecter",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF111184);
    final double totalAutorisations = autorisationsAcceptees.length.toDouble();
    final double totalConges = congesAcceptees.length.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea( // ✅ protège du notch/caméra
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15), // ✅ espace ajouté avant le header

                // 🟦 En-tête bleu descendu légèrement
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 50),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Bienvenue sur l’administration",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Gérez les congés, autorisations et rapports des employés.",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Cartes résumé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      icon: Icons.assignment_turned_in,
                      title: "Autorisations",
                      value: totalAutorisations.toInt().toString(),
                      color: Colors.indigo,
                    ),
                    _buildStatCard(
                      icon: Icons.time_to_leave,
                      title: "Congés",
                      value: totalConges.toInt().toString(),
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Accès rapide",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.assignment,
                      label: "Autorisations",
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminAutorisation(
                              token: widget.token, username: 'Admin'),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.time_to_leave,
                      label: "Congés",
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminConge(
                              token: widget.token, username: 'Admin'),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.fingerprint,
                      label: "Pointage",
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminPointage(token: widget.token)),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.bar_chart_rounded,
                      label: "Rapports",
                      color: Colors.indigoAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminRapport(
                            token: widget.token,
                            username: widget.username,
                          ),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.settings,
                      label: "Paramètres",
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AdminParametres(token: widget.token)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  "Dernières validations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _buildRecentList("Autorisations", autorisationsAcceptees, true),
                const SizedBox(height: 10),
                _buildRecentList("Congés", congesAcceptees, false),
              ],
            ),
          ),
        ),
      ),

      // ✅ barre inférieure inchangée
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Admin connecté",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text("Se déconnecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryLight,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList(
      String title, List<Map<String, dynamic>> items, bool isAuto) {
    if (items.isEmpty) {
      return Text("Aucun $title accepté récemment.",
          style: const TextStyle(color: Colors.black54));
    }

    return Column(
      children: items.take(3).map((item) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(
              isAuto ? Icons.assignment_turned_in : Icons.time_to_leave,
              color: isAuto ? Colors.blueAccent : Colors.green,
            ),
            title: Text(item['username'] ?? 'Inconnu',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              isAuto
                  ? "Type : ${item['type'] ?? '—'}"
                  : "Cause : ${item['cause'] ?? '—'}",
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      }).toList(),
    );
  }
}
