import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../services/api_pointage.dart';

class QrScanPage extends StatefulWidget {
  final String token; // ✅ Reçoit le token utilisateur
  const QrScanPage({Key? key, required this.token}) : super(key: key);

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;
  bool _processing = false;
  bool _flashOn = false;

  int? _dernierPointageId;

  static const Color kPrimaryDark = Color(0xFF111184);
  static const Color kPrimaryLight = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _fetchDernierPointage();
  }

  Future<void> _fetchDernierPointage() async {
    try {
      final pointages = await ApiPointage.fetchPointages(widget.token);
      if (pointages.isNotEmpty) {
        setState(() => _dernierPointageId = pointages.first['id']);
      }
    } catch (e) {
      debugPrint("⚠️ Erreur récupération ID dernier pointage : $e");
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) controller?.pauseCamera();
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) async {
      if (_processing) return;
      setState(() {
        _processing = true;
        qrText = scanData.code;
      });

      controller?.pauseCamera(); // ✅ Empêche les doubles lectures
      HapticFeedback.mediumImpact();

      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm:ss').format(now);

      try {
        if (qrText != null) {
          if (qrText!.toUpperCase().contains("ENTREE")) {
            await _ajouterEntree(formattedTime);
          } else if (qrText!.toUpperCase().contains("SORTIE")) {
            await _ajouterSortie(formattedTime);
          } else {
            _showOverlay("❌ QR invalide", success: false);
          }
        }
      } catch (e) {
        _showOverlay("Erreur réseau, réessaie plus tard", success: false);
        debugPrint("Erreur traitement QR : $e");
      }

      controller?.resumeCamera();
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _processing = false);
    });
  }

  Future<void> _ajouterEntree(String heure) async {
    try {
      final res = await ApiPointage.ajouterEntree(widget.token, heure);
      if (res["success"] == true) {
        _showOverlay("✅ Entrée enregistrée à $heure", success: true);
        await _fetchDernierPointage();
      } else {
        _showOverlay("❌ ${res['message'] ?? 'Erreur inconnue'}", success: false);
      }
    } catch (e) {
      _showOverlay("Erreur réseau lors de l’entrée", success: false);
    }
  }

  Future<void> _ajouterSortie(String heure) async {
    try {
      if (_dernierPointageId == null) {
        await _fetchDernierPointage();
      }

      if (_dernierPointageId == null) {
        _showOverlay("⚠️ Aucun pointage d'entrée trouvé", success: false);
        return;
      }

      final res =
          await ApiPointage.ajouterSortie(widget.token, _dernierPointageId!, heure);

      if (res["success"] == true) {
        _showOverlay("🚪 Sortie enregistrée à $heure", success: true);
      } else {
        _showOverlay("❌ ${res['message'] ?? 'Erreur inconnue'}", success: false);
      }
    } catch (e) {
      _showOverlay("Erreur réseau lors de la sortie", success: false);
    }
  }

  void _showOverlay(String message, {bool success = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 40,
        right: 40,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: success ? Colors.green : Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3)).then((_) => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryDark),
        title: const Text(
          "Scanner pour Pointage",
          style: TextStyle(
            color: kPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: kPrimaryLight,
                    borderRadius: 12,
                    borderLength: 40,
                    borderWidth: 8,
                    cutOutSize: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    qrText ?? "Scannez un QR pour marquer l’entrée ou la sortie",
                    style: const TextStyle(
                      fontSize: 16,
                      color: kPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // 🔦 Bouton pour activer / désactiver la lampe
                  IconButton(
                    icon: Icon(
                      _flashOn ? Icons.flash_off_rounded : Icons.flash_on_rounded,
                      color: kPrimaryLight,
                      size: 28,
                    ),
                    onPressed: () async {
                      await controller?.toggleFlash();
                      setState(() => _flashOn = !_flashOn);
                    },
                    tooltip: _flashOn ? "Éteindre lampe" : "Allumer lampe",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
