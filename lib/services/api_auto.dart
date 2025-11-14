import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiAuto {
static const String baseUrl = 'http://10.197.52.93:8000/api/autorisation';

  // ➕ Ajouter une autorisation
  static Future<bool> ajouterAutorisation(
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
      print("✅ Autorisation ajoutée avec succès !");
      return true;
    } else {
      print("❌ Erreur lors de l'ajout de l'autorisation : ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // 📋 Lister toutes les autorisations
  static Future<List<Map<String, dynamic>>> getAutorisations(String token) async {
    final url = Uri.parse('$baseUrl/lister/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Autorisations récupérées avec succès !");
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      print("❌ Erreur lors de la récupération : ${response.statusCode} - ${response.body}");
      throw Exception("Erreur API: ${response.body}");
    }
  }

  // ✏️ Modifier une autorisation (acceptée ou refusée)
  static Future<bool> updateAutorisation(
      String token, int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/modifier/$id/');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      print("✅ Autorisation modifiée avec succès !");
      return true;
    } else {
      print("❌ Erreur lors de la modification : ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // 🗑 Supprimer une autorisation
  static Future<bool> supprimerAutorisation(int id, String token) async {
    final url = Uri.parse('$baseUrl/supprimer/$id/');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      print("✅ Autorisation supprimée avec succès !");
      return true;
    } else {
      print("❌ Erreur lors de la suppression : ${response.statusCode} - ${response.body}");
      return false;
    }
  }
}
