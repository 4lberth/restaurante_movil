import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String pass) async {
    final url = Uri.parse('${Constants.baseUrl}/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': pass}),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Error de login';

    await TokenStorage.save(body['token'], body['rol']);
    return body;
  }

  static Future<void> logout() => TokenStorage.clear();
}
