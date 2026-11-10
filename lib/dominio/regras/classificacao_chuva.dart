import '../modelos/nivel_alerta.dart';

/// Uma linha da tabela de limiares de chuva acumulada (em mm).
class LimiarChuva {
  const LimiarChuva(this.nivel, {required this.mm24, required this.mm48, required this.mm72});

  final NivelAlerta nivel;
  final double mm24;
  final double mm48;
  final double mm72;
}

/// Tabela da especificação do trabalho. Um nível é atingido quando
/// qualquer uma das três condições é verdadeira; vale o maior nível atingido.
///
/// Fica exposta para a tela de legenda (HM-06) e a tela explicativa (HM-10).
const List<LimiarChuva> limiaresChuva = [
  LimiarChuva(NivelAlerta.atencao, mm24: 30, mm48: 50, mm72: 60),
  LimiarChuva(NivelAlerta.alerta, mm24: 50, mm48: 70, mm72: 90),
  LimiarChuva(NivelAlerta.emergencia, mm24: 80, mm48: 100, mm72: 120),
];

/// Classifica a chuva acumulada pela tabela [limiaresChuva].
///
/// Acumulados `null` são ignorados (a API de dados atuais não traz o de 72h).
/// Devolve `null` quando nenhum acumulado está disponível.
NivelAlerta? classificarChuva({double? mm24, double? mm48, double? mm72}) {
  if (mm24 == null && mm48 == null && mm72 == null) return null;

  var nivel = NivelAlerta.normal;
  for (final limiar in limiaresChuva) {
    final atingiu = (mm24 != null && mm24 >= limiar.mm24) ||
        (mm48 != null && mm48 >= limiar.mm48) ||
        (mm72 != null && mm72 >= limiar.mm72);
    if (atingiu) nivel = limiar.nivel;
  }
  return nivel;
}
