import 'package:flag_domain/flag_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Competition.fromJson/toJson', () {
    test('converte o shape de resumo (id, name, organizationName, status)', () {
      final competition = Competition.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Liga Nacional',
        'organizationName': 'Flag Brasil',
        'status': 'PUBLISHED',
      });

      expect(competition.id, '11111111-1111-1111-1111-111111111111');
      expect(competition.name, 'Liga Nacional');
      expect(competition.organizationName, 'Flag Brasil');
      expect(competition.status, CompetitionStatus.published);
      expect(competition.organizationId, isNull);
      expect(competition.description, isNull);
      expect(competition.startDate, isNull);
      expect(competition.endDate, isNull);
    });

    test('converte o shape completo com datas ISO-8601', () {
      final competition = Competition.fromJson({
        'id': '22222222-2222-2222-2222-222222222222',
        'organizationId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'name': 'Copa Encerramento',
        'description': 'Campeonato de encerramento da temporada',
        'startDate': '2026-08-01T10:00:00.000Z',
        'endDate': '2026-12-20T23:59:59.000Z',
        'status': 'FINISHED',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-07-30T10:00:00.000Z',
      });

      expect(competition.id, '22222222-2222-2222-2222-222222222222');
      expect(competition.organizationId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(competition.name, 'Copa Encerramento');
      expect(competition.description, 'Campeonato de encerramento da temporada');
      expect(competition.status, CompetitionStatus.finished);
      expect(competition.organizationName, isNull);
      expect(
        competition.startDate,
        DateTime.parse('2026-08-01T10:00:00.000Z'),
      );
      expect(competition.endDate, DateTime.parse('2026-12-20T23:59:59.000Z'));
    });

    test('não quebra quando organizationName e datas vêm nulos', () {
      final competition = Competition.fromJson({
        'id': '33333333-3333-3333-3333-333333333333',
        'name': 'Torneio Regional',
        'organizationName': null,
        'startDate': null,
        'endDate': null,
        'status': 'DRAFT',
      });

      expect(competition.organizationName, isNull);
      expect(competition.startDate, isNull);
      expect(competition.endDate, isNull);
    });

    test('toJson é coerente com os campos preenchidos', () {
      final competition = Competition(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Liga Nacional',
        status: CompetitionStatus.published,
        organizationId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        organizationName: 'Flag Brasil',
        description: 'Principal liga do país',
        startDate: DateTime.utc(2026, 8, 1, 10),
        endDate: DateTime.utc(2026, 12, 20),
      );

      final json = competition.toJson();

      expect(json['id'], '11111111-1111-1111-1111-111111111111');
      expect(json['name'], 'Liga Nacional');
      expect(json['status'], 'PUBLISHED');
      expect(json['organizationId'], 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(json['organizationName'], 'Flag Brasil');
      expect(json['description'], 'Principal liga do país');
      expect(json['startDate'], '2026-08-01T10:00:00.000Z');
      expect(json['endDate'], '2026-12-20T00:00:00.000Z');
    });

    test('toJson omite campos opcionais nulos', () {
      final competition = Competition(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Liga Nacional',
        status: CompetitionStatus.draft,
      );

      final json = competition.toJson();

      expect(json.containsKey('organizationId'), isFalse);
      expect(json.containsKey('organizationName'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('startDate'), isFalse);
      expect(json.containsKey('endDate'), isFalse);
    });

    test('rejeita status desconhecido', () {
      expect(
        () => Competition.fromJson({
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'X',
          'status': 'UNKNOWN',
        }),
        throwsFormatException,
      );
    });
  });
}
