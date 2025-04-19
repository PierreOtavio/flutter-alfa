import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';
import 'package:flutter_application_2/goals/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  static const String _tokenKey = 'auth_token';
  late Future<List<dynamic>> _relatorioFuture;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _relatorioFuture = fetchRelatorio();
  }

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
    final url = Uri.parse('${AppConfig.baseUrl}/api/relatorio-veiculos');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('registros')) {
          return decodedBody['registros'] as List<dynamic>;
        } else {
          throw Exception('Formato de resposta inesperado do servidor.');
        }
      } else {
        throw Exception(
          'Erro ao carregar relatório: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Erro na requisição fetchRelatorio: $e');
      throw Exception(
        'Falha ao conectar com o servidor ou processar a resposta: $e',
      );
    }
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'concluída':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatarData(String? data) {
    if (data == null) return '--/--/----';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(data));
    } catch (_) {
      return data;
    }
  }

  String _formatarHora(String? hora) {
    if (hora == null) return '--:--';
    return hora.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Relatório de uso'),
      backgroundColor: const Color(0xFF303030),
      body: FutureBuilder<List<dynamic>>(
        future: _relatorioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar dados:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum relatório encontrado.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final registros = snapshot.data!;

          return Column(
            children: [
              // Apenas a seção do ListView.builder foi modificada
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final item = registros[index];
                    final veiculo = item['veiculo'] ?? {};
                    final user = item['user'] ?? {};
                    final marca =
                        veiculo['marca']?['marca'] ?? 'Marca não informada';
                    final modelo =
                        veiculo['modelo']?['modelo'] ?? 'Modelo não informado';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF444444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabeçalho simplificado
                            Text(
                              '$marca $modelo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Placa: ${veiculo['placa'] ?? 'Indisponível'}',
                              style: const TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 12),

                            // Informações principais
                            Text(
                              'Responsável: ${user['name'] ?? 'Usuário Desconhecido'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Período: ${_formatarData(item['prev_data_inicio'])} '
                              '${_formatarHora(item['prev_hora_inicio'])} - '
                              '${_formatarData(item['prev_data_final'])} '
                              '${_formatarHora(item['prev_hora_final'])}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Motivo: ${item['motivo'] ?? 'Não informado'}',
                              style: const TextStyle(color: Colors.white),
                            ),

                            // Status e detalhes
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${(item['situacao'] ?? '').toUpperCase()}',
                                    style: TextStyle(
                                      color: _corStatus(item['situacao']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item['situacao']?.toLowerCase() ==
                                          'recusada' &&
                                      item['motivo_recusa'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Motivo da recusa: ${item['motivo_recusa']}',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                width: double.infinity,
                color: Colors.transparent,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Obs: para mais informações acesse o relatório no sistema web',
                  style: TextStyle(
                    color: Colors.amber,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
