// screens/ordenes_mozo_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/order_service.dart';
import '../widgets/app_drawer.dart';
import 'editar_orden_screen.dart';
import 'mesa_screen.dart';

class OrdenesMozoScreen extends StatefulWidget {
  const OrdenesMozoScreen({super.key});

  @override
  State<OrdenesMozoScreen> createState() => _OrdenesMozoScreenState();
}

class _OrdenesMozoScreenState extends State<OrdenesMozoScreen> {
  late Future<List<dynamic>> _future;
  int? _procesandoId;

  // Colores del tema oscuro
  static const Color _bgPrimary = Color(0xFF1A1D29); // Actualizado
  static const Color _bgSecondary = Color(0xFF252836); // Actualizado
  static const Color _bgTertiary = Color(0xFF334155);
  static const Color _borderColor = Color(0xFF475569);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _orange = Color(0xFFF97316);
  static const Color _yellow = Color(0xFFEAB308);
  static const Color _green = Color(0xFF10B981);
  static const Color _red = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _refreshOrdenes();
  }

  void _refreshOrdenes() {
    setState(() {
      _future = OrderService.fetchOrders();
    });
  }

  // ✅ FUNCIÓN MEJORADA PARA MANEJAR ZONAS HORARIAS
  String _formatDate(String dateString) {
    try {
      // Parsear la fecha como UTC si no tiene información de zona horaria
      DateTime date;

      if (dateString.contains('T') &&
          !dateString.contains('+') &&
          !dateString.contains('Z')) {
        // Si es formato ISO pero sin zona horaria, asumir UTC
        date = DateTime.parse(dateString + 'Z').toLocal();
      } else if (dateString.endsWith('Z')) {
        // Si termina en Z, es UTC
        date = DateTime.parse(dateString).toLocal();
      } else {
        // Intentar parsear normalmente y convertir a local
        date = DateTime.parse(dateString);
        if (date.isUtc) {
          date = date.toLocal();
        }
      }

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month $hour:$minute';
    } catch (e) {
      // Fallback si hay error en el parsing
      print('Error parsing date: $dateString - $e');
      return 'Fecha inválida';
    }
  }

  // ✅ FUNCIÓN ADICIONAL PARA DEBUG (opcional)
  String _formatDateWithDebug(String dateString) {
    try {
      final originalDate = DateTime.parse(dateString);
      final localDate = originalDate.toLocal();

      print('Original: $dateString');
      print('Parsed: $originalDate (UTC: ${originalDate.isUtc})');
      print('Local: $localDate');
      print('Timezone offset: ${DateTime.now().timeZoneOffset}');

      return _formatDate(dateString);
    } catch (e) {
      return _formatDate(dateString);
    }
  }

  Future<void> _servirOrden(Map<String, dynamic> orden) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _bgSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _borderColor),
            ),
            title: const Text(
              '¿Marcar como servida?',
              style: TextStyle(color: _textPrimary),
            ),
            content: Text(
              'Esta acción liberará la mesa ${orden['mesa']['numero']} y marcará la orden como completada.',
              style: const TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      setState(() => _procesandoId = orden['id']);
      await OrderService.updateOrder(orden['id'], 'servido');
      _refreshOrdenes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden marcada como servida'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _red),
        );
      }
    } finally {
      setState(() => _procesandoId = null);
    }
  }

  Future<void> _cancelarOrden(Map<String, dynamic> orden) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _bgSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _borderColor),
            ),
            title: const Text(
              '¿Cancelar orden?',
              style: TextStyle(color: _textPrimary),
            ),
            content: const Text(
              'Esta acción no se puede deshacer. La orden será cancelada permanentemente.',
              style: TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'No cancelar',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sí, cancelar orden'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      setState(() => _procesandoId = orden['id']);
      await OrderService.cancelOrder(orden['id']);
      _refreshOrdenes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden cancelada'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _red),
        );
      }
    } finally {
      setState(() => _procesandoId = null);
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return _yellow;
      case 'en_preparacion':
        return _orange;
      case 'listo':
        return _green;
      default:
        return _textSecondary;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.access_time;
      case 'en_preparacion':
        return FontAwesomeIcons.bowlFood;
      case 'listo':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_preparacion':
        return 'Preparando';
      case 'listo':
        return 'Listo';
      default:
        return estado;
    }
  }

  Widget _buildEstadisticaCard({
    required String titulo,
    required int cantidad,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSecondary.withOpacity(0.5),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            cantidad.toString(),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(color: _textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(Map<String, dynamic> orden) {
    final isProcessing = _procesandoId == orden['id'];
    final estadoColor = _getEstadoColor(orden['estado']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgSecondary.withOpacity(0.8),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header de la orden
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgTertiary.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Mesa
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Mesa ${orden['mesa']['numero']}',
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getEstadoIcon(orden['estado']),
                        size: 12,
                        color: estadoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getEstadoText(orden['estado']),
                        style: TextStyle(
                          color: estadoColor,
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

          // Contenido de la orden
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente y detalles básicos
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (orden['cliente'] != null) ...[
                            Text(
                              orden['cliente']['nombre'],
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (orden['cliente']['telefono']?.isNotEmpty ==
                                true)
                              Text(
                                orden['cliente']['telefono'],
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ] else
                            const Text(
                              'Sin cliente',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/ ${(orden['total'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${orden['detalles'].length} platos',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Información adicional
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      orden['mozo']?['nombre'] ?? 'mozo',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(
                        orden['createdAt'],
                      ), // ✅ Usando función mejorada
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    // Editar
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed:
                              isProcessing
                                  ? null
                                  : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                EditarOrdenScreen(orden: orden),
                                      ),
                                    );
                                    _refreshOrdenes();
                                  },
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Editar',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Servir
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed:
                              isProcessing ? null : () => _servirOrden(orden),
                          icon:
                              isProcessing
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          label: const Text(
                            'Servir',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cancelar
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed:
                              isProcessing ? null : () => _cancelarOrden(orden),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            // Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Título
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RestaurantApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'MOZO',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: _bgSecondary,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrdenes,
          ),
        ],
      ),
      drawer: const AppDrawer(rol: 'mozo'),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _orange),
            );
          }

          final lista = snap.data!;
          final activas =
              lista
                  .where((o) => !['servido', 'cancelada'].contains(o['estado']))
                  .toList();

          final pendientes =
              activas.where((o) => o['estado'] == 'pendiente').length;
          final preparando =
              activas.where((o) => o['estado'] == 'en_preparacion').length;
          final listas = activas.where((o) => o['estado'] == 'listo').length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgSecondary.withOpacity(0.5),
                    border: const Border(
                      bottom: BorderSide(color: _borderColor),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Órdenes',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gestiona las órdenes activas y su estado',
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Estadísticas
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildEstadisticaCard(
                          titulo: 'Total Activas',
                          cantidad: activas.length,
                          color: _blue,
                          icon: Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEstadisticaCard(
                          titulo: 'Pendientes',
                          cantidad: pendientes,
                          color: _yellow,
                          icon: Icons.access_time,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEstadisticaCard(
                          titulo: 'Preparando',
                          cantidad: preparando,
                          color: _orange,
                          icon: FontAwesomeIcons.bowlFood,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEstadisticaCard(
                          titulo: 'Listas',
                          cantidad: listas,
                          color: _green,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de órdenes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activas.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: _bgSecondary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: _textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay órdenes activas',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Las nuevas órdenes aparecerán aquí',
                                style: TextStyle(
                                  color: _textSecondary.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...activas.map((orden) => _buildOrdenCard(orden)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
