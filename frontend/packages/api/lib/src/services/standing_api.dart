import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de classificação.
class StandingApi {
  final ApiClient _client;

  StandingApi(this._client);

  /// Lista a tabela de classificação de uma categoria (endpoint público,
  /// ordenada por pontos, saldo e gols pró).
  Future<List<Standing>> listByCategory(String categoryId) => _client.getList(
    '/api/v1/categories/$categoryId/standings',
    Standing.fromJson,
  );
}
