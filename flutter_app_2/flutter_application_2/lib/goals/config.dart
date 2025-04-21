import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // const AppConfig({super.key});

  static String baseUrl =
      kIsWeb
          ? 'http://127.0.0.1:8000'
          : Platform.isAndroid
          ? 'http://10.0.2.2:8000'
          : 'http://127.0.0.1:8000';
}
