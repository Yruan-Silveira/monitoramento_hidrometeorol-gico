import 'package:flutter/material.dart';

import 'cores.dart';

/// Tema Material 3 do app, claro e escuro, gerado a partir do azul-rio.
abstract final class TemaApp {
  static ThemeData get claro => _criar(Brightness.light);
  static ThemeData get escuro => _criar(Brightness.dark);

  static ThemeData _criar(Brightness brilho) {
    final esquema = ColorScheme.fromSeed(seedColor: CoresApp.primaria, brightness: brilho);
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      appBarTheme: AppBarTheme(
        backgroundColor: brilho == Brightness.light ? CoresApp.primaria : esquema.surface,
        foregroundColor: brilho == Brightness.light ? Colors.white : esquema.onSurface,
      ),
    );
  }
}
