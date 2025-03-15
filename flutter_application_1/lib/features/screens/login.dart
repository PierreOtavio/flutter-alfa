import 'package:flutter_application_1/features/login/components/cpf_field.dart';
import 'package:flutter_application_1/features/login/components/dropdwn_button.dart';
import 'package:flutter_application_1/features/login/components/senha_field.dart';
import 'package:flutter_application_1/features/login/auth_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/screens/black_teste.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  Future<void> _realizarLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _apiService.login(
          _cpfController.text,
          _senhaController.text,
        );
        if (user != null) {
          print('Login efetuado com sucesso!');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BlackTeste()),
            (Route<dynamic> route) => false,
          );
        } else {
          print('Erro ao realizar login');
        }
      } catch (e) {
        print('Erro ao realizar login: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CpfField(controller: _cpfController),
                SizedBox(height: 10), // Adicionei espaço entre os campos
                SenhaField(controller: _senhaController),
                SizedBox(height: 10), // Adicionei espaço entre os campos
                MyDropdwnButton(),
                SizedBox(height: 20.0),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _realizarLogin,
                      child: Text('Login'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
