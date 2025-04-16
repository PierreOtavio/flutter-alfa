import 'dart:convert';
import 'package:flutter_application_2/goals/globals.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SolicitadosUser extends StatefulWidget {
  const SolicitadosUser({super.key});

  @override
  State<SolicitadosUser> createState() => _SolicitadosUserState();
}

class _SolicitadosUserState extends State<SolicitadosUser> {
  @override
  void initState() {
    super.initState();
    getSolic();
  }

  Future<void> getSolic() async {
    final String apiUrl = 'http://127.0.0.1:8000/api/solicitacoes';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Process the data as needed
        print('Solicitações obtidas: $data');
      } else {
        print('Erro ao obter solicitações: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao se comunicar com a API: $e');
    }
  }

  List<dynamic> solicitacoes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicita es')),
      body: ListView.builder(
        itemCount: solicitacoes.length,
        itemBuilder: (context, index) {
          final solicitacao = solicitacoes[index];
          return Card(
            child: ListTile(
              title: Text(solicitacao['motivo']),
              subtitle: Text(
                solicitacao['prev_data_inicio'] +
                    ' - ' +
                    solicitacao['prev_hora_inicio'],
              ),
            ),
          );
        },
      ),
    );
  }
}
