class Cargo {
  final int id;
  final String nome;

  Cargo({required this.id, required this.nome});

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(id: json['id'], nome: json['nome']);
  }

  @override
  String toString() {
    return 'Cargo(id: $id, nome: $nome)';
  }
}
