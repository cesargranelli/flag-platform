import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de check-in e validação de atletas.
class CheckInApi {
  final ApiClient _client;

  CheckInApi(this._client);

  Future<List<CheckIn>> getList(String gameId) => _client.getList(
        '/api/v1/games/$gameId/checkin',
        CheckIn.fromJson,
      );

  Future<CheckIn> checkin({
    required String gameId,
    required String athleteId,
    required CheckInStatus status,
  }) =>
      _client.post(
        '/api/v1/games/$gameId/checkin/$athleteId',
        {'status': status.toJson()},
        CheckIn.fromJson,
      );

  Future<CheckIn> validate({
    required String gameId,
    required String athleteId,
  }) =>
      _client.post(
        '/api/v1/games/$gameId/checkin/$athleteId/validate',
        {},
        CheckIn.fromJson,
      );

  /// Define (ou limpa, com number nulo) a numeração de partida do atleta,
  /// sem alterar o número oficial cadastrado.
  Future<CheckIn> setMatchNumber({
    required String gameId,
    required String athleteId,
    int? number,
  }) =>
      _client.put(
        '/api/v1/games/$gameId/checkin/$athleteId/match-number',
        {'number': number},
        CheckIn.fromJson,
      );
}
