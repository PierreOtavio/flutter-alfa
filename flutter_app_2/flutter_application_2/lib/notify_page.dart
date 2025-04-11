import 'package:flutter/material.dart';
import 'package:flutter_application_2/components/app_bar.dart';

class NotificacoesGeral extends StatefulWidget {
  const NotificacoesGeral({super.key});

  @override
  State<NotificacoesGeral> createState() => _NotificacoesGeralState();
}

class _NotificacoesGeralState extends State<NotificacoesGeral> {
  final List<Map<String, String>> notificacoes = [
    {
      'mensagem': 'Tales Lima quer utilizar de um Honda Civic!',
      'acao': 'Ver Mais',
    },
    {
      'mensagem': 'O Honda Civic já rodou 5.530km. 4495 KM para revisão',
      'acao': 'Relatório',
    },
    {
      'mensagem': 'Rodrigo Lopes terminou de utilizar o Fiat Cronos',
      'acao': 'Relatório',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: const CustomAppBar(title: 'Notificações'),
      // appBar: AppBar(
      //   backgroundColor: Colors.blue[900],
      //   title: const Text(
      //     'Notificações',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       Navigator.pop(context); // Voltar pra tela anterior
      //     },
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: () {
      //         // Atualizar notificações (futuramente)
      //       },
      //     ),
      //   ],
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: notificacoes.length,
          itemBuilder: (context, index) {
            final item = notificacoes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['mensagem'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // ação do botão, pode navegar pra outra tela
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        item['acao'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
