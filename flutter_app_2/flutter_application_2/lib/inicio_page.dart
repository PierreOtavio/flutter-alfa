import 'package:flutter/material.dart';
import 'package:flutter_application_2/login_page.dart';
import 'package:flutter_application_2/notify_page.dart';
import 'package:flutter_application_2/veicsoli_page.dart';
import 'package:flutter_application_2/veiculo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/goals/globals.dart';
import 'package:flutter_application_2/veiculo_page.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => VeiculoPage()),
    );
  }

  Future<void> redirectSolic() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => VeicsoliPage()),
    );
  }

  Future<void> redirectNotify() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NotifyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 330,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              color: Color(0xFF424242),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF424242),
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

                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance!.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      instance!.status,
                      style: TextStyle(color: Colors.white, fontSize: 19),
                    ),
                  ],
                ),

                SizedBox(width: 40),
                IconButton(
                  onPressed: () => logout(context),
                  icon: Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          GestureDetector(
            onTap: () {
              redirectForVeic();
            },
            child: Container(
              alignment: Alignment.centerRight,
              width: 330,
              height: 80,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Color(0xFF424242),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => redirectForVeic(),
                    icon: Icon(
                      Icons.car_rental,
                      color: Color(0xFFFFFFFF),
                      size: 40,
                    ),
                  ),

                  SizedBox(width: 0),

                  Expanded(
                    child: Column(
                      // verticalDirection: VerticalDirection.down,
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
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => redirectSolic(),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
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
                    onPressed: () => redirectSolic(),
                    icon: Icon(
                      Icons.call_merge_rounded,
                      color: Color(0xFFFFFFFF),
                      size: 40,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      // verticalDirection: VerticalDirection.down,
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

          Column(
            children: [
              FloatingActionButton(
                onPressed: () {
                  redirectNotify();
                },
                backgroundColor:
                    Colors.transparent, // Fundo transparente do FAB
                elevation: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fundo do botão
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E), // Cor de fundo do botão
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // Bordas arredondadas
                      ),
                    ),
                    // Ícone de sino
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 32,
                    ),
                    // Alerta no canto superior esquerdo
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red, // Cor do alerta
                          shape: BoxShape.circle, // Formato circular
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
