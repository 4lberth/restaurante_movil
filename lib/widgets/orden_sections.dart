// widgets/orden_sections.dart - Secciones modulares
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plato_service.dart';
import '../models/cliente_model.dart';

// ═══════════════════ SECCIÓN CLIENTE ═══════════════════
class _ClienteSection extends StatelessWidget {
  final List<Cliente> clientes;
  final Cliente? clienteSeleccionado;
  final bool mostrandoNuevoCliente;
  final bool loadingClientes;
  final TextEditingController nombreController;
  final TextEditingController dniController;
  final TextEditingController telefonoController;
  final Function(Cliente?) onClienteSeleccionado;
  final Function(bool) onMostrarNuevoCliente;
  final VoidCallback onCrearCliente;

  const _ClienteSection({
    required this.clientes,
    required this.clienteSeleccionado,
    required this.mostrandoNuevoCliente,
    required this.loadingClientes,
    required this.nombreController,
    required this.dniController,
    required this.telefonoController,
    required this.onClienteSeleccionado,
    required this.onMostrarNuevoCliente,
    required this.onCrearCliente,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Cliente',
      icon: Icons.person_outline,
      child:
          mostrandoNuevoCliente
              ? _buildNuevoClienteForm(context)
              : _buildClienteDropdown(context),
    );
  }

  Widget _buildClienteDropdown(BuildContext context) {
    return Container(
      decoration: _inputDecoration(),
      child: loadingClientes ? _buildLoadingState() : _buildDropdown(context),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Text('Cargando clientes...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Cliente?>(
        value: clienteSeleccionado,
        hint: const Text(
          '(Sin cliente)',
          style: TextStyle(color: Colors.white60),
        ),
        icon: _buildDropdownIcon(),
        dropdownColor: const Color(0xFF1A202C),
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        items: _buildDropdownItems(),
        onChanged: onClienteSeleccionado,
      ),
    );
  }

  Widget _buildDropdownIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.expand_more, color: Colors.white60),
          const SizedBox(width: 12),
          _buildNuevoClienteButton(),
        ],
      ),
    );
  }

  Widget _buildNuevoClienteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onMostrarNuevoCliente(true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[700]!],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Nuevo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<Cliente?>> _buildDropdownItems() {
    return [
      const DropdownMenuItem<Cliente?>(
        value: null,
        child: Text('(Sin cliente)', style: TextStyle(color: Colors.white60)),
      ),
      ...clientes.map((cliente) {
        return DropdownMenuItem<Cliente>(
          value: cliente,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text(
                    cliente.initials,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'DNI: ${cliente.dniFormatted}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
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

  Widget _buildNuevoClienteForm(BuildContext context) {
    return Column(
      children: [
        _buildFormHeader(),
        const SizedBox(height: 16),
        _CustomTextField(
          controller: nombreController,
          hint: 'Nombre completo',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CustomTextField(
                controller: dniController,
                hint: 'DNI',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CustomTextField(
                controller: telefonoController,
                hint: 'Teléfono',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFormButtons(),
      ],
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onMostrarNuevoCliente(false);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text(
                  'Volver',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Nuevo Cliente',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCrearCliente,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1A202C),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    );
  }
}

// ═══════════════════ SECCIÓN PLATOS ═══════════════════
class _PlatosSection extends StatelessWidget {
  final double keyboardHeight;
  final List<dynamic> carrito;
  final Function(Map<String, dynamic>) onAgregarPlato;

  const _PlatosSection({
    required this.keyboardHeight,
    required this.carrito,
    required this.onAgregarPlato,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Menú de Platos',
      icon: Icons.restaurant_menu,
      child: SizedBox(
        height: keyboardHeight > 0 ? 220 : 280,
        child: FutureBuilder(
          future: PlatoService.fetchDisponibles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final platos = snapshot.data as List<dynamic>;
            if (platos.isEmpty) {
              return _buildEmptyState();
            }

            return _buildPlatosGrid(platos);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('Cargando platos...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar platos',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_outlined, size: 48, color: Colors.white60),
          SizedBox(height: 16),
          Text(
            'No hay platos disponibles',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: platos.length,
      itemBuilder: (context, index) {
        final plato = platos[index];
        return _PlatoCard(
          plato: plato,
          cantidadEnCarrito: _getCantidadEnCarrito(plato['id']),
          onTap: () => onAgregarPlato(plato),
        );
      },
    );
  }

  int _getCantidadEnCarrito(int platoId) {
    return carrito
        .where((item) => item.platoId == platoId)
        .fold<int>(
          0,
          (sum, item) => sum + ((item.cantidad?.toInt() ?? 0) as int),
        );
  }
}

// ═══════════════════ CARD DE PLATO ═══════════════════
class _PlatoCard extends StatelessWidget {
  final Map<String, dynamic> plato;
  final int cantidadEnCarrito;
  final VoidCallback onTap;

  const _PlatoCard({
    required this.plato,
    required this.cantidadEnCarrito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A202C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                cantidadEnCarrito > 0
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
            width: cantidadEnCarrito > 0 ? 2 : 1,
          ),
          boxShadow:
              cantidadEnCarrito > 0
                  ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen placeholder
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.orange.withOpacity(0.6),
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nombre del plato
                  Expanded(
                    child: Text(
                      plato['nombre'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Precio
                  Text(
                    'S/ ${(plato['precio'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cantidadEnCarrito',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════ SECCIÓN CARRITO ═══════════════════
class _CarritoSection extends StatelessWidget {
  final List<dynamic> carrito;
  final double keyboardHeight;
  final Function(int) onRemoverItem;
  final Function(int, int) onActualizarCantidad;

  const _CarritoSection({
    required this.carrito,
    required this.keyboardHeight,
    required this.onRemoverItem,
    required this.onActualizarCantidad,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Platos Seleccionados',
      icon: Icons.shopping_cart_outlined,
      badge: carrito.length.toString(),
      child: Container(
        height: keyboardHeight > 0 ? 100 : 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1A202C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: carrito.isEmpty ? _buildEmptyCart() : _buildCartItems(),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, color: Colors.white60, size: 32),
          SizedBox(height: 8),
          Text(
            'Carrito vacío',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Selecciona platos del menú',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: carrito.length,
      itemBuilder: (context, index) {
        final item = carrito[index];
        return _CarritoItemWidget(
          item: item,
          index: index,
          onRemover: () => onRemoverItem(index),
          onActualizarCantidad:
              (cantidad) => onActualizarCantidad(index, cantidad),
        );
      },
    );
  }
}

// ═══════════════════ WIDGET ITEM CARRITO ═══════════════════
class _CarritoItemWidget extends StatelessWidget {
  final dynamic item;
  final int index;
  final VoidCallback onRemover;
  final Function(int) onActualizarCantidad;

  const _CarritoItemWidget({
    required this.item,
    required this.index,
    required this.onRemover,
    required this.onActualizarCantidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Info del plato
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'S/ ${item.precio.toStringAsFixed(2)} c/u',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),

          // Controles de cantidad
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap:
                    () =>
                        onActualizarCantidad((item.cantidad?.toInt() ?? 1) - 1),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.cantidad?.toInt() ?? 0}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap:
                    () =>
                        onActualizarCantidad((item.cantidad?.toInt() ?? 0) + 1),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Subtotal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${item.subtotal?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRemover();
                },
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 16,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
    );
  }
}

// ═══════════════════ SECCIÓN NOTAS ═══════════════════
class _NotasSection extends StatelessWidget {
  final TextEditingController controller;
  final double keyboardHeight;

  const _NotasSection({required this.controller, required this.keyboardHeight});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Notas para Cocina',
      icon: Icons.note_outlined,
      child: _CustomTextField(
        controller: controller,
        hint: 'Instrucciones especiales, alergias, preferencias...',
        icon: Icons.restaurant_menu,
        maxLines: keyboardHeight > 0 ? 2 : 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

// ═══════════════════ WIDGETS HELPER ═══════════════════
class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.icon,
    this.badge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.orange, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A202C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        counterStyle: const TextStyle(color: Colors.white60),
      ),
    );
  }
}
