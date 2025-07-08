import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/mozo_screen.dart';
import 'screens/cocina_screen.dart';
import 'screens/mesa_screen.dart';
import 'screens/ordenes_mozo_screen.dart';
import 'screens/historial_cocina_screen.dart';
import 'screens/facturas_screen.dart';
import 'screens/crear_factura_screen.dart';
import 'screens/factura_detalle_screen.dart';
import 'utils/token_storage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Restaurante',
    theme: ThemeData(primarySwatch: Colors.deepOrange),
    routes: {
      '/': (_) => const _Launch(),
      '/mozo': (_) => const MozoScreen(),
      '/cocina': (_) => const CocinaScreen(),
      '/mesas': (_) => const MesaScreen(),
      '/ordenes': (_) => const OrdenesMozoScreen(),
      '/historial': (_) => const HistorialCocinaScreen(),
      '/facturas': (_) => const FacturasScreen(),
      '/facturas/crear': (_) => const CrearFacturaScreen(),
    },
    onGenerateRoute: (settings) {
      //  Soporta /facturas/42 → FacturaDetalleScreen(id:42)
      final uri = Uri.parse(settings.name ?? '');
      if (uri.pathSegments.length == 2 &&
          uri.pathSegments.first == 'facturas') {
        final id = int.tryParse(uri.pathSegments[1]);
        if (id != null) {
          return MaterialPageRoute(
            builder: (_) => FacturaDetalleScreen(id: id),
          );
        }
      }
      return null; // ruta desconocida
    },
  );
}

/// Pantalla de decisión (según rol)
class _Launch extends StatelessWidget {
  const _Launch({super.key});

  Future<Widget> _decidir() async {
    final rol = await TokenStorage.rol;
    if (rol == 'mozo') return const MozoScreen();
    if (rol == 'cocina') return const CocinaScreen();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _decidir(),
    builder: (_, snap) {
      if (!snap.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snap.data!;
    },
  );
}
