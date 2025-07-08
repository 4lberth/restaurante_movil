// models/cliente_model.dart
class Cliente {
  final int? id;
  final String nombre;
  final String dni;
  final String telefono;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cliente({
    this.id,
    required this.nombre,
    required this.dni,
    required this.telefono,
    this.createdAt,
    this.updatedAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      dni: json['dni'] ?? '',
      telefono: json['telefono'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'dni': dni,
      'telefono': telefono,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Método para obtener las iniciales del nombre
  String get initials {
    final words = nombre.split(' ');
    if (words.isEmpty) return 'C';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  // Método para formatear DNI
  String get dniFormatted {
    if (dni.length == 8) {
      return '${dni.substring(0, 2)}.${dni.substring(2, 5)}.${dni.substring(5, 8)}';
    }
    return dni;
  }

  // Método para formatear teléfono
  String get telefonoFormatted {
    if (telefono.length == 9) {
      return '${telefono.substring(0, 3)} ${telefono.substring(3, 6)} ${telefono.substring(6, 9)}';
    }
    return telefono;
  }

  // Método para copiar con cambios
  Cliente copyWith({
    int? id,
    String? nombre,
    String? dni,
    String? telefono,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Cliente(id: $id, nombre: $nombre, dni: $dni, telefono: $telefono)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente &&
        other.id == id &&
        other.nombre == nombre &&
        other.dni == dni &&
        other.telefono == telefono;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nombre.hashCode ^ dni.hashCode ^ telefono.hashCode;
  }
}
