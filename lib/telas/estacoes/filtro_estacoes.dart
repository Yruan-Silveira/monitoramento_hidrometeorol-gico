import '../../dominio/modelos/estacao.dart';

/// Busca e filtros da lista de estações (HM-05). Imutável.
class FiltroEstacoes {
  const FiltroEstacoes({
    this.texto = '',
    this.regiao,
    this.bacia,
    this.coordenadoria,
    this.tipo,
    this.soComCota = false,
    this.soFavoritas = false,
  });

  /// Busca no nome (que costuma ser o município) e no código.
  final String texto;
  final String? regiao;
  final String? bacia;
  final String? coordenadoria;
  final TipoEstacao? tipo;

  /// Só estações com cota de inundação cadastrada pela Defesa Civil.
  final bool soComCota;
  final bool soFavoritas;

  /// Quantos filtros estão ligados (sem contar a busca por texto).
  int get quantidadeAtivos => [regiao, bacia, coordenadoria, tipo].where((v) => v != null).length +
      (soComCota ? 1 : 0) +
      (soFavoritas ? 1 : 0);

  List<Estacao> aplicar(List<Estacao> estacoes, {Set<String> favoritos = const {}}) {
    final busca = normalizar(texto.trim());
    return [
      for (final e in estacoes)
        if ((busca.isEmpty || normalizar(e.nome).contains(busca) || normalizar(e.codigo).contains(busca)) &&
            (regiao == null || e.regiao == regiao) &&
            (bacia == null || e.bacia == bacia) &&
            (coordenadoria == null || e.coordenadoria == coordenadoria) &&
            (tipo == null || e.tipo == tipo) &&
            (!soComCota || e.medicao.temLimiarRio) &&
            (!soFavoritas || favoritos.contains(e.codigo)))
          e,
    ];
  }

  FiltroEstacoes comTexto(String texto) => FiltroEstacoes(
        texto: texto,
        regiao: regiao,
        bacia: bacia,
        coordenadoria: coordenadoria,
        tipo: tipo,
        soComCota: soComCota,
        soFavoritas: soFavoritas,
      );

  /// Mantém só a busca por texto.
  FiltroEstacoes semFiltros() => FiltroEstacoes(texto: texto);

  /// Valores distintos de um campo, em ordem alfabética, para os menus.
  static List<String> opcoes(List<Estacao> estacoes, String? Function(Estacao) campo) =>
      ({for (final e in estacoes) ?campo(e)}.toList()..sort());

  /// Minúsculas e sem acentos, para "sao" achar "São Borja".
  static String normalizar(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final i = de.indexOf(letra);
      buffer.write(i >= 0 ? para[i] : letra);
    }
    return buffer.toString();
  }
}
