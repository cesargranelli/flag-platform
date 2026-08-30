import 'package:flag_api/flag_api.dart';
import 'package:flutter/material.dart';

/// Executa uma mutação com o ritual padrão do Admin Web (M11 #475).
///
/// Encapsula o padrão repetido em várias telas:
/// - marca o item como "em progresso" (adiciona [progressId] em
///   [progressIds] e chama [notify] — o chamador fornece o guard `mounted`);
/// - executa a ação e mostra `SnackBar` de sucesso ([successMessage]) e
///   dispara [onSuccess] (invalidação de providers / navegação);
/// - erros: `RepositoryException` mostra a mensagem do backend; erro genérico
///   mostra [errorMessage];
/// - `finally` remove o [progressId] e notifica de novo.
///
/// Retorna `true` em caso de sucesso (útil para o chamador decidir
/// navegação), `false` em erro.
Future<bool> runMutation(
  BuildContext context, {
  required Future<void> Function() action,
  required String successMessage,
  required String errorMessage,
  required String progressId,
  required Set<String> progressIds,
  required void Function() notify,
  VoidCallback? onSuccess,
}) async {
  // Capturado antes do await: o contexto pode sair de cena ao trocar de tela.
  final messenger = ScaffoldMessenger.of(context);

  progressIds.add(progressId);
  notify();
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
    progressIds.remove(progressId);
    notify();
  }
}