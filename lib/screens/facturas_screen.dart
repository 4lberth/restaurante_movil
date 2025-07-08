import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/factura_model.dart';
import '../services/factura_service.dart';
import '../widgets/app_drawer.dart';

class FacturasScreen extends StatefulWidget {
  const FacturasScreen({super.key});

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen>
    with TickerProviderStateMixin {
  List<Factura> _facturas = [];
  bool _loading = true;
  String? _error;
  String _filtro = 'todas'; // todas | hoy | semana

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Colores del tema
  static const Color _bgPrimary = Color(0xFF1A1D29);
  static const Color _bgSecondary = Color(0xFF252836);
  static const Color _bgTertiary = Color(0xFF334155);
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _success = Color(0xFF10B981);
  static const Color _info = Color(0xFF3B82F6);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargar();
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

  /* ───────────── CARGA DATOS ───────────── */
  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _facturas = await FacturaService.fetchFacturas();
      _slideController.forward();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ───────────── FILTRO ───────────── */
  List<Factura> get _filtradas {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final inicioSemana = inicioHoy.subtract(const Duration(days: 7));

    return _facturas.where((f) {
        switch (_filtro) {
          case 'hoy':
            return f.creadoEn.isAfter(inicioHoy);
          case 'semana':
            return f.creadoEn.isAfter(inicioSemana);
          default:
            return true;
        }
      }).toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  }

  /* ───────────── HELPERS CON FIX DE ZONA HORARIA ───────────── */
  String _moneda(double v) => 'S/ ${v.toStringAsFixed(2)}';

  // ✅ FUNCIONES MEJORADAS PARA MANEJAR ZONAS HORARIAS
  String _fecha(DateTime d) {
    // Convertir a hora local si es necesario
    final localDate = d.isUtc ? d.toLocal() : d;
    return DateFormat('dd/MM/yy, HH:mm').format(localDate);
  }

  String _fechaCorta(DateTime d) {
    final localDate = d.isUtc ? d.toLocal() : d;
    return DateFormat('dd/MM').format(localDate);
  }

  String _hora(DateTime d) {
    final localDate = d.isUtc ? d.toLocal() : d;
    return DateFormat('HH:mm').format(localDate);
  }

  // ✅ FUNCIÓN ADICIONAL PARA PARSEAR FECHAS DE STRING (si necesitas)
  DateTime _parseDate(String dateString) {
    try {
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
        // Intentar parsear normalmente
        date = DateTime.parse(dateString);
        if (date.isUtc) {
          date = date.toLocal();
        }
      }

      return date;
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      return DateTime.now(); // Fallback
    }
  }

  /* ───────────── BUILD ───────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgPrimary,
    drawer: const AppDrawer(rol: 'mozo'),
    appBar: _buildAppBar(),
    floatingActionButton: _buildFAB(),
    body: SafeArea(
      child: FadeTransition(opacity: _fadeAnimation, child: _buildBody()),
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: Row(
      children: [
        // Logo y título
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RestaurantApp',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
    ),
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
              _cargar();
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

  Widget _buildFAB() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _accent.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: FloatingActionButton.extended(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      elevation: 0,
      icon: const Icon(Icons.add_rounded, size: 24),
      label: const Text(
        'Nueva Factura',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/facturas/crear').then((_) => _cargar());
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();

    return Column(
      children: [
        _buildHeader(),
        _buildFiltros(),
        Expanded(child: _buildFacturasList()),
      ],
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
          'Cargando facturas...',
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
              onPressed: _cargar,
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

  Widget _buildHeader() => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_success.withOpacity(0.1), _info.withOpacity(0.1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total Facturado',
            value: _moneda(_filtradas.fold(0, (s, f) => s + f.totalFinal)),
            color: _success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.description_rounded,
            label: 'Facturas',
            value: '${_filtradas.length}',
            color: _info,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 12),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildFiltros() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(child: _buildFiltroBtn('todas', 'Todas', Icons.list_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _buildFiltroBtn('hoy', 'Hoy', Icons.today_rounded)),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFiltroBtn('semana', 'Semana', Icons.date_range_rounded),
        ),
      ],
    ),
  );

  Widget _buildFiltroBtn(String value, String label, IconData icon) {
    final isSelected = _filtro == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filtro = value);
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
            mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildFacturasList() {
    if (_filtradas.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: RefreshIndicator(
        color: _accent,
        backgroundColor: _bgSecondary,
        onRefresh: _cargar,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _filtradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildFacturaCard(_filtradas[i], i),
        ),
      ),
    );
  }

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
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _filtro == 'todas'
                ? 'No hay facturas'
                : _filtro == 'hoy'
                ? 'No hay facturas de hoy'
                : 'No hay facturas esta semana',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Las facturas creadas aparecerán aquí',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildFacturaCard(Factura factura, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              '/facturas/${factura.id}',
            ).then((_) => _cargar());
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: _accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura #${factura.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _fecha(
                                  factura.creadoEn,
                                ), // ✅ Usando función mejorada
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                          _moneda(factura.totalFinal),
                          style: const TextStyle(
                            color: _success,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PAGADA',
                            style: TextStyle(
                              color: _success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Toca para ver detalles',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.4),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
