class User {
  final int id;
  final String nome;
  final String cpf;
  final String senha;
  final String email;
  final String telefone;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.cpf,
    required this.telefone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      senha: json['senha'],
      cpf: json['cpf'],
      telefone: json['telefone'],
    );
  }
}
