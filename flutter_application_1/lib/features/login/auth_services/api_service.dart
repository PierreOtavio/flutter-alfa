import 'dart:convert';
import 'package:http/http.dart' as http;

import '/data/models/user.dart';
import 'auth_excp.dart';
import 'network_excp.dart';
import 'server_excp.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000/api/login';

  Future login(String cpf, String senha) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'cpf': cpf, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 30)); // Defina um timeout

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        return User.fromJson(jsonMap);
      } else {
        throw Exception('Falha no Login');
      }
    } on SocketException {
      throw Exception('Erro de conexão com o servidor');
    } on TimeoutException {
      throw Exception('Timeout de conexão');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
