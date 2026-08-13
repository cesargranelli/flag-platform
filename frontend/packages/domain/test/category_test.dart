import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Category.fromJson/toJson', () {
    test('converte o shape público (id UUID, competitionId, name)', () {
      final category = Category.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'competitionId': '22222222-2222-2222-2222-222222222222',
        'name': 'Masculino',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-07-30T10:00:00.000Z',
      });

      expect(category.id, '11111111-1111-1111-1111-111111111111');
      expect(category.competitionId, '22222222-2222-2222-2222-222222222222');
      expect(category.name, 'Masculino');
      expect(category.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(category.updatedAt, DateTime.parse('2026-07-30T10:00:00.000Z'));
    });

    test('não quebra quando as datas de auditoria vêm nulas', () {
      final category = Category.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'competitionId': '22222222-2222-2222-2222-222222222222',
        'name': 'Feminino',
      });

      expect(category.id, '11111111-1111-1111-1111-111111111111');
      expect(category.name, 'Feminino');
      expect(category.createdAt, isNull);
      expect(category.updatedAt, isNull);
    });

    test('toJson é coerente com o shape público', () {
      final category = Category(
        id: '11111111-1111-1111-1111-111111111111',
        competitionId: '22222222-2222-2222-2222-222222222222',
        name: 'Masculino',
      );

      final json = category.toJson();

      expect(json['id'], '11111111-1111-1111-1111-111111111111');
      expect(json['competitionId'], '22222222-2222-2222-2222-222222222222');
      expect(json['name'], 'Masculino');
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
    });
  });
}
