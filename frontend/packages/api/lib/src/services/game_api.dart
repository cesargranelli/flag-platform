import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de jogos.
class GameApi {
  final ApiClient _client;

  GameApi(this._client);

  Future<List<Game>> listByRound(int roundId) =>
      _client.getList('/api/v1/rounds/$roundId/games', Game.fromJson);

  Future<Game> getById(int id) =>
      _client.getOne('/api/v1/games/$id', Game.fromJson);

  Future<Game> create({
    required int roundId,
    required int homeTeamId,
    required int awayTeamId,
    required int? venueId,
    required DateTime scheduledAt,
  }) =>
      _client.post(
        '/api/v1/games',
        {
          'roundId': roundId,
          'homeTeamId': homeTeamId,
          'awayTeamId': awayTeamId,
          'venueId': venueId,
          'scheduledAt': scheduledAt.toIso8601String(),
        },
        Game.fromJson,
      );
}
