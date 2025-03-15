import 'dart:convert';
import 'package:http/http.dart' as http;

import '/data/models/user.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<User?> login(String cpf, String senha) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'cpf': cpf, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      return User.fromJson(jsonMap);
    } else {
      throw Exception('Falha no Login');
    }
  }
}
