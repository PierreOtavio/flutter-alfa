import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> getToken() async {
    final tokenData = await getAndValidateTokens();

    if (tokenData['secureStorage'] != null) {
      return tokenData['secureStorage'];
    } else if (tokenData['sharedPreferences'] != null) {
      return tokenData['sharedPreferences'];
    } else {
      throw Exception('Usuário não autenticado ou token inválido.');
    }
  }

  /// Busca e valida os tokens nas duas instâncias de armazenamento.
  Future<Map<String, dynamic>> getAndValidateTokens() async {
    String? tokenShared;
    String? tokenSecure;

    // Buscar no SharedPreferences (funciona em todas as plataformas suportadas)
    try {
      final prefs = await SharedPreferences.getInstance();
      tokenShared = prefs.getString('auth_token');
      print('[DEBUG] Token no SharedPreferences: ${tokenShared ?? "NULO"}');
    } catch (e) {
      print('[ERRO] Falha ao ler do SharedPreferences: $e');
    }

    // Buscar no SecureStorage (funciona em mobile, desktop e web com suporte)
    try {
      tokenSecure = await _secureStorage.read(key: 'auth_token');
      print('[DEBUG] Token no SecureStorage: ${tokenSecure ?? "NULO"}');
    } catch (e) {
      print('[ERRO] Falha ao ler do SecureStorage: $e');
    }

    // Validação simples
    String status;
    if (tokenShared == null && tokenSecure == null) {
      status = "Nenhum token encontrado em nenhum armazenamento.";
    } else if (tokenShared != null && tokenSecure != null) {
      if (tokenShared == tokenSecure) {
        status = "Tokens encontrados e são IGUAIS.";
      } else {
        status = "Tokens encontrados, mas são DIFERENTES.";
      }
    } else if (tokenShared != null) {
      status = "Token encontrado apenas no SharedPreferences.";
    } else {
      status = "Token encontrado apenas no SecureStorage.";
    }

    print('[VALIDAÇÃO] $status');

    return {
      'sharedPreferences': tokenShared,
      'secureStorage': tokenSecure,
      'status': status,
    };
  }
}
