import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/data/veiculo.dart';
// import 'package:flutter_application_2/data/marca.dart';
// import 'package:flutter_application_2/data/modelo.dart';
import 'package:flutter_application_2/inicio_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SolicitarFinalizarPage extends StatefulWidget {
  final int solicitacaoId; // ID da solicitação a ser finalizada
  final Veiculo veiculo; // Dados do veículo para exibição/verificação
  final int kmInicial; // KM com que a viagem começou (vem de HistVeiculo)

  const SolicitarFinalizarPage({
    super.key,
    required this.solicitacaoId,
    required this.veiculo,
    required this.kmInicial,
  });

  @override
  State<SolicitarFinalizarPage> createState() => _SolicitarFinalizarPageState();
}

class _SolicitarFinalizarPageState extends State<SolicitarFinalizarPage> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _kmFinalController = TextEditingController(); // Para o KM final
  final _obsController = TextEditingController(); // Para observações
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;

  static const String _tokenKey = 'auth_token';

  static const Color pageBackgroundColor = Color(0xFF303030);
  static const Color appBarColor = Color(0xFF013A65);
  static const Color buttonColor = Color(0xFF013A65);
  static const Color textColor = Colors.white;
  static const Color hintColor = Colors.white70;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.green; // Para snackbar de sucesso

  @override
  void initState() {
    super.initState();
    // Pré-preenche a placa para facilitar a confirmação
    _placaController.text = widget.veiculo.placa;
  }

  @override
  void dispose() {
    _placaController.dispose();
    _kmFinalController.dispose();
    _obsController.dispose();
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

  // Função para normalizar placa (remover traço e maiúsculas)
  String _normalizePlaca(String placa) {
    return placa.replaceAll('-', '').toUpperCase();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      // Validação do formulário primeiro
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authToken = await _getAuthToken();
      if (authToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro de autenticação.';
        });
        _showSnackBar(_errorMessage!);
        return;
      }

      try {
        final response = await _callFinalizarApi(authToken);
        if (!mounted) return;
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          _showSnackBar(
            data['message'] ?? 'Viagem finalizada com sucesso!',
            isError: false,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Limpa a pilha e volta para a tela inicial
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const InicioPage()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          // Trata erro da API
          setState(() {
            _isLoading = false;
            String errorMsg =
                data['message'] ??
                data['error'] ??
                'Ocorreu um erro ao finalizar.';
            if (data.containsKey('errors') && data['errors'] is Map) {
              errorMsg = data['errors'].entries.first.value[0] ?? errorMsg;
            }
            _errorMessage = errorMsg;
          });
          _showSnackBar(_errorMessage!);
        }
      } catch (e) {
        // Trata erros de conexão/timeout/etc.
        if (!mounted) return;
        print("Erro ao submeter finalização: $e");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro de conexão ou inesperado.';
        });
        _showSnackBar(_errorMessage! + '\nDetalhes: ${e.toString()}');
      }
    }
  }

  // API Call para FINALIZAR a solicitação
  Future<http.Response> _callFinalizarApi(String authToken) {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/solicitar/${widget.solicitacaoId}/finalizar',
    );

    final body = jsonEncode({
      // Backend espera 'placa_confirmar'
      'placa_confirmar': _placaController.text.trim(),
      // Backend espera 'km_velocimetro' para o KM final
      'km_velocimetro': int.parse(_kmFinalController.text.trim()),
      // Backend espera 'obs_users'
      'obs_users':
          _obsController.text.trim().isEmpty
              ? null
              : _obsController.text.trim(), // Envia null se vazio
    });

    print("Chamando API Finalizar: $url com body $body"); // Log

    return http
        .post(url, headers: _getHeaders(authToken), body: body)
        .timeout(const Duration(seconds: 25));
  }

  // Helper para headers comuns
  Map<String, String> _getHeaders(String authToken) {
    return {
      'Authorization': 'Bearer $authToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorColor : successColor, // Cor de sucesso
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Finalizar Viagem',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Informações da Viagem (Opcional, mas útil) ---
              Card(
                color: Colors.grey[800],
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalhes da Viagem:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('Veículo:', widget.veiculo.placa),
                      // Exibir Marca/Modelo se disponíveis no objeto Veiculo
                      if (widget.veiculo.marca?.marca != null)
                        _buildInfoRow('Marca:', widget.veiculo.marca!.marca!),
                      if (widget.veiculo.modelo?.modelo != null)
                        _buildInfoRow(
                          'Modelo:',
                          widget.veiculo.modelo!.modelo!,
                        ),
                      _buildInfoRow(
                        'KM Inicial:',
                        widget.kmInicial.toString(),
                      ), // Mostra o KM inicial
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- Campo Confirmar Placa ---
              TextFormField(
                controller: _placaController,
                style: const TextStyle(color: textColor),
                decoration: _inputDecoration('Confirmar Placa', 'Ex: AAA-1234'),
                textCapitalization:
                    TextCapitalization.characters, // Ajuda a digitar maiúsculas
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirme a placa do veículo.';
                  }
                  // Validação comparando com a placa original (normalizada)
                  if (_normalizePlaca(value.trim()) !=
                      _normalizePlaca(widget.veiculo.placa)) {
                    return 'A placa informada não confere com a do veículo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Campo KM Final ---
              TextFormField(
                controller: _kmFinalController,
                style: const TextStyle(color: textColor),
                decoration: _inputDecoration(
                  'KM Final no Velocímetro',
                  'Ex: 150450',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o KM final.';
                  }
                  final kmFinal = int.tryParse(value);
                  if (kmFinal == null || kmFinal < 0) {
                    return 'Informe um valor numérico válido.';
                  }
                  // Validação comparando com o KM inicial
                  if (kmFinal < widget.kmInicial) {
                    return 'KM final não pode ser menor que o KM inicial (${widget.kmInicial}).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Campo Observações (Opcional) ---
              TextFormField(
                controller: _obsController,
                style: const TextStyle(color: textColor),
                decoration: _inputDecoration(
                  'Observações (Opcional)',
                  'Ex: Pequeno ruído na suspensão dianteira',
                ),
                maxLines: 4, // Mais espaço para observações
                maxLength: 500, // Limite definido no backend
                // Sem validator obrigatório
              ),
              const SizedBox(height: 30),

              // --- Botão Finalizar ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: textColor,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text(
                          'Finalizar Viagem',
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
              ),

              // --- Mensagem de Erro ---
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: errorColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Input Decoration (reutilizado)
  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: hintColor),
      hintText: hint,
      hintStyle: TextStyle(color: hintColor.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: buttonColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      counterStyle: TextStyle(
        color: hintColor.withOpacity(0.8),
      ), // Estilo para o contador de caracteres (maxLength)
    );
  }

  // Helper Info Row (reutilizado)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinha melhor se valor for longo
        children: [
          Text(
            label,
            style: const TextStyle(
              color: hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textColor, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
