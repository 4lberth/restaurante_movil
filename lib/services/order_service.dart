// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';

class OrderService {
  /*──────── LISTADOS BÁSICOS ────────*/
  static Future<List<dynamic>> fetchOrders() async {
    final token = await TokenStorage.token;
    final url = Uri.parse('${Constants.baseUrl}/ordenes');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener órdenes';
    return jsonDecode(res.body);
  }

  /*──────── CAMBIO DE ESTADO RÁPIDO ────────*/
  static Future<void> updateOrder(int id, String estado) async {
    final token = await TokenStorage.token;
    final url = Uri.parse('${Constants.baseUrl}/ordenes/$id/estado');
    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': estado}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al actualizar orden';
    }
  }

  /*──────── CREAR ────────*/
  static Future<Map<String, dynamic>> createOrder({
    required int mesaId,
    required List<Map<String, int>> items, // [{platoId, cantidad}]
    int? clienteId,
    String? notas,
  }) async {
    final token = await TokenStorage.token;
    final res = await http.post(
      Uri.parse('${Constants.baseUrl}/ordenes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mesaId': mesaId,
        'items': items,
        if (clienteId != null) 'clienteId': clienteId,
        if (notas != null) 'notas': notas,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al crear orden';
    }
    return jsonDecode(res.body);
  }

  static Future<void> cancelOrder(int id) => updateOrder(id, 'cancelada');

  /*──────── FILTROS ADICIONALES ────────*/
  static Future<List<dynamic>> fetchOrdersByCliente(int clienteId) async {
    final token = await TokenStorage.token;
    final url = Uri.parse('${Constants.baseUrl}/ordenes?clienteId=$clienteId');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener órdenes del cliente';
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> fetchOrdersByMesa(int mesaId) async {
    final token = await TokenStorage.token;
    final url = Uri.parse('${Constants.baseUrl}/ordenes?mesaId=$mesaId');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener órdenes de la mesa';
    return jsonDecode(res.body);
  }

  /*══════════ NUEVO – DETALLE Y EDICIÓN COMPLETA ══════════*/

  /// Trae una orden individual con todos sus detalles.
  static Future<Map<String, dynamic>> fetchOrder(int id) async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/ordenes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Orden no encontrada';
    return jsonDecode(res.body);
  }

  /// Actualiza una orden completa (mesa, cliente, ítems, notas).
  ///
  /// `payload` acepta cualquiera de estas claves:
  /// - mesaId (int)
  /// - clienteId (int)
  /// - cliente (Map<String,dynamic>)
  /// - items (List<{platoId,cantidad}>)
  /// - notas (String)
  static Future<void> editOrder(int id, Map<String, dynamic> payload) async {
    if (payload.isEmpty) return; // nada que enviar

    final token = await TokenStorage.token;
    final res = await http.put(
      Uri.parse('${Constants.baseUrl}/ordenes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al editar orden';
    }
  }

  /*──────── ACCESOS DIRECTOS DE ESTADO ────────*/
  static Future<void> markPrepared(int id) => updateOrder(id, 'en_preparacion');
  static Future<void> markReady(int id) => updateOrder(id, 'listo');
  static Future<void> markServed(int id) => updateOrder(id, 'servido');

  /*──────── HISTORIAL ────────*/
  static Future<List<dynamic>> fetchHistorial(String fecha) async {
    final token = await TokenStorage.token; // ✅ tu JWT
    final uri = Uri.parse(
      '${Constants.baseUrl}/ordenes/historial?desde=$fecha&hasta=$fecha',
    ); //  ej.  http://192.168.100.31:3000/api/ordenes/historial?desde=2025-07-07&hasta=2025-07-07

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // ✅ token real
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al obtener historial';
    }
    return jsonDecode(res.body);
  }
}
