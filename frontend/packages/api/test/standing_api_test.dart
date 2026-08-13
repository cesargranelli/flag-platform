import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
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
  group('StandingApi', () {
    test('listByCategory chama GET público e converte a lista', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode([
          {
            'position': 1,
            'teamId': '11111111-1111-1111-1111-111111111111',
            'teamName': 'Flames',
            'played': 6,
            'wins': 5,
            'draws': 1,
            'losses': 0,
            'goalsFor': 24,
            'goalsAgainst': 8,
            'goalDifference': 16,
            'points': 16,
          },
          {
            'position': 2,
            'teamId': '22222222-2222-2222-2222-222222222222',
            'teamName': 'Titans',
            'played': 6,
            'wins': 4,
            'draws': 1,
            'losses': 1,
            'goalsFor': 18,
            'goalsAgainst': 10,
            'goalDifference': 8,
            'points': 13,
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

      final api = StandingApi(
        ApiClient(session: _FakeSessionManager(), dio: dio),
      );

      final standings = await api.listByCategory(
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
      );

      expect(
        captured.uri.path,
        '/api/v1/categories/cccccccc-cccc-cccc-cccc-cccccccccccc/standings',
      );
      expect(captured.method, 'GET');
      expect(standings, hasLength(2));
      expect(standings.first.position, 1);
      expect(standings.first.teamId, '11111111-1111-1111-1111-111111111111');
      expect(standings.first.teamName, 'Flames');
      expect(standings.first.points, 16);
      expect(standings.last.teamName, 'Titans');
      expect(standings.last.goalDifference, 8);
    });
  });
}
