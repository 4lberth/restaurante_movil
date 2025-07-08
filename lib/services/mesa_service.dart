import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';

class MesaService {
  static Future<List<dynamic>> fetchMesas() async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/mesas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener mesas';
    return jsonDecode(res.body);
  }

  static Future<void> liberar(int id) => _updateEstado(id, 'libre');
  static Future<void> ocupar(int id) => _updateEstado(id, 'ocupada');

  static Future<void> _updateEstado(int id, String estado) async {
    final token = await TokenStorage.token;
    final res = await http.put(
      Uri.parse('${Constants.baseUrl}/mesas/$id/estado'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': estado}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al cambiar estado mesa';
    }
  }
}
