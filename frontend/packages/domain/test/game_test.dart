import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Game.fromJson/toJson', () {
    test('converte o shape completo do calendário', () {
      final game = Game.fromJson({
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
      });

      expect(game.id, '11111111-1111-1111-1111-111111111111');
      expect(game.roundId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(game.roundNumber, 1);
      expect(game.homeTeamName, 'Flames');
      expect(game.awayTeamName, 'Titans');
      expect(game.venueId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
      expect(game.venueName, 'Campo do Parque');
      expect(game.scheduledAt, DateTime.parse('2026-08-20T19:30:00'));
      expect(game.status, GameStatus.scheduled);
      expect(game.homeScore, isNull);
      expect(game.awayScore, isNull);
    });

    test('converte jogo encerrado com placar e rodada', () {
      final game = Game.fromJson({
        'id': '22222222-2222-2222-2222-222222222222',
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

      expect(game.roundNumber, 2);
      expect(game.status, GameStatus.finished);
      expect(game.homeScore, 3);
      expect(game.awayScore, 2);
      expect(game.venueId, isNull);
      expect(game.venueName, 'Arena Central');
    });

    test('não quebra quando campos opcionais vêm nulos', () {
      final game = Game.fromJson({
        'id': '33333333-3333-3333-3333-333333333333',
        'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'roundNumber': null,
        'homeTeamName': null,
        'awayTeamName': null,
        'venueId': null,
        'venueName': null,
        'scheduledAt': '2026-08-20T19:30:00',
        'status': 'CANCELLED',
        'homeScore': null,
        'awayScore': null,
      });

      expect(game.roundNumber, isNull);
      expect(game.homeTeamName, isNull);
      expect(game.awayTeamName, isNull);
      expect(game.venueId, isNull);
      expect(game.venueName, isNull);
      expect(game.homeScore, isNull);
      expect(game.awayScore, isNull);
      expect(game.status, GameStatus.cancelled);
    });

    test('aceita shape mínimo sem campos opcionais', () {
      final game = Game.fromJson({
        'id': '44444444-4444-4444-4444-444444444444',
        'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'scheduledAt': '2026-09-01T10:00:00',
        'status': 'IN_PROGRESS',
      });

      expect(game.id, '44444444-4444-4444-4444-444444444444');
      expect(game.roundId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(game.roundNumber, isNull);
      expect(game.homeTeamName, isNull);
      expect(game.awayTeamName, isNull);
      expect(game.venueName, isNull);
      expect(game.status, GameStatus.inProgress);
    });

    test('toJson é coerente com o shape do calendário', () {
      final game = Game(
        id: '11111111-1111-1111-1111-111111111111',
        roundId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        roundNumber: 1,
        homeTeamName: 'Flames',
        awayTeamName: 'Titans',
        venueName: 'Campo do Parque',
        scheduledAt: DateTime(2026, 8, 20, 19, 30),
        status: GameStatus.scheduled,
      );

      final json = game.toJson();

      expect(json['id'], '11111111-1111-1111-1111-111111111111');
      expect(json['roundId'], 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(json['roundNumber'], 1);
      expect(json['homeTeamName'], 'Flames');
      expect(json['awayTeamName'], 'Titans');
      expect(json['venueName'], 'Campo do Parque');
      expect(json['scheduledAt'], '2026-08-20T19:30:00.000');
      expect(json['status'], 'SCHEDULED');
    });

    test('toJson omite campos opcionais nulos', () {
      final game = Game(
        id: '11111111-1111-1111-1111-111111111111',
        roundId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        scheduledAt: DateTime(2026, 8, 20, 19, 30),
        status: GameStatus.scheduled,
      );

      final json = game.toJson();

      expect(json.containsKey('roundNumber'), isFalse);
      expect(json.containsKey('homeTeamName'), isFalse);
      expect(json.containsKey('awayTeamName'), isFalse);
      expect(json.containsKey('venueId'), isFalse);
      expect(json.containsKey('venueName'), isFalse);
      expect(json.containsKey('homeScore'), isFalse);
      expect(json.containsKey('awayScore'), isFalse);
    });

    test('rejeita status desconhecido', () {
      expect(
        () => Game.fromJson({
          'id': '11111111-1111-1111-1111-111111111111',
          'roundId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'scheduledAt': '2026-08-20T19:30:00',
          'status': 'UNKNOWN',
        }),
        throwsFormatException,
      );
    });
  });
}
