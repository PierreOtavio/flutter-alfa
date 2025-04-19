import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({Key? key}) : super(key: key);

  @override
  _RelatorioPageState createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  static const String _tokenKey = 'auth_token'; // Definindo chave do token
  late Future<List<dynamic>> _relatorioFuture;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _relatorioFuture = fetchRelatorio();
  }

  // Função para pegar o token
  Future<String?> _getToken() async {
    try {
      String? token;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_tokenKey);
      } else {
        token = await _secureStorage.read(key: _tokenKey);
      }
      return token;
    } catch (e) {
      debugPrint("Erro ao obter token: $e");
      return null;
    }
  }

  Future<List<dynamic>> fetchRelatorio() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado ou token inválido.');
    }

    final String baseUrl = 'http://127.0.0.1:8000/api'; 
    final url = Uri.parse('$baseUrl/relatorio-veiculos');

    debugPrint('Fazendo requisição para: $url');
    debugPrint('Usando token: Bearer $token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Status Code recebido: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          return decodedBody;
        } else {
          throw Exception('Formato de resposta inesperado do servidor.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado ou sessão expirada (Erro 401). Faça login novamente.');
      } else {
        throw Exception('Erro ao carregar relatório: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Erro na requisição fetchRelatorio: $e');
      throw Exception('Falha ao conectar com o servidor ou processar a resposta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Uso de Veículos'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _relatorioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar dados:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum relatório encontrado.'));
          }

          final relatorios = snapshot.data!;

          return ListView.builder(
            itemCount: relatorios.length,
            itemBuilder: (context, index) {
              final item = relatorios[index];

              final modeloVeiculo = item['veiculo']?['modelo'] ?? 'Veículo Indisponível';
              final nomeUsuario = item['user']?['nome'] ?? 'Usuário Desconhecido';
              final dataInicio = item['prev_data_inicio'] ?? '??/??/????';
              final horaInicio = item['prev_hora_inicio'] ?? '??:??';
              final dataFim = item['prev_data_final'] ?? '??/??/????';
              final horaFim = item['prev_hora_final'] ?? '??:??';
              final motivo = item['motivo'] ?? 'Motivo não informado';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  title: Text(modeloVeiculo),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Responsável: $nomeUsuario'),
                      Text('Início: $dataInicio $horaInicio'),
                      Text('Fim: $dataFim $horaFim'),
                      Text('Motivo: $motivo'),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
