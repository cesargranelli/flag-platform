import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de categorias.
class CategoryApi {
  final ApiClient _client;

  CategoryApi(this._client);

  /// Lista as categorias de um campeonato (endpoint público).
  Future<List<Category>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/categories',
        Category.fromJson,
      );
}
