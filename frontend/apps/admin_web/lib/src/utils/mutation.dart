import 'package:flag_api/flag_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Progresso de mutações por escopo de tela (M11 passo 2, #482).
///
/// A chave do family isola telas (ex.: `'approvals'`, `'roster-add'`).
/// `start`/`finish` atualizam o [Set] de ids em andamento; as telas
/// assistem via `ref.watch(mutationProgressProvider(scope))`.
class MutationProgressNotifier extends FamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String arg) => <String>{};

  void start(String id) => state = {...state, id};

  void finish(String id) {
    final next = {...state};
    next.remove(id);
    state = next;
  }
}

final mutationProgressProvider =
    NotifierProvider.family<MutationProgressNotifier, Set<String>, String>(
  MutationProgressNotifier.new,
);

/// Executa uma mutação com o ritual padrão do Admin Web (M11).
///
/// Encapsula o padrão repetido em várias telas:
/// - marca o item como "em progresso" no [mutationProgressProvider] do
///   [scope] (as telas assistem o set para spinner/disable);
/// - executa a ação e mostra `SnackBar` de sucesso ([successMessage]) e
///   dispara [onSuccess] (invalidação de providers / navegação);
/// - erros: `RepositoryException` mostra a mensagem do backend; erro genérico
///   mostra [errorMessage];
/// - `finally` remove o [progressId].
///
/// Retorna `true` em caso de sucesso (útil para o chamador decidir
/// navegação), `false` em erro.
Future<bool> runMutation(
  BuildContext context, {
  required WidgetRef ref,
  required String scope,
  required Future<void> Function() action,
  required String successMessage,
  required String errorMessage,
  required String progressId,
  VoidCallback? onSuccess,
}) async {
  // Capturado antes do await: o contexto pode sair de cena ao trocar de tela.
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(mutationProgressProvider(scope).notifier);

  notifier.start(progressId);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    onSuccess?.call();
    return true;
  } on RepositoryException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    return false;
  } finally {
    notifier.finish(progressId);
  }
}
