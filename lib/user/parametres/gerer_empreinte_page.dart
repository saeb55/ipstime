import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class GererEmpreintePage extends StatefulWidget {
  final String token;
  const GererEmpreintePage({super.key, required this.token});

  @override
  State<GererEmpreintePage> createState() => _GererEmpreintePageState();
}

class _GererEmpreintePageState extends State<GererEmpreintePage> {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _biometricEnabled = false;
  bool _checkingSupport = true;
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _loadBiometricStatus();
  }

  Future<void> _checkSupport() async {
    bool canCheck = await _auth.canCheckBiometrics;
    bool isDeviceSupported = await _auth.isDeviceSupported();
    setState(() {
      _supported = canCheck && isDeviceSupported;
      _checkingSupport = false;
    });
  }

  Future<void> _loadBiometricStatus() async {
    String? enabled = await _storage.read(key: 'biometric_enabled');
    setState(() {
      _biometricEnabled = enabled == 'true';
    });
  }

  Future<void> _toggleBiometric() async {
    if (!_supported) {
      _showMessage("Ce dispositif ne supporte pas la biométrie.");
      return;
    }

    if (!_biometricEnabled) {
      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Confirmez pour activer la connexion biométrique',
      );

      if (didAuthenticate) {
        await _storage.write(key: 'biometric_enabled', value: 'true');
        await _storage.write(key: 'refresh_token', value: widget.token);
        setState(() => _biometricEnabled = true);
        _showMessage("Connexion biométrique activée ✅");
      }
    } else {
      await _storage.delete(key: 'biometric_enabled');
      await _storage.delete(key: 'refresh_token');
      setState(() => _biometricEnabled = false);
      _showMessage("Connexion biométrique désactivée ❌");
    }
  }

  Future<void> _testBiometric() async {
    if (!_biometricEnabled) {
      _showMessage("Activez d’abord la biométrie.");
      return;
    }

    bool didAuthenticate = await _auth.authenticate(
      localizedReason: 'Testez votre empreinte ou Face ID',
    );

    if (didAuthenticate) {
      _showMessage("Empreinte reconnue 👌");
    } else {
      _showMessage("Échec de l’authentification ❌");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSupport) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer la connexion biométrique"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Connexion par empreinte / Face ID",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                Switch(
                  activeColor: Colors.green,
                  value: _biometricEnabled,
                  onChanged: (_) => _toggleBiometric(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (!_supported)
              const Text(
                "⚠️ La biométrie n’est pas disponible sur cet appareil.",
                style: TextStyle(color: Colors.redAccent, fontSize: 15),
              ),
            if (_supported)
              Column(
                children: [
                  const Text(
                    "Une fois activée, vous pourrez vous reconnecter sans mot de passe, "
                    "grâce à votre empreinte digitale ou Face ID.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _testBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text("Tester la biométrie"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
