class Order {
  final int id;
  final String estado;
  final String mesa;
  final double total;

  Order({
    required this.id,
    required this.estado,
    required this.mesa,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    estado: j['estado'],
    mesa: j['mesa']['numero'].toString(),
    total: (j['total'] as num).toDouble(),
  );
}
