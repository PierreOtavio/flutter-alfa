import 'package:flutter/material.dart';
import 'package:flutter_application_2/login_page.dart';
import 'package:flutter_application_2/veiculo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 500,
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
                  height: 70,
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
                      'oi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'sla',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),

                SizedBox(width: 136),
                IconButton(
                  onPressed: () => logout(context),
                  icon: Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),
          Container(
            alignment: Alignment.centerRight,
            width: 330,
            height: 70,
            margin: EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Color(0xFF424242),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                IconButton(
                  onPressed: () => redirectForVeic(),
                  icon: Icon(
                    Icons.car_rental,
                    color: Color(0xFFFFFFFF),
                    size: 40,
                  ),
                ),
              ],
            ),
            // child: IconButton(onPressed: , icon: Icons.car_rental,),
          ),
        ],
      ),
    );
  }
}
