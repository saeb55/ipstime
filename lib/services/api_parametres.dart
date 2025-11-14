import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiParametres {
final String baseUrl = "http://10.197.52.93:8000/api/auth";

  Future<Map<String, dynamic>> changerMotDePasse(
      String token, String ancienMdp, String nouveauMdp, String confirmerMdp) async {
    final url = Uri.parse("$baseUrl/change-password/"); // ✅ cohérent avec ton backend

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token", // ✅ important
        },
        body: jsonEncode({
          "old_password": ancienMdp,
          "new_password": nouveauMdp,
          "confirm_password": confirmerMdp, // ✅ obligatoire pour ton backend
        }),
      );

      // ✅ Succès
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data["detail"] ?? "Mot de passe changé avec succès"
        };
      }

      // ❌ Gestion des erreurs backend
      try {
        final data = jsonDecode(response.body);
        return {
          "success": false,
          "message": data["detail"] ?? data.toString(),
        };
      } catch (_) {
        return {
          "success": false,
          "message": "Erreur ${response.statusCode}: ${response.reasonPhrase ?? 'Inconnue'}",
        };
      }
    } catch (e) {
      // ❌ Erreur réseau / parsing
      return {
        "success": false,
        "message": "Erreur de connexion au serveur : $e"
      };
    }
  }
}
