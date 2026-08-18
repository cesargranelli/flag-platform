import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.onRequest);

  final Future<ResponseBody> Function(RequestOptions options) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSessionManager extends SessionManager {
  @override
  Future<String?> getToken() async => null;
}

void main() {
  group('CategoryApi', () {
    test('listByCompetition chama GET público e converte a lista', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode([
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'competitionId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'modalityId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'modalityName': 'Flag Football',
            'modalityFormat': '5x5',
            'gender': 'MALE',
            'ageGroup': 'ADULT',
            'name': 'Masculino',
            'createdAt': '2026-01-01T10:00:00.000Z',
            'updatedAt': null,
          },
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'competitionId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'modalityId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'gender': 'FEMALE',
            'ageGroup': 'SUB14',
            'name': 'Feminino',
          },
        ]);
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = CategoryApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final categories = await api.listByCompetition(
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      );

      expect(
        captured.uri.path,
        '/api/v1/competitions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/categories',
      );
      expect(captured.method, 'GET');
      expect(categories, hasLength(2));
      expect(categories.first.id, '11111111-1111-1111-1111-111111111111');
      expect(categories.first.name, 'Masculino');
      expect(categories.first.competitionId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(categories.first.modalityId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
      expect(categories.first.gender, Gender.male);
      expect(categories.first.ageGroup, AgeGroup.adult);
      expect(categories.last.id, '22222222-2222-2222-2222-222222222222');
      expect(categories.last.gender, Gender.female);
      expect(categories.last.ageGroup, AgeGroup.sub14);
      expect(categories.last.createdAt, isNull);
    });

    test('getById chama GET do detalhe e converte', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode({
          'id': '11111111-1111-1111-1111-111111111111',
          'competitionId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'modalityId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'gender': 'MALE',
          'ageGroup': 'ADULT',
          'name': 'Masculino',
          'createdAt': '2026-01-01T10:00:00.000Z',
          'updatedAt': '2026-01-02T10:00:00.000Z',
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = CategoryApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final category = await api.getById('11111111-1111-1111-1111-111111111111');

      expect(captured.uri.path, '/api/v1/categories/11111111-1111-1111-1111-111111111111');
      expect(captured.method, 'GET');
      expect(category.id, '11111111-1111-1111-1111-111111111111');
      expect(category.name, 'Masculino');
      expect(category.competitionId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(category.createdAt, isNotNull);
    });
  });
}
