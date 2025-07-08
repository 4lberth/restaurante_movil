// screens/crear_orden_screen.dart - Versión con diseño mejorado
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/plato_service.dart';
import '../services/order_service.dart';
import '../services/cliente_service.dart';
import '../models/cliente_model.dart';

class CrearOrdenScreen extends StatefulWidget {
  final int mesaId;
  final int numero;

  const CrearOrdenScreen({
    super.key,
    required this.mesaId,
    required this.numero,
  });

  @override
  State<CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<CrearOrdenScreen>
    with SingleTickerProviderStateMixin {
  // ═══════════════════ VARIABLES DE ESTADO ═══════════════════
  final List<CarritoItem> _carrito = [];
  final _notasController = TextEditingController();

  // Cliente variables
  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  bool _mostrandoNuevoCliente = false;
  final _nombreClienteController = TextEditingController();
  final _dniClienteController = TextEditingController();
  final _telefonoClienteController = TextEditingController();

  // Estado general
  double _total = 0.0;
  bool _isCreating = false;
  bool _loadingClientes = false;

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // ═══════════════════ CICLO DE VIDA ═══════════════════
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarClientes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notasController.dispose();
    _nombreClienteController.dispose();
    _dniClienteController.dispose();
    _telefonoClienteController.dispose();
    super.dispose();
  }

  // ═══════════════════ INICIALIZACIÓN ═══════════════════
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  // ═══════════════════ LÓGICA DE NEGOCIO ═══════════════════
  Future<void> _cargarClientes() async {
    setState(() => _loadingClientes = true);

    try {
      final clientesData = await ClienteService.fetchClientes();
      setState(() {
        _clientes = clientesData.map((c) => Cliente.fromJson(c)).toList();
      });
    } catch (e) {
      _mostrarError('Error cargando clientes: $e');
    } finally {
      setState(() => _loadingClientes = false);
    }
  }

  Future<void> _crearNuevoCliente() async {
    if (!_validarDatosCliente()) return;

    try {
      final nuevoClienteData = await ClienteService.createCliente(
        nombre: _nombreClienteController.text.trim(),
        dni: _dniClienteController.text.trim(),
        telefono: _telefonoClienteController.text.trim(),
      );

      final nuevoCliente = Cliente.fromJson(nuevoClienteData);

      setState(() {
        _clientes.add(nuevoCliente);
        _clienteSeleccionado = nuevoCliente;
        _mostrandoNuevoCliente = false;
        _limpiarFormularioCliente();
      });

      _mostrarExito('Cliente creado exitosamente');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _mostrarError('Error al crear cliente: $e');
    }
  }

  bool _validarDatosCliente() {
    if (_nombreClienteController.text.trim().isEmpty ||
        _dniClienteController.text.trim().isEmpty ||
        _telefonoClienteController.text.trim().isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return false;
    }

    if (_dniClienteController.text.trim().length != 8) {
      _mostrarError('El DNI debe tener 8 dígitos');
      return false;
    }

    if (_telefonoClienteController.text.trim().length != 9) {
      _mostrarError('El teléfono debe tener 9 dígitos');
      return false;
    }

    return true;
  }

  void _limpiarFormularioCliente() {
    _nombreClienteController.clear();
    _dniClienteController.clear();
    _telefonoClienteController.clear();
  }

  void _agregarAlCarrito(Map<String, dynamic> plato) {
    HapticFeedback.lightImpact();

    setState(() {
      final existingIndex = _carrito.indexWhere(
        (item) => item.platoId == plato['id'],
      );

      if (existingIndex >= 0) {
        _carrito[existingIndex] = _carrito[existingIndex].copyWith(
          cantidad: _carrito[existingIndex].cantidad + 1,
        );
      } else {
        _carrito.add(CarritoItem.fromPlato(plato));
      }
      _calcularTotal();
    });

    // Mostrar feedback visual
    _mostrarFeedback('${plato['nombre']} agregado');
  }

  void _removerDelCarrito(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _carrito.removeAt(index);
      _calcularTotal();
    });
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index] = _carrito[index].copyWith(cantidad: nuevaCantidad);
      }
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    _total = _carrito.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int _getCantidadEnCarrito(int platoId) {
    return _carrito
        .where((item) => item.platoId == platoId)
        .fold(0, (sum, item) => sum + item.cantidad);
  }

  Future<void> _crearOrden() async {
    if (_carrito.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final items =
          _carrito
              .map(
                (item) => {'platoId': item.platoId, 'cantidad': item.cantidad},
              )
              .toList();

      await OrderService.createOrder(
        mesaId: widget.mesaId,
        items: items,
        clienteId: _clienteSeleccionado?.id,
        notas: _notasController.text.isNotEmpty ? _notasController.text : null,
      );

      HapticFeedback.heavyImpact();
      _mostrarExito(
        _clienteSeleccionado != null
            ? '¡Orden creada para ${_clienteSeleccionado!.nombre}!'
            : '¡Orden creada exitosamente!',
      );

      Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error al crear orden: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  // ═══════════════════ HELPERS UI ═══════════════════
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarFeedback(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(
          left: 60,
          right: 60,
          bottom: MediaQuery.of(context).size.height * 0.8,
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // ═══════════════════ BUILD PRINCIPAL ═══════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 50),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildModalContainer(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalContainer() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth * 0.95,
        height: _calculateModalHeight(screenHeight, keyboardHeight),
        margin: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 40,
          bottom: math.max(20, keyboardHeight * 0.1), // Cambio aquí
        ),
        decoration: _modalDecoration(),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              // Asegúrate de que el contenido tenga espacio flexible
              child: _buildContent(keyboardHeight),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  double _calculateModalHeight(double screenHeight, double keyboardHeight) {
    final baseHeight = screenHeight * 0.85; // Reducido de 0.88 a 0.85
    final adjustment = keyboardHeight * 0.4; // Aumentado de 0.35 a 0.4
    return (baseHeight - adjustment).clamp(
      400.0,
      screenHeight * 0.90,
    ); // Ajustado el mínimo
  }

  BoxDecoration _modalDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xFF1A202C),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.orange.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ═══════════════════ COMPONENTES UI ═══════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear Orden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mesa ${widget.numero}',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double keyboardHeight) {
    return Container(
      color: const Color(0xFF1A202C),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap client section in a container with proper constraints
            Container(width: double.infinity, child: _buildClienteSection()),
            const SizedBox(height: 20),
            _buildPlatosSection(keyboardHeight),
            if (_carrito.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildCarritoSection(keyboardHeight),
            ],
            const SizedBox(height: 20),
            _buildNotasSection(keyboardHeight),
            // Extra space for keyboard
            SizedBox(height: keyboardHeight > 0 ? 100 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSection() {
    return Container(
      // Add a minimum height to accommodate the dropdown
      constraints: const BoxConstraints(minHeight: 80),
      child: _buildSectionContainer(
        title: 'Cliente',
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        child:
            _mostrandoNuevoCliente
                ? _buildNuevoClienteForm()
                : _buildClienteDropdown(),
      ),
    );
  }

  Widget _buildClienteDropdown() {
    return Container(
      decoration: _inputDecoration(),
      child: _loadingClientes ? _buildLoadingState() : _buildDropdown(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange[400],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cargando clientes...',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Cliente?>(
                value: _clienteSeleccionado,
                hint: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.white38, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Seleccionar cliente (opcional)',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ],
                ),
                icon: const Icon(Icons.expand_more, color: Colors.white54),
                dropdownColor: const Color(0xFF2D3748),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                selectedItemBuilder:
                    (context) => [
                      const Text(
                        'Sin cliente',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      ..._clientes
                          .map(
                            (cliente) => Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.orange.withOpacity(
                                    0.2,
                                  ),
                                  child: Text(
                                    cliente.initials,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cliente.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                items: _buildDropdownItems(),
                onChanged: (cliente) {
                  setState(() => _clienteSeleccionado = cliente);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildNuevoClienteButton(),
        ],
      ),
    );
  }

  Widget _buildNuevoClienteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _mostrandoNuevoCliente = true);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[700]!],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  List<DropdownMenuItem<Cliente?>> _buildDropdownItems() {
    return [
      const DropdownMenuItem<Cliente?>(
        value: null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4), // Reduced padding
          child: Text(
            'Sin cliente',
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
        ),
      ),
      ..._clientes.map((cliente) {
        return DropdownMenuItem<Cliente>(
          value: cliente,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14, // Reduced size
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text(
                    cliente.initials,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important: minimize space
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1, // Ensure single line
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'DNI: ${cliente.dniFormatted}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11, // Reduced font size
                        ),
                        maxLines: 1, // Ensure single line
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }

  Widget _buildNuevoClienteForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          _buildFormHeader(),
          const SizedBox(height: 20),
          _buildCustomTextField(
            controller: _nombreClienteController,
            hint: 'Nombre completo',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  controller: _dniClienteController,
                  hint: 'DNI',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomTextField(
                  controller: _telefonoClienteController,
                  hint: 'Teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFormButtons(),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _mostrandoNuevoCliente = false);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Volver',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, color: Colors.blue, size: 16),
              SizedBox(width: 6),
              Text(
                'Nuevo Cliente',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormButtons() {
    return ElevatedButton.icon(
      onPressed: _crearNuevoCliente,
      icon: const Icon(Icons.check, size: 20),
      label: const Text(
        'Crear Cliente',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        elevation: 2,
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
    );
  }

  Widget _buildPlatosSection(double keyboardHeight) {
    return _buildSectionContainer(
      title: 'Menú de Platos',
      icon: Icons.restaurant_menu,
      iconColor: Colors.orange,
      child: SizedBox(
        height: keyboardHeight > 0 ? 200 : 260,
        child: FutureBuilder(
          future: PlatoService.fetchDisponibles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPlatosLoadingState();
            }

            if (snapshot.hasError) {
              return _buildPlatosErrorState(snapshot.error.toString());
            }

            final platos = snapshot.data as List<dynamic>;
            if (platos.isEmpty) {
              return _buildPlatosEmptyState();
            }

            return _buildPlatosGrid(platos);
          },
        ),
      ),
    );
  }

  Widget _buildPlatosLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange[400], strokeWidth: 3),
          const SizedBox(height: 16),
          const Text(
            'Cargando menú...',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatosErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar platos',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatosEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay platos disponibles',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatosGrid(List<dynamic> platos) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: platos.length,
      itemBuilder: (context, index) {
        final plato = platos[index];
        return _buildPlatoCard(plato);
      },
    );
  }

  Widget _buildPlatoCard(Map<String, dynamic> plato) {
    final cantidadEnCarrito = _getCantidadEnCarrito(plato['id']);
    final isSelected = cantidadEnCarrito > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _agregarAlCarrito(plato),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D3748),
                        const Color(0xFF1A202C),
                      ],
                    )
                    : null,
            color: isSelected ? null : const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.orange.withOpacity(0.6)
                      : Colors.white.withOpacity(0.08),
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icono del plato
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.withOpacity(0.15),
                              Colors.orange.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.orange.withOpacity(0.8),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nombre del plato
                    Expanded(
                      flex: 2,
                      child: Text(
                        plato['nombre'],
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Precio
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'S/ ${(plato['precio'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          color:
                              isSelected ? Colors.orange : Colors.orange[300],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de cantidad
              if (cantidadEnCarrito > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[600]!, Colors.orange[700]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$cantidadEnCarrito',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarritoSection(double keyboardHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _buildSectionContainer(
        title: 'Platos Seleccionados',
        icon: Icons.shopping_cart_outlined,
        iconColor: Colors.green,
        badge: _carrito.length.toString(),
        child: Container(
          height: keyboardHeight > 0 ? 120 : 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2D3748).withOpacity(0.5),
                const Color(0xFF1A202C).withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: _carrito.isEmpty ? _buildEmptyCart() : _buildCartItems(),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white.withOpacity(0.2),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Carrito vacío',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona platos del menú',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _carrito.length,
      itemBuilder: (context, index) {
        final item = _carrito[index];
        return _buildCarritoItem(item, index);
      },
    );
  }

  Widget _buildCarritoItem(CarritoItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2D3748), const Color(0xFF1A202C)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del plato
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant,
              color: Colors.orange.withOpacity(0.6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info del plato
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${item.precio.toStringAsFixed(2)} c/u',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Controles de cantidad
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: () => _actualizarCantidad(index, item.cantidad - 1),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.cantidad}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: () => _actualizarCantidad(index, item.cantidad + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Subtotal y eliminar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _removerDelCarrito(index);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
        ),
      ),
    );
  }

  Widget _buildNotasSection(double keyboardHeight) {
    return _buildSectionContainer(
      title: 'Notas para Cocina',
      icon: Icons.note_outlined,
      iconColor: Colors.purple,
      child: _buildCustomTextField(
        controller: _notasController,
        hint: 'Instrucciones especiales, alergias, preferencias...',
        icon: Icons.edit_note,
        maxLines: keyboardHeight > 0 ? 2 : 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  // ═══════════════════ WIDGETS HELPER ═══════════════════
  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    Color iconColor = Colors.orange,
    String? badge,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (badge != null && badge != '0') ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 22),
        filled: true,
        fillColor: const Color(0xFF2D3748).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: const Color(0xFF2D3748).withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_carrito.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total de la orden',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'S/ ',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _total.toStringAsFixed(2),
                              style: TextStyle(
                                color: Colors.green[400],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.green[400],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_carrito.length} platos',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        (_carrito.isEmpty || _isCreating) ? null : _crearOrden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      elevation: 3,
                      shadowColor: Colors.orange.withOpacity(0.5),
                    ),
                    child:
                        _isCreating
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Crear Orden',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
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
    );
  }
}

// ═══════════════════ MODELO DE CARRITO ═══════════════════
class CarritoItem {
  final int platoId;
  final String nombre;
  final double precio;
  final int cantidad;

  CarritoItem({
    required this.platoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  factory CarritoItem.fromPlato(Map<String, dynamic> plato) {
    return CarritoItem(
      platoId: plato['id'],
      nombre: plato['nombre'],
      precio: (plato['precio'] as num).toDouble(),
      cantidad: 1,
    );
  }

  double get subtotal => precio * cantidad;

  CarritoItem copyWith({
    int? platoId,
    String? nombre,
    double? precio,
    int? cantidad,
  }) {
    return CarritoItem(
      platoId: platoId ?? this.platoId,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
