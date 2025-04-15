import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Keep for potential Platform checks if needed later

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/data/solicitar.dart';
import 'package:flutter_application_2/goals/globals.dart';
// Ensure these imports point to the correct files in your project
// import 'package:flutter_application_2/data/solicitar.dart';
import 'package:flutter_application_2/inicio_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoAddSolicPage extends StatefulWidget {
  final int veiculoId;
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

  // --- API URL Configuration ---
  // Use 127.0.0.1 for iOS Simulators / Web connecting to localhost
  // Use 10.0.2.2 for Android Emulators connecting to localhost
  // Use your machine's network IP for physical devices on the same network
  final String _apiUrl = 'http://127.0.0.1:8000/api/solicitar/create';
  // --- End API URL Config ---

  bool _isLoading = false;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  @override
  void dispose() {
    prevDataInicioController.dispose();
    prevHoraInicioController.dispose();
    prevDataFinalController.dispose();
    prevHoraFinalController.dispose();
    motivoController.dispose();
    super.dispose();
  }

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
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
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
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:"
          "${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  Future<String?> _getToken() async {
    // ... (getToken implementation remains the same)
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        print("Token (Web): ${token != null ? 'Found' : 'Not Found'}");
        return token;
      } catch (e) {
        print("Erro SharedPreferences (Web): $e");
        return null;
      }
    } else {
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        print("Token (Mobile): ${token != null ? 'Found' : 'Not Found'}");
        return token;
      } on PlatformException catch (e) {
        print("Erro Platform Secure Storage: $e");
        if (!mounted) return null; // Check mounted before context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de armazenamento: ${e.message}')),
        );
        return null;
      } catch (e) {
        print("Erro Secure Storage: $e");
        if (!mounted) return null; // Check mounted before context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado de armazenamento: $e')),
        );
        return null;
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    String? authToken = await _getToken();

    if (authToken == null || authToken.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sessão expirada ou token inválido. Faça login novamente.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate back to login page if token is invalid
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InicioPage(),
        ), // Use const
      );
      return;
    }

    setState(() => _isLoading = true);

    String? formattedPrevDataInicio;
    String? formattedPrevDataFinal;
    try {
      // --- Date Format Conversion ---
      final DateFormat displayFormat = DateFormat('dd-MM-yyyy');
      final DateFormat apiFormat = DateFormat('yyyy-MM-dd');

      // Use parse() - throws FormatException if input is invalid
      // This exception will be caught by the generic 'catch (e)' below
      final DateTime dateInicio = displayFormat.parse(
        prevDataInicioController.text,
      );
      final DateTime dateFinal = displayFormat.parse(
        prevDataFinalController.text,
      );

      formattedPrevDataInicio = apiFormat.format(dateInicio);
      formattedPrevDataFinal = apiFormat.format(dateFinal);

      print("Data Início (Enviando): $formattedPrevDataInicio");
      print("Hora Início (Enviando): ${prevHoraInicioController.text}");
      print("Data Final (Enviando): $formattedPrevDataFinal");
      print("Hora Final (Enviando): ${prevHoraFinalController.text}");

      // Create instance of the data class
      instanceSolicitar = Solicitar(
        veiculoId: widget.veiculoId,
        prevDataInicio: formattedPrevDataInicio,
        prevHoraInicio: prevHoraInicioController.text,
        prevDataFinal: formattedPrevDataFinal,
        prevHoraFinal: prevHoraFinalController.text,
        motivo: motivoController.text,
      );

      print("Data Object Prepared: $instanceSolicitar"); // Log the JSON data

      // REMOVED: The specific 'on FormatException catch' block as requested
    } catch (e) {
      // Catch any other potential error during date parsing/formatting
      // including FormatException if parse() fails
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar data/hora: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return; // Stop execution
    }
    // --- End Date Format Conversion ---

    try {
      final Map<String, dynamic> requestBody = {
        'veiculo_id': widget.veiculoId,
        'prev_data_inicio': formattedPrevDataInicio,
        'prev_hora_inicio': prevHoraInicioController.text,
        'prev_data_final': formattedPrevDataFinal,
        'prev_hora_final': prevHoraFinalController.text,
        'motivo': motivoController.text,
      };
      print("Request Body: ${jsonEncode(requestBody)}"); // Log request body

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return; // Check mounted after await

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // --- SUCCESS FLOW ---
        // 1. Show Success SnackBar
        if (!mounted) return; // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // Use const
            content: Text(
              'Solicitação realizada com sucesso!',
            ), // Updated message
            backgroundColor: Colors.green,
            duration: Duration(
              seconds: 2,
            ), // Show for 2 seconds (matches delay)
          ),
        );

        // 2. Wait for 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        // 3. Navigate back to InicioPage (Login/Home)
        if (!mounted) return; // Check mounted again after delay
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const InicioPage(),
          ), // Use const
          (route) => false, // Remove all previous routes
        );
        // --- END SUCCESS FLOW ---
      } else {
        // Handle backend errors (including validation errors)
        String errorMessage = 'Erro desconhecido do servidor.';
        // Safely parse error message
        try {
          if (responseBody is Map) {
            if (responseBody.containsKey('error')) {
              errorMessage = responseBody['error'];
            } else if (responseBody.containsKey('message')) {
              errorMessage = responseBody['message'];
              if (responseBody.containsKey('errors')) {
                print("Validation Errors: ${responseBody['errors']}");
                // Optionally append specific field errors to errorMessage
              }
            }
          } else if (responseBody is String && responseBody.isNotEmpty) {
            errorMessage = responseBody; // Handle plain string error response
          }
        } catch (parseError) {
          print("Error parsing error response body: $parseError");
          errorMessage = "Erro ao processar resposta do servidor.";
        }

        print("Server Error (${response.statusCode}): ${response.body}");
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } on SocketException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de rede. Verifique sua conexão.'),
          backgroundColor: Colors.red,
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tempo de conexão excedido.'),
          backgroundColor: Colors.orange,
        ),
      );
    } on http.ClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de cliente HTTP: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Catch all other errors (including the Exception thrown for non-201 status)
      if (!mounted) return;
      String errorText = e.toString().replaceFirst(RegExp(r'Exception: '), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $errorText'), // Simplified error display
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Realizar Solicitação'),
      backgroundColor: const Color(0xFF303030),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDatePickerField(
                label: 'Data Início',
                controller: prevDataInicioController,
              ),
              const SizedBox(height: 12),
              _buildTimePickerField(
                label: 'Hora Início',
                controller: prevHoraInicioController,
              ),
              const SizedBox(height: 12),
              _buildDatePickerField(
                label: 'Data Final',
                controller: prevDataFinalController,
              ),
              const SizedBox(height: 12),
              _buildTimePickerField(
                label: 'Hora Final',
                controller: prevHoraFinalController,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Motivo da Solicitação',
                ).copyWith(
                  // Reuse helper
                  hintText: 'Descreva o propósito do uso do veículo',
                  hintStyle: const TextStyle(color: Colors.white38),
                ), // Adjusted decoration
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O motivo é obrigatório';
                  }
                  if (value.length < 5) {
                    return 'Descreva um pouco mais o motivo';
                  }
                  if (value.length > 255) {
                    return 'O motivo não pode exceder 255 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF013A65),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitForm,
                    child: const Text('Enviar Solicitação'),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Refactored Input Field Builders ---
  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      readOnly: true,
      decoration: _inputDecoration(label: label, icon: Icons.calendar_today),
      onTap: () => _selectDate(context, controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione a $label';
        }
        // Basic check for display format (optional but helpful)
        try {
          DateFormat('dd-MM-yyyy').parseStrict(value);
        } catch (_) {
          return 'Formato inválido (DD-MM-YYYY)';
        }
        return null;
      },
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
      decoration: _inputDecoration(label: label, icon: Icons.access_time),
      onTap: () => _selectTime(context, controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione a $label';
        }
        final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
        if (!timeRegex.hasMatch(value)) {
          return 'Formato inválido (HH:MM)';
        }
        return null;
      },
    );
  }

  // Helper for common input decoration
  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    // Made icon optional
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      suffixIcon:
          icon != null
              ? Icon(icon, color: Colors.white70)
              : null, // Handle optional icon
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      // filled: true,
      // fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 12.0,
      ),
    );
  }
}
