import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';

class ApiService {
final String baseUrl = 'http://10.197.52.93:8000/api';

  // -------------------- HEADERS --------------------
  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // -------------------- LOGIN --------------------
  /// Retourne un `Map<String, dynamic>` contenant le token et le rôle utilisateur.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: _headers(),
      body: json.encode({'username': username, 'password': password}),
    );

    print("📥 Réponse du backend (login): ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      // ✅ Structure attendue depuis ton backend Django :
      // { "token": "...", "user_type": "admin|user|superuser", ... }
      return {
        'token': data['token'] ?? '',
        'user_type': data['user_type'] ?? 'user',
        'role': data['role'] ?? 'Employé',
        'username': data['username'] ?? '',
        'email': data['email'] ?? '',
        'first_name': data['first_name'] ?? '',
        'last_name': data['last_name'] ?? '',
        'department': data['department'] ?? 'Non défini',
        'matricule': data['matricule'] ?? '',
        'image_url': data['image_url'],
      };
    } else {
      throw Exception('Échec de la connexion : ${response.body}');
    }
  }

  // -------------------- LOGOUT --------------------
  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout/'),
      headers: _headers(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de déconnexion : ${response.body}');
    }
  }

  // -------------------- INFOS UTILISATEUR --------------------
  Future<Map<String, dynamic>> me(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me/'),
      headers: _headers(token: token),
    );

    print("📦 Réponse du backend (me): ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      return {
        'id': data['id'],
        'username': data['username'] ?? '',
        'email': data['email'] ?? '',
        'first_name': data['first_name'] ?? '',
        'last_name': data['last_name'] ?? '',
        'user_type': data['user_type'] ?? 'user',
        'matricule': data['matricule'] ?? '',
        'role': data['role'] ?? 'Employé',
        'department': data['department'] ?? 'Non défini',
        'image_url': data['image_url'],
      };
    } else {
      throw Exception('Erreur récupération profil : ${response.body}');
    }
  }

  // -------------------- CHANGEMENT DE MOT DE PASSE --------------------
  Future<void> changePassword(
    String token,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/parametres/changer-motdepasse/'),
      headers: _headers(token: token),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );

    print("🔐 Réponse du backend (changer mot de passe): ${response.body}");

    if (response.statusCode == 200) {
      print("✅ Mot de passe changé avec succès !");
    } else {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Erreur lors du changement de mot de passe.');
    }
  }

  // -------------------- LISTE DES UTILISATEURS (ADMIN) --------------------
  Future<List<dynamic>> getUsers(String token) async {
    final response = await http.get(
  Uri.parse('$baseUrl/users/'), // ✅ ancien: $baseUrl/auth/users/
  headers: _headers(token: token),
);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception("Erreur récupération utilisateurs : ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createUser(
    String token,
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
  Uri.parse('$baseUrl/users/'), // ✅ ancien: $baseUrl/auth/users/
  headers: _headers(token: token),
  body: json.encode({
    'username': username,
    'email': email,
    'password': password,
  }),
);


    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur création utilisateur : ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String token,
    int userId,
    Map<String, dynamic> updates,
  ) async {
   final response = await http.put(
  Uri.parse('$baseUrl/users/$userId/'), // ✅ ancien: $baseUrl/auth/users/$userId/
  headers: _headers(token: token),
  body: json.encode(updates),
);


    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur mise à jour utilisateur : ${response.body}");
    }
  }

  Future<void> deleteUser(String token, int userId) async {
    final response = await http.delete(
  Uri.parse('$baseUrl/users/$userId/'), // ✅ ancien: $baseUrl/auth/users/$userId/
  headers: _headers(token: token),
);

    if (response.statusCode != 204) {
      throw Exception("Erreur suppression utilisateur : ${response.body}");
    }
  }

  // -------------------- UPLOAD IMAGE (profil) --------------------
  Future<String?> uploadProfileImage(String token, XFile pickedFile) async {
    try {
      var uri = Uri.parse('$baseUrl/user/profile/upload/');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Token $token';

      request.files.add(await http.MultipartFile.fromBytes(
        'image',
        await pickedFile.readAsBytes(),
        filename: pickedFile.name,
      ));

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      print("🖼 Réponse du backend (upload): $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(respStr);
        return data['image_url'];
      } else {
        print('❌ Upload échoué : $respStr');
        return null;
      }
    } catch (e) {
      print('⚠️ Erreur upload image : $e');
      return null;
    }
  }

  // -------------------- MISE À JOUR DU PROFIL --------------------
  Future<bool> updateUserInfo({
    required String token,
    required String email,
    required String firstName,
    required String lastName,
    required String matricule,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/me/'),
      headers: _headers(token: token),
      body: json.encode({
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "matricule": matricule,
      }),
    );

    print("✏️ Réponse du backend (update info): ${response.body}");

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Erreur updateUserInfo : ${response.body}');
      return false;
    }
  }

// -------------------- DÉPARTEMENT PAR USERNAME --------------------
Future<String> getUserDepartmentByUsername(String username, String token) async {
  try {
    final url = Uri.parse('$baseUrl/user/get-department/$username/');
    final response = await http.get(url, headers: _headers(token: token));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['department'] != null) {
        return data['department'].toString();
      } else {
        return 'Non défini';
      }
    } else {
      print('❌ Erreur récupération département (${response.statusCode})');
      return 'Non défini';
    }
  } catch (e) {
    print('⚠️ Erreur getUserDepartmentByUsername : $e');
    return 'Non défini';
  }
}


}