import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/theme/app_typography.dart';

/// As fontes são embutidas (sem download em tempo de execução): todo peso
/// usado pelo app precisa ter o arquivo com o nome que o `google_fonts` procura.
void main() {
  final names = {
    FontWeight.w400.value: 'Regular',
    FontWeight.w500.value: 'Medium',
    FontWeight.w600.value: 'SemiBold',
    FontWeight.w700.value: 'Bold',
  };

  test('Inter e Poppins: um arquivo por peso embutido', () {
    for (final weight in AppTypography.bundledWeights) {
      for (final family in ['Inter', 'Poppins']) {
        final file = File(
          'assets/google_fonts/$family-${names[weight.value]}.ttf',
        );
        expect(file.existsSync(), isTrue, reason: file.path);
      }
    }
  });

  test('wordmark (Cormorant 600) e licenças OFL presentes', () {
    expect(
      File('assets/google_fonts/CormorantGaramond-SemiBold.ttf').existsSync(),
      isTrue,
    );
    for (final f in ['inter', 'poppins', 'cormorantgaramond']) {
      expect(File('assets/google_fonts/OFL-$f.txt').existsSync(), isTrue);
    }
  });

  test('arquivos cortados (subset latino): bem menores que os originais', () {
    final total = Directory('assets/google_fonts')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))
        .fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThan(600 * 1024));
  });
}
