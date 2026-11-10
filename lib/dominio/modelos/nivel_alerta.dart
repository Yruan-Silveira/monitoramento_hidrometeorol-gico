/// Nível de alerta de uma estação, do menos ao mais grave.
///
/// A ordem dos valores é a ordem de gravidade: dá para comparar com
/// [NivelAlerta.maior] ou pelo `index`.
///
/// O mesmo enum serve para as duas origens de alerta:
/// - rio: status 0 a 3 devolvido pela API (ver [NivelAlerta.doStatusRio]);
/// - chuva: tabela mm24/mm48/mm72 da especificação
///   (ver `classificarChuva` em `regras/classificacao_chuva.dart`).
///
/// "Sem dado" não é um nível: use `null`.
enum NivelAlerta {
  normal('Normal'),
  atencao('Atenção'),
  alerta('Alerta'),
  emergencia('Emergência');

  const NivelAlerta(this.rotulo);

  /// Texto para mostrar na tela.
  final String rotulo;

  /// Texto quando o nível vem do rio. A API chama o nível mais alto de
  /// "Inundação", não de "Emergência".
  String get rotuloRio => this == emergencia ? 'Inundação' : rotulo;

  /// Converte o `status` de `rio_alarmes.inundacao` (0 a 3) da API.
  /// Devolve `null` para status ausente ou fora da faixa.
  static NivelAlerta? doStatusRio(int? status) {
    if (status == null || status < 0 || status >= values.length) return null;
    return values[status];
  }

  /// O mais grave entre dois níveis, ignorando `null`.
  static NivelAlerta? maior(NivelAlerta? a, NivelAlerta? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.index >= b.index ? a : b;
  }
}
