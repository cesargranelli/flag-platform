import 'package:dio/dio.dart';

import 'package:flag_core/flag_core.dart';

import 'repository_exception.dart';

/// Cliente HTTP da API REST do Flag Platform.
///
/// Usa [AppConfig.apiBaseUrl] como base URL e injeta o token JWT via
/// [SessionManager] quando autenticado.
class ApiClient {
  final Dio dio;
  final SessionManager _session;

  ApiClient({
    required SessionManager session,
    Dio? dio,
  })  : _session = session,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  ApiClient get public => this;

  Future<Map<String, dynamic>> _headers() async {
    final token = await _session.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<T>> getList<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await dio.get<List<dynamic>>(
        path,
        options: Options(headers: await _headers()),
      );
      return (response.data ?? const [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> getOne<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<T> patch<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: await _headers()),
      );
      return fromJson(response.data!);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<void>(path, options: Options(headers: await _headers()));
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e);
    }
  }
}
