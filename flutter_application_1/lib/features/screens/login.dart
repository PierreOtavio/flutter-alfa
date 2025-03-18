import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/login/auth_services/api_service.dart';
import 'package:flutter_application_1/features/login/auth_services/auth_excp.dart';
import 'package:flutter_application_1/features/login/auth_services/network_excp.dart';
import 'package:flutter_application_1/features/screens/black_teste.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Importando os componentes
import '/features/login/components/cpf_field.dart';
import '/features/login/components/senha_field.dart';
import '/features/login/components/dropdwn_button.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await _apiService.realizeLogin(
          _cpfController.text,
          _passwordController.text,
        );

        final token = response['token'];
        await _storage.write(key: 'auth_token', value: token);

        // Verificar se o token é válido
        final tokenValido = await _apiService.verificarToken(token);

        if (!tokenValido) {
          throw AuthException('Token inválido');
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BlackTeste()),
          );
        }
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        log('Erro de autenticação: ${e.toString()}');
      } on NetworkException catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        log('Erro de rede: ${e.toString()}');
      } catch (e) {
        setState(() {
          _errorMessage = 'Erro inesperado: $e';
        });
        log('Erro inesperado: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo ou imagem
                  Container(
                    child: Image.asset('assets/image/alfaid.png', width: 200),

                    decoration: BoxDecoration(color: Color(0xFF08416C)),
                  ),
                  // const Icon(
                  //   Icons.account_circle,
                  //   size: 100,
                  //   color: Colors.blue,
                  // ),
                  const SizedBox(height: 32),

                  // Campo de CPF
                  CpfField(controller: _cpfController),
                  const SizedBox(height: 16),

                  // Campo de Senha
                  SenhaField(controller: _passwordController),
                  const SizedBox(height: 24),

                  // Mensagem de erro
                  MyDropdownButton(),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Botão de Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16, color: Colors.white),
                      backgroundColor: Color(0xFF08416C),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
