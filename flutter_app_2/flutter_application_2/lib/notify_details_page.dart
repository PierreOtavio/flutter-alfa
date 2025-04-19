import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotifyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> notificationJson;

  const NotifyDetailsPage({super.key, required this.notificationJson});

  @override
  _NotifyDetailsPageState createState() => _NotifyDetailsPageState();
}

class _NotifyDetailsPageState extends State<NotifyDetailsPage> {
  bool isLoading = false;
  String? responseMessage;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  @override
  Widget build(BuildContext context) {
    // Extrair o ID da solicitação do JSON
    final solicitacaoId =
        widget.notificationJson['data']['solicitacao_id']?.toString() ?? '';

    // Extrair mensagem para o motivo - CORREÇÃO AQUI
    final motivo =
        widget
            .notificationJson['data']['detalhes']?['solicitacao']?['motivo'] ??
        widget.notificationJson['data']['motivo'] ??
        widget.notificationJson['data']['mensagem'] ??
        'Sem motivo especificado';
    // Extrair informações de data e hora
    final detalhes = widget.notificationJson['data']['detalhes'] ?? {};
    final dataInicio = detalhes['data_inicio'] ?? detalhes['data'] ?? '';
    final dataFinal = detalhes['data_final'] ?? '';
    final horaInicio = detalhes['hora_inicio'] ?? '';
    final horaFinal = detalhes['hora_final'] ?? '';

    // Formatar data/hora para exibição
    String dataFormatada = '';
    if (dataInicio.isNotEmpty) {
      final dataPartes = dataInicio.toString().split('-');
      if (dataPartes.length == 3) {
        dataFormatada = 'Data: ${dataPartes[2]}/${dataPartes[1]}';
        if (dataFinal.isNotEmpty && dataFinal != dataInicio) {
          final dataFinalPartes = dataFinal.toString().split('-');
          dataFormatada += ' a ${dataFinalPartes[2]}/${dataFinalPartes[1]}';
        }
      }
    }

    String horaFormatada = '';
    if (horaInicio.isNotEmpty) {
      horaFormatada = 'Hora: ${horaInicio.toString().substring(0, 5)}';
      if (horaFinal.isNotEmpty) {
        horaFormatada += ' às ${horaFinal.toString().substring(0, 5)} h';
      }
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Notificações'),
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivo da Utilização
            Text(
              'Motivo da Utilização:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                motivo,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            SizedBox(height: 16),

            // Previsão de utilização
            Text(
              'Previsão de utilização:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$dataFormatada\n$horaFormatada',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            Spacer(),

            // Mensagem de resposta (se houver)
            if (responseMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isLoading ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  responseMessage!,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),

            // Botões Permitir e Negar
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () =>
                              _responderSolicitacao(solicitacaoId, 'aceitar'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Permitir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            final motivo = await _showRecusaDialog();
                            if (motivo != null && motivo.isNotEmpty) {
                              _responderSolicitacao(
                                solicitacaoId,
                                'recusar',
                                motivoRecusa: motivo,
                              );
                            }
                          },

                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Negar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Obter token de autenticação
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

  Future<String?> _showRecusaDialog() async {
    final TextEditingController motivoController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF444444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Motivo da Recusa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: motivoController,
            maxLength: 255,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Digite o motivo da recusa...',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF303030),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1818),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (motivoController.text.trim().isEmpty) return;
                Navigator.of(context).pop(motivoController.text.trim());
              },
              child: const Text('Recusar'),
            ),
          ],
        );
      },
    );
  }

  // Enviar resposta (aceitar ou recusar) para a API
  Future<void> _responderSolicitacao(
    String solicitacaoId,
    String acao, {
    String? motivoRecusa,
  }) async {
    if (solicitacaoId.isEmpty) {
      setState(() {
        responseMessage = 'ID da solicitação não encontrado';
      });
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = 'Processando...';
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token inválido');
      }

      // Monta o corpo da requisição
      final Map<String, dynamic> bodyMap = {'button': acao};
      if (acao == 'recusar' &&
          motivoRecusa != null &&
          motivoRecusa.isNotEmpty) {
        bodyMap['motivo_recusa'] = motivoRecusa;
      }
      final body = jsonEncode(bodyMap);

      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/api/solicitar/$solicitacaoId/aceitarOuRecusar',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          responseMessage =
              acao == 'aceitar'
                  ? 'Solicitação aceita com sucesso!'
                  : 'Solicitação recusada com sucesso!';
        });

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao processar solicitação');
      }
    } catch (e) {
      setState(() {
        responseMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
