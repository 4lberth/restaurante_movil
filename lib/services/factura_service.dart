import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/token_storage.dart';
import '../models/factura_model.dart';

class FacturaService {
  static Future<List<Factura>> fetchFacturas() async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/facturas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Error al obtener facturas';
    return (jsonDecode(res.body) as List)
        .map((j) => Factura.fromJson(j))
        .toList();
  }

  static Future<Factura> fetchFactura(int id) async {
    final token = await TokenStorage.token;
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/facturas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Factura no encontrada';
    return Factura.fromJson(jsonDecode(res.body));
  }

  static Future<Factura> crearFactura({
    required int ordenId,
    double descuento = 0,
    String tipoDescuento = 'porcentaje',
    double propina = 0,
  }) async {
    final token = await TokenStorage.token;
    final res = await http.post(
      Uri.parse('${Constants.baseUrl}/facturas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ordenId': ordenId,
        'descuento': descuento,
        'tipoDescuento': tipoDescuento,
        'propina': propina,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw body['error'] ?? 'Error al crear factura';
    }
    return Factura.fromJson(jsonDecode(res.body));
  }
}
