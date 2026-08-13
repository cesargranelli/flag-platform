import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('usa valores default de API_BASE_URL e ENVIRONMENT', () {
      expect(AppConfig.apiBaseUrl, 'http://localhost:8080');
      expect(AppConfig.environment, 'dev');
    });
  });

  group('AppColors', () {
    test('define a cor primária do tema', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.primary, isNot(const Color(0x00000000)));
    });
  });
}
