import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/data/user.dart';
import 'package:flutter_application_2/goals/globals.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'inicio_page.dart';

class LoginPage extends StatefulWidget {
  @override
  const LoginPage({super.key});

  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final List<String> items = ['Adm', 'User'];
  String? selectedValue;
  bool _isLoading = false;
  bool _passwordvisible = false;

  Future<void> login() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/login'),
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({
          'cpf': cpfController.text,
          'password': passwordController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Imprima a resposta para depuração
        print('Resposta: ${response.body}');

        final data = jsonDecode(response.body);

        final userData = data['user'];

        instance = User(
          id: userData['id'],
          cpf: userData['cpf'],
          name: userData['name'],
          password: userData['password'],
          email: userData['email'],
          telefone: userData['telefone'],
          status: userData['status'],
          // cargoId: data['cargo_id'],
        );

        print(instance);

        // print(instance);

        // Verifique se a chave token existe
        if (data.containsKey('token')) {
          final token = data['token'];

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('auth_token', token);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => InicioPage()),
          );
        } else {
          // Verifique se o token está em um objeto aninhado
          print('Estrutura da resposta: $data');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token não encontrado na resposta')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login falhou! Tente novamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro durante o login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B1C1E),

      appBar: AppBar(backgroundColor: Color(0xFF013A65)),
      body: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/image/alfalogo2.png',
                  width: double.infinity, // Ocupa toda a largura disponível
                  height: 300, // Altura ajustável
                  fit: BoxFit.cover, // Ajusta a imagem para cobrir o espaço
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                style: TextStyle(color: Color(0xFFC7C7CF)),
                controller: cpfController,
                decoration: const InputDecoration(
                  labelText: "CPF",
                  prefixIcon: Icon(Icons.person, color: Color(0xFFC7C7CF)),
                  labelStyle: TextStyle(color: Color(0xFFC7C7CF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor, insira o seu CPF";
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              TextFormField(
                style: TextStyle(color: Color(0xFFC7C7CF)),
                controller: passwordController,
                obscureText: !_passwordvisible,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Color(0xFFC7C7CF)),
                  labelText: "Senha",
                  labelStyle: TextStyle(color: Color(0xFFC7C7CF)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordvisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Color(0xFFC7C7CF),
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordvisible = !_passwordvisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor, insira sua senha";
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              DropdownButtonHideUnderline(
                child: DropdownButton2(
                  isExpanded: true,
                  items:
                      items
                          .map(
                            (String items) => DropdownMenuItem(
                              value: items,
                              child: Text(
                                items,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    height: 50,
                    width: double.infinity,
                  ),
                  menuItemStyleData: const MenuItemStyleData(height: 30),
                  iconStyleData: const IconStyleData(
                    icon: Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: Color(0xFFC7C7CF),
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFC7C7CF), width: 1),
                    ),
                  ),
                  customButton: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFC7C7CF), width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFF303030),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Color(0xFFC7C7CF)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            selectedValue ?? 'Selecione um item',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFC7C7CF),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          color: Color(0xFFC7C7CF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF013A65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50),
                  textStyle: TextStyle(fontSize: 20),
                ),
                child: Text(
                  "Entrar",
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
                onPressed: () {
                  setState(() => _isLoading = true);
                  login();
                  if (_isLoading)
                    CircularProgressIndicator(color: Colors.white);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
