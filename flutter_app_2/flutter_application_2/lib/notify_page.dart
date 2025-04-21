import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/data/notificacao.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/notify_details_page.dart';
import 'package:flutter_application_2/relatorio_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotifyPage extends StatefulWidget {
  const NotifyPage({super.key});

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  bool isLoading = true;
  String? errorMessage;
  List<Notificacao> notifications = [];
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  @override
  void initState() {
    super.initState();
    getNotifications();
  }

  Future<String?> _getToken() async {
    try {
      String? token;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_tokenKey);
      } else {
        token = await _secureStorage.read(key: _tokenKey);
      }
      return token;
    } catch (e) {
      debugPrint("Erro ao obter token: $e");
      return null;
    }
  }

  Future<void> getNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token inválido');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> listJson = data['notifications'] ?? [];

        notifications = listJson.map((n) => Notificacao.fromJson(n)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada');
      } else {
        throw Exception('Erro: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = _handleError(e);
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _handleError(dynamic e) {
    if (e is SocketException) return 'Sem conexão com a internet';
    if (e is HttpException) return 'Erro no servidor';
    if (e is FormatException) return 'Dados inválidos';
    if (e.toString().contains('Sessão expirada')) return 'Faça login novamente';
    return 'Erro ao carregar notificações';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Notificações'),
      backgroundColor: Color(0xFF303030),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    if (errorMessage != null)
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.white)),
      );
    if (notifications.isEmpty)
      return const Center(
        child: Text(
          'Nenhuma notificação',
          style: TextStyle(color: Colors.white),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return _buildNotificationCard(notif);
      },
    );
  }

  Widget _buildNotificationCard(Notificacao notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF444444),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Conteúdo da notificação
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Placa: ${notif.placaVeiculo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getSolicitante(notif.detalhes),
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    notif.mensagem,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Botão Ver Mais
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                if (_getButtonText(notif) == 'Relatório') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RelatorioPage()),
                  );
                } else if (_getButtonText(notif) == 'Ver Mais') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => NotifyDetailsPage(
                            notificationJson: notif.rawJson,
                          ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF003366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Text(
                // if(_getButtonText(notif) == 'Relatório')
                _getButtonText(notif),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText(Notificacao notif) {
    if (notif.tipo.contains('viagem_concluida_admin')) {
      return 'Relatório';
    } else {
      return 'Ver Mais';
    }
  }

  String _getSolicitante(detalhes) {
    if (detalhes == null || detalhes['user'] == null) {
      return 'Informação indisponível';
    }
    final cargoId = detalhes['user']['cargo_id'];
    final nome = detalhes['user']['name'] ?? 'Desconhecido';
    if (cargoId == 1) {
      return 'Aprovador: $nome';
    } else if (cargoId == 2) {
      return 'Solicitante: $nome';
    }
    return 'Usuário desconhecido';
  }
}
