import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Category.fromJson/toJson', () {
    test('converte o shape público (id, competitionId, modalityId, gender, ageGroup, name)', () {
      final category = Category.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'competitionId': '22222222-2222-2222-2222-222222222222',
        'modalityId': '33333333-3333-3333-3333-333333333333',
        'modalityName': 'Flag Football',
        'modalityFormat': '5x5',
        'gender': 'MALE',
        'ageGroup': 'ADULT',
        'name': 'Masculino',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-07-30T10:00:00.000Z',
      });

      expect(category.id, '11111111-1111-1111-1111-111111111111');
      expect(category.competitionId, '22222222-2222-2222-2222-222222222222');
      expect(category.modalityId, '33333333-3333-3333-3333-333333333333');
      expect(category.modalityName, 'Flag Football');
      expect(category.modalityFormat, '5x5');
      expect(category.gender, Gender.male);
      expect(category.ageGroup, AgeGroup.adult);
      expect(category.name, 'Masculino');
      expect(category.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(category.updatedAt, DateTime.parse('2026-07-30T10:00:00.000Z'));
    });

    test('não quebra quando as datas de auditoria vêm nulas', () {
      final category = Category.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'competitionId': '22222222-2222-2222-2222-222222222222',
        'modalityId': '33333333-3333-3333-3333-333333333333',
        'gender': 'FEMALE',
        'ageGroup': 'SUB14',
        'name': 'Feminino',
      });

      expect(category.id, '11111111-1111-1111-1111-111111111111');
      expect(category.name, 'Feminino');
      expect(category.gender, Gender.female);
      expect(category.ageGroup, AgeGroup.sub14);
      expect(category.createdAt, isNull);
      expect(category.updatedAt, isNull);
    });

    test('toJson é coerente com o shape público', () {
      final category = Category(
        id: '11111111-1111-1111-1111-111111111111',
        competitionId: '22222222-2222-2222-2222-222222222222',
        modalityId: '33333333-3333-3333-3333-333333333333',
        gender: Gender.male,
        ageGroup: AgeGroup.adult,
        name: 'Masculino',
      );

      final json = category.toJson();

      expect(json['id'], '11111111-1111-1111-1111-111111111111');
      expect(json['competitionId'], '22222222-2222-2222-2222-222222222222');
      expect(json['modalityId'], '33333333-3333-3333-3333-333333333333');
      expect(json['gender'], 'MALE');
      expect(json['ageGroup'], 'ADULT');
      expect(json['name'], 'Masculino');
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
    });
  });
}
