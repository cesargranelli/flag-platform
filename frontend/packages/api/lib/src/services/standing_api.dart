import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de classificação.
class StandingApi {
  final ApiClient _client;

  StandingApi(this._client);

  /// Lista a tabela de classificação de um campeonato (endpoint público,
  /// ordenada por pontos, saldo e gols pró).
  Future<List<Standing>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/standings',
        Standing.fromJson,
      );
}
