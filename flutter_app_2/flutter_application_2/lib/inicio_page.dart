import 'package:flutter/material.dart';
import 'package:flutter_application_2/login_page.dart';
import 'package:flutter_application_2/notify_page.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
import 'package:flutter_application_2/veiculo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/goals/globals.dart';
import 'package:flutter_application_2/solicitados_user.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> redirectForVeic() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VeiculoPage()),
    );
  }

  Future<void> redirectSolic([veiculo]) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VeicSoliPage(veiculo: veiculo)),
    );
  }

  Future<void> redirectNotify() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificacoesGeral()),
    );
  }

  Future<void> redirectSolicitadosUser() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SolicitacaoVeiculoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),

      // Conteúdo principal
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 330,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/image/alfaid.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.center,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instance!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        instance!.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    onPressed: () => logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Botão 1 - Solicitar Veículo
            GestureDetector(
              onTap: () {
                redirectForVeic();
              },
              child: Container(
                alignment: Alignment.centerRight,
                width: 330,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => redirectForVeic(),
                      icon: const Icon(
                        Icons.car_rental,
                        color: Color(0xFFFFFFFF),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 0),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Solicitar um Veículo',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botão 2 - Veículos Solicitados
            GestureDetector(
              onTap: () => redirectSolic(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 330,
                height: 80,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => redirectSolic(),
                      icon: const Icon(
                        Icons.call_merge_rounded,
                        color: Color(0xFFFFFFFF),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Veículos Solicitados',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botão 3 - Ver Solicitações (solicitados_user.dart)
            GestureDetector(
              onTap: () => redirectSolicitadosUser(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 330,
                height: 80,
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => redirectSolicitadosUser(),
                      icon: const Icon(
                        Icons.list,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Ver Solicitações',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // espaço para não encobrir o botão
          ],
        ),
      ),

      // Botão de notificação
      floatingActionButton: GestureDetector(
        onTap: () => redirectNotify(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const Icon(Icons.notifications, color: Colors.white, size: 32),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
