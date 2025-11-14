import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/qr_scan_page.dart';
import 'package:flutter_complete_demo/services/api_auto.dart';
import 'package:flutter_complete_demo/services/api_conge.dart';
import 'package:flutter_complete_demo/user/notification_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_complete_demo/chatbot_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'user/compte_page.dart';
import 'user/conge_page.dart';
import 'user/autorisation_page.dart';
import 'user/pointage_page.dart';
import 'user/parametres_page.dart';
import 'user/rapport_page.dart';


class HomeUser extends StatefulWidget {
  final String token;
  final String username;

  const HomeUser({
    required this.token,
    required this.username,
    Key? key,
  }) : super(key: key);

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _welcomeShown = false;
int _notifCount = 3; // 🔢 Exemple initial (le compteur de notifications)

  static const Color kPrimaryDark = Color(0xFF111184);
  static const double kRadius = 18;

  final String apiUrl = "http://10.197.52.93:8000/api/user";

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final res = await http.get(
      Uri.parse('$apiUrl/user_info/'),
      headers: {'Authorization': 'Token ${widget.token}'},
    );

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les informations utilisateur');
    }
    return json.decode(res.body);
  }

  Future<List<Map<String, dynamic>>> fetchPauses() async {
    final res = await http.get(
      Uri.parse('$apiUrl/pauses/'),
      headers: {'Authorization': 'Token ${widget.token}'},
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement pauses');
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  }

  Future<List<Map<String, dynamic>>> fetchPointages() async {
    final res = await http.get(
      Uri.parse('$apiUrl/pointages/'),
      headers: {'Authorization': 'Token ${widget.token}'},
    );
    if (res.statusCode != 200) throw Exception('Erreur chargement pointages');
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  }

  List<DateTime> getNext14Days() {
    final days = <DateTime>[];
    var date = DateTime.now().add(const Duration(days: 1));
    while (days.length < 14) {
      if (date.weekday != DateTime.sunday) days.add(date);
      date = date.add(const Duration(days: 1));
    }
    return days;
  }

  String formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String dayName(DateTime d) {
    const names = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche"
    ];
    return names[d.weekday - 1];
  }

  Widget _sectionHeader(String title, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: kPrimaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 20),
          if (icon != null) const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- Drawer utilisateur (version professionnelle avec photo réelle) ---
ListTile _drawerItem(IconData icon, String title, Color color, VoidCallback onTap) {
  return ListTile(
    leading: Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: color, size: 24),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    onTap: onTap,
  );
}

Drawer _buildDrawer(Map<String, dynamic>? user) {
  final String realUsername = user?['username']?.toString() ?? widget.username;
  final String? email = user?['email'] ?? 'Email inconnu';

  return Drawer(
    elevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: Column(
      children: [
        // --- En-tête bleu avec photo réelle + infos utilisateur ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2F6EDB), Color(0xFF4BA3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              FutureBuilder<String?>(
                future: SharedPreferences.getInstance()
                    .then((prefs) => prefs.getString('userProfileImage')),
                builder: (context, snapshot) {
                  final profileImage = snapshot.data;
                  return CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage: (profileImage != null &&
                            profileImage.isNotEmpty)
                        ? NetworkImage(profileImage)
                        : null,
                    child: (profileImage == null || profileImage.isEmpty)
                        ? const Icon(Icons.person,
                            size: 48, color: Color(0xFF111184))
                        : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                realUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Utilisateur",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Liste des options du menu ---
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _drawerItem(
                Icons.account_circle,
                "Compte",
                Colors.indigo,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComptePage(token: widget.token),
                  ),
                ),
              ),
              _drawerItem(
                Icons.event_available,
                "Congés",
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CongePage(
                      token: widget.token,
                      username: realUsername,
                    ),
                  ),
                ),
              ),
              _drawerItem(
                Icons.lock,
                "Autorisations",
                Colors.blueAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutorisationPage(
                      token: widget.token,
                      username: realUsername,
                    ),
                  ),
                ),
              ),
              _drawerItem(
                Icons.access_time_filled,
                "Pointages",
                Colors.cyan,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PointagePage(token: widget.token),
                  ),
                ),
              ),
              _drawerItem(
                Icons.bar_chart_rounded,
                "Rapports",
                Colors.deepPurpleAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RapportPage(token: widget.token),
                  ),
                ),
              ),
              _drawerItem(
                Icons.settings,
                "Paramètres",
                Colors.grey,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParametresPage(token: widget.token),
                  ),
                ),
              ),
              const Divider(),
              _drawerItem(
                Icons.exit_to_app_rounded,
                "Déconnexion",
                Colors.redAccent,
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // 🌟 --- UI principale --- 🌟
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserInfo(),
        builder: (context, snap) => _buildDrawer(snap.data),
      ),
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
floatingActionButton: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 🔔 Notifications
        FutureBuilder(
          future: Future.wait([
            ApiConge.listerConges(widget.token),
            ApiAuto.getAutorisations(widget.token),
          ]),
          builder: (context, snapshot) {
            int treatedCount = 0;
            if (snapshot.hasData) {
              final conges = snapshot.data![0] as List;
              final autos = snapshot.data![1] as List;

              treatedCount = [
                ...conges.where((c) =>
                    c['username'] == widget.username &&
                    (c['accepted'] == true || c['accepted'] == false)),
                ...autos.where((a) =>
                    a['username'] == widget.username &&
                    (a['accepted'] == true || a['accepted'] == false)),
              ].length;
            }

            return _buildFABIcon(
              icon: Icons.notifications,
              color: Colors.deepOrangeAccent,
              badgeCount: treatedCount,
              tooltip: "Notifications",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationPage(
                      token: widget.token,
                      username: widget.username,
                    ),
                  ),
                );
              },
            );
          },
        ),
 // 📱 QR Scanner (remplace Messages)
        _buildFABIcon(
          icon: Icons.qr_code_2_rounded,
          color: Colors.teal,
          tooltip: "Scanner QR",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrScanPage(token: widget.token),
              ),
            );
          },
        ),

        
        // 🤖 Chatbot
        _buildFABIcon(
          icon: Icons.smart_toy_rounded,
          color: Colors.purpleAccent,
          tooltip: "Chatbot IA",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotPage()),
            );
          },
        ),

        // ☰ Menu
        _buildFABIcon(
          icon: Icons.menu,
          color: kPrimaryDark,
          tooltip: "Menu principal",
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    ),
  ),
),





      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: fetchUserInfo(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Center(
                    child: Text('Erreur de chargement des informations'));
              }
              final user = userSnapshot.data!;

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // ==== En-tête utilisateur ====
                  Card(
  elevation: 12,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kRadius),
  ),
  clipBehavior: Clip.antiAlias,
  child: Container(
    decoration: BoxDecoration(
      // 🎨 Même dégradé que le Drawer
      gradient: const LinearGradient(
        colors: [
          Color(0xFF9EC7FF), // Bleu clair du Drawer
          Color(0xFF2F6EDB), // Bleu foncé du Drawer
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(kRadius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2F6EDB).withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.all(24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 👔 Section gauche : infos employé
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icône professionnelle stylisée (bleue comme tableau pointages)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.business_center_rounded,
                    color: Color(0xFF111184), // 💙 même bleu que tableau pointages
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  "Bonjour,\n${user['first_name'] ?? user['username'] ?? 'Employé'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Matricule : ${user['matricule'] ?? 'N/A'}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tickets : ${user['tickets_restaurant'] ?? '0'}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),

        // 👋 Emoji avec effet métallique animé
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.2),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: ShaderMask(
                shaderCallback: (bounds) => const RadialGradient(
                  colors: [
                    Color(0xFFE0E0E0),
                    Color(0xFFB0B0B0),
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ).createShader(bounds),
                child: const Text(
                  "👋",
                  style: TextStyle(
                    fontSize: 52,
                    shadows: [
                      Shadow(
                        color: Colors.white70,
                        blurRadius: 30,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) setState(() {});
            });
          },
        ),
      ],
    ),
  ),
),

                  const SizedBox(height: 20),

                  // ==== Tableau des Pauses ==== (version moderne)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchPauses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child:
                                Text('Erreur de chargement des pauses'));
                      }
                      final pauses = snapshot.data ?? [];
                      if (pauses.isEmpty) {
                        return _buildEmptyCard(
                            "Aucune pause trouvée", Icons.coffee);
                      }

                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(kRadius)),
                        shadowColor: Colors.blue.withOpacity(0.2),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader("Vos Pauses",
                                icon: Icons.coffee),
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: pauses.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final p = pauses[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.blue.shade50,
                                    child: const Icon(
                                        Icons.free_breakfast,
                                        color: kPrimaryDark),
                                  ),
                                  title: Text(
                                    p['nom'] ?? 'Pause',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryDark),
                                  ),
                                  subtitle: Text(
                                    "Restantes : ${p['restantes'] ?? '-'} / Quota : ${p['quota'] ?? '-'}",
                                    style: const TextStyle(
                                        color: Colors.black54),
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      "${p['nombre'] ?? 0}",
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    backgroundColor:
                                        Colors.blueAccent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ==== Tableau des pointages ==== (modernisé)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchPointages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text(
                                'Erreur de chargement des pointages'));
                      }

                      final pointages = snapshot.data ?? [];
                      final days = getNext14Days();

                      if (pointages.isEmpty) {
                        return _buildEmptyCard("Aucun pointage trouvé",
                            Icons.calendar_today);
                      }

                      Map<String, dynamic>? findForDate(String date) {
                        return pointages.firstWhere(
                          (p) => p['date']?.startsWith(date) ?? false,
                          orElse: () => {},
                        );
                      }

                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(kRadius)),
                        shadowColor: Colors.blue.withOpacity(0.2),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _sectionHeader("Historique (14 derniers jours)",
                                icon: Icons.calendar_month),
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: days.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final d = days[index];
                                final date = formatDate(d);
                                final p = findForDate(date);

                                final debut =
                                    p?['debut'] ?? p?['start'] ?? '-';
                                final fin =
                                    p?['fin'] ?? p?['end'] ?? '-';
                                final isComplet =
                                    debut != '-' && fin != '-';

                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isComplet
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      isComplet
                                          ? Icons.check_circle
                                          : Icons.timelapse,
                                      color: isComplet
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    "${dayName(d)} - $date",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryDark),
                                  ),
                                  subtitle: Text(
                                    "Début : $debut   |   Fin : $fin",
                                    style: const TextStyle(
                                        color: Colors.black54),
                                  ),
                                  trailing: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isComplet
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isComplet
                                          ? "Complet"
                                          : "En cours",
                                      style: TextStyle(
                                        color: isComplet
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

 @override
void initState() {
  super.initState();
  // ✅ Désactivation du message de bienvenue animé et du rafraîchissement
  _welcomeShown = true;
}

  Widget _buildFABIcon({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  String? tooltip,
  int badgeCount = 0,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
      if (badgeCount > 0)
        Positioned(
          right: -2,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              badgeCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  );
}

}
