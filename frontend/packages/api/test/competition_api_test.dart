import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter HTTP fake que responde sem rede real.
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

/// SessionManager fake: evita o platform channel do flutter_secure_storage.
class _FakeSessionManager extends SessionManager {
  @override
  Future<String?> getToken() async => null;
}

void main() {
  group('CompetitionApi', () {
    test('listAll chama GET /api/v1/competitions e converte a lista', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode([
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'name': 'Liga Nacional',
            'organizationName': 'Flag Brasil',
            'status': 'PUBLISHED',
          },
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'name': 'Torneio Regional',
            'organizationName': 'Liga Sul',
            'status': 'DRAFT',
          },
        ]);
        return ResponseBody.fromString(body, 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final api = CompetitionApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final competitions = await api.listAll();

      expect(captured.uri.path, '/api/v1/competitions');
      expect(captured.method, 'GET');
      expect(competitions, hasLength(2));
      expect(competitions.first.id, '11111111-1111-1111-1111-111111111111');
      expect(competitions.first.name, 'Liga Nacional');
      expect(competitions.first.organizationName, 'Flag Brasil');
      expect(competitions.first.status, CompetitionStatus.published);
      expect(competitions.last.status, CompetitionStatus.draft);
    });

    test('getById usa o id UUID na URL e converte o shape completo', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode({
          'id': '11111111-1111-1111-1111-111111111111',
          'organizationId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'name': 'Liga Nacional',
          'description': 'Principal liga do país',
          'startDate': '2026-08-01T10:00:00.000Z',
          'endDate': '2026-12-20T00:00:00.000Z',
          'status': 'PUBLISHED',
          'createdAt': '2026-01-01T10:00:00.000Z',
          'updatedAt': '2026-07-30T10:00:00.000Z',
        });
        return ResponseBody.fromString(body, 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final api = CompetitionApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final competition =
          await api.getById('11111111-1111-1111-1111-111111111111');

      expect(
        captured.uri.path,
        '/api/v1/competitions/11111111-1111-1111-1111-111111111111',
      );
      expect(competition.id, '11111111-1111-1111-1111-111111111111');
      expect(
        competition.organizationId,
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      );
      expect(competition.name, 'Liga Nacional');
      expect(competition.status, CompetitionStatus.published);
      expect(competition.startDate, DateTime.parse('2026-08-01T10:00:00.000Z'));
      expect(competition.endDate, DateTime.parse('2026-12-20T00:00:00.000Z'));
    });

    test('listByOrganization aceita id UUID na URL', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        return ResponseBody.fromString('[]', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final api = CompetitionApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final competitions =
          await api.listByOrganization('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

      expect(
        captured.uri.path,
        '/api/v1/organizations/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/competitions',
      );
      expect(competitions, isEmpty);
    });
  });
}
