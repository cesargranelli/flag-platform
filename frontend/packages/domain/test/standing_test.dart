import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Standing.fromJson/toJson', () {
    test('converte o shape público da classificação', () {
      final standing = Standing.fromJson({
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
      });

      expect(standing.position, 1);
      expect(standing.teamId, '11111111-1111-1111-1111-111111111111');
      expect(standing.teamName, 'Flames');
      expect(standing.played, 6);
      expect(standing.wins, 5);
      expect(standing.draws, 1);
      expect(standing.losses, 0);
      expect(standing.goalsFor, 24);
      expect(standing.goalsAgainst, 8);
      expect(standing.goalDifference, 16);
      expect(standing.points, 16);
    });

    test('não quebra quando teamName vem nulo', () {
      final standing = Standing.fromJson({
        'position': 2,
        'teamId': '22222222-2222-2222-2222-222222222222',
        'teamName': null,
        'played': 6,
        'wins': 4,
        'draws': 1,
        'losses': 1,
        'goalsFor': 18,
        'goalsAgainst': 10,
        'goalDifference': 8,
        'points': 13,
      });

      expect(standing.teamName, isNull);
      expect(standing.position, 2);
    });

    test('toJson é coerente com o shape público', () {
      final standing = Standing(
        position: 1,
        teamId: '11111111-1111-1111-1111-111111111111',
        teamName: 'Flames',
        played: 6,
        wins: 5,
        draws: 1,
        losses: 0,
        goalsFor: 24,
        goalsAgainst: 8,
        goalDifference: 16,
        points: 16,
      );

      final json = standing.toJson();

      expect(json['position'], 1);
      expect(json['teamId'], '11111111-1111-1111-1111-111111111111');
      expect(json['teamName'], 'Flames');
      expect(json['played'], 6);
      expect(json['wins'], 5);
      expect(json['draws'], 1);
      expect(json['losses'], 0);
      expect(json['goalsFor'], 24);
      expect(json['goalsAgainst'], 8);
      expect(json['goalDifference'], 16);
      expect(json['points'], 16);
    });
  });
}
