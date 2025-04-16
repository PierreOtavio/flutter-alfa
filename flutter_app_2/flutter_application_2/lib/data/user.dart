import 'package:flutter_application_2/data/cargo.dart';

class User {
  final int id;
  final String cpf;
  final String name;
  final String? password;
  final String email;
  final String telefone;
  final String status;
  final Cargo cargo;
  // final int cargoId;

  User({
    required this.id,
    required this.cpf,
    required this.name,
    required this.password,
    required this.email,
    required this.telefone,
    required this.status,
    required this.cargo,
    // required this.cargoId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      cpf: json['cpf'],
      name: json['name'],
      password: json['password'] ?? 0,
      email: json['email'],
      telefone: json['telefone'],
      status: json['status'],
      cargo: Cargo.fromJson(json['cargo']),
      // cargoId: json['cargoId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
      'name': name,
      'password': password ?? 0,
      'email': email,
      'telefone': telefone,
      'stauts': status,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, cpf: $cpf, name: $name, email: $email, telefone: $telefone, status: $status, cargo: $cargo)';
  }
}
