import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';

/// [SessionManager] em memória para testes (evita FlutterSecureStorage).
class InMemorySessionManager extends SessionManager {
  final Map<String, String> data = {};

  /// Pré-popula uma sessão autenticada (para testes de proteção de rota).
  void seedToken(String token, {List<String> roles = const [], String? userName}) {
    data['auth_token'] = token;
    data['auth_roles'] = roles.join(',');
    if (userName != null) {
      data['auth_user_name'] = userName;
    }
  }

  @override
  Future<void> saveSession({
    required String token,
    required List<String> roles,
    String? userName,
  }) async {
    data['auth_token'] = token;
    data['auth_roles'] = roles.join(',');
    if (userName != null) {
      data['auth_user_name'] = userName;
    }
  }

  @override
  Future<String?> getToken() async => data['auth_token'];

  @override
  Future<List<String>> getRoles() async =>
      (data['auth_roles'] ?? '').split(',').where((r) => r.isNotEmpty).toList();

  @override
  Future<String?> getUserName() async => data['auth_user_name'];

  @override
  Future<bool> isAuthenticated() async => data['auth_token'] != null;

  @override
  Future<void> clear() async => data.clear();
}

/// [AuthApi] com respostas controladas para testes.
class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(ApiClient(session: SessionManager()));

  Object? failure;
  LoginResponse? loginResponse;
  User? meUser;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    return loginResponse!;
  }

  @override
  Future<User> me() async {
    final user = meUser;
    if (user != null) {
      return user;
    }
    throw const RepositoryException('Sem sessão');
  }
}

/// [OrganizationApi] com dados controlados para testes.
class FakeOrganizationApi extends OrganizationApi {
  FakeOrganizationApi() : super(ApiClient(session: SessionManager()));

  List<Organization> organizations = [];
  int createCalls = 0;
  int updateCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Organization>> list() async => organizations;

  @override
  Future<Organization> getById(String id) async =>
      organizations.firstWhere((o) => o.id == id);

  @override
  Future<Organization> create(Map<String, dynamic> body) async {
    createCalls++;
    lastBody = body;
    final org = Organization.fromJson({...body, 'id': 'org-nova'});
    organizations = [...organizations, org];
    return org;
  }

  @override
  Future<Organization> update(String id, Map<String, dynamic> body) async {
    updateCalls++;
    lastBody = body;
    return Organization.fromJson({...body, 'id': id});
  }
}

/// Usuário de exemplo para testes.
User testUser({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'Ana Lima',
  String email = 'ana@exemplo.com',
  String role = 'ORGANIZER',
}) {
  return User(id: id, name: name, email: email, role: role);
}

/// Resposta de login de exemplo para testes.
LoginResponse testLoginResponse({User? user}) {
  final u = user ?? testUser();
  return LoginResponse(
    token: 'jwt-token-de-teste',
    tokenType: 'Bearer',
    expiresInSeconds: 3600,
    user: u,
  );
}

/// [CompetitionApi] com dados controlados para testes.
class FakeCompetitionApi extends CompetitionApi {
  FakeCompetitionApi() : super(ApiClient(session: SessionManager()));

  List<Competition> competitions = [];
  int createCalls = 0;
  int updateCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Competition>> listAll() async => competitions;

  @override
  Future<Competition> getById(String id) async =>
      competitions.firstWhere((c) => c.id == id);

  @override
  Future<Competition> create({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
  }) async {
    createCalls++;
    lastBody = {
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'status': status?.toJson(),
    };
    final competition = Competition(
      id: 'comp-nova',
      name: name,
      status: status ?? CompetitionStatus.draft,
      organizationId: organizationId,
      description: description,
    );
    competitions = [...competitions, competition];
    return competition;
  }

  @override
  Future<Competition> update(
    String id, {
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
  }) async {
    updateCalls++;
    lastBody = {
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'status': status?.toJson(),
    };
    return Competition(
      id: id,
      name: name,
      status: status ?? CompetitionStatus.draft,
      organizationId: organizationId,
      description: description,
    );
  }
}

/// [CategoryApi] com dados controlados para testes.
class FakeCategoryApi extends CategoryApi {
  FakeCategoryApi() : super(ApiClient(session: SessionManager()));

  List<Category> categories = [];
  int createCalls = 0;
  int deleteCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Category>> listByCompetition(String competitionId) async =>
      categories.where((c) => c.competitionId == competitionId).toList();

  @override
  Future<Category> create({
    required String competitionId,
    required String name,
  }) async {
    createCalls++;
    lastBody = {'competitionId': competitionId, 'name': name};
    final category = Category(id: 'cat-nova', competitionId: competitionId, name: name);
    categories = [...categories, category];
    return category;
  }

  @override
  Future<Category> update(
    String id, {
    required String competitionId,
    required String name,
  }) async {
    lastBody = {'competitionId': competitionId, 'name': name};
    return Category(id: id, competitionId: competitionId, name: name);
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    categories = categories.where((c) => c.id != id).toList();
  }
}

/// [VenueApi] com dados controlados para testes.
class FakeVenueApi extends VenueApi {
  FakeVenueApi() : super(ApiClient(session: SessionManager()));

  List<Venue> venues = [];
  int createCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Venue>> list() async => venues;

  @override
  Future<Venue> getById(String id) async =>
      venues.firstWhere((v) => v.id == id);

  @override
  Future<Venue> create({
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) async {
    createCalls++;
    lastBody = {
      'organizationId': organizationId,
      'name': name,
      'address': address,
      'mapsUrl': mapsUrl,
    };
    final venue = Venue(
      id: 'venue-nova',
      organizationId: organizationId,
      name: name,
      address: address,
    );
    venues = [...venues, venue];
    return venue;
  }

  @override
  Future<Venue> update(
    String id, {
    required String organizationId,
    required String name,
    String? address,
    String? mapsUrl,
  }) async {
    lastBody = {
      'organizationId': organizationId,
      'name': name,
      'address': address,
      'mapsUrl': mapsUrl,
    };
    return Venue(id: id, organizationId: organizationId, name: name, address: address);
  }
}

/// Campo de exemplo para testes.
Venue testVenue({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'Arena Paulista',
  String organizationId = '11111111-1111-1111-1111-111111111111',
}) {
  return Venue(id: id, organizationId: organizationId, name: name);
}

/// Categoria de exemplo para testes.
Category testCategory({
  String id = '11111111-1111-1111-1111-111111111111',
  String competitionId = '11111111-1111-1111-1111-111111111111',
  String name = 'Masculino 5x5',
}) {
  return Category(id: id, competitionId: competitionId, name: name);
}

/// Campeonato de exemplo para testes.
Competition testCompetition({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'Taça SP',
  String organizationId = '11111111-1111-1111-1111-111111111111',
  CompetitionStatus status = CompetitionStatus.draft,
}) {
  return Competition(
    id: id,
    name: name,
    status: status,
    organizationId: organizationId,
  );
}

/// Organização de exemplo para testes.
Organization testOrganization({
  String id = '11111111-1111-1111-1111-111111111111',
  String tradeName = 'Flag Brasil',
  String legalName = 'Associação Flag Brasil',
}) {
  return Organization(
    id: id,
    tradeName: tradeName,
    legalName: legalName,
    country: 'BR',
    timezone: 'America/Sao_Paulo',
    locale: 'pt-BR',
    organizationType: OrganizationType.association,
  );
}
