import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('CheckIn.fromJson/toJson', () {
    test('converte JSON completo de forma ida e volta', () {
      final json = {
        'gameId': 'game-1',
        'teamId': 'team-1',
        'teamName': 'Tritões',
        'athleteId': 'athlete-1',
        'athleteName': 'João Silva',
        'number': 7,
        'status': 'PRESENT',
        'validatedBy': 'user-1',
        'validatedAt': '2026-08-10T10:00:00.000',
      };

      final checkIn = CheckIn.fromJson(json);

      expect(checkIn.gameId, 'game-1');
      expect(checkIn.teamId, 'team-1');
      expect(checkIn.teamName, 'Tritões');
      expect(checkIn.athleteId, 'athlete-1');
      expect(checkIn.athleteName, 'João Silva');
      expect(checkIn.number, 7);
      expect(checkIn.status, CheckInStatus.present);
      expect(checkIn.validatedBy, 'user-1');
      expect(checkIn.toJson()['status'], 'PRESENT');
    });

    test('aceita campos opcionais ausentes', () {
      final checkIn = CheckIn.fromJson({
        'gameId': 'game-1',
        'teamId': 'team-1',
        'athleteId': 'athlete-1',
        'athleteName': 'João Silva',
      });

      expect(checkIn.status, isNull);
      expect(checkIn.teamName, isNull);
      expect(checkIn.validatedBy, isNull);
      expect(checkIn.validatedAt, isNull);
    });

    test('rejeita status desconhecido', () {
      expect(
        () => CheckIn.fromJson({
          'gameId': 'game-1',
          'teamId': 'team-1',
          'athleteId': 'athlete-1',
          'athleteName': 'João Silva',
          'status': 'UNKNOWN',
        }),
        throwsFormatException,
      );
    });
  });
}
