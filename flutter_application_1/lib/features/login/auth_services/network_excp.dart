import 'package:flutter/material.dart';

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

class SocketException implements Exception {
  SocketException(String message) : super();
}

class TimeoutException implements Exception {
  TimeoutException(String message) : super();
}
