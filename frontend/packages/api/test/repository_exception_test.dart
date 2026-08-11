import 'package:dio/dio.dart';
import 'package:flag_api/flag_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepositoryException.fromDio', () {
    test('extrai mensagem do corpo da resposta', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 422,
          data: {'message': 'Atleta não encontrado no roster'},
        ),
      );

      final exception = RepositoryException.fromDio(error);

      expect(exception.statusCode, 422);
      expect(exception.message, 'Atleta não encontrado no roster');
    });

    test('usa a mensagem do DioException quando o corpo não tem message',
        () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: 'Connection timed out',
      );

      final exception = RepositoryException.fromDio(error);

      expect(exception.statusCode, isNull);
      expect(exception.message, 'Connection timed out');
    });
  });
}
