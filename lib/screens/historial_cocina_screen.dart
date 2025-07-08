import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistorialCocinaScreen extends StatefulWidget {
  const HistorialCocinaScreen({super.key});

  @override
  State<HistorialCocinaScreen> createState() => _HistorialCocinaScreenState();
}

class _HistorialCocinaScreenState extends State<HistorialCocinaScreen>
    with TickerProviderStateMixin {
  List<dynamic> _ordenes = [];
  String _fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _loading = true;
  String? _error;
  String _filtroEstado = 'todas'; // todas, servido, cancelada

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Colores del tema
  static const Color _bgPrimary = Color(0xFF0F172A);
  static const Color _bgSecondary = Color(0xFF1E293B);
  static const Color _bgTertiary = Color(0xFF334155);
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _initAnimations();
    _loadHistorial();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('es_ES', null);
    } catch (e) {
      // Si falla la inicialización, usar formato por defecto
      print('Error inicializando formato de fecha: $e');
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await OrderService.fetchHistorial(_fecha);
      setState(() => _ordenes = data);
      _slideController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectFecha() async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fecha),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _bgSecondary,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fecha = DateFormat('yyyy-MM-dd').format(picked));
      _loadHistorial();
    }
  }

  List<dynamic> get _ordenesFiltradas {
    if (_filtroEstado == 'todas') return _ordenes;
    return _ordenes.where((o) => o['estado'] == _filtroEstado).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'servido':
        return _success;
      case 'cancelada':
        return _danger;
      case 'listo':
        return _warning;
      case 'en_preparacion':
        return _info;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'servido':
        return Icons.check_circle_rounded;
      case 'cancelada':
        return Icons.cancel_rounded;
      case 'listo':
        return Icons.restaurant_rounded;
      case 'en_preparacion':
        return Icons.schedule_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado.toLowerCase()) {
      case 'servido':
        return 'Servido';
      case 'cancelada':
        return 'Cancelada';
      case 'listo':
        return 'Listo';
      case 'en_preparacion':
        return 'Preparando';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: FadeTransition(opacity: _fadeAnimation, child: _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: const Text(
      'Historial de Órdenes',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    backgroundColor: _bgSecondary,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 16),
        child: Material(
          color: _bgTertiary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              _loadHistorial();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        _buildFiltros(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_accent.withOpacity(0.1), _info.withOpacity(0.1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: _accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha Seleccionada',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFechaEspanol(DateTime.parse(_fecha)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(
                    'Total',
                    '${_ordenes.length}',
                    _info,
                    Icons.receipt_long_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    'Servidas',
                    '${_ordenes.where((o) => o['estado'] == 'servido').length}',
                    _success,
                    Icons.check_circle_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _selectFecha,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.edit_calendar_rounded, color: _accent, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Cambiar',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildFiltros() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFiltroBtn('todas', 'Todas', Icons.list_rounded),
          const SizedBox(width: 8),
          _buildFiltroBtn('servido', 'Servidas', Icons.check_circle_rounded),
          const SizedBox(width: 8),
          _buildFiltroBtn('cancelada', 'Canceladas', Icons.cancel_rounded),
          const SizedBox(width: 8),
          _buildFiltroBtn('listo', 'Listas', Icons.restaurant_rounded),
        ],
      ),
    ),
  );

  Widget _buildFiltroBtn(String value, String label, IconData icon) {
    final isSelected = _filtroEstado == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filtroEstado = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? _accent : _bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _accent : _bgTertiary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_ordenesFiltradas.isEmpty) return _buildEmptyState();

    return SlideTransition(
      position: _slideAnimation,
      child: RefreshIndicator(
        color: _accent,
        backgroundColor: _bgSecondary,
        onRefresh: _loadHistorial,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: _ordenesFiltradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildOrdenCard(_ordenesFiltradas[i], i),
        ),
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(
            color: _accent,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Cargando historial...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.1),
        border: Border.all(color: _danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.error_outline, color: _danger, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadHistorial,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Container(
      margin: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _bgSecondary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _filtroEstado == 'todas'
                ? 'No hay órdenes para esta fecha'
                : 'No hay órdenes ${_getEstadoText(_filtroEstado).toLowerCase()} para esta fecha',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Intenta seleccionar otra fecha o cambiar el filtro',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildOrdenCard(Map<String, dynamic> orden, int index) {
    final estado = orden['estado']?.toString() ?? '';
    final estadoColor = _getEstadoColor(estado);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _bgTertiary, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${orden['mesa']?['numero'] ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(orden['createdAt'])),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getEstadoIcon(estado),
                        color: estadoColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getEstadoText(estado),
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Información del cliente y mozo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              orden['cliente']?['nombre'] ?? 'Sin cliente',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              orden['mozo']?['nombre'] ?? 'Sin mozo',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'S/ ${orden['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _success,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${orden['detalles'].length} items',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
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
    );
  }

  // Helper para formatear fecha en español sin locales
  String _formatFechaEspanol(DateTime fecha) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
