import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';

/// [SessionManager] em memória para testes (evita FlutterSecureStorage).
class InMemorySessionManager extends SessionManager {
  final Map<String, String> data = {};

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
  Future<void> saveKeepConnected(bool value) async =>
      data['auth_keep_connected'] = value.toString();

  @override
  Future<bool> isKeepConnected() async => data['auth_keep_connected'] == 'true';

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

/// Usuário de exemplo (mesa) para testes.
User testUser({
  String id = '11111111-1111-1111-1111-111111111111',
  String name = 'Mesa Central',
  String email = 'mesa@exemplo.com',
  String role = 'MESA',
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

class FakeCompetitionApi extends CompetitionApi {
  FakeCompetitionApi() : super(ApiClient(session: SessionManager()));
  List<Competition> competitions = [];
  @override
  Future<List<Competition>> listAll() async => competitions;
}

class FakeCategoryApi extends CategoryApi {
  FakeCategoryApi() : super(ApiClient(session: SessionManager()));
  List<Category> categories = [];
  @override
  Future<List<Category>> listByCompetition(String competitionId) async =>
      categories.where((c) => c.competitionId == competitionId).toList();
}

class FakeRoundApi extends RoundApi {
  FakeRoundApi() : super(ApiClient(session: SessionManager()));
  List<Round> rounds = [];
  @override
  Future<List<Round>> listByCategory(String categoryId) async =>
      rounds.where((r) => r.categoryId == categoryId).toList();
}

class FakeGameApi extends GameApi {
  FakeGameApi() : super(ApiClient(session: SessionManager()));
  List<Game> games = [];
  GameStatus? lastStatus;
  List<ScoreEvent> scoreEvents = [];
  @override
  Future<List<Game>> listByRound(String roundId) async =>
      games.where((g) => g.roundId == roundId).toList();
  @override
  Future<List<ScoreEvent>> listScoreEvents(String gameId) async =>
      scoreEvents;
  @override
  Future<Game> updateStatus(String id, GameStatus status) async {
    lastStatus = status;
    final index = games.indexWhere((g) => g.id == id);
    final updated = Game(
      id: id,
      roundId: games[index].roundId,
      homeTeamId: games[index].homeTeamId,
      awayTeamId: games[index].awayTeamId,
      scheduledAt: games[index].scheduledAt,
      status: status,
    );
    games[index] = updated;
    return updated;
  }
}

Competition testCompetition({String id = 'c1', String name = 'Taça SP'}) =>
    Competition(id: id, name: name, status: CompetitionStatus.published);

Category testCategory({
  String id = 'cat1',
  String competitionId = 'c1',
  String modalityId = 'm1',
  Gender gender = Gender.male,
  AgeGroup ageGroup = AgeGroup.adult,
  String name = 'Masculino',
}) =>
    Category(
      id: id,
      competitionId: competitionId,
      modalityId: modalityId,
      gender: gender,
      ageGroup: ageGroup,
      name: name,
    );

Round testRound({String id = 'r1', String categoryId = 'cat1', int number = 1, String name = 'Primeira'}) =>
    Round(id: id, categoryId: categoryId, number: number, name: name, type: RoundType.regular);

Game testGame({
  String id = 'g1',
  String roundId = 'r1',
  GameStatus status = GameStatus.scheduled,
}) =>
    Game(
      id: id,
      roundId: roundId,
      homeTeamId: 't1',
      awayTeamId: 't2',
      scheduledAt: DateTime(2026, 2, 1, 19),
      status: status,
    );

class FakeCheckInApi extends CheckInApi {
  FakeCheckInApi() : super(ApiClient(session: SessionManager()));

  List<CheckIn> entries = [];
  CheckInStatus? lastStatus;
  CheckInStatus? validateResult;
  int? lastMatchNumber;

  @override
  Future<List<CheckIn>> getList(String gameId) async => entries;

  @override
  Future<CheckIn> checkin({
    required String gameId,
    required String athleteId,
    required CheckInStatus status,
  }) async {
    lastStatus = status;
    return CheckIn(
      gameId: gameId,
      teamId: 't1',
      athleteId: athleteId,
      athleteName: 'João Silva',
      status: status,
    );
  }

  @override
  Future<CheckIn> validate({
    required String gameId,
    required String athleteId,
  }) async {
    return CheckIn(
      gameId: gameId,
      teamId: 't1',
      athleteId: athleteId,
      athleteName: 'João Silva',
      status: validateResult ?? CheckInStatus.present,
    );
  }

  @override
  Future<CheckIn> setMatchNumber({
    required String gameId,
    required String athleteId,
    int? number,
  }) async {
    lastMatchNumber = number;
    return CheckIn(
      gameId: gameId,
      teamId: 't1',
      athleteId: athleteId,
      athleteName: 'João Silva',
      number: number ?? 7,
      athleteNumber: 7,
      matchNumber: number,
      status: CheckInStatus.present,
    );
  }
}

CheckIn testCheckIn({
  String gameId = 'g1',
  String athleteId = 'a1',
  String athleteName = 'João Silva',
  String teamName = 'Tritões',
  CheckInStatus? status,
  int? number = 7,
  int? athleteNumber,
  int? matchNumber,
}) =>
    CheckIn(
      gameId: gameId,
      teamId: 't1',
      teamName: teamName,
      athleteId: athleteId,
      athleteName: athleteName,
      number: number,
      athleteNumber: athleteNumber,
      matchNumber: matchNumber,
      status: status,
    );
