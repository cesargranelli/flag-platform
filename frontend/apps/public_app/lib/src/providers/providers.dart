import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gerenciador de sessão do app público.
///
/// O Public App não tem login: o token fica nulo e as chamadas são feitas
/// sem cabeçalho de autenticação. Sobrescreva em testes se necessário.
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Cliente HTTP da API REST (injeção de dependência padrão da aplicação).
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(sessionManagerProvider)),
);

/// Serviço de campeonatos.
final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
);

/// Lista de campeonatos exibida na tela inicial.
final competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(competitionApiProvider).listAll(),
);
