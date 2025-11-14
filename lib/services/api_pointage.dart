import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiPointage {
static const String baseUrl = "http://10.197.52.93:8000/api/pointage/";

  /// ✅ Ajouter un pointage (entrée)
  static Future<Map<String, dynamic>> ajouterEntree(
      String token, String heureEntree) async {
    final url = Uri.parse("${baseUrl}ajouter/");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
      body: jsonEncode({
        "check_in": heureEntree,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ ${data["message"] ?? "Entrée enregistrée"}");
      return {"success": true, "message": data["message"] ?? "Entrée enregistrée avec succès"};
    } else {
      print("❌ Erreur entrée : ${response.statusCode} - ${response.body}");
      return {"success": false, "message": "Erreur entrée (${response.statusCode})"};
    }
  }

  /// ✅ Ajouter une sortie
  static Future<Map<String, dynamic>> ajouterSortie(
      String token, int pointageId, String heureSortie) async {
    final url = Uri.parse("${baseUrl}modifier/$pointageId/");
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
      body: jsonEncode({
        "check_out": heureSortie,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("✅ ${data["message"] ?? "Sortie enregistrée"}");
      return {"success": true, "message": data["message"] ?? "Sortie enregistrée avec succès"};
    } else {
      print("❌ Erreur sortie : ${response.statusCode} - ${response.body}");
      return {"success": false, "message": "Erreur sortie (${response.statusCode})"};
    }
  }

  /// 📋 Lister les pointages de l'utilisateur
  static Future<List<Map<String, dynamic>>> fetchPointages(String token) async {
    final url = Uri.parse("${baseUrl}lister/");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception("Erreur récupération pointages : ${response.body}");
    }
  }

  /// 🧑‍💼 Lister tous les pointages (admin ou superviseur)
  static Future<List<Map<String, dynamic>>> fetchAllPointages(
      String token) async {
    final url = Uri.parse("${baseUrl}lister/");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception(
          "Erreur récupération pointages (admin) : ${response.body}");
    }
  }

  /// ✏️ Modifier un pointage (entrée et sortie)
  static Future<void> updatePointage(
      String token, int id, String heureEntree, String heureSortie) async {
    final url = Uri.parse("${baseUrl}modifier/$id/");
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
      body: jsonEncode({
        "check_in": heureEntree,
        "check_out": heureSortie,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur modification : ${response.body}");
    } else {
      print("✅ Pointage modifié avec succès");
    }
  }

  /// 🗑 Supprimer un pointage
  static Future<void> deletePointage(String token, int id) async {
    final url = Uri.parse("${baseUrl}supprimer/$id/");
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Token $token",
      },
    );

    if (response.statusCode != 204) {
      throw Exception("Erreur suppression : ${response.body}");
    } else {
      print("🗑 Pointage supprimé avec succès");
    }
  }
}
