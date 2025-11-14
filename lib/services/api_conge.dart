import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConge {
  // Base URL pour tous les endpoints congé
static const String baseUrl = 'http://10.197.52.93:8000/api/conge';

  // ➕ Ajouter un congé
  static Future<bool> ajouterConge(
      Map<String, dynamic> data, String token, String username) async {
    data['username'] = username; // Ajouter le username
    final url = Uri.parse('$baseUrl/ajouter/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      print("✅ Congé ajouté avec succès !");
      return true;
    } else {
      print(
          "❌ Erreur lors de l'ajout du congé : ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // 📋 Lister tous les congés
  static Future<List<Map<String, dynamic>>> listerConges(String token) async {
    final url = Uri.parse('$baseUrl/lister/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Congés récupérés avec succès !");
      final List<dynamic> body = json.decode(response.body);
      return body.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      print(
          "❌ Erreur lors de la récupération des congés : ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  // ✏️ Modifier un congé (accepté ou refusé)
  static Future<bool> modifierConge(
      int id, bool accepted, String token) async {
    final url = Uri.parse('$baseUrl/modifier/$id/');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'accepted': accepted}),
    );

    if (response.statusCode == 200) {
      print("✅ Congé modifié avec succès !");
      return true;
    } else {
      print(
          "❌ Erreur lors de la modification du congé : ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // 🗑 Supprimer un congé
  static Future<bool> supprimerConge(int id, String token) async {
    final url = Uri.parse('$baseUrl/supprimer/$id/');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      print("✅ Congé supprimé avec succès !");
      return true;
    } else {
      print(
          "❌ Erreur lors de la suppression du congé : ${response.statusCode} - ${response.body}");
      return false;
    }
  }
}
