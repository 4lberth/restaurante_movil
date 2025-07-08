import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/order_service.dart';
import '../services/mesa_service.dart';
import '../services/plato_service.dart';

/*════════════ MODELO TEMPORAL PARA ÍTEM EN FORM ═══════════*/
class _EdItem {
  int? platoId;
  int cantidad;
  double precio;
  _EdItem({this.platoId, this.cantidad = 1, this.precio = 0});

  double get subtotal => precio * cantidad;
}

/*════════════ PANTALLA DE EDICIÓN RESPONSIVE ═══════════*/
class EditarOrdenScreen extends StatefulWidget {
  final Map<String, dynamic> orden;
  const EditarOrdenScreen({super.key, required this.orden});

  @override
  State<EditarOrdenScreen> createState() => _EditarOrdenScreenState();
}

class _EditarOrdenScreenState extends State<EditarOrdenScreen> {
  /* ---------- Data ---------- */
  List<dynamic> _mesas = [];
  List<dynamic> _platos = [];

  /* ---------- Form state ---------- */
  int? _mesaId;
  final _nombreCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final List<_EdItem> _items = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Colores del tema - consistentes con OrdenesMozoScreen
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
    _initForm();
  }

  Future<void> _initForm() async {
    try {
      final m = MesaService.fetchMesas();
      final p = PlatoService.fetchDisponibles();
      final all = await Future.wait([m, p]);
      _mesas = all[0];
      _platos = all[1];

      final ord = widget.orden;
      if (['listo', 'servido', 'cancelada'].contains(ord['estado'])) {
        throw 'No se puede editar una orden en estado "${ord['estado']}"';
      }

      _mesaId = ord['mesaId'];
      _nombreCtrl.text = ord['cliente']?['nombre'] ?? '';
      _telCtrl.text = ord['cliente']?['telefono'] ?? '';
      _dniCtrl.text = ord['cliente']?['dni'] ?? '';
      _notasCtrl.text = ord['notas'] ?? '';

      for (final d in ord['detalles']) {
        _items.add(
          _EdItem(
            platoId: d['platoId'],
            cantidad: d['cantidad'],
            precio:
                (d['plato']?['precio'] ?? d['subtotal'] / d['cantidad'])
                    .toDouble(),
          ),
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _total => _items.fold(0, (s, it) => s + it.subtotal);

  void _show(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );

  Future<void> _guardar() async {
    if (_mesaId == null) {
      _show('Selecciona mesa', _yellow);
      return;
    }
    if (_items.isEmpty) {
      _show('Agrega al menos un plato', _yellow);
      return;
    }

    final payload = {
      'mesaId': _mesaId,
      'items':
          _items
              .map((e) => {'platoId': e.platoId, 'cantidad': e.cantidad})
              .toList(),
      'notas': _notasCtrl.text,
    };

    if (_nombreCtrl.text.trim().isNotEmpty || _dniCtrl.text.trim().isNotEmpty) {
      payload['cliente'] = {
        'nombre': _nombreCtrl.text.trim(),
        'telefono': _telCtrl.text.trim(),
        'dni': _dniCtrl.text.trim(),
      };
    }

    setState(() => _saving = true);
    try {
      await OrderService.editOrder(widget.orden['id'], payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _show('Error: $e', _red);
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSecondary.withOpacity(0.8),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textSecondary, fontSize: 12),
          prefixIcon:
              icon != null ? Icon(icon, color: _orange, size: 20) : null,
          filled: true,
          fillColor: _bgTertiary.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _orange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPlatoCard(_EdItem item, int index) {
    return _buildCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del plato
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Plato ${index + 1}',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'S/ ${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Selector de plato
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bgTertiary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor.withOpacity(0.3)),
            ),
            child: DropdownButton<int>(
              value: item.platoId,
              hint: const Text(
                'Seleccionar Plato',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              isExpanded: true,
              underline: Container(),
              dropdownColor: _bgSecondary,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              items:
                  _platos.map<DropdownMenuItem<int>>((p) {
                    final disp = p['disponible'] as bool;
                    return DropdownMenuItem(
                      value: p['id'],
                      enabled: disp,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: disp ? _green : _red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['nombre'],
                                  style: TextStyle(
                                    color: disp ? _textPrimary : _textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'S/ ${(p['precio'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: disp ? _orange : _textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged:
                  (v) => setState(() {
                    item.platoId = v;
                    final precio =
                        _platos.firstWhere((p) => p['id'] == v)['precio']
                            as num;
                    item.precio = precio.toDouble();
                  }),
            ),
          ),

          const SizedBox(height: 12),

          // Cantidad y acciones
          Row(
            children: [
              // Cantidad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _bgTertiary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _borderColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                                () => setState(() {
                                  if (item.cantidad > 1) item.cantidad--;
                                }),
                            icon: const Icon(
                              Icons.remove,
                              color: _textSecondary,
                              size: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.cantidad.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => item.cantidad++),
                            icon: const Icon(
                              Icons.add,
                              color: _textSecondary,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Botón eliminar
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _red.withOpacity(0.3)),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _items.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, color: _red, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bgPrimary,
        body: const Center(child: CircularProgressIndicator(color: _orange)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgPrimary,
        appBar: AppBar(
          backgroundColor: _bgSecondary,
          elevation: 0,
          iconTheme: const IconThemeData(color: _textPrimary),
          title: const Text('Error', style: TextStyle(color: _textPrimary)),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: _textPrimary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgSecondary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar Orden #${widget.orden['id']}',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Mesa ${widget.orden['mesa']['numero']}',
              style: const TextStyle(color: _orange, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesa
            _buildSectionTitle('Mesa'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Mesa',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _bgTertiary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor.withOpacity(0.3)),
                    ),
                    child: DropdownButton<int>(
                      value: _mesaId,
                      isExpanded: true,
                      underline: Container(),
                      dropdownColor: _bgSecondary,
                      style: const TextStyle(color: _textPrimary),
                      items:
                          _mesas.map<DropdownMenuItem<int>>((m) {
                            final isOcupada =
                                m['estado'] == 'ocupada' && m['id'] != _mesaId;
                            return DropdownMenuItem<int>(
                              value: m['id'] as int,
                              enabled: !isOcupada,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isOcupada ? _red : _green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Mesa ${m['numero']}',
                                    style: TextStyle(
                                      color:
                                          isOcupada
                                              ? _textSecondary
                                              : _textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isOcupada) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Ocupada',
                                        style: TextStyle(
                                          color: _red,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (v) => setState(() => _mesaId = v),
                    ),
                  ),
                ],
              ),
            ),

            // Cliente
            _buildSectionTitle('Información del Cliente'),
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre del Cliente',
                    icon: Icons.person,
                  ),
                  _buildTextField(
                    controller: _telCtrl,
                    label: 'Teléfono',
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone,
                  ),
                  _buildTextField(
                    controller: _dniCtrl,
                    label: 'DNI',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.badge,
                  ),
                ],
              ),
            ),

            // Platos
            _buildSectionTitle(
              'Platos (${_items.length})',
              trailing: Container(
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () => setState(() => _items.add(_EdItem())),
                ),
              ),
            ),

            if (_items.isEmpty)
              _buildCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: _textSecondary.withOpacity(0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay platos agregados',
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca el botón + para agregar platos',
                      style: TextStyle(
                        color: _textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._items.asMap().entries.map(
                (entry) => _buildPlatoCard(entry.value, entry.key),
              ),

            // Notas
            _buildSectionTitle('Notas Adicionales'),
            _buildCard(
              child: _buildTextField(
                controller: _notasCtrl,
                label: 'Observaciones o notas especiales',
                maxLines: 3,
                icon: Icons.note,
              ),
            ),

            // Total y botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgSecondary.withOpacity(0.8),
                border: Border.all(color: _borderColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Total
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
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
                          'S/ ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones
                  Column(
                    children: [
                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon:
                              _saving
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _saving ? 'Guardando...' : 'Guardar Cambios',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Botón cancelar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _textSecondary.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.cancel, color: _textSecondary),
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(color: _textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
