import 'dart:convert'; // Para jsonDecode
import 'dart:io'; // Para Platform
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para requisições HTTP
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Para token mobile
import 'package:shared_preferences/shared_preferences.dart'; // Para token web

// ------ IMPORTANTE: Ajuste estes imports ------
// 1. Importe sua classe Model 'Veiculo' (verifique o caminho correto)
import 'package:flutter_application_2/data/veiculo.dart';
// 2. Importe a página para onde o usuário vai ao solicitar um veículo urgente
import 'package:flutter_application_2/veicsoli_page.dart';
// 3. !!! IMPORTANTE: Importe a página para onde o usuário vai para INICIAR a viagem agendada !!!
// Substitua 'nome_da_pagina_inicio_viagem.dart' e 'InicioViagemPage' pelos nomes corretos
// import 'package:flutter_application_2/nome_da_pagina_inicio_viagem.dart';
// ------ Fim dos Ajustes de Import ------

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key});

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  String? qrCodeResult;
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _feedbackMessage;

  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  Future<String?> _getAuthToken() async {
    if (kIsWeb) {
      // Lógica para Web
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        print(
          "Token lido do SharedPreferences (Web): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } catch (e) {
        print("Erro ao ler SharedPreferences na Web: $e");
        return null;
      }
    } else {
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        print(
          "Token lido do Secure Storage (Mobile): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } catch (e) {
        print("Erro ao ler token do Secure Storage: $e");
        return null;
      }
    }
  }
  // --- Fim da Lógica de Token ---

  Future<void> _handleQrCodeScan(String? url) async {
    if (url == null || url.isEmpty || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _feedbackMessage = 'Verificando QR Code...';
      qrCodeResult = url;
    });

    String? authToken = await _getAuthToken();

    if (authToken == null || authToken.isEmpty) {
      setState(() {
        _isProcessing = false;
        _feedbackMessage = 'Erro: Autenticação necessária.';
      });
      _showErrorDialog(
        'Não foi possível obter o token de autenticação. Faça o login novamente.',
      );
      return;
    }

    try {
      final Map<String, String> headers = {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      };

      print('Fazendo requisição GET para: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      print('Status Code recebido: ${response.statusCode}');
      print('Corpo da Resposta: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Sucesso
        final String action = responseBody['action'];
        final String message = responseBody['message'];

        setState(() {
          _feedbackMessage = message;
        });

        switch (action) {
          case 'allow_start':
            final int solicitacaoId = responseBody['solicitacao_id'];
            _showConfirmationDialog(
              message,
              confirmText: 'Iniciar Viagem', // Texto do botão de confirmação
              onConfirm: () {
                print('Navegando para iniciar viagem ID: $solicitacaoId');

                // ------ IMPORTANTE: Substitua pela sua página correta ------
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => InicioViagemPage(solicitacaoId: solicitacaoId), // Use o nome correto da sua página e parâmetro
                //   ),
                // );
                _showPlaceholderNavigationDialog(
                  "Navegar para Iniciar Viagem (ID: $solicitacaoId)",
                );
              },
            );
            break;
          case 'prompt_urgent_request':
            final Veiculo veiculo = Veiculo.fromJson(
              responseBody['veiculo'] as Map<String, dynamic>,
            );
            _showConfirmationDialog(
              message,
              confirmText: 'Solicitar Agora',
              onConfirm: () {
                print(
                  'Navegando para solicitar urgente Veículo ID: ${veiculo.id}',
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VeicSoliPage(veiculo: veiculo),
                  ),
                );
              },
            );
            break;
          default:
            _showErrorDialog('Ação desconhecida recebida da API: $action');
            setState(() {
              _isProcessing = false;
            });
        }
      } else {
        final String errorMessage =
            responseBody['message'] ??
            responseBody['error'] ??
            'Erro ${response.statusCode} ao processar o QR Code.';
        setState(() {
          _feedbackMessage = errorMessage;
        });
        _showErrorDialog(errorMessage);
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Erro ao processar QR Code: $e');
      String errorMessage;
      if (e is SocketException || e is http.ClientException) {
        errorMessage =
            'Erro de conexão. Verifique sua rede ou a URL no QR Code.';
      } else if (e is FormatException) {
        errorMessage = 'Erro ao ler a resposta do servidor.';
      } else {
        errorMessage = 'Ocorreu um erro inesperado ao verificar o QR Code.';
      }
      setState(() {
        _feedbackMessage = errorMessage;
      });
      _showErrorDialog(errorMessage);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Permite novo scan após fechar o erro
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                },
              ),
            ],
          ),
    ).then((_) {
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  // Função para exibir um diálogo de confirmação/ação
  void _showConfirmationDialog(
    String message, {
    required VoidCallback onConfirm,
    String confirmText = 'OK',
    String cancelText = 'Cancelar',
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Atenção'),
            content: Text(message),
            actions: [
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                      _feedbackMessage = 'Scan cancelado pelo usuário.';
                    });
                  }
                },
              ),
              TextButton(
                child: Text(confirmText),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ],
          ),
    );
  }

  void _showPlaceholderNavigationDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Navegação Simulada'),
            content: Text('Deveria navegar para:\n\n$message'),
            actions: [
              TextButton(
                child: const Text('OK (Fechar Scanner)'),
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha diálogo
                  Navigator.of(context).pop(); // Fecha scanner
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
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        leading: IconButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF013A65),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: _isProcessing ? null : () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: _isProcessing ? null : () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (BarcodeCapture capture) {
                    if (!_isProcessing) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        print('Código detectado: ${barcode!.rawValue}');
                        _handleQrCodeScan(
                          barcode.rawValue,
                        ); // Inicia o processamento
                      }
                    }
                  },
                ),
                if (_isProcessing)
                  Container(
                    // Fundo semi-transparente opcional
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF013A65).withOpacity(0.8),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _feedbackMessage ??
                      qrCodeResult ??
                      'Aponte a câmera para o QR Code',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
