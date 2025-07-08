// screens/cocina_screen.dart
// Versión móvil optimizada con mejor UX
// Alberth – 2025‑06‑30

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

import '../services/order_service.dart';
import '../services/plato_service.dart';
import '../widgets/app_drawer.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _future;
  late AnimationController _fabController;
  late AnimationController _statsController;

  // --- ESTADOS --- //
  bool _showListos = false;
  String _search = '';
  final Set<int> _selected = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _statsController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final futures = await Future.wait([
      OrderService.fetchOrders(),
      PlatoService.fetchDisponibles(),
    ]);

    final todas = futures[0] as List<dynamic>;
    final platos = futures[1] as List<dynamic>;

    return {'todas': todas, 'platos': platos};
  }

  void _refresh() {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    setState(() => _future = _loadData());

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  // ---- ACCIONES MASIVAS ---- //
  Future<void> _setEstadoMasivo(String estado) async {
    if (_selected.isEmpty) return;

    HapticFeedback.mediumImpact();

    try {
      await Future.wait(
        _selected.map((id) => OrderService.updateOrder(id, estado)),
      );
      _selected.clear();
      _fabController.reset();
      _refresh();

      if (mounted) {
        _snack(
          '✅ ${_selected.length} órdenes → ${_getStatusText(estado)}',
          const Color(0xFF10B981),
        );
      }
    } catch (e) {
      if (mounted) _snack('❌ Error: $e', const Color(0xFFEF4444));
    }
  }

  void _toggleSelection(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }

      if (_selected.isNotEmpty) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF10B981)
                  ? Icons.check_circle
                  : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: _buildAppBar(),
      drawer: const AppDrawer(rol: 'cocina'),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: const Color(0xFF3B82F6),
            backgroundColor: const Color(0xFF374151),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (snap.hasError) {
                  return _buildErrorState();
                }

                final todas = snap.data!['todas'] as List<dynamic>;
                final platos = snap.data!['platos'] as List<dynamic>;

                final ordenes =
                    todas.where((o) {
                      final estadoOk =
                          _showListos
                              ? [
                                'pendiente',
                                'en_preparacion',
                                'listo',
                              ].contains(o['estado'])
                              : [
                                'pendiente',
                                'en_preparacion',
                              ].contains(o['estado']);
                      final term = _search.toLowerCase();
                      final campo =
                          ("${o['mesa']['numero']}${o['cliente']?['nombre'] ?? ''}")
                              .toLowerCase();
                      return estadoOk && campo.contains(term);
                    }).toList();

                final stats = _calculateStats(todas);

                return Column(
                  children: [
                    _buildStatsPanel(stats),
                    _buildSearchBar(),
                    Expanded(
                      child:
                          ordenes.isEmpty
                              ? _buildEmptyState()
                              : _buildOrdersList(ordenes, platos),
                    ),
                  ],
                );
              },
            ),
          ),

          // FAB para acciones masivas
          _buildFloatingActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Cocina', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      backgroundColor: const Color(0xFF1F2937),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: AnimatedRotation(
                turns: _isRefreshing ? 1 : 0,
                duration: const Duration(milliseconds: 800),
                child: const Icon(Icons.refresh_rounded, size: 22),
              ),
              onPressed: _refresh,
            ),
            if (_isRefreshing)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando órdenes...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats(List<dynamic> todas) {
    return {
      'pendientes': todas.where((o) => o['estado'] == 'pendiente').length,
      'enPrep': todas.where((o) => o['estado'] == 'en_preparacion').length,
      'listas': todas.where((o) => o['estado'] == 'listo').length,
      'total':
          todas
              .where(
                (o) => ['pendiente', 'en_preparacion'].contains(o['estado']),
              )
              .length,
    };
  }

  Widget _buildStatsPanel(Map<String, int> stats) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _statsController.value)),
          child: Opacity(
            opacity: _statsController.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1F2937), const Color(0xFF374151)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4B5563).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Total activas - destacado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.3),
                          const Color(0xFF3B82F6).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ÓRDENES ACTIVAS',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats['total']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grid de estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pendientes',
                          stats['pendientes']!,
                          const Color(0xFFF59E0B),
                          Icons.schedule_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'En Cocina',
                          stats['enPrep']!,
                          const Color(0xFFB45309),
                          FontAwesomeIcons.bowlFood,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Listas',
                          stats['listas']!,
                          const Color(0xFF10B981),
                          Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Prom. Min',
                          12,
                          const Color(0xFF8B5CF6),
                          Icons.timer_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4B5563).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Buscador
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por mesa o cliente...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF374151),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white54,
                size: 20,
              ),
              suffixIcon:
                  _search.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _search = ''),
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4B5563)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _search = v),
          ),

          const SizedBox(height: 12),

          // Toggle mostrar listos
          Row(
            children: [
              Switch(
                value: _showListos,
                activeColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: const Color(0xFF4B5563),
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _showListos = v);
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Incluir órdenes listas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_showListos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Activo',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> ordenes, List<dynamic> platos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordenes.length,
      itemBuilder: (_, i) => _buildOrderCard(ordenes[i], platos),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orden, List<dynamic> platos) {
    final estado = orden['estado'] as String;
    final isEnPrep = estado == 'en_preparacion';
    final isListo = estado == 'listo';

    Color accent;
    if (isListo) {
      accent = const Color(0xFF10B981);
    } else if (isEnPrep) {
      accent = const Color(0xFF3B82F6);
    } else {
      accent = const Color(0xFFF59E0B);
    }

    // Urgente si pendiente > 30 min
    final created = DateTime.parse(orden['createdAt']);
    final urgent =
        estado == 'pendiente' &&
        DateTime.now().difference(created).inMinutes > 30;

    final selected = _selected.contains(orden['id']);

    return GestureDetector(
      onLongPress: () => _toggleSelection(orden['id']),
      onTap: _selected.isNotEmpty ? () => _toggleSelection(orden['id']) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                urgent
                    ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                    : [const Color(0xFF374151), const Color(0xFF1F2937)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : accent,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? const Color(0xFF3B82F6) : accent).withOpacity(
                0.2,
              ),
              blurRadius: selected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(orden, accent, urgent),
              const SizedBox(height: 16),
              _buildMesaInfo(orden),
              if (orden['detalles'] != null) ...[
                const SizedBox(height: 16),
                _buildPlatos(orden, platos, accent),
              ],
              if (orden['notas'] != null &&
                  (orden['notas'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNotas(orden),
              ],
              const SizedBox(height: 20),
              if (_selected.isEmpty) _buildActionButtons(orden),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
    Map<String, dynamic> orden,
    Color accent,
    bool urgent,
  ) {
    final estado = orden['estado'] as String;
    final created = DateTime.parse(orden['createdAt']);
    final elapsed = DateTime.now().difference(created);

    return Row(
      children: [
        // ID de la orden
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                '#${orden['id']}',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Tiempo transcurrido
        if (urgent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 12,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  '${elapsed.inMinutes}min',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(width: 8),

        // Estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(estado), size: 12, color: accent),
              const SizedBox(width: 6),
              Text(
                _getStatusText(estado),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMesaInfo(Map<String, dynamic> o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.table_restaurant_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa ${o['mesa']['numero']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (o['cliente']?['nombre'] != null)
                  Text(
                    o['cliente']['nombre'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'S/ ${(o['total'] as num).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatos(
    Map<String, dynamic> o,
    List<dynamic> platos,
    Color accent,
  ) {
    final detalles = o['detalles'] as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_rounded, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                'Platos (${detalles.length})',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...detalles.map((d) {
            final plato = platos.firstWhere(
              (p) => p['id'] == d['platoId'],
              orElse: () => null,
            );
            final nombre =
                d['plato']?['nombre'] ??
                plato?['nombre'] ??
                d['nombre'] ??
                'Plato';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.3),
                          accent.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${d['cantidad']}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNotas(Map<String, dynamic> o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.2),
            const Color(0xFFF59E0B).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sticky_note_2_rounded,
              size: 16,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas especiales:',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  o['notas'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> o) {
    final estado = o['estado'] as String;

    if (estado == 'pendiente') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(o['id'], 'en_preparacion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.bowlFood, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Preparar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(o['id'], 'listo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Listo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (estado == 'en_preparacion') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateOrderStatus(o['id'], 'listo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Marcar como Listo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Orden Lista',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFloatingActions() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        if (_selected.isEmpty) return const SizedBox.shrink();

        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Transform.scale(
            scale: _fabController.value,
            child: Opacity(
              opacity: _fabController.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_selected.length} órdenes seleccionadas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _selected.clear());
                            _fabController.reverse();
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setEstadoMasivo('en_preparacion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB45309),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FontAwesomeIcons.bowlFood, size: 14),
                                const SizedBox(width: 8),
                                const Text(
                                  'Preparar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setEstadoMasivo('listo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Listo',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateOrderStatus(int id, String estado) async {
    HapticFeedback.mediumImpact();

    try {
      await OrderService.updateOrder(id, estado);
      _refresh();

      if (mounted) {
        _snack(
          '✅ Orden #$id → ${_getStatusText(estado)}',
          const Color(0xFF10B981),
        );
      }
    } catch (e) {
      if (mounted) _snack('❌ Error: $e', const Color(0xFFEF4444));
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'en_preparacion':
        return FontAwesomeIcons.bowlFood;
      case 'listo':
        return Icons.check_circle_rounded;
      case 'servido':
        return Icons.room_service_rounded;
      case 'cancelada':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusText(String e) {
    switch (e) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_preparacion':
        return 'En Preparación';
      case 'listo':
        return 'Listo';
      case 'servido':
        return 'Servido';
      case 'cancelada':
        return 'Cancelada';
      default:
        return e;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar las órdenes',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.3),
                    const Color(0xFF10B981).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Todo al día!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showListos
                  ? 'No hay órdenes que mostrar'
                  : 'No hay órdenes pendientes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎉 Excelente trabajo',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
