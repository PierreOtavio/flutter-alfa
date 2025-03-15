import 'package:flutter/material.dart';

class ServerException implements Exception {
  final int statusCode;
  final String message;

  ServerException({required this.statusCode, required this.message});

  @override
  String toString() => 'Error code: $statusCode, message: $message';
}
