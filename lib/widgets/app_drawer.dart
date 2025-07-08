// widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String rol;
  const AppDrawer({super.key, required this.rol});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252836),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1D29), // Mismo fondo oscuro
      child: Column(
        children: [
          // Header del drawer
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF252836)),
            child: SafeArea(
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'RestaurantApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          rol.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                if (rol == 'mozo') ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.table_restaurant,
                    title: 'Mesas',
                    route: '/mesas',
                    hasNotification: true, // Simulando notificación
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.list_alt,
                    title: 'Órdenes',
                    route: '/mozo',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Facturas',
                    route: '/facturas',
                  ),
                ] else if (rol == 'cocina') ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.kitchen,
                    title: 'Órdenes',
                    route: '/cocina',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Historial',
                    route: '/historial',
                  ),
                ],
              ],
            ),
          ),

          // Botón de logout en la parte inferior
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool hasNotification = false,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepOrange : Colors.grey[400],
              size: 24,
            ),
            if (hasNotification)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepOrange : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.deepOrange.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}
