import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_file/cross_file.dart';

// 🔹 Import de tes autres pages
import '../login_page.dart';
import 'parametres_page.dart';

class ComptePage extends StatefulWidget {
  final String token;

  const ComptePage({required this.token, Key? key}) : super(key: key);

  @override
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage>
    with SingleTickerProviderStateMixin {
  XFile? _pickedFile;
  String? _imageUrl;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  final String apiUrl = "http://10.197.52.93:8000/api/user";

  @override
  void initState() {
    super.initState();
    _loadImage();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ---- Récupération des infos utilisateur ----
  Future<Map<String, dynamic>> fetchUserInfo() async {
    final res = await http.get(
      Uri.parse('$apiUrl/user_info/'),
      headers: {'Authorization': 'Token ${widget.token}'},
    );

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger les informations utilisateur');
    }

    final data = json.decode(res.body);
    return data;
  }

  // ---- Upload de l'image ----
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _pickedFile = pickedFile);

      try {
        final uri = Uri.parse('$apiUrl/profile/upload/');
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Token ${widget.token}';

        request.files.add(await http.MultipartFile.fromBytes(
          'image',
          await pickedFile.readAsBytes(),
          filename: pickedFile.name,
        ));

        final response = await request.send();
        final respStr = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResp = json.decode(respStr);
          final newUrl = jsonResp['image_url'];

          if (newUrl != null) {
            setState(() => _imageUrl = newUrl);
            await _saveImageLocally(newUrl);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Photo mise à jour avec succès")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Erreur lors du téléchargement de l'image")),
          );
        }
      } catch (e) {
        debugPrint("Erreur upload image : $e");
      }
    }
  }

  Future<void> _saveImageLocally(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfileImage', imageUrl);
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imageUrl = prefs.getString('userProfileImage');
    });
  }

  ImageProvider<Object>? _getBackgroundImage() {
    try {
      if (_pickedFile != null && !kIsWeb) {
        final file = File(_pickedFile!.path);
        if (file.existsSync()) return FileImage(file);
      }
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        return NetworkImage(_imageUrl!);
      }
    } catch (e) {
      debugPrint('Erreur lecture image : $e');
    }
    return null;
  }

  // ---------------- INTERFACE ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mon Compte",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.8,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Erreur : ${snapshot.error}"),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Aucune donnée reçue"));
            }

            final user = snapshot.data!;
            final firstName = user['first_name'] ?? 'Non renseigné';
            final lastName = user['last_name'] ?? '';
            final email = user['email'] ?? '';
            final role = user['role'] ?? 'Employé';
            final matricule = user['matricule'] ?? '—';
            final department = user['department'] ?? '—';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ---- Carte profil ----
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9EC7FF), Color(0xFF2F6EDB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white.withOpacity(0.4),
                            backgroundImage: _getBackgroundImage(),
                            child: (_pickedFile == null &&
                                    (_imageUrl == null || _imageUrl!.isEmpty))
                                ? Icon(Icons.person,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.8))
                                : null,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Text(
                              (_pickedFile != null || _imageUrl != null)
                                  ? "Modifier la photo"
                                  : "Ajouter une photo",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$firstName $lastName",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---- Infos utilisateur ----
                    _infoCard(Icons.email_outlined, "Email", email),
                    _infoCard(Icons.badge_outlined, "Matricule", matricule),
                    _infoCard(Icons.apartment, "Département", department),
                    _infoCard(Icons.work_outline, "Rôle", role),

                    const SizedBox(height: 25),

                    // ---- Boutons fonctionnels ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 🔹 Bouton Paramètres
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ParametresPage(token: widget.token, ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          icon: const Icon(Icons.settings, color: Colors.white),
                          label: const Text(
                            "Paramètres",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),

                        // 🔹 Bouton Déconnexion
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Déconnexion",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16),
                          ),
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

  // ---------------- WIDGET CARTE INFO ----------------
  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: kPrimaryLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
