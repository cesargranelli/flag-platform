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

  List<User> users = [];
  int createUserCalls = 0;

  @override
  Future<List<User>> listUsers() async => users;

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    createUserCalls++;
    final user = User(
      id: 'user-novo',
      name: name,
      email: email,
      role: role,
    );
    users = [...users, user];
    return user;
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

/// [TeamApi] com dados controlados para testes.
class FakeTeamApi extends TeamApi {
  FakeTeamApi() : super(ApiClient(session: SessionManager()));

  List<Team> teams = [];
  int createCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Team>> listByCategory(String categoryId) async =>
      teams.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Team> getById(String id) async =>
      teams.firstWhere((t) => t.id == id);

  @override
  Future<Team> create({
    required String categoryId,
    required String name,
    String? shortName,
    String? logoUrl,
  }) async {
    createCalls++;
    lastBody = {
      'categoryId': categoryId,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
    };
    final team = Team(id: 'team-novo', categoryId: categoryId, name: name);
    teams = [...teams, team];
    return team;
  }

  @override
  Future<Team> update(
    String id, {
    required String categoryId,
    required String name,
    String? shortName,
    String? logoUrl,
  }) async {
    lastBody = {
      'categoryId': categoryId,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
    };
    return Team(id: id, categoryId: categoryId, name: name);
  }
}

/// [RoundApi] com dados controlados para testes.
class FakeRoundApi extends RoundApi {
  FakeRoundApi() : super(ApiClient(session: SessionManager()));

  List<Round> rounds = [];
  int createCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Round>> listByCategory(String categoryId) async =>
      rounds.where((r) => r.categoryId == categoryId).toList();

  @override
  Future<Round> create({
    required String categoryId,
    required int number,
    required String name,
    required RoundType type,
  }) async {
    createCalls++;
    lastBody = {
      'categoryId': categoryId,
      'number': number,
      'name': name,
      'type': type.toJson(),
    };
    final round = Round(
        id: 'round-nova', categoryId: categoryId, number: number, name: name, type: type);
    rounds = [...rounds, round];
    return round;
  }

  @override
  Future<Round> update(
    String id, {
    required String categoryId,
    required int number,
    required String name,
    required RoundType type,
  }) async {
    lastBody = {
      'categoryId': categoryId,
      'number': number,
      'name': name,
      'type': type.toJson(),
    };
    return Round(id: id, categoryId: categoryId, number: number, name: name, type: type);
  }
}

/// [GameApi] com dados controlados para testes.
class FakeGameApi extends GameApi {
  FakeGameApi() : super(ApiClient(session: SessionManager()));

  List<Game> games = [];
  int createCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Game>> listByRound(String roundId) async =>
      games.where((g) => g.roundId == roundId).toList();

  @override
  Future<Game> getById(String id) async => games.firstWhere((g) => g.id == id);

  @override
  Future<Game> create({
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) async {
    createCalls++;
    lastBody = {
      'roundId': roundId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'venueId': venueId,
      'scheduledAt': scheduledAt,
    };
    final game = Game(
      id: 'game-novo',
      roundId: roundId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      venueId: venueId,
      scheduledAt: scheduledAt,
      status: GameStatus.scheduled,
    );
    games = [...games, game];
    return game;
  }
}

/// [AthleteApi] com dados controlados para testes.
class FakeAthleteApi extends AthleteApi {
  FakeAthleteApi() : super(ApiClient(session: SessionManager()));

  List<Athlete> athletes = [];
  int createCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<List<Athlete>> list() async => athletes;

  @override
  Future<Athlete> getById(String id) async =>
      athletes.firstWhere((a) => a.id == id);

  @override
  Future<Athlete> create(Map<String, dynamic> body) async {
    createCalls++;
    lastBody = body;
    final athlete = Athlete.fromJson({...body, 'id': 'atleta-novo'});
    athletes = [...athletes, athlete];
    return athlete;
  }

  @override
  Future<Athlete> update(String id, Map<String, dynamic> body) async {
    lastBody = body;
    return Athlete.fromJson({...body, 'id': id});
  }
}

/// [RosterApi] com dados controlados para testes.
class FakeRosterApi extends RosterApi {
  FakeRosterApi() : super(ApiClient(session: SessionManager()));

  List<RosterEntry> entries = [];
  int addCalls = 0;
  int removeCalls = 0;

  @override
  Future<List<RosterEntry>> listByTeam(String teamId) async =>
      entries.where((e) => e.teamId == teamId).toList();

  @override
  Future<void> add({required String teamId, required String athleteId}) async {
    addCalls++;
    entries = [
      ...entries,
      RosterEntry(
        id: 'entry-novo',
        teamId: teamId,
        athleteId: athleteId,
        athleteName: 'Atleta $athleteId',
        status: 'ACTIVE',
      ),
    ];
  }

  @override
  Future<void> remove({required String teamId, required String athleteId}) async {
    removeCalls++;
    entries = entries
        .where((e) => !(e.teamId == teamId && e.athleteId == athleteId))
        .toList();
  }
}

/// Atleta de exemplo para testes.
Athlete testAthlete({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'João Silva',
  AthletePosition position = AthletePosition.qb,
  int? number = 7,
}) {
  return Athlete(id: id, name: name, position: position, number: number);
}

/// Jogo de exemplo para testes.
Game testGame({
  String id = '11111111-1111-1111-1111-111111111111',
  String roundId = '11111111-1111-1111-1111-111111111111',
  String homeTeamId = '22222222-2222-2222-2222-222222222222',
  String awayTeamId = '33333333-3333-3333-3333-333333333333',
}) {
  return Game(
    id: id,
    roundId: roundId,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    scheduledAt: DateTime(2026, 2, 1, 19, 0),
    status: GameStatus.scheduled,
  );
}

/// Rodada de exemplo para testes.
Round testRound({
  String id = '11111111-1111-1111-1111-111111111111',
  String categoryId = '11111111-1111-1111-1111-111111111111',
  int number = 1,
  String name = 'Primeira Rodada',
  RoundType type = RoundType.regular,
}) {
  return Round(id: id, categoryId: categoryId, number: number, name: name, type: type);
}

/// Time de exemplo para testes.
Team testTeam({
  String id = '11111111-1111-1111-1111-111111111111',
  String categoryId = '11111111-1111-1111-1111-111111111111',
  String name = 'Tritões',
}) {
  return Team(id: id, categoryId: categoryId, name: name);
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
