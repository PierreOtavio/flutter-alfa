import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dsart';

class NotificationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsPage({super.key, required this.notification});

  @override
  State<NotificationDetailsPage> createState() =>
      _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  bool _isLoading = false;
  Future<void> _handleResponse(String action, {String? motivoRecusa}) async {
    setState(() => _isLoading = true);

    try {
      final token = await ApiService().getToken();
      final solicitacaoId = widget.notification['data']['solicitacao_id'];
      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/solicitar/$solicitacaoId/aceitarOuRecusar',
      );

      final body = {
        'button': action,
        if (action == 'recusar') 'motivo_recusa': motivoRecusa ?? '',
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      );

      if (response.statusCode == 200) {
        final message =
            action == 'aceitar'
                ? 'Solicitação aceita com sucesso!'
                : 'Solicitação recusada!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao processar solicitação',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.yellow,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro de conexão com o servidor',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRecusarDialog() async {
    final TextEditingController motivoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.transparent, width: 2),
          ),
          title: const Text(
            'Motivo da Recusa',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: TextField(
            style: TextStyle(color: Colors.white),
            controller: motivoController,
            autofocus: true,
            maxLength: 255,
            decoration: const InputDecoration(
              // hintText: 'Descreva o motivo da recusa',
              hintStyle: TextStyle(color: Colors.white),
              labelText: 'Motivo',
              labelStyle: TextStyle(color: Colors.white),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                overlayColor: Colors.white,
              ),
              child: const Text(
                'Enviar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                if (motivoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O motivo é obrigatório!')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _handleResponse(
                  'recusar',
                  motivoRecusa: motivoController.text.trim(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String formatarPeriodoNotificacao(
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    // Data
    DateTime? dataInicio =
        data['data_inicio'] != null
            ? DateTime.tryParse(data['data_inicio'])
            : null;
    DateTime? dataFinal =
        data['data_final'] != null
            ? DateTime.tryParse(data['data_final'])
            : null;

    // Hora
    TimeOfDay? horaInicio =
        data['hora_inicio'] != null
            ? TimeOfDay(
              hour: int.parse(data['hora_inicio'].substring(0, 2)),
              minute: int.parse(data['hora_inicio'].substring(3, 5)),
            )
            : null;

    TimeOfDay? horaFinal =
        data['hora_final'] != null
            ? TimeOfDay(
              hour: int.parse(data['hora_final'].substring(0, 2)),
              minute: int.parse(data['hora_final'].substring(3, 5)),
            )
            : null;

    final formatoData = DateFormat('dd/MM/yyyy');
    String dataStr = '';
    if (dataInicio != null && dataFinal != null) {
      dataStr =
          'Data: ${formatoData.format(dataInicio)} a ${formatoData.format(dataFinal)}';
    }

    String formatHora(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    String horaStr = '';
    if (horaInicio != null && horaFinal != null) {
      horaStr = 'Hora: ${formatHora(horaInicio)} às ${formatHora(horaFinal)} h';
    }

    return '$dataStr\n$horaStr';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.notification['data']['detalhes'];
    final motivo =
        widget.notification['data']['detalhes']['solicitacao']?['motivo'] ??
        widget.notification['data']['detalhes']['motivo'] ??
        'Motivo não especificado';
    final situacao =
        data['situacao'] ?? data['solicitacao']?['situacao'] ?? 'pendente';
    final periodo = formatarPeriodoNotificacao(data, context);
    final largura = MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      appBar: CustomAppBar(title: 'Detalhes da Notificação'),
      backgroundColor: const Color(0xFF303030),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: largura,
              height: 600,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 22),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: Offset(4, 4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motivo da Utilização:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          motivo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: Offset(4, 4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Previsão de utilização:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          periodo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white),
            if (situacao != 'aceita' && situacao != 'recusada') ...[
              SizedBox(
                width: largura,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23B04B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleResponse('aceitar'),
                  child: const Text(
                    'Permitir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: largura,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showRecusarDialog,
                  child: const Text(
                    'Negar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'Obs: Solicitação já foi $situacao, para mais informações, acesse o website.',
                  style: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
