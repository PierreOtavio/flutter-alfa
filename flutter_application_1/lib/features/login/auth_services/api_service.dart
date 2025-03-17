import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '/data/models/user.dart';
import 'network_excp.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000/api/';
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String cpf, String senha) async {
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
        return jsonDecode(response.body);
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

  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-type': 'application/json',
      },
    );
  }
}
