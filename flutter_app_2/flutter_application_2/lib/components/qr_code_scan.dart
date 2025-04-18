import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
// import 'package:flutter_application_2/config.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _secureStorage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário de iniciar

  // Controllers para os campos do formulário de iniciar viagem
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();

  bool _isProcessing = false;
  String? _feedbackMessage;
  String _feedbackTitle = 'Status';
  Color _feedbackColor = Colors.white;
  String? _scannedUrl; // Armazena a URL escaneada

  static const String _tokenKey = 'auth_token';

  @override
  void dispose() {
    _scannerController.dispose();
    _placaController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      } else {
        return await _secureStorage.read(key: _tokenKey);
      }
    } catch (e) {
      print("Erro ao ler token: $e");
      return null;
    }
  }

  void _setFeedback(
    String title,
    String message,
    Color color, {
    bool clearUrl = false,
  }) {
    if (!mounted) return;
    setState(() {
      _feedbackTitle = title;
      _feedbackMessage = message;
      _feedbackColor = color;
      if (clearUrl) _scannedUrl = null; // Limpa URL para permitir novo scan
    });
  }

  // Função principal que lida com o resultado do scan
  Future<void> _handleQrCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return; // Ignora se já estiver processando

    final barcode = capture.barcodes.firstOrNull;
    final url = barcode?.rawValue;

    if (url == null || url.isEmpty || url == _scannedUrl) {
      // Ignora se for nulo, vazio ou a mesma URL já processada
      return;
    }

    setState(() {
      _isProcessing = true; // Inicia processamento
      _scannedUrl = url; // Armazena a URL para evitar reprocessamento imediato
    });

    _setFeedback('Verificando', 'Analisando QR Code...', Colors.amber);
    await _processQrCodeUrl(url); // Chama a função de processamento da API

    // Se o processamento falhou ou não levou a uma ação que mantém ocupado,
    // permite novo scan após um pequeno delay para evitar scans múltiplos acidentais
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isProcessing) {
        // Só libera se ainda estiver 'processando' (indicando que nenhuma ação longa foi iniciada)
        setState(() => _isProcessing = false);
      }
    });
  }

  // Função para chamar a API de verificação do QR Code
  Future<void> _processQrCodeUrl(String url) async {
    final authToken = await _getAuthToken();
    if (authToken == null) {
      _setFeedback(
        'Erro',
        'Não autenticado. Faça login.',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'Sua sessão expirou ou não foi encontrada. Por favor, faça login novamente.',
      );
      setState(() => _isProcessing = false);
      return;
    }

    // Validar se a URL parece ser do nosso backend (medida de segurança básica)
    if (!url.startsWith(AppConfig.baseUrl)) {
      _setFeedback(
        'Erro',
        'QR Code inválido ou não pertence ao sistema.',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog('Este QR Code não parece ser válido para este sistema.');
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15)); // Aumentar timeout um pouco

      // Verificar se widget ainda está montado após chamada async
      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final action = data['action'];
        final message = data['message'] ?? 'Ação recebida.';
        final Veiculo? veiculoData =
            data.containsKey('veiculo')
                ? Veiculo.fromJson(data['veiculo'])
                : null;

        _setFeedback(
          'Informação',
          message,
          Colors.cyan,
        ); // Usar uma cor neutra para info

        switch (action) {
          case 'allow_start':
            final solicitacaoId = data['solicitacao_id'];
            _showIniciarViagemDialog(
              solicitacaoId,
              veiculoData?.placa ?? '',
            ); // Passar placa para pré-preencher
            // Manter _isProcessing = true até o diálogo ser fechado ou a API iniciar ser chamada
            break;

          case 'prompt_urgent_request':
            if (veiculoData == null) {
              _setFeedback(
                'Erro',
                'Dados do veículo ausentes para solicitação urgente.',
                Colors.red,
                clearUrl: true,
              );
              _showErrorDialog(
                'Não foi possível obter os dados do veículo para a solicitação.',
              );
              setState(() => _isProcessing = false);
              return;
            }
            _showConfirmationDialog(
              title: 'Veículo Disponível',
              message: message,
              confirmText: 'Solicitar Agora',
              onConfirm: () {
                // Navega para a página de solicitação, passando o veículo
                Navigator.pushReplacement(
                  // Use pushReplacement para fechar o scanner
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => VeicSoliPage(
                          veiculo: veiculoData,
                        ), // Assumindo que VeicSoliPage aceita Veiculo
                  ),
                );
                // Não precisa mais mexer em _isProcessing aqui, a navegação cuida disso.
              },
              onCancel: () {
                // Usuário cancelou, liberar para novo scan
                _setFeedback(
                  'Cancelado',
                  'Solicitação urgente cancelada.',
                  Colors.orange,
                  clearUrl: true,
                );
                setState(() => _isProcessing = false);
              },
            );
            // Manter _isProcessing = true enquanto o diálogo estiver aberto
            break;

          default:
            // Ação desconhecida vinda da API
            _setFeedback(
              'Erro',
              'Ação desconhecida: $action',
              Colors.red,
              clearUrl: true,
            );
            _showErrorDialog(
              'O servidor retornou uma ação inesperada. ($action)',
            );
            setState(() => _isProcessing = false);
        }
      } else {
        // Erro da API (4xx, 5xx)
        final error =
            data['message'] ??
            data['error'] ??
            'Erro desconhecido ao processar o QR Code.';
        _setFeedback('Erro', error, Colors.red, clearUrl: true);
        _showErrorDialog(error);
        setState(() => _isProcessing = false);
      }
    } on SocketException {
      if (!mounted) return;
      _setFeedback(
        'Erro de Rede',
        'Sem conexão com a internet.',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
      setState(() => _isProcessing = false);
    } on FormatException {
      if (!mounted) return;
      _setFeedback(
        'Erro de Resposta',
        'Resposta inválida do servidor.',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'O servidor enviou uma resposta que não pôde ser entendida.',
      );
      setState(() => _isProcessing = false);
    } on http.ClientException catch (e) {
      if (!mounted) return;
      _setFeedback(
        'Erro de Cliente HTTP',
        'Erro na requisição: ${e.message}',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'Ocorreu um erro ao tentar comunicar com o servidor: ${e.message}',
      );
      setState(() => _isProcessing = false);
    } catch (e) {
      // Erro genérico
      if (!mounted) return;
      print("Erro inesperado no processQrCodeUrl: $e");
      _setFeedback(
        'Erro Inesperado',
        'Ocorreu um erro: ${e.toString()}',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog('Ocorreu um erro inesperado durante o processamento.');
      setState(() => _isProcessing = false);
    }
    // Não resetar _isProcessing aqui se uma ação (dialog) estiver pendente
  }

  // Diálogo para confirmar placa e KM e chamar a API de iniciar
  void _showIniciarViagemDialog(int solicitacaoId, String placaVeiculo) {
    _placaController.text = placaVeiculo; // Pré-preenche a placa para facilitar
    _kmController.clear(); // Limpa o campo KM

    showDialog(
      context: context,
      barrierDismissible: false, // Não fechar clicando fora
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Iniciar Viagem'),
          content: SingleChildScrollView(
            // Para evitar overflow se teclado aparecer
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Confirme a placa do veículo e informe o KM atual no velocímetro para iniciar a viagem (Solicitação ID: $solicitacaoId).',
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _placaController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Placa',
                      hintText: 'AAA-1234 ou AAA1B34',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, confirme a placa.';
                      }
                      // Adicionar validação de formato de placa se necessário
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _kmController,
                    decoration: const InputDecoration(
                      labelText: 'KM Inicial',
                      hintText: 'Ex: 150320',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o KM inicial.';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Informe um valor numérico válido para KM.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                _setFeedback(
                  'Cancelado',
                  'Início de viagem cancelado.',
                  Colors.orange,
                  clearUrl: true,
                );
                setState(() => _isProcessing = false); // Libera para novo scan
              },
            ),
            TextButton(
              child: const Text('Iniciar Viagem'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Formulário válido, chamar a API
                  Navigator.of(dialogContext).pop(); // Fecha o diálogo de input
                  _callIniciarApi(
                    solicitacaoId,
                    _placaController.text.trim(),
                    int.parse(_kmController.text.trim()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Função para chamar a API /solicitar/{id}/iniciar
  Future<void> _callIniciarApi(int solicitacaoId, String placa, int km) async {
    _setFeedback('Processando', 'Iniciando viagem...', Colors.blue);
    // Manter _isProcessing = true

    final authToken = await _getAuthToken();
    if (authToken == null) {
      _setFeedback(
        'Erro',
        'Não autenticado. Faça login.',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'Sua sessão expirou. Faça login novamente para iniciar a viagem.',
      );
      setState(() => _isProcessing = false);
      return;
    }

    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/solicitar/$solicitacaoId/iniciar',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
              'Content-Type':
                  'application/json', // Importante para POST com JSON
            },
            body: jsonEncode({'placa_confirmar': placa, 'km_velocimetro': km}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Sucesso! Viagem iniciada.
        final message = data['message'] ?? 'Viagem iniciada com sucesso!';
        _setFeedback('Sucesso', message, Colors.green);
        _showSuccessDialog(
          title: 'Viagem Iniciada!',
          message: message,
          onDismiss: () {
            // Fechar a tela do scanner após sucesso
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        );
        // _isProcessing será tratado pelo fechamento do diálogo de sucesso
      } else {
        // Erro da API ao iniciar
        final error =
            data['message'] ?? data['error'] ?? 'Erro ao iniciar a viagem.';
        _setFeedback(
          'Erro',
          error,
          Colors.red,
          clearUrl: true,
        ); // Permite tentar de novo
        _showErrorDialog(error);
        setState(
          () => _isProcessing = false,
        ); // Libera para tentar novamente ou escanear outro
      }
    } on SocketException {
      if (!mounted) return;
      _setFeedback('Erro de Rede', 'Sem conexão.', Colors.red, clearUrl: true);
      _showErrorDialog(
        'Não foi possível conectar ao servidor para iniciar a viagem.',
      );
      setState(() => _isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      print("Erro ao chamar API iniciar: $e");
      _setFeedback(
        'Erro Inesperado',
        'Erro ao iniciar: ${e.toString()}',
        Colors.red,
        clearUrl: true,
      );
      _showErrorDialog(
        'Ocorreu um erro inesperado ao tentar iniciar a viagem.',
      );
      setState(() => _isProcessing = false);
    }
    // Não resetar _isProcessing aqui, diálogos cuidam disso ou falha reseta.
  }

  // --- Funções Auxiliares de Diálogo ---

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Erro'),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Não mexer em _isProcessing aqui, a função que chamou deve decidir
                },
              ),
            ],
          ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // Importante para forçar uma escolha
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel(); // Chama o callback de cancelamento
                },
              ),
              TextButton(
                child: Text(confirmText),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm(); // Chama o callback de confirmação
                },
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required VoidCallback onDismiss,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // Não fechar clicando fora
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Row(
              // Adicionar ícone de sucesso
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss(); // Chama o callback ao fechar
                  // Resetar estado para permitir novo scan (se a tela não for fechada)
                  setState(() {
                    _isProcessing = false;
                    _setFeedback(
                      'Status',
                      'Aponte para um QR Code',
                      Colors.white,
                      clearUrl: true,
                    );
                  });
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanear QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF013A65), // Cor padrão
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4, // Mais espaço para a câmera
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect:
                      _handleQrCodeDetected, // Chama a função quando detectar
                  // Adicionar configurações visuais opcionais
                  scanWindow: Rect.fromCenter(
                    center:
                        MediaQuery.of(context).size.center(Offset.zero) /
                        2, // Ajustar centro
                    width: 250, // Largura da janela
                    height: 250, // Altura da janela
                  ),
                  // errorBuilder: (context, error, child) { // Lidar com erros da câmera
                  //    return Center(child: Text('Erro na câmera: $error'));
                  // },
                ),
                // Overlay de processamento
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Column(
                        // Adiciona texto ao indicador
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 15),
                          Text(
                            'Processando...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Adicionar uma borda visual para a área de scan (opcional)
                Container(
                  width: 255,
                  height: 255,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          // Painel de Feedback Inferior
          Expanded(
            flex: 1, // Menos espaço para o feedback
            child: Container(
              color: _feedbackColor.withOpacity(
                0.85,
              ), // Usar a cor do feedback com opacidade
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _feedbackTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors
                              .white, // Cor do texto sempre branca para contraste
                      shadows: [
                        Shadow(
                          blurRadius: 1.0,
                          color: Colors.black,
                          offset: Offset(1.0, 1.0),
                        ),
                      ], // Sombra para legibilidade
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _feedbackMessage ??
                        'Aponte a câmera para o QR Code do veículo',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white, // Cor do texto sempre branca
                      shadows: [
                        Shadow(
                          blurRadius: 1.0,
                          color: Colors.black,
                          offset: Offset(1.0, 1.0),
                        ),
                      ], // Sombra
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Limitar linhas
                    overflow:
                        TextOverflow
                            .ellipsis, // Adicionar '...' se texto for longo
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
