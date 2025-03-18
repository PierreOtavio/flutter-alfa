class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class SocketException extends NetworkException {
  SocketException(String message) : super(message);
}

class TimeoutException extends NetworkException {
  TimeoutException(String message) : super(message);
}
