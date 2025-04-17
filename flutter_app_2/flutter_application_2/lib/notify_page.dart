import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Simulação do model Notificacao
class Notificacao {
  final int id;
  final String titulo;
  final String mensagem;

  Notificacao({required this.id, required this.titulo, required this.mensagem});

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
    );
  }
}

class NotifyPage extends StatefulWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  bool isLoading = true;
  String? errorMessage;
  List<Notificacao> notifications = [];

  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token'; // <- CHAVE CORRETA

  @override
  void initState() {
    super.initState();
    getnotifications();
  }

  Future<String?> _getToken() async {
    String? token;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey); // <- CHAVE CORRETA
    } else {
      token = await _secureStorage.read(key: _tokenKey); // <- CHAVE CORRETA
    }

    debugPrint("Token recuperado: $token");
    return token;
  }

  Future<void> getnotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Sessão expirada. Faça login novamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          kIsWeb
              ? 'http://127.0.0.1:8000/api/notifications'
              : 'http://127.0.0.1:800/api/notifications',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> listJson = data['notifications'] ?? [];

        final fetched =
            listJson.map((n) => Notificacao.fromJson(n)).toList();

        setState(() {
          notifications = fetched;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token expirado. Faça login novamente.';
        });
      } else {
        throw Exception('Erro: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    setState(() {
      isLoading = false;
      if (e is SocketException) {
        errorMessage = 'Sem conexão com a internet.';
      } else if (e is HttpException) {
        errorMessage = 'Erro no servidor.';
      } else if (e is FormatException) {
        errorMessage = 'Erro ao interpretar dados do servidor.';
      } else {
        errorMessage = 'Erro inesperado: ${e.toString()}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return ListTile(
          title: Text(notif.titulo),
          subtitle: Text(notif.mensagem),
        );
      },
    );
  }
}
