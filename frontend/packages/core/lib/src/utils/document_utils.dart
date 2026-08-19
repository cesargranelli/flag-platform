/// Utilitários para documentos brasileiros (CNPJ/CPF): máscara e validação
/// pelos dígitos verificadores.
class DocumentUtils {
  DocumentUtils._();

  static String maskCpf(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) {
      return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    }
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9, 11)}';
  }

  static String maskCnpj(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)}.${d.substring(2)}';
    if (d.length <= 8) return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5)}';
    if (d.length <= 12) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8)}';
    }
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
        '${d.substring(8, 12)}-${d.substring(12, 14)}';
  }

  /// Aplica a máscara conforme o tamanho dos dígitos (11 = CPF, 14 = CNPJ).
  static String mask(String digits, {bool isCpf = false, bool isCnpj = false}) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (isCpf || d.length <= 11) return maskCpf(d);
    if (isCnpj || d.length > 11) return maskCnpj(d);
    return d;
  }

  static bool isValidCpf(String value) {
    final cpf = value.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    int calc(int start) {
      var sum = 0;
      for (var i = 0; i < start - 1; i++) {
        sum += int.parse(cpf[i]) * (start - i);
      }
      final rest = (sum * 10) % 11;
      return rest == 10 ? 0 : rest;
    }

    return calc(10) == int.parse(cpf[9]) && calc(11) == int.parse(cpf[10]);
  }

  static bool isValidCnpj(String value) {
    final cnpj = value.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;
    const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int calc(List<int> weights, int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += int.parse(cnpj[i]) * weights[i];
      }
      final rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    }

    return calc(w1, 12) == int.parse(cnpj[12]) &&
        calc(w2, 13) == int.parse(cnpj[13]);
  }

  static bool isValid(String value, {bool isCpf = false, bool isCnpj = false}) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    if (isCpf || d.length <= 11) return isValidCpf(value);
    if (isCnpj || d.length > 11) return isValidCnpj(value);
    return false;
  }
}
