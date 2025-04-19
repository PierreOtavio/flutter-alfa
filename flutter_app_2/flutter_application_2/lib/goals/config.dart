// import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
// // import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart'; // Import for kIsWeb
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_application_2/components/app_bar.dart';
// import 'package:flutter_application_2/goals/config.dart';
// import 'package:flutter_application_2/veicsoli_page.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_application_2/data/veiculo.dart';
// import 'package:flutter_application_2/components/qr_code_scan.dart'; // Verifique o caminho
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // const AppConfig({super.key});

  static String baseUrl =
      kIsWeb
          ? 'http://127.0.0.1:8000'
          : Platform.isAndroid
          ? 'http://10.0.2.2:8000'
          : 'http://127.0.0.1:8000';
}
