import 'dart:convert';
import 'dart:async'; // Adicionar esta importação
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'auth_excp.dart'; // Importar a exceção de autenticação
import 'network_excp.dart';

class ApiService {
  // Alterar o endereço para um que funcione em dispositivos físicos/emuladores
  final String baseUrl = 'http://127.0.0.1:8000/api/'; // Para emulador Android
  // Use seu IP local para dispositivos físicos, exemplo: 192.168.1.100:8000/api

  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> realizeLogin(String cpf, String senha) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cpf': cpf, 'senha': senha}),
      );
      //.timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw AuthException('Credenciais inválidas');
      } else {
        throw AuthException('Falha no Login: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Erro de conexão com o servidor');
    } on TimeoutException {
      throw NetworkException('Timeout de conexão');
    } catch (e) {
      throw NetworkException('Erro inesperado: $e');
    }
  }

  Future<void> logout(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw AuthException('Falha ao fazer logout');
      }
    } catch (e) {
      throw NetworkException('Erro ao fazer logout: $e');
    }
  }

  // Adicionar método para verificar token
  Future<bool> verificarToken(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
