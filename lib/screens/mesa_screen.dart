// screens/mesa_screen.dart
import 'package:flutter/material.dart';
import '../services/mesa_service.dart';
import '../services/order_service.dart';
import '../services/plato_service.dart';
import 'crear_orden_screen.dart';
import '../widgets/app_drawer.dart';

class MesaScreen extends StatefulWidget {
  const MesaScreen({super.key});

  @override
  State<MesaScreen> createState() => _MesaScreenState();
}

class _MesaScreenState extends State<MesaScreen> {
  late Future<List<dynamic>> _future;

  // Colores del tema consistentes
  static const Color _bgPrimary = Color(0xFF0F172A);
  static const Color _bgSecondary = Color(0xFF1E293B);
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
    _future = MesaService.fetchMesas();
  }

  void _refreshMesas() {
    setState(() {
      _future = MesaService.fetchMesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RestaurantApp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'GESTIÓN DE MESAS',
              style: TextStyle(
                color: _orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: _bgSecondary,
        foregroundColor: _textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshMesas),
        ],
      ),
      drawer: const AppDrawer(rol: 'mozo'),
      body: RefreshIndicator(
        onRefresh: () async => _refreshMesas(),
        backgroundColor: _bgSecondary,
        color: _orange,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _bgSecondary.withOpacity(0.5),
                  border: Border.all(color: _borderColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Mesas',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selecciona una mesa libre para crear una nueva orden',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingStats();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  }

                  final mesas = snapshot.data as List<dynamic>;
                  return _buildStatsAndMesas(mesas);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Mesas',
                '...',
                Icons.table_restaurant,
                _blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Mesas Libres',
                '...',
                Icons.check_circle,
                _green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Mesas Ocupadas',
                '...',
                Icons.schedule,
                _orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Center(child: CircularProgressIndicator(color: _orange)),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _bgSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: _red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(color: _textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshMesas,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndMesas(List<dynamic> mesas) {
    final mesasLibres = mesas.where((m) => m['estado'] == 'libre').length;
    final mesasOcupadas = mesas.where((m) => m['estado'] == 'ocupada').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Mesas',
                '${mesas.length}',
                Icons.table_restaurant,
                _blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Mesas Libres',
                '$mesasLibres',
                Icons.check_circle,
                _green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Mesas Ocupadas',
                '$mesasOcupadas',
                Icons.schedule,
                _orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Título de selección
        const Text(
          'Seleccionar Mesa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        // Grid de mesas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
          ),
          itemCount: mesas.length,
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            return _buildMesaCard(mesa);
          },
        ),

        const SizedBox(height: 20),

        // Leyenda
        _buildLeyenda(),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: _textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMesaCard(Map<String, dynamic> mesa) {
    final isLibre = mesa['estado'] == 'libre';
    final numero = mesa['numero'];

    return GestureDetector(
      onTap: () {
        if (isLibre) {
          _navegarACrearOrden(mesa);
        } else {
          _mostrarDetallesOrden(mesa);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLibre ? _green.withOpacity(0.1) : _orange.withOpacity(0.1),
          border: Border.all(color: isLibre ? _green : _orange, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mesa $numero',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isLibre ? _green : _orange).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLibre ? 'Disponible' : 'Ocupada',
                  style: TextStyle(
                    color: isLibre ? _green : _orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSecondary.withOpacity(0.5),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leyenda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildLeyendaItem(
            color: _green,
            text: 'Mesa disponible - Clic para crear orden',
          ),
          const SizedBox(height: 8),
          _buildLeyendaItem(
            color: _orange,
            text: 'Mesa ocupada - Clic para ver detalles de la orden',
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _navegarACrearOrden(Map<String, dynamic> mesa) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              CrearOrdenScreen(mesaId: mesa['id'], numero: mesa['numero']),
    );

    if (result == true) {
      _refreshMesas();
    }
  }

  void _mostrarDetallesOrden(Map<String, dynamic> mesa) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              const Center(child: CircularProgressIndicator(color: _orange)),
    );

    try {
      // Obtener órdenes activas de la mesa Y lista de platos
      final futures = await Future.wait([
        OrderService.fetchOrders(),
        PlatoService.fetchDisponibles(),
      ]);

      final ordenes = futures[0];
      final platos = futures[1];

      final ordenMesa = ordenes.firstWhere(
        (orden) =>
            orden['mesaId'] == mesa['id'] &&
            !['servido', 'cancelada'].contains(orden['estado']),
        orElse: () => null,
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (ordenMesa == null) {
        _mostrarMesaSinOrden(mesa);
      } else {
        _mostrarDetallesOrdenCompleta(mesa, ordenMesa, platos);
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles: $e'),
          backgroundColor: _red,
        ),
      );
    }
  }

  void _mostrarMesaSinOrden(Map<String, dynamic> mesa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                const Icon(Icons.info_outline, color: _yellow, size: 48),
                const SizedBox(height: 16),

                Text(
                  'Mesa ${mesa['numero']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Esta mesa está marcada como ocupada pero no tiene órdenes activas.',
                  style: TextStyle(color: _textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarConfirmacionLiberar(mesa);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cleaning_services,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Liberar Mesa',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _mostrarDetallesOrdenCompleta(
    Map<String, dynamic> mesa,
    Map<String, dynamic> orden,
    List<dynamic> platos,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header de la orden
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mesa ${mesa['numero']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Orden #${orden['id']}',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(
                                orden['estado'],
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getEstadoColor(
                                  orden['estado'],
                                ).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getEstadoText(orden['estado']),
                              style: TextStyle(
                                color: _getEstadoColor(orden['estado']),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Información del cliente
                      if (orden['cliente'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgTertiary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _borderColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person, color: _blue, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cliente',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                orden['cliente']['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              if (orden['cliente']['telefono']?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: _textSecondary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      orden['cliente']['telefono'],
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (orden['cliente']['dni']?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.badge,
                                      color: _textSecondary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DNI: ${orden['cliente']['dni']}',
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Lista de platos
                      const Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: _orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Platos Pedidos',
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: orden['detalles'].length,
                          itemBuilder: (context, index) {
                            final detalle = orden['detalles'][index];

                            // Debug: imprimir información para diagnosticar
                            print('--- DEBUG PLATO $index ---');
                            print('detalle completo: $detalle');
                            print('platoId: ${detalle['platoId']}');
                            print('plato en detalle: ${detalle['plato']}');
                            print(
                              'primer plato en lista: ${platos.isNotEmpty ? platos[0] : "lista vacía"}',
                            );

                            // Buscar el plato en la lista de platos usando el platoId
                            final plato = platos.firstWhere(
                              (p) => p['id'] == detalle['platoId'],
                              orElse: () => null,
                            );

                            print('plato encontrado: $plato');

                            // Obtener nombre del plato con múltiples fallbacks
                            final nombrePlato =
                                detalle['plato']?['nombre'] ??
                                plato?['nombre'] ??
                                detalle['nombre'] ??
                                'Plato ID: ${detalle['platoId']}';

                            print('nombre final: $nombrePlato');
                            print('--- FIN DEBUG ---');

                            // Obtener precio unitario con múltiples fallbacks
                            final precioUnitario =
                                detalle['plato']?['precio'] ??
                                plato?['precio'] ??
                                detalle['precio'] ??
                                (detalle['subtotal'] / detalle['cantidad']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bgTertiary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _borderColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Cantidad
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${detalle['cantidad']}',
                                        style: const TextStyle(
                                          color: _orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nombre del plato
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombrePlato,
                                          style: const TextStyle(
                                            color: _textPrimary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'S/ ${precioUnitario.toStringAsFixed(2)} c/u',
                                          style: const TextStyle(
                                            color: _textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Subtotal
                                  Text(
                                    'S/ ${(detalle['subtotal'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: _orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Notas
                      if (orden['notas']?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _yellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _yellow.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.note, color: _yellow, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Notas:',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orden['notas'],
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Total y botones
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'S/ ${(orden['total'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _mostrarConfirmacionLiberar(mesa);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: _blue),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.cleaning_services,
                                      color: _blue,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Liberar Mesa',
                                      style: TextStyle(
                                        color: _blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Cerrar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                ),
          ),
    );
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

  void _mostrarConfirmacionLiberar(Map<String, dynamic> mesa) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _bgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Liberar Mesa',
            style: TextStyle(color: _textPrimary),
          ),
          content: Text(
            '¿Estás seguro que quieres liberar la Mesa ${mesa['numero']}?\n\n'
            'Esta acción marcará la mesa como disponible.',
            style: const TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _textSecondary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Liberar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await MesaService.liberar(mesa['id']);
                  _refreshMesas();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesa liberada exitosamente'),
                        backgroundColor: _green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: _red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
