import 'package:flutter/material.dart';
import 'package:flutter_complete_demo/api_service.dart';
import 'package:flutter_complete_demo/home_admin.dart';

class AdminParametres extends StatefulWidget {
  final String token;
  const AdminParametres({super.key, required this.token});

  @override
  State<AdminParametres> createState() => _AdminParametresState();
}

class _AdminParametresState extends State<AdminParametres>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  List<dynamic> users = [];
  bool isLoading = true;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _loadUsers();
    _animCtrl.forward();
  }

  Future<void> _loadUsers() async {
    try {
      final data = await apiService.getUsers(widget.token);
      setState(() {
        users = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnack("Erreur lors du chargement : $e", Colors.redAccent);
    }
  }

  // 🧍 Ajouter un utilisateur
  void _addUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _buildUserDialog(
        title: "Ajouter un utilisateur",
        confirmText: "Ajouter",
        nameCtrl: nameCtrl,
        emailCtrl: emailCtrl,
        passCtrl: passCtrl,
        onConfirm: () async {
          try {
            await apiService.createUser(
              widget.token,
              nameCtrl.text.trim(),
              emailCtrl.text.trim(),
              passCtrl.text.trim(),
            );
            Navigator.pop(context);
            _loadUsers();
            _showSnack("✅ Utilisateur ajouté avec succès", Colors.green);
          } catch (e) {
            _showSnack("❌ Erreur : $e", Colors.redAccent);
          }
        },
      ),
    );
  }

  // ✏️ Modifier un utilisateur
  void _editUserDialog(int index) {
    final user = users[index];
    final nameCtrl = TextEditingController(text: user["username"]);
    final emailCtrl = TextEditingController(text: user["email"]);

    showDialog(
      context: context,
      builder: (context) => _buildUserDialog(
        title: "Modifier l'utilisateur",
        confirmText: "Sauvegarder",
        nameCtrl: nameCtrl,
        emailCtrl: emailCtrl,
        onConfirm: () async {
          try {
            await apiService.updateUser(widget.token, user["id"], {
              "username": nameCtrl.text,
              "email": emailCtrl.text,
            });
            Navigator.pop(context);
            _loadUsers();
            _showSnack("✅ Modifié avec succès", Colors.green);
          } catch (e) {
            _showSnack("❌ Erreur : $e", Colors.redAccent);
          }
        },
      ),
    );
  }

  // 🗑️ Supprimer un utilisateur
  void _deleteUser(int index) async {
    final user = users[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Supprimer l'utilisateur",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Voulez-vous vraiment supprimer ${user["username"]} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteUser(widget.token, user["id"]);
        _loadUsers();
        _showSnack("✅ Utilisateur supprimé", Colors.green);
      } catch (e) {
        _showSnack("❌ Erreur suppression : $e", Colors.redAccent);
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildUserDialog({
    required String title,
    required String confirmText,
    required TextEditingController nameCtrl,
    required TextEditingController emailCtrl,
    TextEditingController? passCtrl,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kPrimaryDark)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputField("Nom d’utilisateur", nameCtrl),
          const SizedBox(height: 10),
          _inputField("Adresse email", emailCtrl),
          if (passCtrl != null) ...[
            const SizedBox(height: 10),
            _inputField("Mot de passe", passCtrl, obscure: true),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kPrimaryLight, width: 2),
        ),
      ),
    );
  }

  // 🔙 Retour vers HomeAdmin au lieu du Login
  void _goBackToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeAdmin(
          token: widget.token,
          username: "Admin",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        title: const Text(
          "Gestion des utilisateurs",
          style: TextStyle(
              color: kPrimaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: kPrimaryDark,
          tooltip: "Retour",
          onPressed: _goBackToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kPrimaryLight),
            tooltip: "Actualiser",
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryLight,
        onPressed: _addUserDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryLight))
            : users.isEmpty
                ? const Center(
                    child: Text(
                      "Aucun utilisateur trouvé",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(Icons.people_alt_rounded,
                                  color: kPrimaryLight, size: 30),
                              Text(
                                "Liste des utilisateurs enregistrés",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryDark,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        kPrimaryLight.withOpacity(0.1),
                                    child: const Icon(Icons.person,
                                        color: kPrimaryLight),
                                  ),
                                  title: Text(
                                    user["username"] ?? "—",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    user["email"] ?? "—",
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 13),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orangeAccent),
                                        onPressed: () => _editUserDialog(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () => _deleteUser(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
