import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/notify_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InicioSolicPage extends StatefulWidget {
  final int solicitacaoID;

  const InicioSolicPage({super.key, required this.solicitacaoID});

  @override
  State<InicioSolicPage> createState() => _InicioSolicPageState();
}

class _InicioSolicPageState extends State<InicioSolicPage> {
  bool isLoading = false;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  Map<String, dynamic>? solicitacaoDetalhes;
  DateTime? dataPrevPegar;
  DateTime? dataPrevDevolver;
  TimeOfDay? horaInicial;
  TimeOfDay? horaFinal;

  @override
  void initState() {
    super.initState();
    getSolicByID(widget.solicitacaoID);
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      } catch (e) {
        print("Erro ao ler SharedPreferences na Web: $e");
        return null;
      }
    } else {
      try {
        return await _secureStorage.read(key: _tokenKey);
      } on PlatformException catch (e) {
        print("Erro ao ler token do Secure Storage: $e");
        return null;
      }
    }
  }

  Future<void> getSolicByID(int id) async {
    setState(() => isLoading = true);
    final token = await _getToken();

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/solicitar/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final solicitacao = data['solicitar']; // Acesso direto ao objeto

        setState(() {
          solicitacaoDetalhes = solicitacao;
          dataPrevPegar = _parseDate(solicitacao?['prev_data_inicio']);
          dataPrevDevolver = _parseDate(solicitacao?['prev_data_final']);
          horaInicial = _parseTime(solicitacao?['prev_hora_inicio']);
          horaFinal = _parseTime(solicitacao?['prev_hora_final']);
        });
      } else {
        print('Erro na requisição: ${response.statusCode}');
        setState(() => solicitacaoDetalhes = null);
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
      setState(() => solicitacaoDetalhes = null);
    } finally {
      setState(() => isLoading = false);
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: CustomAppBar(title: 'Iniciar Solicitação'),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : solicitacaoDetalhes == null
              ? const Center(
                child: Text(
                  'Nenhum dado encontrado',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Container do veículo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF424242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuário Solicitante: ${solicitacaoDetalhes!['user']?['name'] ?? '--'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${solicitacaoDetalhes!['user']?['email'] ?? '--'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Placa do veículo: ${solicitacaoDetalhes!['veiculo']?['placa'] ?? '--'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Previsão de utilização
                    const Text(
                      'Previsão de utilização:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    // Container de data e hora
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF424242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data: ${dataPrevPegar != null ? DateFormat('dd/MM').format(dataPrevPegar!) : '--'} a ${dataPrevDevolver != null ? DateFormat('dd/MM').format(dataPrevDevolver!) : '--'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hora: ${horaInicial != null ? horaInicial!.format(context) : '--'} às ${horaFinal != null ? horaFinal!.format(context) : '--'} h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (solicitacaoDetalhes!['motivo'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Motivo: ${solicitacaoDetalhes!['motivo']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                          if (solicitacaoDetalhes!['situacao'] != null)
                            situacaoCard(solicitacaoDetalhes!['situacao']),
                        ],
                      ),
                    ),

                    const Spacer(),
                    _verifyAcception(solicitacaoDetalhes),
                  ],
                ),
              ),
    );
  }

  Widget situacaoCard(String situacao) {
    // Escolha a cor do card conforme a situação (opcional)
    Color backgroundColor;
    switch (situacao.toLowerCase()) {
      case 'pendente':
        backgroundColor = Colors.orange[700]!;
        break;
      case 'aceita':
        backgroundColor = Colors.green[700]!;
        break;
      case 'recusada':
        backgroundColor = Colors.red[700]!;
        break;
      default:
        backgroundColor = Colors.grey[700]!;
    }

    return Card(
      color: backgroundColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Situação: ${situacao[0].toUpperCase()}${situacao.substring(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyAcception(Map<String, dynamic>? solicitacaoDetalhes) {
    final int? cargoId = solicitacaoDetalhes?['user']?['cargo_id'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cargoId == 1)
          // Botão para cargo_id == 1 (navegação para notificações)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifyPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.notification_important,
              color: Colors.white,
            ), // Ícone de iniciar,
            label: const Text(
              'Aceitar nas notificações',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

        if (cargoId == 2) ...[
          // Botão Iniciar
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRCodeScannerPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Iniciar',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          const SizedBox(height: 12),

          // Botão Finalizar
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A65),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Finalizar',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}
