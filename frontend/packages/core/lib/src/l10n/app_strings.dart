/// Textos centralizados da UI (pt-BR default).
///
/// Ponto único para externalizar strings e permitir localização futura
/// (arb/intl). Novas telas devem usar estas chaves em vez de texto hardcoded.
abstract final class AppStrings {
  // Comum
  static const save = 'Salvar';
  static const cancel = 'Cancelar';
  static const back = 'Voltar';
  static const continueNext = 'Continuar';
  static const retry = 'Tentar novamente';
  static const loading = 'Carregando...';

  // Autenticação
  static const loginTitle = 'Flag Admin Web';
  static const loginSubtitle = 'Acesso do organizador';
  static const loginEmail = 'E-mail';
  static const loginPassword = 'Senha';
  static const loginSubmit = 'Entrar';
  static const loginInvalidEmail = 'E-mail inválido';
  static const loginRequiredEmail = 'Informe o e-mail';
  static const loginRequiredPassword = 'Informe a senha';
  static const loginConnectionError = 'Não foi possível conectar ao servidor.';

  // Home / navegação
  static const appBarTitle = 'Admin Web';
  static const welcome = 'Bem-vindo';
  static const hello = 'Olá';
  static const quickActions = 'Ações rápidas';
  static const modules = 'Módulos';
  static const newCompetition = 'Novo campeonato';
  static const newGame = 'Novo jogo';
  static const importAthletes = 'Importar atletas';
  static const newOrganization = 'Nova organização';
  static const logout = 'Sair';
  static const homeHint = 'Selecione uma opção para gerenciar os cadastros.';
  static const organizations = 'Organizações';
  static const competitions = 'Campeonatos';
  static const categories = 'Categorias';
  static const venues = 'Campos';
  static const teams = 'Times';
  static const rounds = 'Rodadas';
  static const games = 'Jogos';
  static const athletes = 'Atletas';
  static const rosters = 'Elencos';
  static const users = 'Usuários';
}
