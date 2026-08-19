import 'package:flag_core/flag_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentUtils.mask', () {
    test('mascara CPF', () {
      expect(DocumentUtils.maskCpf('12345678909'), '123.456.789-09');
    });

    test('mascara CNPJ', () {
      expect(DocumentUtils.maskCnpj('11222333000181'), '11.222.333/0001-81');
    });
  });

  group('DocumentUtils.isValidCpf', () {
    test('aceita CPF valido', () {
      expect(DocumentUtils.isValidCpf('123.456.789-09'), isTrue);
    });

    test('rejeita CPF invalido', () {
      expect(DocumentUtils.isValidCpf('111.111.111-11'), isFalse);
      expect(DocumentUtils.isValidCpf('12345678900'), isFalse);
    });
  });

  group('DocumentUtils.isValidCnpj', () {
    test('aceita CNPJ valido', () {
      expect(DocumentUtils.isValidCnpj('11.222.333/0001-81'), isTrue);
    });

    test('rejeita CNPJ invalido', () {
      expect(DocumentUtils.isValidCnpj('11.111.111/1111-11'), isFalse);
    });
  });
}
