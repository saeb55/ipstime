import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiMailService {
  // Point d'entrée de ton API mail
  final String baseUrl = 'http://10.197.52.93:8000/api/mail';

  /// 🔹 Envoie un email via le backend Django
  Future<bool> sendMail({
    required String token,
    required String destinataire,
    required String sujet,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/send-report-reply/');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };

    final body = jsonEncode({
      'to': destinataire,  // ✅ correspond exactement à ton backend
      'subject': sujet,
      'message': message,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Email envoyé avec succès au backend Django.");
        return true;
      } else {
        print("❌ Erreur backend (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Erreur réseau / serveur : $e");
      return false;
    }
  }
}
