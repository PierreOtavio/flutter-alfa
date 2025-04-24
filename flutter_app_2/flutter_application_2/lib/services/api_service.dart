import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService 
{
  final _secureStorage = FlutterSecureStorage();

  Future<String?> getToken() async {
  if (kIsWeb) {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (prefs.containsKey('auth_token')) {
        print("Chave: 'auth_token'");
        print("Valor: ${token ?? 'Nulo'}");
      } else {
        print("Token não encontrado no SharedPreferences.");
      }

      return token;
    } catch (e) {
      print("Erro ao ler SharedPreferences na Web: $e");
      // _handleError("Erro ao acessar preferências na web: $e");
      return null;
    }
  } else {
    try {
      String? token = await _secureStorage.read(key: 'auth_token');

      if (token != null) {
        print("Chave: 'auth_token'");
        print("Valor: $token");
      } else {
        print("Token não encontrado no Secure Storage.");
      }

      return token;
    } on PlatformException catch (e) {
      print("Erro ao ler token do Secure Storage: $e");
      // _handleError(e);
      return null;
    } catch (e) {
      print("Erro inesperado ao ler Secure Storage: $e");
      // _handleError("Erro inesperado ao ler armazenamento: $e");
      return null;
    }
  }
}

}