import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de jogos.
class GameApi {
  final ApiClient _client;

  GameApi(this._client);

  /// Lista os jogos de uma competição (endpoint público, ordenados por data).
  Future<List<Game>> listByCompetition(String competitionId) => _client.getList(
    '/api/v1/competitions/$competitionId/games',
    Game.fromJson,
  );

  Future<List<Game>> listByRound(String roundId) =>
      _client.getList('/api/v1/rounds/$roundId/games', Game.fromJson);

  Future<Game> getById(String id) =>
      _client.getOne('/api/v1/games/$id', Game.fromJson);

  Future<Game> create({
    required int roundId,
    required int homeTeamId,
    required int awayTeamId,
    required int? venueId,
    required DateTime scheduledAt,
  }) => _client.post('/api/v1/games', {
    'roundId': roundId,
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'venueId': venueId,
    'scheduledAt': scheduledAt.toIso8601String(),
  }, Game.fromJson);
}
