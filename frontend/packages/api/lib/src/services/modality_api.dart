import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de modalidades (catálogo).
class ModalityApi {
  final ApiClient _client;

  ModalityApi(this._client);

  /// Lista as modalidades ativas (endpoint público).
  Future<List<Modality>> list() =>
      _client.getList('/api/v1/modalities', Modality.fromJson);
}
