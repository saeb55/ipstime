import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'api_service.dart';
import 'home_user.dart';
import 'home_admin.dart';
import 'home_supervision.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  bool _loading = false;
  bool _obscure = true;
  bool _biometricAvailable = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
    _checkBiometricAvailable();
  }

  Future<void> _checkBiometricAvailable() async {
    bool canCheck = await _auth.canCheckBiometrics;
    bool isSupported = await _auth.isDeviceSupported();
    String? enabled = await _storage.read(key: 'biometric_enabled');

    setState(() {
      _biometricAvailable = canCheck && isSupported && (enabled == 'true');
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// 🔐 Connexion classique
  Future<void> _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await _api.login(username, password);
      final token = data['token'];
      final userType = data['user_type'];

      // 🧬 Sauvegarde token + nom utilisateur pour la biométrie
      await _storage.write(key: 'refresh_token', value: token);
      await _storage.write(key: 'username', value: username);

      _navigateToHome(userType, token, username);
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🧬 Connexion biométrique
  Future<void> _loginWithBiometric() async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Connectez-vous avec votre empreinte digitale',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) return;

      final token = await _storage.read(key: 'refresh_token');
      final username = await _storage.read(key: 'username');

      if (token == null || username == null) {
        _showError("Aucune empreinte enregistrée. Activez la biométrie d’abord.");
        return;
      }

      // ✅ Connexion directe
      _navigateToHome("user", token, username);
    } catch (e) {
      _showError("Erreur biométrique : ${e.toString()}");
    }
  }

  /// 🏠 Redirection selon le type d'utilisateur
  void _navigateToHome(String userType, String token, String username) {
    Widget dest;
    if (userType == 'admin') {
      dest = HomeAdmin(token: token, username: username);
    } else if (userType == 'superuser') {
      dest = HomeSupervision(token: token, username: username);
    } else {
      dest = HomeUser(token: token, username: username);
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Erreur de connexion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', width: size.width * 0.4),
                  const SizedBox(height: 28),

                  const Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  // 🧭 Formulaire principal
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: Colors.blue.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _userCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 🔵 Bouton principal
                          _loading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                          // 🧬 Bouton biométrique professionnel
                          if (_biometricAvailable)
                            Column(
                              children: [
                                const SizedBox(height: 25),
                                const Text(
                                  "Ou connectez-vous avec votre empreinte",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _loginWithBiometric,
                                  borderRadius: BorderRadius.circular(60),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2F6EDB),
                                          Color(0xFF9EC7FF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _loginWithBiometric,
                                  child: const Text(
                                    "Connexion biométrique",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 👤 Comptes tests
                  Text(
                    'Comptes tests :',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'utilisateur / utilisateur → Employé\n'
                    'admin / admin → Admin\n'
                    'super / super → Supervision',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
