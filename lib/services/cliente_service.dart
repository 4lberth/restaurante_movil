// services/cliente_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';

class ClienteService {
  static Future<List<dynamic>> fetchClientes() async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/clientes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener clientes';
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createCliente({
    required String nombre,
    required String dni,
    required String telefono,
  }) async {
    final token = await TokenStorage.token;
    final res = await http.post(
      Uri.parse('${Constants.baseUrl}/clientes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nombre': nombre, 'dni': dni, 'telefono': telefono}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al crear cliente';
    }
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getCliente(int id) async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/clientes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Cliente no encontrado';
    }
    return jsonDecode(res.body);
  }

  static Future<void> updateCliente(
    int id, {
    String? nombre,
    String? dni,
    String? telefono,
  }) async {
    final token = await TokenStorage.token;
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (dni != null) data['dni'] = dni;
    if (telefono != null) data['telefono'] = telefono;

    final res = await http.put(
      Uri.parse('${Constants.baseUrl}/clientes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al actualizar cliente';
    }
  }

  static Future<void> deleteCliente(int id) async {
    final token = await TokenStorage.token;
    final res = await http.delete(
      Uri.parse('${Constants.baseUrl}/clientes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al eliminar cliente';
    }
  }
}
