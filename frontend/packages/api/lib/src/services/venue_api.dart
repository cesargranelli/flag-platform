import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de campos de jogo.
class VenueApi {
  final ApiClient _client;

  VenueApi(this._client);

  Future<List<Venue>> list() =>
      _client.getList('/api/v1/venues', Venue.fromJson);

  Future<Venue> getById(String id) =>
      _client.getOne('/api/v1/venues/$id', Venue.fromJson);

  Future<Venue> create({
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) =>
      _client.post(
        '/api/v1/venues',
        {
          'organizationId': organizationId,
          'name': name,
          'address': ?address,
          'mapsUrl': ?mapsUrl,
        },
        Venue.fromJson,
      );

  Future<Venue> update(
    String id, {
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) =>
      _client.put(
        '/api/v1/venues/$id',
        {
          'organizationId': organizationId,
          'name': name,
          'address': ?address,
          'mapsUrl': ?mapsUrl,
        },
        Venue.fromJson,
      );
}

