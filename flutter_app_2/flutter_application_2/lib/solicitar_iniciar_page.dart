import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/data/veiculo.dart'; // Verifique se seu modelo Veiculo está correto
import 'package:flutter_application_2/data/marca.dart'; // Importe se Marca for um objeto separado
import 'package:flutter_application_2/data/modelo.dart'; // Importe se Modelo for um objeto separado
import 'package:flutter_application_2/inicio_page.dart'; // Verifique se é a página correta para navegar
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SolicitarIniciarPage extends StatefulWidget {
  final Veiculo veiculo;
  final int? solicitacaoId;
  final bool isUrgent;

  const SolicitarIniciarPage({
    super.key,
    required this.veiculo,
    this.solicitacaoId,
    required this.isUrgent,
  });

  @override
  State<SolicitarIniciarPage> createState() => _SolicitarIniciarPageState();
}

class _SolicitarIniciarPageState extends State<SolicitarIniciarPage> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _motivoController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;

  static const String _tokenKey = 'auth_token';

  // Cores
  static const Color pageBackgroundColor = Color(0xFF303030);
  static const Color appBarColor = Color(0xFF013A65);
  static const Color buttonColor = Color(0xFF013A65);
  static const Color textColor = Colors.white;
  static const Color hintColor = Colors.white70;
  static const Color errorColor = Colors.redAccent;

  @override
  void dispose() {
    _kmController.dispose();
    _motivoController.dispose();
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

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authToken = await _getAuthToken();
      if (authToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro de autenticação. Faça login novamente.';
        });
        _showSnackBar(_errorMessage!);
        return;
      }

      try {
        http.Response response;
        String successMessage;

        if (widget.solicitacaoId != null) {
          response = await _callIniciarApi(authToken);
          successMessage = 'Viagem iniciada com sucesso!';
        } else {
          // Chama API para criar/iniciar urgente
          response = await _callCriarSolicitacaoUrgenteApi(authToken);
          successMessage = 'Solicitação urgente criada e viagem iniciada!';
        }

        if (!mounted) return;
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackBar(data['message'] ?? successMessage, isError: false);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Limpa a pilha e vai para a tela inicial
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
                data['message'] ?? data['error'] ?? 'Ocorreu um erro.';
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
        print("Erro ao submeter formulário: $e");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro de conexão ou inesperado.';
        });
        _showSnackBar(_errorMessage! + '\nDetalhes: ${e.toString()}');
      }
    }
  }

  Future<http.Response> _callIniciarApi(String authToken) {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/solicitar/${widget.solicitacaoId}/iniciar',
    );
    final body = jsonEncode({
      'placa_confirmar': widget.veiculo.placa,
      'km_velocimetro': int.parse(
        _kmController.text.trim(),
      ), // Backend espera km_velocimetro aqui
    });
    print("Chamando API Iniciar: $url com body $body");
    return http
        .post(url, headers: _getHeaders(authToken), body: body)
        .timeout(const Duration(seconds: 25));
  }

  Future<http.Response> _callCriarSolicitacaoUrgenteApi(String authToken) {
    // <<< CORREÇÃO DA URL: Usar o endpoint padrão de STORE >>>
    final url = Uri.parse('${AppConfig.baseUrl}/api/solicitar/create');

    final body = jsonEncode({
      'veiculo_id': widget.veiculo.id,
      'km_inicial': int.parse(
        _kmController.text.trim(),
      ), // Backend espera km_inicial aqui
      'motivo': _motivoController.text.trim(),
      'urgente': true, // Sinaliza que é urgente
    });
    print("Chamando API Criar Urgente: $url com body $body");
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
        backgroundColor: isError ? errorColor : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isUrgent ? 'Solicitação Urgente' : 'Iniciar Viagem',
          style: const TextStyle(color: textColor),
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
              Card(
                /* ... Card com informações do veículo ... */
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
                        'Veículo Selecionado:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('Placa:', widget.veiculo.placa),
                      // <<< CORREÇÃO: Acessar o nome dentro do objeto marca/modelo >>>
                      // Verifique se os nomes 'marca' e 'modelo' no seu Veiculo.dart
                      // correspondem aos objetos Marca e Modelo e se eles têm um campo 'nome'.
                      if (widget.veiculo.marca?.marca !=
                          null) // Assumindo que o campo é 'nome'
                        _buildInfoRow(
                          'Marca:',
                          widget.veiculo.marca!.marca!,
                        ), // Usar ! pois já checou null
                      if (widget.veiculo.modelo?.modelo !=
                          null) // Assumindo que o campo é 'nome'
                        _buildInfoRow(
                          'Modelo:',
                          widget.veiculo.modelo!.modelo!,
                        ), // Usar ! pois já checou null
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                /* ... Campo KM Inicial ... */
                controller: _kmController,
                style: const TextStyle(color: textColor),
                decoration: _inputDecoration(
                  'KM Inicial no Velocímetro',
                  'Ex: 150320',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o KM inicial.';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Informe um valor numérico válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              if (widget.isUrgent)
                TextFormField(
                  /* ... Campo Motivo ... */
                  controller: _motivoController,
                  style: const TextStyle(color: textColor),
                  decoration: _inputDecoration(
                    'Motivo da Urgência',
                    'Ex: Reunião emergencial',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (widget.isUrgent &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Informe o motivo da urgência.';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                /* ... Botão de Submissão ... */
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
                        : Text(
                          widget.isUrgent
                              ? 'Solicitar e Iniciar'
                              : 'Confirmar e Iniciar',
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
              ),
              if (_errorMessage != null) /* ... Mensagem de Erro ... */
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

  // Helper para Input Decoration (mantido)
  InputDecoration _inputDecoration(String label, String hint) {
    /* ... código mantido ... */
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
    );
  }

  // Helper para Info Row (mantido)
  Widget _buildInfoRow(String label, String value) {
    /* ... código mantido ... */
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
