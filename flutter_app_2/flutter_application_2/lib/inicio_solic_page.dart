import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart';
// import 'package:flutter_application_2/components/qr_code_scan.dart'; // Importa Scanner
import 'package:flutter_application_2/solicitar_finalizar_page.dart'; // Importa Finalizar
// >>> ADICIONAR SE NECESSÁRIO PARA O FLUXO DO QR CODE <<<
import 'package:flutter_application_2/solicitar_iniciar_page.dart';
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
  State createState() => _InicioSolicPageState();
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

  int? _kmInicialConfirmado;

  // --- CORES PARA OS ESTADOS DOS BOTÕES ---
  static const Color _buttonEnabledBgColor = Color(0xFF013A65);
  static const Color _buttonEnabledFgColor = Colors.white;
  // MUDANÇA: Cores para o botão DESABILITADO
  static final Color _buttonDisabledBgColor =
      Colors.blue.shade100; // Azul claro
  static final Color _buttonDisabledFgColor =
      Colors.grey.shade700; // Cinza escuro para texto

  @override
  void initState() {
    super.initState();
    getSolicByID(widget.solicitacaoID);
  }

  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (kDebugMode) {
          print(
            'Token lido do SharedPreferences (Web): ${token != null ? "Encontrado" : "NÃO encontrado"}',
          );
        }
        return token;
      } else {
        final token = await _secureStorage.read(key: _tokenKey);
        if (kDebugMode) {
          print(
            'Token lido do SecureStorage (Mobile): ${token != null ? "Encontrado" : "NÃO encontrado"}',
          );
        }
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao ler token: $e");
      }
      return null;
    }
  }

  Future<void> getSolicByID(int id) async {
    if (!mounted) return;
    if (kDebugMode) {
      print("Iniciando getSolicByID para ID: $id");
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
      _kmInicialConfirmado = null;
    });

    final token = await _getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: Usuário não autenticado.';
      });
      if (kDebugMode) {
        print("Falha em getSolicByID: Token nulo.");
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/api/solicitar/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print(
          "Resposta da API GET /api/solicitar/$id - Status: ${response.statusCode}",
        );
      }

      if (!mounted) {
        if (kDebugMode) {
          print("Widget desmontado após chamada API.");
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final solicitacao = data['solicitar'] as Map<String, dynamic>?;

        if (solicitacao == null) {
          throw Exception(
            "Estrutura da resposta inválida: objeto 'solicitar' não encontrado.",
          );
        }

        int? kmInicialTemp;
        if (solicitacao['hist_veiculo'] != null &&
            solicitacao['hist_veiculo'] is Map) {
          final histVeiculo =
              solicitacao['hist_veiculo'] as Map<String, dynamic>;
          final kmInicioRaw = histVeiculo['km_inicio'];
          if (kDebugMode) {
            print(
              "Encontrado 'hist_veiculo'. km_inicio raw: $kmInicioRaw (Tipo: ${kmInicioRaw?.runtimeType})",
            );
          }
          if (kmInicioRaw is int) {
            kmInicialTemp = kmInicioRaw;
          } else if (kmInicioRaw is String) {
            kmInicialTemp = int.tryParse(kmInicioRaw);
          } else if (kmInicioRaw is double) {
            kmInicialTemp = kmInicioRaw.toInt();
          }

          final historicoTemp =
              solicitacao['historico'] as Map<String, dynamic>?;
          bool viagemIniciadaTemp =
              historicoTemp != null &&
              historicoTemp['data_inicio'] != null &&
              historicoTemp['data_inicio'].isNotEmpty;

          if (kmInicialTemp == 0 && !viagemIniciadaTemp) {
            kmInicialTemp = null;
            if (kDebugMode)
              print("KM Inicial era 0 antes do início, tratando como null.");
          }
        } else {
          if (kDebugMode) {
            print("'hist_veiculo' NÃO encontrado ou inválido.");
          }
        }
        if (kDebugMode) {
          print("KM Inicial processado: $kmInicialTemp");
        }

        setState(() {
          solicitacaoDetalhes = solicitacao;
          _kmInicialConfirmado = kmInicialTemp;

          dataPrevPegar = _parseDate(
            solicitacao['prev_data_inicio'] as String?,
          );
          dataPrevDevolver = _parseDate(
            solicitacao['prev_data_final'] as String?,
          );
          horaInicial = _parseTime(solicitacao['prev_hora_inicio'] as String?);
          horaFinal = _parseTime(solicitacao['prev_hora_final'] as String?);
          _situacao = solicitacao['situacao'] as String? ?? 'desconhecida';

          final historico = solicitacao['historico'] as Map<String, dynamic>?;
          _viagemIniciada =
              historico != null &&
              historico['data_inicio'] != null &&
              historico['data_inicio'].isNotEmpty;
          _viagemFinalizada =
              historico != null &&
              historico['data_final'] != null &&
              historico['data_final'].isNotEmpty;

          isLoading = false;
        });
        if (kDebugMode) {
          print(
            "Estado atualizado. Viagem Iniciada: $_viagemIniciada, Finalizada: $_viagemFinalizada, KM Inicial Confirmado: $_kmInicialConfirmado",
          );
        }
      } else {
        String errorMsg = 'Erro desconhecido';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg =
              'Erro ${response.statusCode}: ${errorData['error'] ?? errorData['message'] ?? response.reasonPhrase}';
        } catch (e) {
          errorMsg =
              'Erro ${response.statusCode}: ${response.reasonPhrase}. Falha ao decodificar corpo do erro.';
        }
        setState(() {
          isLoading = false;
          errorMessage = errorMsg;
        });
        if (kDebugMode) {
          print("Erro ao buscar solicitação $id: $errorMessage");
        }
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      if (kDebugMode) {
        print('Erro em getSolicByID para $id: $e\n$stacktrace');
      }
      setState(() {
        isLoading = false;
        errorMessage = 'Erro de conexão ou inesperado: ${e.runtimeType}';
      });
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao parsear data: $dateString - $e");
      }
      return null;
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao parsear hora: $timeString - $e");
      }
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    if (kDebugMode) {
      print("Exibindo SnackBar de erro: $message");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    if (kDebugMode) {
      print("Exibindo SnackBar de sucesso: $message");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    String textoSituacao = 'Situação: Desconhecida';
    if (!isLoading && errorMessage == null && solicitacaoDetalhes != null) {
      textoSituacao =
          'Situação: ${_situacao[0].toUpperCase()}${_situacao.substring(1)}';
      if (_situacao == 'aceita' && _viagemIniciada && !_viagemFinalizada) {
        textoSituacao = 'Situação: Em Andamento';
      } else if (_situacao == 'aceita' && !_viagemIniciada) {
        textoSituacao = 'Situação: Aceita (Aguardando Início)';
      } else if (_situacao == 'concluída') {
        textoSituacao = 'Situação: Concluída';
      }
    }

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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => getSolicByID(widget.solicitacaoID),
                        icon: Icon(Icons.refresh),
                        label: Text("Tentar Novamente"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _buttonEnabledBgColor, // Usa cor habilitada
                          foregroundColor: _buttonEnabledFgColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : solicitacaoDetalhes == null
              ? Center(
                child: Text(
                  'Nenhuma informação disponível.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
              : RefreshIndicator(
                onRefresh: () => getSolicByID(widget.solicitacaoID),
                color: Colors.white,
                backgroundColor: Color(0xFF013A65),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Card Veículo
                    if (solicitacaoDetalhes!['veiculo'] != null &&
                        solicitacaoDetalhes!['veiculo'] is Map)
                      Card(
                        color: const Color(0xFF424242),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veículo: ${solicitacaoDetalhes!['veiculo']['placa'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '${solicitacaoDetalhes!['veiculo']['marca']?['marca'] ?? ''} ${solicitacaoDetalhes!['veiculo']['modelo']?['modelo'] ?? ''}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Container Detalhes da Reserva
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
                              (solicitacaoDetalhes!['motivo'] as String)
                                  .isNotEmpty)
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
                          situacaoCard(_situacao, textoSituacao),
                          if (_situacao == 'recusada' &&
                              solicitacaoDetalhes!['motivo_recusa'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Motivo Recusa: ${solicitacaoDetalhes!['motivo_recusa']}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          if (_kmInicialConfirmado != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'KM Inicial Registrado: $_kmInicialConfirmado km',
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      persistentFooterButtons:
          isLoading || solicitacaoDetalhes == null
              ? null
              : [_buildActionButtons(solicitacaoDetalhes)],
    );
  }

  Widget situacaoCard(String situacaoKey, String textoSituacao) {
    Color backgroundColor;
    IconData iconData;
    switch (situacaoKey.toLowerCase()) {
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic>? detalhes) {
    if (detalhes == null) return const SizedBox.shrink();

    final int? cargoId = detalhes['user']?['cargo_id'];
    Widget buttonsContent;

    if (cargoId == 1) {
      // Botão Admin
      if (_situacao == 'pendente') {
        buttonsContent = ElevatedButton.icon(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifyPage()),
              ).then((_) {
                if (kDebugMode)
                  print("Retornou da tela de avaliação, atualizando...");
                getSolicByID(widget.solicitacaoID);
              }),
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonEnabledBgColor, // Cor Habilitado
            foregroundColor: _buttonEnabledFgColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.notification_important, color: Colors.white),
          label: const Text(
            'Avaliar Solicitação',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        );
      } else {
        buttonsContent = const SizedBox.shrink();
      }
    } else if (cargoId == 2) {
      // Botões Motorista
      bool podeIniciar = _situacao == 'aceita' && !_viagemIniciada;
      bool podeFinalizar =
          _situacao == 'aceita' && _viagemIniciada && !_viagemFinalizada;
      Veiculo? veiculoParaAcao;
      if (detalhes['veiculo'] != null && detalhes['veiculo'] is Map) {
        try {
          veiculoParaAcao = Veiculo.fromJson(
            detalhes['veiculo'] as Map<String, dynamic>,
          );
        } catch (e) {
          if (kDebugMode) print("Erro ao reconstruir Veiculo: $e");
        }
      }
      final int? kmInicial = _kmInicialConfirmado;

      buttonsContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Botão Iniciar ---
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text(
              'Iniciar Viagem (Ler QR Code)',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              // Cores baseadas se está habilitado ou não
              backgroundColor: _buttonEnabledBgColor, // Cor quando habilitado
              foregroundColor: _buttonEnabledFgColor, // Cor do texto habilitado
              // MUDANÇA: Cores específicas para DESABILITADO
              disabledBackgroundColor: _buttonDisabledBgColor,
              disabledForegroundColor: _buttonDisabledFgColor,
              // --- Fim da Mudança ---
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Define onPressed como null se não pode iniciar (desabilita o botão)
            onPressed:
                !podeIniciar
                    ? null
                    : () {
                      if (veiculoParaAcao == null) {
                        _showErrorSnackBar(
                          'Erro: Dados do veículo indisponíveis.',
                        );
                        return;
                      }
                      if (kDebugMode) print("Navegando para Iniciar...");
                      // Navega para Iniciar (simplificado, assumindo que IniciarPage existe)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QRCodeScannerPage(
                                // veiculo: veiculoParaAcao!,
                                // solicitacaoId: widget.solicitacaoID,
                                // isUrgent: false,
                              ),
                        ),
                      ).then((success) {
                        if (kDebugMode)
                          print(
                            "Retornou após fluxo de início. Atualizando...",
                          );
                        getSolicByID(widget.solicitacaoID);
                        if (success == true)
                          _showSuccessSnackBar("Viagem iniciada!");
                      });
                    },
          ),
          const SizedBox(height: 12),
          // --- Botão Finalizar ---
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Finalizar Viagem',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              // Cores baseadas se está habilitado ou não
              backgroundColor: _buttonEnabledBgColor, // Cor quando habilitado
              foregroundColor: _buttonEnabledFgColor, // Cor do texto habilitado
              // MUDANÇA: Cores específicas para DESABILITADO
              disabledBackgroundColor: _buttonDisabledBgColor,
              disabledForegroundColor: _buttonDisabledFgColor,
              // --- Fim da Mudança ---
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Define onPressed como null se não pode finalizar (desabilita o botão)
            onPressed:
                !podeFinalizar
                    ? null
                    : () {
                      if (veiculoParaAcao == null) {
                        _showErrorSnackBar(
                          'Erro: Dados do veículo indisponíveis.',
                        );
                        return;
                      }
                      if (kmInicial == null) {
                        _showErrorSnackBar('Erro: KM inicial não carregado.');
                        if (kDebugMode)
                          print("ALERTA: kmInicial null ao finalizar.");
                        return;
                      }
                      if (kDebugMode)
                        print("Navegando para Finalizar com KM: $kmInicial");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SolicitarFinalizarPage(
                                solicitacaoId: widget.solicitacaoID,
                                veiculo: veiculoParaAcao!,
                                kmInicial: kmInicial,
                              ),
                        ),
                      ).then((success) {
                        if (kDebugMode)
                          print(
                            "Retornou após fluxo de finalizar. Atualizando...",
                          );
                        getSolicByID(widget.solicitacaoID);
                        if (success == true)
                          _showSuccessSnackBar("Viagem finalizada!");
                      });
                    },
          ),
        ],
      );
    } else {
      buttonsContent = const SizedBox.shrink();
    }

    // Adiciona Padding em volta do conteúdo dos botões
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: buttonsContent,
    );
  }
}
