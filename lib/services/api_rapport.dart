import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiRapport {
  // 🌍 URL de ton backend Django (⚠️ adapte l’adresse si nécessaire)
  static const String baseUrl = 'http://10.197.52.93:8000/rapport/';

  /// 🟩 Ajouter un rapport
  static Future<void> ajouterRapport(
      Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('${baseUrl}ajouter/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token', // Requis car @IsAuthenticated
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      print("✅ Rapport ajouté avec succès !");
    } else {
      print(
          "❌ Erreur lors de l'ajout du rapport : ${response.statusCode} - ${response.body}");
      throw Exception("Erreur API: ${response.body}");
    }
  }

  /// 🟦 Lister les rapports
  /// - Si l'utilisateur est admin → récupère tous les rapports
  /// - Sinon → récupère uniquement les siens
  static Future<List<dynamic>> listerRapports(String token) async {
    final response = await http.get(
      Uri.parse('${baseUrl}liste/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        print("📊 ${data.length} rapports récupérés !");
        return data;
      } else {
        print("⚠️ Format inattendu reçu depuis l’API : $data");
        return [];
      }
    } else {
      print(
          "❌ Erreur lors du chargement des rapports : ${response.statusCode} - ${response.body}");
      throw Exception("Erreur API: ${response.body}");
    }
  }
}
