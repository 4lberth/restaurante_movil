class Factura {
  final int id;
  final double subtotal;
  final double descuento;
  final String tipoDescuento; // porcentaje | monto
  final double propina;
  final double totalFinal;
  final DateTime creadoEn;
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic> orden;

  Factura({
    required this.id,
    required this.subtotal,
    required this.descuento,
    required this.tipoDescuento,
    required this.propina,
    required this.totalFinal,
    required this.creadoEn,
    required this.orden,
    this.cliente,
  });

  factory Factura.fromJson(Map<String, dynamic> j) => Factura(
    id: j['id'],
    subtotal: (j['subtotal'] as num).toDouble(),
    descuento: (j['descuento'] as num).toDouble(),
    tipoDescuento: j['tipoDescuento'],
    propina: (j['propina'] as num).toDouble(),
    totalFinal: (j['totalFinal'] as num).toDouble(),
    creadoEn: DateTime.parse(j['creadoEn']),
    cliente: j['cliente'],
    orden: j['orden'],
  );
}
