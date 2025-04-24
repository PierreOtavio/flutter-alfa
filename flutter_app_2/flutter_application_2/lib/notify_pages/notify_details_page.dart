import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/services/config.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class NotifyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> notificationJson;

  const NotifyDetailsPage({super.key, required this.notificationJson});

  @override
  _NotifyDetailsPageState createState() => _NotifyDetailsPageState();
}

class _NotifyDetailsPageState extends State<NotifyDetailsPage> {
  // >>> MUDANÇA: isLoading começa true para cobrir o fetch inicial do status <<<
  bool isLoading = true;
  String? responseMessage;
  String? errorMessage; // Para erros no fetch inicial
  // final _secureStorage = const FlutterSecureStorage();
  // final String _tokenKey = 'auth_token';

  bool _solicitacaoJaRespondida = false;
  String _statusAtual = '';
  // >>> NOVO: Variável para guardar os detalhes completos e atualizados <<<
  Map<String, dynamic>? _detalhesSolicitacaoAtualizados;

  @override
  void initState() {
    super.initState();
    // >>> MUDANÇA: Chama a nova função para buscar status atual <<<
    _fetchAndVerifyStatus();
  }

  // >>> REMOVIDO: _verificarStatusInicial não é mais necessário da forma antiga <<<
  // void _verificarStatusInicial() { ... }

  // >>> NOVO: Função para buscar o status atual da solicitação via API <<<
  Future<void> _fetchAndVerifyStatus() async {
    if (!mounted) return;
    setState(() {
      isLoading = true; // Garante que está carregando
      errorMessage = null; // Limpa erros antigos
    });

    final String? solicitacaoIdStr =
        widget.notificationJson['data']?['solicitacao_id']?.toString();
    final int? solicitacaoId =
        solicitacaoIdStr != null ? int.tryParse(solicitacaoIdStr) : null;

    if (solicitacaoId == null) {
      if (kDebugMode)
        print(
          "Erro: ID da solicitação inválido ou ausente no JSON da notificação.",
        );
      setState(() {
        isLoading = false;
        errorMessage = "Erro ao obter ID da solicitação da notificação.";
        _solicitacaoJaRespondida =
            true; // Trata como respondida para não mostrar botões
      });
      return;
    }

    final token = await ApiService().getAndValidateTokens();
    if (token == null) {
      if (kDebugMode) print("Erro: Token não encontrado para buscar status.");
      setState(() {
        isLoading = false;
        errorMessage = "Erro de autenticação.";
        _solicitacaoJaRespondida = true;
      });
      return;
    }

    try {
      if (kDebugMode)
        print("Buscando status atual para solicitação ID: $solicitacaoId");
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/api/solicitar/$solicitacaoId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Pega o mapa interno 'solicitar' que contém os dados atualizados
        final solicitacaoAtualizada =
            data['solicitar'] as Map<String, dynamic>?;

        if (solicitacaoAtualizada == null) {
          throw Exception(
            "Resposta da API inválida: objeto 'solicitar' não encontrado.",
          );
        }

        final status =
            solicitacaoAtualizada['situacao']?.toString().toLowerCase() ??
            'desconhecida';

        setState(() {
          _detalhesSolicitacaoAtualizados =
              solicitacaoAtualizada; // Guarda os detalhes atualizados
          _statusAtual = status;
          _solicitacaoJaRespondida = [
            'aceita',
            'recusada',
            'concluída',
            'finalizada',
          ].contains(_statusAtual);
          isLoading = false; // Termina o loading
          errorMessage = null; // Limpa erro se sucesso
        });
        if (kDebugMode)
          print(
            "Status atualizado da API: '$_statusAtual', Respondida: $_solicitacaoJaRespondida",
          );
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar status da solicitação.',
        );
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      if (kDebugMode) print('Erro em _fetchAndVerifyStatus: $e\n$stacktrace');
      setState(() {
        isLoading = false;
        // Tenta pegar o status do JSON original como fallback em caso de erro na API
        _verificarStatusDoJsonOriginal();
        // Mostra um erro mais amigável, mas permite ver os detalhes (se possível)
        errorMessage =
            "Não foi possível verificar o status atual. Exibindo dados da notificação.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      });
    }
  }

  // >>> NOVO: Função fallback para verificar status do JSON original se a API falhar <<<
  void _verificarStatusDoJsonOriginal() {
    String status = '';
    final data = widget.notificationJson['data'];
    if (data is Map) {
      final detalhes = data['detalhes'];
      if (detalhes is Map) {
        status = detalhes['situacao']?.toString().toLowerCase() ?? '';
        if (status.isEmpty && detalhes['solicitacao'] is Map) {
          status =
              detalhes['solicitacao']?['situacao']?.toString().toLowerCase() ??
              '';
        }
      }
      if (status.isEmpty) {
        status = data['situacao']?.toString().toLowerCase() ?? '';
      }
    }
    // Atualiza o estado COM BASE NO JSON ORIGINAL
    _statusAtual = status.isNotEmpty ? status : 'desconhecida';
    _solicitacaoJaRespondida = [
      'aceita',
      'recusada',
      'concluída',
      'finalizada',
    ].contains(_statusAtual);
    if (kDebugMode) {
      print(
        'Fallback: Status verificado do JSON original: "$_statusAtual", Respondida: $_solicitacaoJaRespondida',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // >>> MUDANÇA: Mostra loading se estiver buscando status inicial <<<
    if (isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Carregando Detalhes...'),
        backgroundColor: Color(0xFF303030),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // >>> MUDANÇA: Mostra erro crítico se o fetch inicial falhou completamente <<<
    if (errorMessage != null &&
        _detalhesSolicitacaoAtualizados == null &&
        !_statusAtual.isNotEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Erro'),
        backgroundColor: Color(0xFF303030),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // --- Extração de dados ---
    // Prioriza os dados atualizados da API, senão usa o JSON da notificação como fallback
    final fonteDetalhes =
        _detalhesSolicitacaoAtualizados // Usa os detalhes atualizados se disponíveis
        ??
        widget
            .notificationJson['data']?['detalhes'] // Senão, usa os detalhes do JSON original
        ??
        {}; // Fallback final: mapa vazio

    final solicitacaoId =
        widget.notificationJson['data']['solicitacao_id']?.toString() ?? '';

    // Pega o motivo da fonte de detalhes correta
    String motivo =
        fonteDetalhes['motivo']?.toString() ??
        widget.notificationJson['data']?['mensagem']
            ?.toString() ?? // Fallback para msg da notificação
        'Sem motivo especificado';
    if (motivo.startsWith('Solicitação de veículo de ')) {
      motivo = 'Solicitação de veículo';
    }

    // Pega datas/horas da fonte de detalhes correta, usando as chaves corretas que definimos na adaptação
    final dataInicio =
        fonteDetalhes['data_inicio'] ?? fonteDetalhes['prev_data_inicio'] ?? '';
    final dataFinal =
        fonteDetalhes['data_final'] ?? fonteDetalhes['prev_data_final'] ?? '';
    final horaInicio =
        fonteDetalhes['hora_inicio'] ?? fonteDetalhes['prev_hora_inicio'] ?? '';
    final horaFinal =
        fonteDetalhes['hora_final'] ?? fonteDetalhes['prev_hora_final'] ?? '';

    // Formatação de data/hora (mantida)
    String dataFormatada = '';
    // ... (código de formatação de data exatamente como antes) ...
    if (dataInicio.isNotEmpty) {
      try {
        final dtInicio = DateTime.parse(dataInicio.toString());
        dataFormatada = 'Data: ${DateFormat('dd/MM').format(dtInicio)}';
        if (dataFinal.isNotEmpty && dataFinal != dataInicio) {
          final dtFinal = DateTime.parse(dataFinal.toString());
          if (dtFinal.year != dtInicio.year) {
            dataFormatada =
                'Data: ${DateFormat('dd/MM/yy').format(dtInicio)} a ${DateFormat('dd/MM/yy').format(dtFinal)}';
          } else {
            dataFormatada += ' a ${DateFormat('dd/MM').format(dtFinal)}';
            if (dtInicio.year != DateTime.now().year) {
              dataFormatada += '/${DateFormat('yy').format(dtInicio)}';
            }
          }
        } else if (dtInicio.year != DateTime.now().year) {
          dataFormatada += '/${DateFormat('yy').format(dtInicio)}';
        }
      } catch (e) {
        //  if (kDebugMode) print("Erro ao formatar data: $e. Usando valor original.");
        dataFormatada = 'Data: $dataInicio';
        if (dataFinal.isNotEmpty && dataFinal != dataInicio) {
          dataFormatada += ' a $dataFinal';
        }
      }
    }

    String horaFormatada = '';
    // ... (código de formatação de hora exatamente como antes) ...
    if (horaInicio.isNotEmpty) {
      try {
        horaFormatada = 'Hora: ${horaInicio.toString().substring(0, 5)}';
        if (horaFinal.isNotEmpty) {
          horaFormatada += ' às ${horaFinal.toString().substring(0, 5)} h';
        }
      } catch (e) {
        //  if (kDebugMode) print("Erro ao formatar hora: $e. Usando valor original.");
        horaFormatada = 'Hora: $horaInicio';
        if (horaFinal.isNotEmpty) {
          horaFormatada += ' às $horaFinal h';
        }
      }
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Detalhes da Solicitação'),
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exibe os detalhes (Motivo, Previsão) - sem alterações na estrutura UI
            const Text(
              'Motivo da Utilização:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                motivo,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Previsão de utilização:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (dataFormatada.isEmpty && horaFormatada.isEmpty)
                    ? 'Sem previsão informada'
                    : '$dataFormatada\n$horaFormatada'.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const Spacer(),

            // Mensagem de Resposta da API (se houver)
            if (responseMessage != null &&
                responseMessage !=
                    errorMessage) // Não mostra se for msg de erro do fetch
              Container(
                // ... (estilo da caixa de mensagem como antes) ...
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isLoading // 'isLoading' aqui se refere ao loading da AÇÃO (aceitar/recusar)
                          ? Colors.orange
                          : (responseMessage!.toLowerCase().contains('erro') ||
                              responseMessage!.toLowerCase().contains('falha'))
                          ? Colors.redAccent
                          : Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  responseMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Observação ou Botões
            if (_solicitacaoJaRespondida)
              Container(
                // ... (estilo da observação como antes) ...
                width: double.infinity,
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  _statusAtual == 'aceita'
                      ? 'Obs: Esta solicitação já foi aceita.'
                      : _statusAtual == 'recusada'
                      ? 'Obs: Esta solicitação já foi recusada.'
                      // Adiciona mensagem para outros status finais
                      : ['concluída', 'finalizada'].contains(_statusAtual)
                      ? 'Obs: Esta solicitação já foi concluída.'
                      : 'Obs: Esta solicitação já foi processada ($_statusAtual).',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (!_solicitacaoJaRespondida)
              Column(
                // ... (botões Permitir/Negar como antes) ...
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed:
                        isLoading // Desabilita se estiver carregando a AÇÃO
                            ? null
                            : () =>
                                _responderSolicitacao(solicitacaoId, 'aceitar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          isLoading ? Colors.grey[700] : Colors.green,
                      foregroundColor:
                          isLoading ? Colors.grey[400] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading // Mostra indicador no botão se estiver processando AÇÃO
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Permitir',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        isLoading // Desabilita se estiver carregando a AÇÃO
                            ? null
                            : () async {
                              final motivoRecusaDialog =
                                  await _showRecusaDialog();
                              if (motivoRecusaDialog != null &&
                                  motivoRecusaDialog.isNotEmpty) {
                                _responderSolicitacao(
                                  solicitacaoId,
                                  'recusar',
                                  motivoRecusa: motivoRecusaDialog,
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          isLoading ? Colors.grey[700] : Colors.red,
                      foregroundColor:
                          isLoading ? Colors.grey[400] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading // Mostra indicador no botão se estiver processando AÇÃO
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Negar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Future<String?> _getToken() async {
  //   // ... (código _getToken sem alterações) ...
  //   try {
  //     String? token;
  //     if (kIsWeb) {
  //       final prefs = await SharedPreferences.getInstance();
  //       token = prefs.getString(_tokenKey);
  //     } else {
  //       token = await _secureStorage.read(key: _tokenKey);
  //     }
  //     return token;
  //   } catch (e) {
  //     debugPrint("Erro ao obter token: $e");
  //     return null;
  //   }
  // }

  Future<String?> _showRecusaDialog() async {
    // ... (código _showRecusaDialog sem alterações) ...
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
                final motivoTrimmed = motivoController.text.trim();
                if (motivoTrimmed.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(motivoTrimmed);
              },
              child: const Text('Recusar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _responderSolicitacao(
    String solicitacaoId,
    String acao, {
    String? motivoRecusa,
  }) async {
    // >>> MUDANÇA: 'isLoading' aqui se refere ao loading da AÇÃO <<<
    if (solicitacaoId.isEmpty) {
      setState(() {
        responseMessage = 'ID da solicitação não encontrado';
      });
      return;
    }
    setState(() {
      isLoading = true;
      responseMessage = 'Processando...';
    }); // Inicia loading da AÇÃO

    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token inválido');
      }
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

      if (!mounted) return; // Checa se ainda está montado após a chamada http

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false; // <<< PARA o loading da AÇÃO
          _solicitacaoJaRespondida = true;
          _statusAtual = acao == 'aceitar' ? 'aceita' : 'recusada';
          responseMessage =
              acao == 'aceitar'
                  ? 'Solicitação aceita com sucesso!'
                  : 'Solicitação recusada com sucesso!';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 409) {
        // Trata o erro 409 especificamente
        setState(() {
          isLoading = false; // <<< PARA o loading da AÇÃO
          _solicitacaoJaRespondida =
              true; // Marca como respondida, pois já estava
          _statusAtual =
              ''; // Poderia tentar buscar o status real aqui, mas é complexo
          responseMessage = null; // Limpa a mensagem de processando
          // A observação "já processada" será mostrada automaticamente pelo build
          // Exibe uma snackbar informando sobre o conflito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Esta solicitação já foi processada anteriormente.',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        });
        // Talvez buscar o status real aqui e atualizar _statusAtual se quiser a msg exata
        await _fetchAndVerifyStatus(); // Tenta buscar status atualizado para exibir msg correta
      } else {
        // Outros erros da API
        final data = jsonDecode(response.body);
        setState(() {
          isLoading = false; // <<< PARA o loading da AÇÃO
          responseMessage =
              data['message'] ??
              'Erro ao processar solicitação (${response.statusCode})';
        });
      }
    } catch (e) {
      // Erros de conexão, etc.
      if (!mounted) return;
      setState(() {
        isLoading = false; // <<< PARA o loading da AÇÃO
        responseMessage =
            "Falha na comunicação: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }
}
