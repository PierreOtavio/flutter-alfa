import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/components/app_bar.dart';
// import 'package:flutter_application_2/data/cargo.dart';
import 'package:flutter_application_2/data/user.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_application_2/goals/globals.dart';
import 'package:flutter_application_2/inicio_solic_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SolicitadosUser extends StatefulWidget {
  const SolicitadosUser({super.key});

  @override
  State<SolicitadosUser> createState() => _SolicitadosUserState();
}

class _SolicitadosUserState extends State<SolicitadosUser> {
  bool isLoading = false;
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey =
      'auth_token'; // Altere para sua chave real, se necessário
  List<dynamic> solicitacoes = [];

  @override
  void initState() {
    super.initState();
    getSolic();
  }

  // Recupera o token de autenticação (compatível com web e mobile)
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
        return null;
      }
    }
  }

  // Busca as solicitações da API
  Future<void> getSolic() async {
    setState(() => isLoading = true);

    final String apiUrl = '${AppConfig.baseUrl}/api/solicitacoes';
    final token = await _getToken();

    if (token == null) {
      print('Token não encontrado!');
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Estrutura nova: { "message": "...", "solicitacoes": [...] }
        if (data != null && data.containsKey('solicitacoes')) {
          setState(() => solicitacoes = data['solicitacoes']);
        } else {
          print('Formato de resposta inesperado: $data');
          setState(() => solicitacoes = []);
        }
      } else {
        print('Erro ${response.statusCode}: ${response.body}');
        setState(() => solicitacoes = []);
      }
    } catch (e) {
      print('Erro na requisição: $e');
      setState(() => solicitacoes = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget verifyCargo(User? instance) {
    dynamic appBar;
    if (instance!.cargo.nome == 'Adm') {
      appBar = CustomAppBar(title: 'Solicitações');
      return appBar;
    } else {
      appBar = CustomAppBar(title: 'Minhas solicitações');
      return appBar;
    }
  }

  // Modifique o método redirectInicioSolic
  Future<void> redirectInicioSolic(int index) async {
    final solicitacao = solicitacoes[index];
    final id = solicitacao['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID da solicitação inválido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InicioSolicPage(solicitacaoID: int.parse(id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: verifyCargo(instance) as PreferredSizeWidget,
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : solicitacoes.isEmpty
              ? const Center(
                child: Text(
                  'Nenhuma solicitação encontrada.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                itemCount: solicitacoes.length,
                itemBuilder: (context, index) {
                  final solicitacao = solicitacoes[index];
                  final usuario = solicitacao['user'];
                  final veiculo = solicitacao['veiculo'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        'Solicitado por: ${usuario['name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Placa: ${veiculo['placa']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            // Text(
                            //   'Solicitado por: ${veiculo['obs_veiculo']}',
                            //   style: const TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 16,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        child: IconButton(
                          onPressed: () {
                            redirectInicioSolic(index);
                          },
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
