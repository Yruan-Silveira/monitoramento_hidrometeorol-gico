import 'package:flutter/material.dart';

import '../../dominio/modelos/nivel_alerta.dart';

/// Paleta do app.
///
/// As cores dos níveis são as mesmas do mapa oficial da Rede
/// Hidrometeorológica da Defesa Civil RS, para o usuário reconhecer o código.
abstract final class CoresApp {
  /// Azul-rio: cor da marca, base do tema.
  static const Color primaria = Color(0xFF0B4F6C);

  static const Color normal = Color(0xFF69A82F);
  static const Color atencao = Color(0xFFFABA00);
  static const Color alerta = Color(0xFFE67819);
  static const Color emergencia = Color(0xFFE20228);

  /// Estação sem dado, sem limiar ou em manutenção.
  static const Color semDado = Color(0xFF8A94A6);

  /// Cor de fundo de um nível (`null` = sem dado).
  static Color doNivel(NivelAlerta? nivel) => switch (nivel) {
        NivelAlerta.normal => normal,
        NivelAlerta.atencao => atencao,
        NivelAlerta.alerta => alerta,
        NivelAlerta.emergencia => emergencia,
        null => semDado,
      };

  /// Cor de texto/ícone legível sobre [doNivel]. O amarelo e o laranja pedem
  /// texto escuro; os demais, branco.
  static Color sobreNivel(NivelAlerta? nivel) => switch (nivel) {
        NivelAlerta.atencao || NivelAlerta.alerta => const Color(0xFF1F1400),
        _ => Colors.white,
      };

  /// Ícone do nível. Cor nunca vai sozinha: sempre com ícone e rótulo, para
  /// quem não distingue verde de vermelho.
  static IconData iconeDoNivel(NivelAlerta? nivel) => switch (nivel) {
        NivelAlerta.normal => Icons.check_circle,
        NivelAlerta.atencao => Icons.info,
        NivelAlerta.alerta => Icons.warning,
        NivelAlerta.emergencia => Icons.dangerous,
        null => Icons.help,
      };
}
