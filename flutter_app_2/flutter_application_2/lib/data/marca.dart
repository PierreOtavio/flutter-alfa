class Marca {
  int id;
  String marca;

  Marca({required this.id, required this.marca});

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(id: json['id'], marca: json['marca']);
  }

  @override
  String toString() {
    return 'Marca(id: $id, marca: $marca)';
  }
}
