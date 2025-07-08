import 'package:flutter/material.dart';
import '../services/factura_service.dart';
import '../models/factura_model.dart';
import 'package:intl/intl.dart';

class FacturaDetalleScreen extends StatefulWidget {
  final int id;
  const FacturaDetalleScreen({super.key, required this.id});

  @override
  State<FacturaDetalleScreen> createState() => _FacturaDetalleScreenState();
}

class _FacturaDetalleScreenState extends State<FacturaDetalleScreen> {
  Factura? _factura;
  bool _loading = true;
  String? _error;

  // ─── colores del tema actualizados ─────────────────────────────────────────────────
  static const Color _bgPrimary = Color(0xFF1A1D29); // Actualizado
  static const Color _bgSecondary = Color(0xFF252836); // Actualizado
  static const Color _bgTertiary = Color(0xFF334155);
  static const Color _accent = Colors.deepOrange;
  static const Color _success = Colors.green;
  static const Color _danger = Colors.red;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _factura = await FacturaService.fetchFactura(widget.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _m(double v) => 'S/ ${v.toStringAsFixed(2)}';

  // ✅ FUNCIÓN MEJORADA PARA MANEJAR ZONA HORARIA
  String _f(DateTime d) {
    // Convertir a hora local si es necesario
    final localDate = d.isUtc ? d.toLocal() : d;
    return DateFormat('dd/MM/yy, HH:mm').format(localDate);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgPrimary,
    appBar: _buildAppBar(),
    body: _buildBody(),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Factura #${widget.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'DETALLE',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    backgroundColor: _bgSecondary,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 16),
        child: Material(
          color: _bgTertiary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _cargar,
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
    if (_factura == null) return _buildNotFound();
    return _buildContent();
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
          'Cargando factura...',
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

  Widget _buildNotFound() => Center(
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
              Icons.receipt_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Factura no encontrada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'La factura solicitada no existe o no tienes permisos para verla',
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

  Widget _buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFacturaHeader(),
        const SizedBox(height: 20),
        _buildResumenFacturacion(),
        const SizedBox(height: 20),
        _buildInfoOrden(),
        const SizedBox(height: 20),
        _buildPlatosSection(),
        const SizedBox(height: 20), // Espacio adicional al final
      ],
    ),
  );

  Widget _buildFacturaHeader() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _bgSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bgTertiary),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long, color: _accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Factura #${_factura!.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                        _f(_factura!.creadoEn), // ✅ Usando función mejorada
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Estado de la factura
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: _success, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'PAGADA',
                    style: TextStyle(
                      color: _success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Orden',
                '#${_factura!.orden['id']}',
                Icons.restaurant_menu,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Mesa',
                _factura!.orden['mesa']?['numero']?.toString() ?? 'N/A',
                Icons.table_restaurant,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildInfoCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _bgTertiary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildResumenFacturacion() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _bgSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bgTertiary),
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
            Icon(Icons.calculate, color: _accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Resumen de Facturación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFacturaRow('Subtotal', _m(_factura!.subtotal)),
        if (_factura!.descuento > 0) ...[
          const SizedBox(height: 8),
          _buildFacturaRow(
            'Descuento',
            _factura!.tipoDescuento == 'porcentaje'
                ? '${_factura!.descuento}%'
                : _m(_factura!.descuento),
            color: Colors.yellow.shade400,
            isNegative: true,
          ),
        ],
        if (_factura!.propina > 0) ...[
          const SizedBox(height: 8),
          _buildFacturaRow(
            'Propina',
            _m(_factura!.propina),
            color: Colors.blue.shade400,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _bgTertiary)),
          ),
          child: _buildFacturaRow(
            'Total Final',
            _m(_factura!.totalFinal),
            color: _success,
            isTotal: true,
          ),
        ),
      ],
    ),
  );

  Widget _buildFacturaRow(
    String label,
    String value, {
    Color? color,
    bool isNegative = false,
    bool isTotal = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        '${isNegative ? '-' : ''}$value',
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildInfoOrden() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _bgSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bgTertiary),
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
            Icon(Icons.info_outline, color: _accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Información de la Orden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Estado', _factura!.orden['estado']),
        if (_factura!.cliente != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('Cliente', _factura!.cliente!['nombre']),
          if (_factura!.cliente!['telefono']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', _factura!.cliente!['telefono']),
          ],
        ],
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Row(
    children: [
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );

  Widget _buildPlatosSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _bgSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bgTertiary),
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
            Icon(Icons.restaurant, color: _accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Platos Ordenados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_factura!.orden['detalles'] as List).map((detalle) {
          final nombre = detalle['plato']['nombre'];
          final cantidad = detalle['cantidad'];
          final precio =
              (detalle['precio'] ?? detalle['plato']['precio']).toDouble();
          final subtotal = cantidad * precio;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bgTertiary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$cantidad',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_m(precio)} c/u',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _m(subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
