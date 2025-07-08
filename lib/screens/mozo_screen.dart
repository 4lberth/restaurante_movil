import 'package:flutter/material.dart';
import '../utils/token_storage.dart';
import '../widgets/app_drawer.dart';
import 'ordenes_mozo_screen.dart';

class MozoScreen extends StatefulWidget {
  const MozoScreen({super.key});

  @override
  State<MozoScreen> createState() => _MozoScreenState();
}

class _MozoScreenState extends State<MozoScreen> {
  @override
  void initState() {
    super.initState();
    // Redirigir inmediatamente a la pantalla de órdenes mejorada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToOrdenes();
    });
  }

  void _redirectToOrdenes() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OrdenesMozoScreen()),
    );
  }

  // Función de logout por si se necesita desde otras partes
  static Future<void> logout(BuildContext context) async {
    await TokenStorage.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras se hace la redirección
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando órdenes...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
