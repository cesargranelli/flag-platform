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
  group('GameApi', () {
    test(
      'listByCompetition chama GET do calendário e converte a lista',
      () async {
        late RequestOptions captured;
        final dio = Dio();
        dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
          captured = options;
          final body = jsonEncode([
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
              'roundNumber': 1,
              'homeTeamName': 'Flames',
              'awayTeamName': 'Titans',
              'venueId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
              'venueName': 'Campo do Parque',
              'scheduledAt': '2026-08-20T19:30:00',
              'status': 'SCHEDULED',
              'homeScore': null,
              'awayScore': null,
            },
            {
              'id': '22222222-2222-2222-2222-222222222222',
              'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
              'roundNumber': 1,
              'homeTeamName': 'Falcons',
              'awayTeamName': 'Eagles',
              'venueName': 'Arena Central',
              'scheduledAt': '2026-08-22T15:00:00',
              'status': 'FINISHED',
              'homeScore': 3,
              'awayScore': 2,
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

        final api = GameApi(
          ApiClient(session: _FakeSessionManager(), dio: dio),
        );

        final games = await api.listByCompetition(
          'cccccccc-cccc-cccc-cccc-cccccccccccc',
        );

        expect(
          captured.uri.path,
          '/api/v1/competitions/cccccccc-cccc-cccc-cccc-cccccccccccc/games',
        );
        expect(captured.method, 'GET');
        expect(games, hasLength(2));
        expect(games.first.id, '11111111-1111-1111-1111-111111111111');
        expect(games.first.roundNumber, 1);
        expect(games.first.homeTeamName, 'Flames');
        expect(games.first.awayTeamName, 'Titans');
        expect(games.first.venueName, 'Campo do Parque');
        expect(games.first.status, GameStatus.scheduled);
        expect(games.first.scheduledAt, DateTime.parse('2026-08-20T19:30:00'));
        expect(games.last.status, GameStatus.finished);
        expect(games.last.homeScore, 3);
        expect(games.last.awayScore, 2);
      },
    );

    test('listByRound usa o id UUID na URL', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = GameApi(ApiClient(session: _FakeSessionManager(), dio: dio));

      final games = await api.listByRound(
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      );

      expect(
        captured.uri.path,
        '/api/v1/rounds/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/games',
      );
      expect(games, isEmpty);
    });

    test('getById usa o id UUID na URL', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        captured = options;
        final body = jsonEncode({
          'id': '11111111-1111-1111-1111-111111111111',
          'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'roundNumber': 2,
          'homeTeamName': 'Falcons',
          'awayTeamName': 'Eagles',
          'venueName': 'Arena Central',
          'scheduledAt': '2026-08-10T15:00:00',
          'status': 'FINISHED',
          'homeScore': 3,
          'awayScore': 2,
        });
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final api = GameApi(ApiClient(session: _FakeSessionManager(), dio: dio));

      final game = await api.getById('11111111-1111-1111-1111-111111111111');

      expect(
        captured.uri.path,
        '/api/v1/games/11111111-1111-1111-1111-111111111111',
      );
      expect(game.id, '11111111-1111-1111-1111-111111111111');
      expect(game.homeTeamName, 'Falcons');
      expect(game.awayTeamName, 'Eagles');
      expect(game.status, GameStatus.finished);
      expect(game.homeScore, 3);
      expect(game.awayScore, 2);
    });
  });
}
