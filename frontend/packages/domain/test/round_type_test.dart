import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoundType', () {
    test('fromJson converte todos os tipos', () {
      expect(RoundType.fromJson('REGULAR'), RoundType.regular);
      expect(RoundType.fromJson('PLAYOFFS'), RoundType.playoffs);
      expect(RoundType.fromJson('WILDCARD'), RoundType.wildcard);
      expect(RoundType.fromJson('SEMIFINAL'), RoundType.semifinal);
      expect(RoundType.fromJson('FINAL'), RoundType.finalRound);
    });

    test('toJson converte todos os tipos', () {
      expect(RoundType.regular.toJson(), 'REGULAR');
      expect(RoundType.playoffs.toJson(), 'PLAYOFFS');
      expect(RoundType.wildcard.toJson(), 'WILDCARD');
      expect(RoundType.semifinal.toJson(), 'SEMIFINAL');
      expect(RoundType.finalRound.toJson(), 'FINAL');
    });

    test('label retorna rótulo pt-BR amigável', () {
      expect(RoundType.regular.label, 'Regular');
      expect(RoundType.playoffs.label, 'Playoffs');
      expect(RoundType.wildcard.label, 'Wildcard');
      expect(RoundType.semifinal.label, 'Semifinal');
      expect(RoundType.finalRound.label, 'Final');
    });

    test('fromJson lança para valor desconhecido', () {
      expect(() => RoundType.fromJson('QUARTAS'),
          throwsA(isA<FormatException>()));
    });
  });
}
