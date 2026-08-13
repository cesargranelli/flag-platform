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
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) => _client.post(
    '/api/v1/games',
    _body(
      roundId: roundId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      venueId: venueId,
      scheduledAt: scheduledAt,
    ),
    Game.fromJson,
  );

  Future<Game> update(
    String id, {
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) => _client.put(
    '/api/v1/games/$id',
    _body(
      roundId: roundId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      venueId: venueId,
      scheduledAt: scheduledAt,
    ),
    Game.fromJson,
  );

  Future<Game> updateStatus(String id, GameStatus status) =>
      _client.patch(
        '/api/v1/games/$id/status',
        {'status': status.toJson()},
        Game.fromJson,
      );

  Map<String, dynamic> _body({
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) =>
      {
        'roundId': roundId,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        if (venueId != null) 'venueId': venueId,
        'scheduledAt': _formatDateTime(scheduledAt),
      };
}

String _formatDateTime(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}T'
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}:00';
