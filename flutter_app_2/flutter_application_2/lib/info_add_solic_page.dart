import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/data/solicitar.dart';
import 'package:flutter_application_2/inicio_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoAddSolicPage extends StatefulWidget {
  final int veiculoId; // Adicione este parâmetro
  const InfoAddSolicPage({super.key, required this.veiculoId});

  @override
  State<InfoAddSolicPage> createState() => _InfoAddSolicPageState();
}

class _InfoAddSolicPageState extends State<InfoAddSolicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController prevDataInicioController =
      TextEditingController();
  final TextEditingController prevHoraInicioController =
      TextEditingController();
  final TextEditingController prevDataFinalController = TextEditingController();
  final TextEditingController prevHoraFinalController = TextEditingController();
  final TextEditingController motivoController = TextEditingController();
  final String _apiUrl = 'http://127.0.0.1:8000/api/solicitar/create';
  bool _isLoading = false;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      // Formato 24h com padding para 2 dígitos
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:"
          "${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        print(
          "Token lido do SharedPreferences (Web): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } catch (e) {
        print("Erro ao ler SharedPreferences na Web: $e");
        // _handleError("Erro ao acessar preferências na web: $e");
        return null;
      }
    } else {
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        print(
          "Token lido do Secure Storage (Mobile): ${token != null && token.isNotEmpty ? 'Encontrado' : 'Não encontrado'}",
        );
        return token;
      } on PlatformException catch (e) {
        print("Erro ao ler token do Secure Storage: $e");
        return null;
      } catch (e) {
        print("Erro inesperado ao ler Secure Storage: $e");
        // _handleError("Erro inesperado ao ler armazenamento: $e");
        return null;
      }
    }
  }

  Future<void> _submitForm() async {
    // 1. Validação do formulário e estado do widget
    if (!_formKey.currentState!.validate() || !mounted) return;

    // 2. Obtenção do token com tratamento de erros
    String? authToken;
    try {
      authToken = await _getToken();

      if (authToken == null || authToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada! Faça login novamente.'),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter token: ${e.toString()}')),
      );
      return;
    }

    // 3. Configuração do loading
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 4. Preparação dos dados
      final Map<String, dynamic> requestBody = {
        'veiculo_id': widget.veiculoId,
        'prev_data_inicio': prevDataInicioController.text,
        'prev_hora_inicio': prevHoraInicioController.text,
        'prev_data_final': prevDataFinalController.text,
        'prev_hora_final': prevHoraFinalController.text,
        'motivo': motivoController.text,
      };

      print("Data Início: ${prevDataInicioController.text}");
      print("Hora Início: ${prevHoraInicioController.text}");
      print("Data Final: ${prevDataFinalController.text}");
      print("Hora Final: ${prevHoraFinalController.text}");

      // 5. Envio da requisição com timeout
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      // 6. Tratamento da resposta
      if (!mounted) return;

      if (response.statusCode == 201) {
        // Cria a instância de Solicitar a partir da resposta
        final responseData = jsonDecode(response.body);
        final solicitar = Solicitar.fromJson(responseData['solicitacao']);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const InicioPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitação #${solicitar.id} criada com sucesso!'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Erros do servidor
        final errorMessage =
            jsonDecode(response.body)['error'] ?? 'Erro desconhecido';
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException {
      // Sem conexão
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem conexão com o servidor')),
      );
    } on TimeoutException {
      // Timeout
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tempo de conexão excedido')),
      );
    } catch (e) {
      // Outros erros
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: ${e.toString().replaceAll(RegExp(r'Exception: '), '')}',
          ),
        ),
      );
    } finally {
      // Finalização do loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Realizar Solicitação'),
      backgroundColor: Color(0xFF303030),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children:
                [
                      _buildDatePickerField(
                        label: 'Data Início',
                        controller: prevDataInicioController,
                      ),
                      _buildTimePickerField(
                        label: 'Hora Início',
                        controller: prevHoraInicioController,
                      ),
                      _buildDatePickerField(
                        label: 'Data Final',
                        controller: prevDataFinalController,
                      ),
                      _buildTimePickerField(
                        label: 'Hora Final',
                        controller: prevHoraFinalController,
                      ),
                      TextFormField(
                        controller: motivoController,
                        decoration: const InputDecoration(
                          labelStyle: TextStyle(color: Colors.white),
                          labelText: 'Motivo da Solicitação',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll<Color>(
                                Color(0xFF013A65),
                              ),
                              shape: WidgetStatePropertyAll<
                                RoundedRectangleBorder
                              >(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              minimumSize: WidgetStatePropertyAll<Size>(
                                const Size(double.infinity, 50),
                              ),
                              maximumSize: WidgetStatePropertyAll<Size>(
                                const Size(double.infinity, 50),
                              ),
                              padding: WidgetStatePropertyAll<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              'Enviar Solicitação',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    ]
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: w,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.white),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          // borderSide: BorderSide(color: Colors.white),
        ),
      ),
      onTap: () => _selectDate(context, controller),
      validator: (value) => value!.isEmpty ? 'Selecione uma data' : null,
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelStyle: const TextStyle(color: Colors.white),
        labelText: label,
        suffixIcon: const Icon(Icons.access_time, color: Colors.white),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      onTap: () => _selectTime(context, controller),
      validator: (value) => value!.isEmpty ? 'Selecione um horário' : null,
    );
  }
}
