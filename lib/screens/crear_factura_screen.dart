import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/order_service.dart';
import '../services/factura_service.dart';

class CrearFacturaScreen extends StatefulWidget {
  const CrearFacturaScreen({super.key});

  @override
  State<CrearFacturaScreen> createState() => _CrearFacturaScreenState();
}

class _CrearFacturaScreenState extends State<CrearFacturaScreen>
    with TickerProviderStateMixin {
  // ─── datos ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _ordenes = [];
  Map<String, dynamic>? _seleccionada;

  double _descuento = 0;
  String _tipoDesc = 'porcentaje'; //  porcentaje | monto
  double _propina = 0;

  bool _loading = true;
  bool _creando = false;
  String? _error;

  // ─── controllers para animaciones ─────────────────────────────────────
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // ─── colores del tema ─────────────────────────────────────────────────
  static const Color _bgPrimary = Color(0xFF0F172A);
  static const Color _bgSecondary = Color(0xFF1E293B);
  static const Color _bgTertiary = Color(0xFF334155);
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _accentLight = Color(0xFFFFB5A3);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargar();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /* ─────── Cargar órdenes facturables (servido | listo) ─────── */
  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _seleccionada = null;
    });

    try {
      // 1. Obtener todas las órdenes
      final todasOrdenes = await OrderService.fetchOrders();

      // 2. Obtener todas las facturas para filtrar
      final facturas = await FacturaService.fetchFacturas();

      // 3. Extraer los IDs de órdenes que ya tienen factura
      final ordenesConFactura = facturas.map((f) => f.orden['id']).toSet();

      // 4. Filtrar órdenes sin factura y en estado correcto
      const estadosOk = {'servido', 'listo'};

      final facturables =
          todasOrdenes
              .where((orden) {
                final estado = (orden['estado'] ?? '').toString().toLowerCase();
                if (!estadosOk.contains(estado)) return false;
                final ordenId = orden['id'];
                return !ordenesConFactura.contains(ordenId);
              })
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList()
            ..sort(
              (a, b) => DateTime.parse(
                b['createdAt'],
              ).compareTo(DateTime.parse(a['createdAt'])),
            );

      setState(() => _ordenes = facturables);
    } catch (e) {
      setState(() => _error = 'Error al cargar órdenes: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── cálculos ─────────────────────────────────────────────────────────
  double get _subtotal => (_seleccionada?['total'] as num?)?.toDouble() ?? 0;

  double get _valorDescuento =>
      _tipoDesc == 'porcentaje' ? _subtotal * (_descuento / 100) : _descuento;

  double get _total =>
      (_subtotal - _valorDescuento + _propina).clamp(0, double.infinity);

  // ─── helpers ─────────────────────────────────────────────────────────
  String _m(num v) => 'S/ ${v.toDouble().toStringAsFixed(2)}';
  String _f(DateTime d) => DateFormat('dd/MM/yy, HH:mm').format(d);

  /* ─────────── POST /facturas ─────────── */
  Future<void> _crear() async {
    if (_seleccionada == null) {
      _mostrarSnackBar('Selecciona una orden servida o lista', _danger);
      return;
    }

    // Vibración táctil
    HapticFeedback.mediumImpact();

    setState(() => _creando = true);

    try {
      final factura = await FacturaService.crearFactura(
        ordenId: _seleccionada!['id'],
        descuento: _descuento,
        tipoDescuento: _tipoDesc,
        propina: _propina,
      );

      if (!mounted) return;

      // Vibración de éxito
      HapticFeedback.heavyImpact();
      _mostrarSnackBar('Factura creada exitosamente', _success);

      await Navigator.pushNamed(context, '/facturas/${factura.id}');
      _cargar(); // refrescar al volver
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _mostrarSnackBar(e.toString(), _danger);
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgPrimary,
    resizeToAvoidBottomInset: true, // Ajusta cuando aparece el teclado
    appBar: _buildAppBar(),
    body: SafeArea(
      child: FadeTransition(opacity: _fadeAnimation, child: _buildBody()),
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: const Text(
      'Nueva Factura',
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

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final availableHeight = constraints.maxHeight - keyboardHeight;

        return Column(
          children: [
            // Lista de órdenes - altura flexible
            Flexible(
              flex: _seleccionada == null ? 1 : 2,
              child: _buildOrdersList(),
            ),
            // Panel inferior - altura fija pero scrollable internamente
            Container(
              constraints: BoxConstraints(
                maxHeight: _seleccionada == null ? 120 : availableHeight * 0.6,
              ),
              child: _buildBottomPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
          'Cargando órdenes...',
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

  Widget _buildOrdersList() =>
      _ordenes.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _ordenes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildOrderCard(_ordenes[i]),
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
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No hay órdenes para facturar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Las órdenes "Listo" o "Servido" sin facturar\naparecerán aquí automáticamente',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildOrderCard(Map<String, dynamic> orden) {
    final isSelected = _seleccionada?['id'] == orden['id'];
    final estado = orden['estado'].toString().toLowerCase();
    final estadoColor = estado == 'servido' ? _success : Colors.blue;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _seleccionada = orden);
            if (!isSelected) {
              _slideController.forward();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient:
                  isSelected
                      ? LinearGradient(
                        colors: [
                          _accent.withOpacity(0.2),
                          _accent.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color: isSelected ? null : _bgSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _accent : _bgTertiary,
                width: isSelected ? 2 : 1,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                      : [
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? _accent.withOpacity(0.3) : _bgTertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: isSelected ? _accent : Colors.white70,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orden #${orden['id']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                color: Colors.white.withOpacity(0.6),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mesa ${orden['mesa']['numero']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 15,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              color: estadoColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _m(orden['total']),
                          style: const TextStyle(
                            color: _success,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                        Icons.schedule_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _f(DateTime.parse(orden['createdAt'])),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildBottomPanel() => Container(
    decoration: BoxDecoration(
      color: _bgSecondary,
      border: Border(top: BorderSide(color: _bgTertiary)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, -8),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              _seleccionada == null
                  ? _buildSelectOrderPrompt()
                  : _buildFacturaForm(),
        ),
      ),
    ),
  );

  Widget _buildSelectOrderPrompt() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _bgTertiary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bgTertiary),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app_rounded,
          color: Colors.white.withOpacity(0.6),
          size: 28,
        ),
        const SizedBox(width: 16),
        Text(
          'Selecciona una orden para continuar',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildFacturaForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Subtotal
      _buildSummaryCard(
        icon: Icons.receipt_outlined,
        label: 'Subtotal',
        value: _m(_subtotal),
        color: Colors.white,
        backgroundColor: _bgTertiary.withOpacity(0.5),
      ),
      const SizedBox(height: 12),

      // Descuento
      _buildDescuentoSection(),
      const SizedBox(height: 12),

      // Propina
      _buildPropinaSection(),
      const SizedBox(height: 16),

      // Total
      _buildSummaryCard(
        icon: Icons.monetization_on_rounded,
        label: 'Total Final',
        value: _m(_total),
        color: _success,
        backgroundColor: _success.withOpacity(0.1),
        borderColor: _success.withOpacity(0.3),
        isTotal: true,
      ),
      const SizedBox(height: 20),

      // Botón crear
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _creando ? null : _crear,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _accent.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: _accent.withOpacity(0.4),
          ),
          child:
              _creando
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Creando...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Crear Factura',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    ],
  );

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
    Color? borderColor,
    bool isTotal = false,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: borderColor != null ? Border.all(color: borderColor) : null,
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildDescuentoSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Descuento',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      // Tipo de descuento
      Container(
        height: 48,
        decoration: BoxDecoration(
          color: _bgTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonFormField<String>(
          value: _tipoDesc,
          dropdownColor: _bgTertiary,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.discount_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 18,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'porcentaje',
              child: Text('Porcentaje (%)'),
            ),
            DropdownMenuItem(value: 'monto', child: Text('Monto fijo (S/)')),
          ],
          onChanged:
              (v) => setState(() {
                _tipoDesc = v!;
                _descuento = 0;
              }),
        ),
      ),
      const SizedBox(height: 8),
      // Campo de valor
      _buildNumField(
        value: _descuento,
        onChanged: (v) {
          if (v == null || v < 0) {
            setState(() => _descuento = 0);
            return;
          }

          if (_tipoDesc == 'porcentaje') {
            final valor = (v > 100) ? 100.0 : v;
            setState(() => _descuento = valor);
          } else {
            final valor = (v > _subtotal) ? _subtotal : v;
            setState(() => _descuento = valor);
          }
        },
        hint: _tipoDesc == 'porcentaje' ? '0-100' : '0.00',
        prefixIcon:
            _tipoDesc == 'porcentaje' ? Icons.percent : Icons.attach_money,
        suffix: _tipoDesc == 'porcentaje' ? '%' : null,
      ),
    ],
  );

  Widget _buildPropinaSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Propina',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      _buildNumField(
        value: _propina,
        onChanged: (v) {
          if (v == null || v < 0) {
            setState(() => _propina = 0);
            return;
          }
          setState(() => _propina = v);
        },
        hint: 'Ej: 2.50',
        prefixIcon: Icons.star_rounded,
      ),
    ],
  );

  Widget _buildNumField({
    required double value,
    required void Function(double?) onChanged,
    required String hint,
    String? suffix,
    required IconData prefixIcon,
  }) {
    final controller = TextEditingController();

    if (value > 0) {
      if (value == value.toInt()) {
        controller.text = value.toInt().toString();
      } else {
        controller.text = value.toString();
      }
    }

    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 48),
      child: TextField(
        controller: controller,
        onChanged: (v) {
          if (v.isEmpty) {
            onChanged(0);
            return;
          }
          final parsed = double.tryParse(v);
          onChanged(parsed);
        },
        onTap: () => HapticFeedback.selectionClick(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.white.withOpacity(0.7),
            size: 18,
          ),
          filled: true,
          fillColor: _bgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
