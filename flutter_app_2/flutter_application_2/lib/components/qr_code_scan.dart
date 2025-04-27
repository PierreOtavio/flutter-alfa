import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_application_2/data/veiculo.dart';
import 'package:flutter_application_2/solicitar_pages/solicitar_iniciar_page.dart';
import 'package:flutter_application_2/services/config.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  String? _scannedUrl;
  static const Color _dialogBackgroundColor = Color(0xFF303030);
  static const Color _dialogButtonColor = Color(0xFF013A65);
  static const Color _dialogButtonTextColor = Colors.white;
  static const Color _dialogContentTextColor = Colors.white;
  static const Color _dialogTitleErrorColor = Colors.redAccent;
  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final url = barcode?.rawValue;

    if (url == null || url.isEmpty || url == _scannedUrl) {
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _scannedUrl = url;
      });
    }

    await _processQrCodeUrl(url);
  }

  Future<void> _processQrCodeUrl(String url) async {
    String? errorMessage;
    bool shouldResetStateOnError = true;

    final authToken = await ApiService().getToken();
    if (authToken == null) {
      errorMessage = 'Autenticação necessária. Faça login novamente.';
      print("QR Scan: Erro - Token não encontrado.");
      _showErrorDialog(errorMessage);
      return;
    }
    print("QR Scan: Token obtido. Validando URL...");

    if (!url.startsWith(AppConfig.baseUrl)) {
      errorMessage = 'QR Code inválido ou não pertence ao sistema.';
      print("QR Scan: Erro - URL fora do domínio esperado: $url");
      _showErrorDialog(errorMessage);
      return;
    }
    print("QR Scan: URL validada. Enviando requisição para: $url");
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) {
        print("QR Scan: Widget desmontado após requisição.");
        return;
      }

      print("QR Scan: Resposta Recebida - Status: ${response.statusCode}");

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print("QR Scan: Erro ao decodificar JSON. Corpo: ${response.body}");
        throw FormatException(
          "Resposta inválida do servidor (não JSON). Status: ${response.statusCode}",
        );
      }
      if (response.statusCode != 200) {
        errorMessage =
            data?['message'] as String? ??
            'Erro ${response.statusCode}: Falha ao processar QR Code.';
        print(
          "QR Scan: Erro HTTP ${response.statusCode}. Mensagem: $errorMessage",
        );
      } else {
        final action = data['action'] as String?;
        final Veiculo? veiculoData =
            data.containsKey('veiculo') && data['veiculo'] != null
                ? Veiculo.fromJson(data['veiculo'] as Map<String, dynamic>)
                : null;
        final dynamic solicitacaoIdRaw = data['solicitacao_id'];
        final int? solicitacaoId =
            solicitacaoIdRaw is int
                ? solicitacaoIdRaw
                : (solicitacaoIdRaw is String
                    ? int.tryParse(solicitacaoIdRaw)
                    : null);

        print(
          "QR Scan: Ação: $action, Veiculo: ${veiculoData?.id}, Solicitação: $solicitacaoId",
        );
        switch (action) {
          case 'allow_start':
            if (veiculoData != null && solicitacaoId != null) {
              print("QR Scan: Ação 'allow_start' válida. Navegando...");
              shouldResetStateOnError = false;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SolicitarIniciarPage(
                        veiculo: veiculoData,
                        solicitacaoId: solicitacaoId,
                        isUrgent: false,
                      ),
                ),
              );
            } else {
              errorMessage = 'Dados ausentes para iniciar a solicitação.';
              print("QR Scan: Erro - Dados ausentes para 'allow_start'.");
            }
            break;

          case 'prompt_urgent_request':
            if (veiculoData != null) {
              print(
                "QR Scan: Ação 'prompt_urgent_request' válida. Navegando...",
              );
              shouldResetStateOnError = false;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SolicitarIniciarPage(
                        veiculo: veiculoData,
                        solicitacaoId: null,
                        isUrgent: true,
                      ),
                ),
              );
            } else {
              errorMessage = 'Dados ausentes para solicitação de urgência.';
              print(
                "QR Scan: Erro - Dados ausentes para 'prompt_urgent_request'.",
              );
            }
            break;

          case 'error':
            errorMessage =
                data['message'] as String? ?? 'Erro reportado pelo servidor.';
            print("QR Scan: Ação 'error' recebida: $errorMessage");
            break;

          default:
            errorMessage =
                'Ação desconhecida ou inválida recebida (${action ?? 'N/A'}).';
            print("QR Scan: Erro - Ação desconhecida: $action");
        }
      }
      if (errorMessage != null) {
        _showErrorDialog(errorMessage);
      }
    } on SocketException catch (e) {
      if (!mounted) return;
      print("QR Scan: Erro de Rede (SocketException): $e");
      errorMessage = 'Erro de conexão. Verifique sua internet.';
      _showErrorDialog(errorMessage);
    } on FormatException catch (e) {
      if (!mounted) return;
      print("QR Scan: Erro de Formato (FormatException): $e");
      errorMessage = e.message;
      _showErrorDialog(errorMessage);
    } on http.ClientException catch (e) {
      if (!mounted) return;
      print("QR Scan: Erro de Cliente HTTP: ${e.message}");
      errorMessage = 'Erro de comunicação com o servidor: ${e.message}';
      _showErrorDialog(errorMessage);
    } catch (e, stackTrace) {
      if (!mounted) return;
      print("QR Scan: Erro Inesperado: $e\nStack Trace: $stackTrace");
      errorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted && errorMessage != null && shouldResetStateOnError) {
        print("QR Scan: Resetando estado após erro: $errorMessage");
        setState(() {
          _isProcessing = false;
          _scannedUrl = null;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Navigator.of(context).pop();
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
        backgroundColor: const Color(0xFF013A65),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.screen_rotation_alt_sharp,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --- Câmera ---
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleQrCodeDetected,
            errorBuilder: (context, error, child) {
              // Tratamento de erro da câmera (mantido)
              print("Camera Error: $error");
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.8),
                  child: const Text(
                    'Erro ao iniciar a câmera.\nVerifique as permissões.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7 + 6,
            height: MediaQuery.of(context).size.width * 0.7 + 6,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _isProcessing
                        ? Colors.orangeAccent.withOpacity(0.9)
                        : Colors.greenAccent.withOpacity(0.9),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
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
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
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
    );
  }
}
