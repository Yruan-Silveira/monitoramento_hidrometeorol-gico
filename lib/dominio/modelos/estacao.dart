import 'medicao.dart';
import 'nivel_alerta.dart';

/// Tipo da estação, derivado dos sensores que ela declara ter.
///
/// Hoje as 130 estações da API são [hidrometeorologica]; os outros dois
/// valores existem para o filtro por tipo (HM-05) não quebrar se isso mudar.
enum TipoEstacao {
  hidrometeorologica('Hidrometeorológica'),
  fluviometrica('Fluviométrica'),
  meteorologica('Meteorológica');

  const TipoEstacao(this.rotulo);

  final String rotulo;
}

/// Como está o dado de uma estação agora (HM-09).
enum SituacaoDado {
  /// Leitura dentro do esperado.
  atual,

  /// Há leitura, mas mais velha que [Estacao.limiteAtraso].
  atrasado,

  /// A estação não tem nenhuma leitura.
  ausente,

  /// A estação está marcada como em manutenção.
  manutencao,
}

/// Uma estação da rede, com seus metadados e a leitura mais recente.
class Estacao {
  const Estacao({
    required this.codigo,
    required this.nome,
    this.latitude,
    this.longitude,
    this.altitude,
    this.regiao,
    this.bacia,
    this.coordenadoria,
    this.tipo = TipoEstacao.hidrometeorologica,
    this.emManutencao = false,
    this.medicao = const Medicao(),
  });

  /// Leituras chegam a cada 5 minutos; acima disso o dado é tratado como
  /// atrasado.
  static const Duration limiteAtraso = Duration(minutes: 30);

  /// Identificador, ex.: `DCRS-00001`.
  final String codigo;

  /// Nome da estação. Costuma ser o município, às vezes com o rio ou o
  /// bairro ("Rolante - Centro"). A API não tem campo separado de município.
  final String nome;

  /// Coordenadas. Podem faltar: nesse caso a estação fica fora do mapa.
  final double? latitude;
  final double? longitude;
  final double? altitude;

  /// Mesorregião, ex.: "Metropolitana de Porto Alegre".
  final String? regiao;

  /// Bacia hidrográfica, ex.: "RS - Sinos".
  final String? bacia;

  /// Coordenadoria regional da Defesa Civil, ex.: "LAJEADO".
  final String? coordenadoria;

  final TipoEstacao tipo;
  final bool emManutencao;
  final Medicao medicao;

  bool get temCoordenadas => latitude != null && longitude != null;

  /// Atalho para a cor da estação na lista e no mapa.
  NivelAlerta? get alerta => medicao.alertaGeral;

  /// Situação do dado em relação ao instante [agora].
  SituacaoDado situacao(DateTime agora) {
    if (emManutencao) return SituacaoDado.manutencao;
    final horario = medicao.horario;
    if (horario == null) return SituacaoDado.ausente;
    if (agora.difference(horario) > limiteAtraso) return SituacaoDado.atrasado;
    return SituacaoDado.atual;
  }
}
