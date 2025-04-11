class Modelo {
  int id;
  String modelo;

  Modelo({required this.id, required this.modelo});

  factory Modelo.fromJson(Map<String, dynamic> json) {
    return Modelo(id: json['id'], modelo: json['modelo']);
  }

  @override
  String toString() {
    return 'Modelo(id: $id, nome: $modelo)';
  }
}
