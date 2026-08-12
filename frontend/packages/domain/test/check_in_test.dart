import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('CheckIn.fromJson/toJson', () {
    test('converte JSON completo de forma ida e volta', () {
      final json = {
        'gameId': 1,
        'teamId': 2,
        'athleteId': 3,
        'status': 'VALIDATED',
        'validatedBy': 'mesa',
        'validatedAt': '2026-08-10T10:00:00.000',
      };

      final checkIn = CheckIn.fromJson(json);

      expect(checkIn.gameId, 1);
      expect(checkIn.teamId, 2);
      expect(checkIn.athleteId, 3);
      expect(checkIn.status, CheckInStatus.validated);
      expect(checkIn.validatedBy, 'mesa');
      expect(checkIn.toJson()['status'], 'VALIDATED');
    });

    test('aceita campos opcionais ausentes', () {
      final checkIn = CheckIn.fromJson({
        'gameId': 1,
        'teamId': 2,
        'athleteId': 3,
        'status': 'PENDING',
      });

      expect(checkIn.status, CheckInStatus.pending);
      expect(checkIn.validatedBy, isNull);
      expect(checkIn.validatedAt, isNull);
    });

    test('rejeita status desconhecido', () {
      expect(
        () => CheckIn.fromJson({
          'gameId': 1,
          'teamId': 2,
          'athleteId': 3,
          'status': 'UNKNOWN',
        }),
        throwsFormatException,
      );
    });
  });
}
