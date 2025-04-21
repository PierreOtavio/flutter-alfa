import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // PlatformException não está sendo capturada aqui
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/components/qr_code_scan.dart';
import 'package:flutter_application_2/solicitar_finalizar_page.dart'; // Importa Finalizar
import 'package:flutter_application_2/data/veiculo.dart'; // Importa Modelo Veiculo
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/notify_details_page.dart'; // Importa detalhes da notificação
import 'package:flutter_application_2/goals/globals.dart'; // Importa globals para 'instance'
import 'package:flutter_application_2/data/user.dart'; // Importa User para checar 'instance'
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
  bool isLoading = true; // Começa carregando
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
  static final Color _buttonDisabledBgColor = Colors.blue.shade100;
  static final Color _buttonDisabledFgColor = Colors.grey.shade700;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      solicitacaoDetalhes = null;
    });

    if (instance == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage =
            "Erro crítico: Informações do usuário não carregadas. Tente fazer login novamente.";
      });
      if (kDebugMode) {
        print(
          "Falha ao carregar dados iniciais: Instância global 'instance' é nula.",
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        "Instância do usuário encontrada: ID=${instance!.id}, CargoID=${instance!.cargo.id}",
      );
    }
    await getSolicByID(widget.solicitacaoID);
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        // if (kDebugMode) {
        //   print(
        //     "Token lido do SharedPreferences (Web): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        //   );
        // }
        return token;
      } catch (e) {
        if (kDebugMode) print("Erro ao ler SharedPreferences na Web: $e");
        return null;
      }
    } else {
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        // if (kDebugMode) {
        //   print(
        //     "Token lido do Secure Storage (Mobile): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        //   );
        // }
        return token;
      } catch (e) {
        if (kDebugMode) print("Erro ao ler token do Secure Storage: $e");
        return null;
      }
    }
  }

  Future<void> getSolicByID(int id) async {
    if (!mounted) return;
    if (kDebugMode) {
      print("Iniciando getSolicByID para ID: $id");
    }
    setState(() {
      solicitacaoDetalhes = null;
      _kmInicialConfirmado = null;
      _viagemIniciada = false;
      _viagemFinalizada = false;
      _situacao = 'pendente';
      // Mantém isLoading = true até o fim ou erro
    });

    final token = await _getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: Usuário não autenticado (token ausente).';
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

      // if (kDebugMode) {
      //   print("Resposta da API GET /api/solicitar/$id - Status: ${response.statusCode}");
      // }

      if (!mounted) return;

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
          }
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
          errorMessage = null;
        });
        // if (kDebugMode) { print("Estado atualizado com sucesso."); }
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
          solicitacaoDetalhes = null;
        });
        if (kDebugMode) print("Erro ao buscar solicitação $id: $errorMessage");
      }
    } catch (e, stacktrace) {
      if (!mounted) return;
      if (kDebugMode) print('Erro em getSolicByID para $id: $e\n$stacktrace');
      setState(() {
        isLoading = false;
        errorMessage = 'Erro de conexão ou inesperado: ${e.runtimeType}';
        solicitacaoDetalhes = null;
      });
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
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
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    String textoSituacao = 'Situação: Carregando...';
    if (!isLoading && errorMessage == null && solicitacaoDetalhes != null) {
      textoSituacao =
          'Situação: ${_situacao[0].toUpperCase()}${_situacao.substring(1)}';
      if (_situacao == 'aceita' && _viagemIniciada && !_viagemFinalizada) {
        textoSituacao = 'Situação: Em Andamento';
      } else if (_situacao == 'aceita' && !_viagemIniciada) {
        textoSituacao = 'Situação: Aceita (Aguardando Início)';
      } else if (_situacao == 'concluída' || _situacao == 'finalizada') {
        textoSituacao = 'Situação: Concluída';
      } else if (_situacao == 'recusada') {
        textoSituacao = 'Situação: Recusada';
      } else if (_situacao == 'pendente') {
        textoSituacao = 'Situação: Pendente';
      }
    } else if (!isLoading && errorMessage != null) {
      textoSituacao = 'Situação: Erro ao carregar';
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
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadInitialData,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Tentar Novamente"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonEnabledBgColor,
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
                  'Nenhuma informação disponível para esta solicitação.',
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${solicitacaoDetalhes!['veiculo']['marca']?['marca'] ?? ''} ${solicitacaoDetalhes!['veiculo']['modelo']?['modelo'] ?? ''}',
                                style: const TextStyle(
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
                          situacaoCard(
                            _situacao,
                            textoSituacao,
                          ), // Card de Situação
                          if (_situacao == 'recusada' &&
                              solicitacaoDetalhes!['motivo_recusa'] != null &&
                              (solicitacaoDetalhes!['motivo_recusa'] as String)
                                  .isNotEmpty)
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
          isLoading ||
                  errorMessage != null ||
                  solicitacaoDetalhes == null ||
                  instance == null
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
        bool viagemEmAndamento = _viagemIniciada && !_viagemFinalizada;
        backgroundColor =
            viagemEmAndamento ? Colors.blue[700]! : Colors.green[700]!;
        iconData =
            viagemEmAndamento
                ? Icons.directions_car
                : Icons.check_circle_outline;
        break;
      case 'recusada':
        backgroundColor = Colors.red[700]!;
        iconData = Icons.cancel_outlined;
        break;
      case 'concluída':
      case 'finalizada':
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

  // >>> VERSÃO CORRIGIDA: Função _buildActionButtons com lógica para Admin dono <<<
  Widget _buildActionButtons(Map<String, dynamic>? detalhes) {
    // Validações iniciais
    if (detalhes == null || instance == null) {
      if (kDebugMode)
        print(
          "Botões não renderizados: Detalhes ou instância global ausentes.",
        );
      return const SizedBox.shrink();
    }

    // Pega ID e Cargo da instância global
    final int loggedInUserId = instance!.id;
    // >>> IMPORTANTE: Verifique se o acesso ao ID do cargo está correto <<<
    final int loggedInUserCargoId =
        instance!.cargo.id; // Ou instance!.cargo_id;

    // Obtém o ID do criador da solicitação
    final int? creatorUserId = detalhes['user']?['id'];
    if (creatorUserId == null) {
      if (kDebugMode)
        print(
          "Botões não renderizados: ID do criador da solicitação ausente nos detalhes.",
        );
      return const SizedBox.shrink();
    }

    final bool isOwner = (loggedInUserId == creatorUserId);
    List<Widget> buttonsList = []; // Lista para acumular os botões

    // if (kDebugMode) {
    //    print("Verificando botões: LoggedInUserID: $loggedInUserId, CreatorUserID: $creatorUserId, IsOwner: $isOwner, LoggedInUserCargoID: $loggedInUserCargoId, Situação: $_situacao");
    // }

    // 1. Botão de Avaliar (Exclusivo para Admin e situação pendente)
    if (loggedInUserCargoId == 1 && _situacao == 'pendente') {
      buttonsList.add(
        ElevatedButton.icon(
          onPressed: () {
            if (kDebugMode)
              print(
                "Admin: Adaptando dados e navegando para NotifyDetailsPage",
              );

            if (detalhes == null) {
              _showErrorSnackBar(
                "Erro: Dados da solicitação indisponíveis para navegação.",
              );
              if (kDebugMode)
                print(
                  "Falha ao navegar: 'detalhes' (solicitacaoDetalhes do state) é nulo.",
                );
              return;
            }

            // 2. Cria o Mapa "Wrapper" e o mapa INTERNO 'detalhes' com as chaves CORRETAS
            final Map<String, dynamic> detalhesAdaptados = {
              // Copia outros campos que NotifyDetailsPage possa precisar de dentro dos detalhes
              'user': detalhes['user'],
              'veiculo': detalhes['veiculo'],
              'situacao': detalhes['situacao'], // Passa a situação atual
              'motivo': detalhes['motivo'], // Passa o motivo original
              // >>> MAPEAMENTO DAS CHAVES DE DATA/HORA <<<
              'data_inicio':
                  detalhes['prev_data_inicio'], // Usa a chave esperada pela NotifyDetailsPage
              'data_final': detalhes['prev_data_final'], // Usa a chave esperada
              'hora_inicio':
                  detalhes['prev_hora_inicio'], // Usa a chave esperada
              'hora_final': detalhes['prev_hora_final'], // Usa a chave esperada
              // Adicione aqui quaisquer outros campos do mapa 'detalhes' original
              // que a NotifyDetailsPage possa tentar acessar dentro de ['data']['detalhes']
              // Ex: 'id_solicitacao': detalhes['id'], // Se ela precisar do ID dentro dos detalhes também
            };

            final Map<String, dynamic> dadosParaNotificacao = {
              'data': {
                'solicitacao_id':
                    widget.solicitacaoID, // ID principal para a API
                'detalhes':
                    detalhesAdaptados, // Passa o mapa com chaves renomeadas
                'mensagem':
                    detalhes['motivo'] ??
                    'Avaliar solicitação pendente.', // Mensagem principal
                'tipo': 'solicitacao_veiculo', // Tipo
              },
              // Adicione aqui o 'id' da notificação simulado se NotifyDetailsPage precisar dele no nível raiz
              // 'id': widget.solicitacaoID.toString(),
            };

            // Debug: Imprimir o mapa que será passado
            if (kDebugMode) {
              print(
                "Dados adaptados para NotifyDetailsPage: ${jsonEncode(dadosParaNotificacao)}",
              );
            }

            // 3. Navega passando o mapa adaptado
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => NotifyDetailsPage(
                      notificationJson: dadosParaNotificacao,
                    ), // Passa o mapa adaptado
              ),
            ).then((_) {
              if (kDebugMode)
                print("Retornou da tela de detalhes/avaliação, atualizando...");
              getSolicByID(widget.solicitacaoID); // Atualiza ao retornar
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonEnabledBgColor,
            foregroundColor: _buttonEnabledFgColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.notification_important, color: Colors.white),
          label: const Text(
            'Avaliar Solicitação',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    // 2. Botões de Iniciar/Finalizar (Para o DONO da solicitação, INDEPENDENTE do cargo, se situação for 'aceita')
    if (isOwner && _situacao == 'aceita') {
      bool podeIniciar =
          !_viagemIniciada; // Se está 'aceita' e não iniciada, pode iniciar
      bool podeFinalizar =
          _viagemIniciada &&
          !_viagemFinalizada; // Se está iniciada e não finalizada, pode finalizar

      if (podeIniciar || podeFinalizar) {
        // Só adiciona a coluna se houver alguma ação de motorista possível
        Veiculo? veiculoParaAcao;
        if (detalhes['veiculo'] != null && detalhes['veiculo'] is Map) {
          try {
            veiculoParaAcao = Veiculo.fromJson(
              detalhes['veiculo'] as Map<String, dynamic>,
            );
          } catch (e) {
            if (kDebugMode) print("Erro ao parsear veiculo para botões: $e");
          }
        }
        final int? kmInicial = _kmInicialConfirmado;

        // Adiciona espaçamento se o botão de avaliar já foi adicionado
        if (buttonsList.isNotEmpty) {
          buttonsList.add(const SizedBox(height: 12));
        }

        // Adiciona a coluna com os botões de motorista
        buttonsList.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botão Iniciar
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text(
                  'Iniciar Viagem (Ler QR Code)',
                  style: TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonEnabledBgColor,
                  foregroundColor: _buttonEnabledFgColor,
                  disabledBackgroundColor: _buttonDisabledBgColor,
                  disabledForegroundColor: _buttonDisabledFgColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                          if (kDebugMode)
                            print(
                              "Dono (User ou Admin): Navegando para QRCodeScannerPage (Iniciar)",
                            );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => QRCodeScannerPage(
                                    /* Passe os parâmetros necessários aqui */
                                  ),
                            ),
                          ).then((_) {
                            getSolicByID(widget.solicitacaoID);
                          }); // Atualiza
                        },
              ),
              const SizedBox(height: 12),
              // Botão Finalizar
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Finalizar Viagem',
                  style: TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonEnabledBgColor,
                  foregroundColor: _buttonEnabledFgColor,
                  disabledBackgroundColor: _buttonDisabledBgColor,
                  disabledForegroundColor: _buttonDisabledFgColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                          if (kmInicial == null && _viagemIniciada) {
                            _showErrorSnackBar(
                              'Erro: KM inicial não carregado para finalizar.',
                            );
                            getSolicByID(widget.solicitacaoID);
                            return;
                          }
                          if (kDebugMode)
                            print(
                              "Dono (User ou Admin): Navegando para Finalizar com KM: ${kmInicial ?? 'N/A'}",
                            );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SolicitarFinalizarPage(
                                    solicitacaoId: widget.solicitacaoID,
                                    veiculo: veiculoParaAcao!,
                                    kmInicial: kmInicial ?? 0,
                                  ),
                            ),
                          ).then((success) {
                            getSolicByID(widget.solicitacaoID); // Atualiza
                            if (success == true)
                              _showSuccessSnackBar("Viagem finalizada!");
                          });
                        },
              ),
            ],
          ),
        );
      } else {
        if (kDebugMode)
          print(
            "Dono (User ou Admin): Sem ações de motorista possíveis no momento (Situação: $_situacao, Iniciada: $_viagemIniciada)",
          );
      }
    } else if (isOwner && _situacao != 'aceita') {
      if (kDebugMode)
        print(
          "Dono (User ou Admin): Situação '$_situacao' não permite ações de motorista.",
        );
    }

    // Retorna os botões acumulados ou vazio
    if (buttonsList.isEmpty) {
      if (kDebugMode) print("Nenhum botão de ação aplicável.");
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttonsList,
        ),
      );
    }
  }
}
