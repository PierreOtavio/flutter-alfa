import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart'; // Importa Scanner
import 'package:flutter_application_2/solicitar_finalizar_page.dart'; // Importa Finalizar
import 'package:flutter_application_2/data/veiculo.dart'; // Importa Modelo Veiculo
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
  bool isLoading = true;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  Map<String, dynamic>? solicitacaoDetalhes;
  DateTime? dataPrevPegar, dataPrevDevolver;
  TimeOfDay? horaInicial, horaFinal;
  String? errorMessage;
  bool _viagemIniciada = false;
  bool _viagemFinalizada = false;
  String _situacao = 'pendente';

  @override
  void initState() {
    super.initState();
    getSolicByID(widget.solicitacaoID);
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } else {
      return await _secureStorage.read(key: _tokenKey);
    }
  }

  Future<void> getSolicByID(int id) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final token = await _getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: Usuário não autenticado.';
      });
      return;
    }

    try {
      // Garanta que a API retorna 'historico' e 'hist_veiculo' (com snake_case)
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/api/solicitar/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final solicitacao = data['solicitar'];
        setState(() {
          solicitacaoDetalhes = solicitacao;
          dataPrevPegar = _parseDate(solicitacao?['prev_data_inicio']);
          dataPrevDevolver = _parseDate(solicitacao?['prev_data_final']);
          horaInicial = _parseTime(solicitacao?['prev_hora_inicio']);
          horaFinal = _parseTime(solicitacao?['prev_hora_final']);
          _situacao = solicitacao?['situacao'] ?? 'desconhecida';

          // Verifica o estado da viagem baseado no *histórico da solicitação*
          final historico = solicitacao?['historico']; // Tabela hist_solicitars
          _viagemIniciada =
              historico != null && historico['data_inicio'] != null;
          _viagemFinalizada =
              historico != null && historico['data_final'] != null;

          isLoading = false;
        });
      } else {
        // Tratamento de erro... (mantido como antes)
        final errorData = jsonDecode(response.body);
        setState(() {
          isLoading = false;
          errorMessage =
              'Erro ${response.statusCode}: ${errorData['error'] ?? response.reasonPhrase}';
        });
      }
    } catch (e) {
      // Tratamento de erro... (mantido como antes)
      setState(() {
        isLoading = false;
        errorMessage = 'Erro de conexão ou inesperado.';
      });
    }
  }

  DateTime? _parseDate(String? dateString) {
    /* Mantido */
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    /* Mantido */
    if (timeString == null) return null;
    try {
      final p = timeString.split(':');
      if (p.length >= 2)
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    /* Mantido */
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estrutura do build mantida (Scaffold, AppBar, Loading, Error, Content Column)
    // ...
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: CustomAppBar(title: 'Detalhes da Solicitação'),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : errorMessage != null
              ? Center(
                /* Widget de Erro */ child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : solicitacaoDetalhes == null
              ? const Center(
                /* Widget Sem Dados */ child: Text(
                  'Nenhuma informação disponível.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
              : Padding(
                /* Conteúdo Principal */
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Container do usuário e veículo (mantido)
                    Container(/* ... */),
                    const SizedBox(height: 16),
                    // Container de previsão/motivo/situação (mantido)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF424242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalhes da Reserva:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Data Prevista: ${dataPrevPegar != null ? DateFormat('dd/MM/yyyy').format(dataPrevPegar!) : '--'} a ${dataPrevDevolver != null ? DateFormat('dd/MM/yyyy').format(dataPrevDevolver!) : '--'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hora Prevista: ${horaInicial != null ? horaInicial!.format(context) : '--'} às ${horaFinal != null ? horaFinal!.format(context) : '--'} h',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (solicitacaoDetalhes!['motivo'] != null &&
                              solicitacaoDetalhes!['motivo'].isNotEmpty)
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
                          // Card de situação
                          situacaoCard(_situacao),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildActionButtons(solicitacaoDetalhes), // Botões de Ação
                  ],
                ),
              ),
    );
    // ...
  }

  Widget situacaoCard(String situacao) {
    /* Mantido como antes */
    Color backgroundColor;
    IconData iconData;
    switch (situacao.toLowerCase()) {
      case 'pendente':
        backgroundColor = Colors.orange[700]!;
        iconData = Icons.hourglass_empty;
        break;
      case 'aceita':
        backgroundColor =
            _viagemIniciada ? Colors.blue[700]! : Colors.green[700]!;
        iconData =
            _viagemIniciada ? Icons.directions_car : Icons.check_circle_outline;
        break;
      case 'recusada':
        backgroundColor = Colors.red[700]!;
        iconData = Icons.cancel_outlined;
        break;
      case 'concluída':
        backgroundColor = Colors.grey[700]!;
        iconData = Icons.check_circle;
        break;
      default:
        backgroundColor = Colors.grey[700]!;
        iconData = Icons.help_outline;
    }
    String textoSituacao =
        'Situação: ${situacao[0].toUpperCase()}${situacao.substring(1)}';
    if (_situacao == 'aceita' && _viagemIniciada && !_viagemFinalizada) {
      textoSituacao = 'Situação: Em Andamento';
    }
    return Card(
      color: backgroundColor,
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              textoSituacao,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic>? detalhes) {
    if (detalhes == null) return const SizedBox.shrink();
    final int? cargoId = detalhes['user']?['cargo_id'];

    // --- Lógica Admin (cargo_id == 1) --- Mantida
    if (cargoId == 1) {
      if (_situacao == 'pendente') {
        return ElevatedButton.icon(
          /* Botão Avaliar */
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifyPage()),
              ).then((_) => getSolicByID(widget.solicitacaoID)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF013A65),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.notification_important, color: Colors.white),
          label: const Text(
            'Avaliar Solicitação',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
    // --- Lógica Usuário Comum (cargo_id == 2) ---
    else if (cargoId == 2) {
      bool podeIniciar = _situacao == 'aceita' && !_viagemIniciada;
      bool podeFinalizar =
          _situacao == 'aceita' && _viagemIniciada && !_viagemFinalizada;

      Veiculo? veiculoParaAcao;
      if (detalhes['veiculo'] != null) {
        try {
          veiculoParaAcao = Veiculo.fromJson(detalhes['veiculo']);
        } catch (e) {
          print("Erro ao reconstruir Veiculo: $e");
        }
      }

      // <<< Acessa km_inicio da relação hist_veiculo (snake_case) >>>
      final int? kmInicial =
          detalhes['histVeiculo']?['km_inicio']; // Não precisa mais de km_velocimetro aqui

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botão Iniciar (Navega para QRCodeScannerPage)
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text(
              'Iniciar Viagem (Ler QR Code)',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  podeIniciar ? const Color(0xFF013A65) : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (podeIniciar) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRCodeScannerPage(),
                  ),
                ).then((_) => getSolicByID(widget.solicitacaoID));
              } else {
                /* Mostra erro */
                if (_situacao != 'aceita')
                  _showErrorSnackBar(
                    'A solicitação precisa estar "Aceita" para iniciar.',
                  );
                else if (_viagemIniciada)
                  _showErrorSnackBar('Esta viagem já foi iniciada.');
                else
                  _showErrorSnackBar(
                    'Não é possível iniciar a viagem nesta situação.',
                  );
              }
            },
          ),
          const SizedBox(height: 12),
          // Botão Finalizar (Navega para SolicitarFinalizarPage)
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Finalizar Viagem',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  podeFinalizar ? const Color(0xFF013A65) : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (podeFinalizar) {
                if (veiculoParaAcao == null) {
                  _showErrorSnackBar('Erro: Dados do veículo indisponíveis.');
                  return;
                }
                if (kmInicial == null) {
                  // Verifica se o KM inicial foi carregado
                  _showErrorSnackBar(
                    'Erro: KM inicial da viagem não encontrado.',
                  );
                  print(
                    "ALERTA: kmInicial é null ao tentar finalizar solicitação ${widget.solicitacaoID}",
                  );
                  return;
                }
                // Navega passando os dados corretos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SolicitarFinalizarPage(
                          solicitacaoId: widget.solicitacaoID,
                          veiculo: veiculoParaAcao!, // O objeto veículo
                          kmInicial:
                              kmInicial, // O KM inicial lido de hist_veiculo
                        ),
                  ),
                ).then((_) => getSolicByID(widget.solicitacaoID));
              } else {
                /* Mostra erro */
                if (_situacao != 'aceita')
                  _showErrorSnackBar(
                    'A solicitação precisa estar "Aceita" para finalizar.',
                  );
                else if (!_viagemIniciada)
                  _showErrorSnackBar(
                    'A viagem precisa ser iniciada antes de finalizar.',
                  );
                else if (_viagemFinalizada)
                  _showErrorSnackBar('Esta viagem já foi finalizada.');
                else
                  _showErrorSnackBar(
                    'Não é possível finalizar a viagem nesta situação.',
                  );
              }
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink(); // Caso de cargo desconhecido
  }
}
