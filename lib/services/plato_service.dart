import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PlatoService {
  static Future<List<dynamic>> fetchDisponibles() async {
    final res = await http.get(
      Uri.parse('${Constants.baseUrl}/platos?soloDisponibles=1'),
    );
    if (res.statusCode != 200) throw 'Error al obtener platos';
    // servidor devuelve [{ categoria, platos:[…] }]; aquí aplanamos:
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.expand((cat) => cat['platos']).toList();
  }
}
