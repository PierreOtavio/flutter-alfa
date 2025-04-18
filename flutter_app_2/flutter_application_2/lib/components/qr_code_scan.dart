import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/solicitar_iniciar_page.dart'; // <<< IMPORTANTE
import 'package:flutter_application_2/goals/config.dart'; // Sua configuração de URL base

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _secureStorage = const FlutterSecureStorage();

  bool _isProcessing = false; // Controla o overlay de processamento
  String?
  _scannedUrl; // Guarda a última URL escaneada para evitar processamento repetido

  // Chave para armazenamento seguro do token
  static const String _tokenKey = 'auth_token';

  // --- Cores para Diálogo de Erro (ainda necessário) ---
  static const Color _dialogBackgroundColor = Color(0xFF303030);
  static const Color _dialogButtonColor = Color(0xFF013A65);
  static const Color _dialogButtonTextColor = Colors.white;
  static const Color _dialogContentTextColor = Colors.white;
  static const Color _dialogTitleErrorColor = Colors.redAccent;
  // --- Fim das Cores ---

  @override
  void dispose() {
    _scannerController.dispose(); // Libera o controller da câmera
    super.dispose();
  }

  // --- Função para obter o Token (mantida) ---
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
      // Mostrar erro crítico se não conseguir ler o token?
      // _showErrorDialog("Falha ao acessar o armazenamento seguro. Tente reiniciar o app.");
      return null;
    }
  }

  // --- Função chamada quando um QR Code é detectado ---
  Future<void> _handleQrCodeDetected(BarcodeCapture capture) async {
    // Ignora se já estiver processando
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final url = barcode?.rawValue;

    // Ignora se a URL for nula, vazia ou a mesma que a última processada
    if (url == null || url.isEmpty || url == _scannedUrl) {
      return;
    }

    // Ativa o estado de processamento e guarda a URL
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _scannedUrl = url;
      });
    }

    // Chama a função que processa a URL (chama a API)
    await _processQrCodeUrl(url);

    // O estado _isProcessing será desativado pela função _processQrCodeUrl
    // em caso de erro, ou a navegação removerá esta tela.
  }

  // --- Função que chama a API do Backend com a URL escaneada ---
  Future<void> _processQrCodeUrl(String url) async {
    final authToken = await _getAuthToken();
    if (authToken == null) {
      // Se não houver token, mostra erro e para o processamento
      _showErrorDialog(
        'Autenticação necessária. Por favor, faça login novamente.',
      );
      if (mounted) setState(() => _isProcessing = false);
      _scannedUrl = null; // Permite tentar escanear novamente
      return;
    }

    // Verifica se a URL pertence ao domínio esperado
    if (!url.startsWith(AppConfig.baseUrl)) {
      _showErrorDialog('QR Code inválido ou não pertence ao sistema.');
      if (mounted) setState(() => _isProcessing = false);
      _scannedUrl = null; // Permite tentar escanear novamente
      return;
    }

    try {
      // Faz a requisição GET para a API do QR Code
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15)); // Timeout de 15 segundos

      // Garante que o widget ainda existe antes de continuar
      if (!mounted) return;

      final data = jsonDecode(response.body);

      // --- Lógica Principal: Interpreta a resposta da API ---
      if (response.statusCode == 200) {
        final action = data['action'];
        final Veiculo? veiculoData =
            data.containsKey('veiculo')
                ? Veiculo.fromJson(data['veiculo'])
                : null;

        switch (action) {
          case 'allow_start':
            final solicitacaoId = data['solicitacao_id'];
            if (veiculoData != null && solicitacaoId != null) {
              print("QR Scan: Ação 'allow_start' recebida. Navegando...");
              // Navega para a tela de iniciar, passando os dados
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SolicitarIniciarPage(
                        veiculo: veiculoData,
                        solicitacaoId: solicitacaoId,
                        isUrgent: false, // Não é urgente
                      ),
                ),
              );
              // Não desativa _isProcessing aqui, pois a tela será substituída
            } else {
              // Erro: dados faltando na resposta da API
              _showErrorDialog(
                'Resposta inválida do servidor (dados ausentes para iniciar).',
              );
              setState(() => _isProcessing = false);
              _scannedUrl = null;
            }
            break;

          case 'prompt_urgent_request':
            if (veiculoData != null) {
              print(
                "QR Scan: Ação 'prompt_urgent_request' recebida. Navegando...",
              );
              // Navega para a tela de iniciar/solicitar, passando os dados
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SolicitarIniciarPage(
                        veiculo: veiculoData,
                        solicitacaoId:
                            null, // Sem ID de solicitação pré-existente
                        isUrgent: true, // É urgente
                      ),
                ),
              );
              // Não desativa _isProcessing aqui
            } else {
              // Erro: dados faltando na resposta da API
              _showErrorDialog(
                'Resposta inválida do servidor (dados ausentes para solicitar).',
              );
              setState(() => _isProcessing = false);
              _scannedUrl = null;
            }
            break;

          // Casos de erro retornados pela API (com status 200, mas action 'error')
          // Ou ações desconhecidas que deveriam ser tratadas como erro
          default:
            final errorMsg =
                data['message'] ??
                data['error'] ??
                'Ação desconhecida recebida do servidor.';
            print(
              "QR Scan: Ação desconhecida ou erro retornado pela API: $errorMsg",
            );
            _showErrorDialog(errorMsg);
            setState(() => _isProcessing = false);
            _scannedUrl = null;
        }
      } else {
        // Erros HTTP (4xx, 5xx)
        final error =
            data['message'] ??
            data['error'] ??
            'Erro ao processar o QR Code (Código: ${response.statusCode}).';
        print("QR Scan: Erro HTTP ${response.statusCode} - $error");
        _showErrorDialog(error);
        setState(() => _isProcessing = false);
        _scannedUrl = null;
      }
    } on SocketException {
      // Erro de conexão
      if (!mounted) return;
      print("QR Scan: Erro de Rede (SocketException)");
      _showErrorDialog('Erro de conexão. Verifique sua internet.');
      setState(() => _isProcessing = false);
      _scannedUrl = null;
    } on FormatException {
      // Erro ao decodificar JSON
      if (!mounted) return;
      print("QR Scan: Erro de formato na resposta da API (FormatException)");
      _showErrorDialog('Resposta inválida recebida do servidor.');
      setState(() => _isProcessing = false);
      _scannedUrl = null;
    } on http.ClientException catch (e) {
      // Outros erros HTTP
      if (!mounted) return;
      print("QR Scan: Erro de Cliente HTTP: ${e.message}");
      _showErrorDialog('Erro de comunicação com o servidor: ${e.message}');
      setState(() => _isProcessing = false);
      _scannedUrl = null;
    } catch (e) {
      // Qualquer outro erro inesperado
      if (!mounted) return;
      print("QR Scan: Erro inesperado: $e");
      _showErrorDialog('Ocorreu um erro inesperado: ${e.toString()}');
      setState(() => _isProcessing = false);
      _scannedUrl = null;
    }
  }

  // --- Função para Mostrar Diálogo de Erro (simplificada) ---
  void _showErrorDialog(String message) {
    // Garante que só mostre se o widget ainda estiver montado
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Usuário precisa clicar em OK
      builder:
          (_) => AlertDialog(
            backgroundColor: _dialogBackgroundColor,
            title: const Text(
              'Atenção',
              style: TextStyle(color: _dialogTitleErrorColor),
            ),
            content: Text(
              message,
              style: const TextStyle(color: _dialogContentTextColor),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _dialogButtonColor,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: _dialogButtonTextColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  // Não precisa mais mexer em _isProcessing aqui, já foi tratado antes de chamar
                  // _scannedUrl também já foi resetado para permitir nova tentativa
                },
              ),
            ],
          ),
    );
  }

  // --- Construção da Interface Gráfica ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        title: const Text(
          'Escanear QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF013A65), // Cor padrão do AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          // Desabilita o botão voltar enquanto processa
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      // --- Corpo da Tela ---
      body: Stack(
        // Usa Stack para sobrepor o overlay e a borda
        alignment: Alignment.center, // Centraliza os filhos do Stack
        children: [
          // --- Câmera ---
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleQrCodeDetected, // Função chamada ao detectar
            // Ajuste da janela de scan para ser responsiva
            scanWindow: Rect.fromCenter(
              center:
                  MediaQuery.of(context).size.center(Offset.zero) *
                  0.45, // Ajuste do centro
              width:
                  MediaQuery.of(context).size.width * 0.7, // Largura da janela
              height:
                  MediaQuery.of(context).size.width *
                  0.7, // Altura da janela (quadrada)
            ),
            // Lida com erros da câmera (opcional, mas recomendado)
            errorBuilder: (context, error, child) {
              print("Camera Error: $error");
              // Pode mostrar um diálogo ou uma mensagem na tela
              return Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.7),
                  child: Text(
                    'Erro ao iniciar a câmera. Verifique as permissões do aplicativo.\n($error)',
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          // --- Borda Visual para Área de Scan ---
          Container(
            width:
                MediaQuery.of(context).size.width * 0.7 +
                6, // Pouco maior que a janela
            height: MediaQuery.of(context).size.width * 0.7 + 6,
            decoration: BoxDecoration(
              border: Border.all(
                // Muda a cor da borda se estiver processando
                color:
                    _isProcessing
                        ? Colors.orangeAccent.withOpacity(0.8)
                        : Colors.greenAccent.withOpacity(0.8),
                width: 3, // Espessura da borda
              ),
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas
            ),
          ),

          // --- Overlay de Processamento ---
          if (_isProcessing)
            Positioned.fill(
              // Garante que cubra toda a área do Stack
              child: Container(
                color: Colors.black.withOpacity(0.75), // Mais opaco
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Processando QR Code...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Mensagem Fixa de Instrução (Opcional) ---
          Positioned(
            bottom:
                MediaQuery.of(context).size.height * 0.1, // Posição relativa
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Aponte a câmera para o QR Code',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      // Painel inferior foi removido
    );
  }
}
