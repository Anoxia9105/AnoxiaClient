class ApiException implements Exception {
  final int? code;
  final String message;

  ApiException(this.message, {this.code});

  @override
  String toString() => 'ApiException(code:$code, message:$message)';
}
