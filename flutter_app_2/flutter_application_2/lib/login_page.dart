// import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/cargo.dart';
import 'package:flutter_application_2/data/user.dart';
import 'package:flutter_application_2/goals/config.dart';
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
  final Map<String, int> cargoMap = {'Adm': 1, 'User': 2};
  final List<String> items = ['Adm', 'User'];
  String? selectedValue;
  bool _isLoading = false;
  bool _passwordvisible = false;

  Future<void> login() async {
    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione o Centro de Custo/Cargo.'),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      int? selectedCargoId = cargoMap[selectedValue];
      if (selectedCargoId == null) {
        print("Erro: Cargo selecionado inválido: $selectedValue");
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro interno: Cargo selecionado inválido.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/login'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'cpf': cpfController.text,
          'password': passwordController.text,
          'cargo_id': selectedCargoId,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
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
          cargo: Cargo.fromJson(userData['cargo']),
        );
        print(instance);

        if (data.containsKey('token')) {
          final token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => InicioPage()),
          );
        } else {
          print('Estrutura da resposta: $data');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Token não encontrado na resposta')),
          );
        }
      } else if (response.statusCode == 422) {
        final errors = jsonDecode(response.body)['errors'];
        String errorMessage = 'Erro de validação:';
        if (errors != null && errors.isNotEmpty) {
          errorMessage = errors.entries.first.value[0];
        } else {
          errorMessage =
              'As credenciais (CPF, Senha ou Cargo) estão incorretas.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } else {
        print('Erro de servidor: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha no login! Verifique os dados ou tente mais tarde.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro durante o login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ou processamento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B1C1E),
      appBar: AppBar(backgroundColor: Color(0xFF013A65), elevation: 0),
      body: Column(
        children: [
          Image.asset(
            'assets/image/alfalogo2.png',
            width: double.infinity,
            height: 250, // Ajuste a altura conforme necessário (antes era 300)
            fit:
                BoxFit
                    .cover, // Garante que a imagem cubra a área, cortando se necessário
          ),
          // --- Conteúdo rolável com padding ---
          Expanded(
            // Faz com que o SingleChildScrollView ocupe o espaço restante
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                16.0,
              ), // Padding aplicado aqui, apenas no conteúdo rolável
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center, // Centraliza os itens verticalmente se houver espaço
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SizedBox(height: 20), // Pode não ser necessário se a imagem já der espaço
                  TextFormField(
                    style: TextStyle(color: Color(0xFFC7C7CF)),
                    controller: cpfController,
                    decoration: const InputDecoration(
                      // labelText: "CPF", // Mudado para hintText para ficar dentro do campo
                      hintText: "Usuário (CPF)", // Usando hintText
                      hintStyle: TextStyle(
                        color: Color(0xFF8F8F96),
                      ), // Cor mais suave para hint
                      prefixIcon: Icon(Icons.person, color: Color(0xFFC7C7CF)),
                      // labelStyle: TextStyle(color: Color(0xFFC7C7CF)), // Removido pois usamos hintText
                      border: OutlineInputBorder(
                        // Borda padrão (pode remover se usar enabled/focused)
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide:
                            BorderSide
                                .none, // Remover borda padrão se quiser só a do enabled/focused
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF5A5A5F),
                        ), // Borda cinza mais escura quando inativo
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ), // Borda branca quando focado
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true, // Para aplicar fillColor
                      fillColor: Color(0xFF303030), // Fundo do campo
                    ),
                    keyboardType: TextInputType.number,
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
                      // labelText: "Senha",
                      hintText: "Senha",
                      hintStyle: TextStyle(color: Color(0xFF8F8F96)),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFFC7C7CF)),
                      // labelStyle: TextStyle(color: Color(0xFFC7C7CF)),
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
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF5A5A5F)),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Color(0xFF303030),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor, insira sua senha";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    items:
                        items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Selecione o Centro de Custo',
                      // hintText:
                      // 'Selecione o Centro de Custo', // Usando hintText
                      // hintStyle: TextStyle(color: Color(0xFF8F8F96)),
                      labelStyle: TextStyle(
                        color: Color(0xFF8F8F96),
                      ), // Removido
                      prefixIcon: Icon(
                        Icons.work_outline,
                        color: Color(0xFFC7C7CF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF5A5A5F)),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Color(0xFF303030),
                    ),
                    dropdownColor: Color(0xFF212121),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    iconEnabledColor: Color(0xFFC7C7CF),
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione um cargo';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF013A65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(double.infinity, 50),
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ), // Adicionei bold
                    ),
                    onPressed: _isLoading ? null : login,
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              "Entrar",
                              style: TextStyle(color: Color(0xFFFFFFFF)),
                            ),
                  ),
                  // SizedBox(height: 20), // Espaço extra no final se necessário
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
