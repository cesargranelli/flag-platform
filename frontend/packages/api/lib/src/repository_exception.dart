import 'package:dio/dio.dart';

/// Exceção de domínio da camada de dados.
class RepositoryException implements Exception {
  final String message;
  final int? statusCode;

  const RepositoryException(this.message, {this.statusCode});

  factory RepositoryException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String message;
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (error.message != null) {
      message = error.message!;
    } else {
      message = 'Erro de comunicação com o servidor';
    }
    return RepositoryException(message, statusCode: status);
  }

  @override
  String toString() => 'RepositoryException($statusCode): $message';
}
