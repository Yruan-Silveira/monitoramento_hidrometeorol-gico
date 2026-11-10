import '../regras/classificacao_chuva.dart';
import 'nivel_alerta.dart';
import 'variavel.dart';

/// Chuva acumulada (mm) nas janelas que a API de dados atuais devolve.
///
/// [mm72] não vem na consulta de dados atuais: o repositório real precisa
/// calculá-lo somando a série histórica das últimas 72h. Enquanto não for
/// calculado fica `null` e a classificação usa só 24h e 48h.
class ChuvaAcumulada {
  const ChuvaAcumulada({
    this.mm5min,
    this.mm1h,
    this.mm3h,
    this.mm6h,
    this.mm12h,
    this.mm24,
    this.mm48,
    this.mm72,
    this.mm7dias,
  });

  final double? mm5min;
  final double? mm1h;
  final double? mm3h;
  final double? mm6h;
  final double? mm12h;
  final double? mm24;
  final double? mm48;
  final double? mm72;
  final double? mm7dias;
}

/// Leitura mais recente de uma estação. Qualquer valor pode ser `null`:
/// a API devolve `null` quando o sensor não mandou dado nos últimos 20 minutos.
class Medicao {
  const Medicao({
    this.horario,
    this.nivelRio,
    this.variacaoNivelRio,
    this.alertaRio,
    this.temLimiarRio = false,
    this.chuva = const ChuvaAcumulada(),
    this.temperatura,
    this.sensacaoTermica,
    this.umidade,
    this.pressao,
    this.ventoVelocidadeMedia,
    this.ventoVelocidadeMaxima,
    this.ventoDirecao,
    this.radiacaoSolar,
  });

  /// Início do bloco de 5 minutos da leitura. `null` = estação sem leitura.
  final DateTime? horario;

  /// Cota do rio em metros.
  final double? nivelRio;

  /// Nível atual menos a média da última hora (m): positivo = subindo.
  final double? variacaoNivelRio;

  /// Situação do rio frente às cotas de inundação, calculada pela API.
  /// `null` quando a estação não tem limiar ([temLimiarRio] falso) ou não
  /// tem leitura recente de nível.
  final NivelAlerta? alertaRio;

  /// Se a Defesa Civil cadastrou cotas de inundação para a estação.
  final bool temLimiarRio;

  final ChuvaAcumulada chuva;

  final double? temperatura;
  final double? sensacaoTermica;
  final double? umidade;
  final double? pressao;
  final double? ventoVelocidadeMedia;
  final double? ventoVelocidadeMaxima;

  /// Em graus, 0 = norte.
  final double? ventoDirecao;
  final double? radiacaoSolar;

  /// Nível pela tabela de chuva acumulada da especificação.
  NivelAlerta? get alertaChuva =>
      classificarChuva(mm24: chuva.mm24, mm48: chuva.mm48, mm72: chuva.mm72);

  /// O mais grave entre rio e chuva: é a cor da estação na lista e no mapa
  /// e o indicativo de risco de alagamento (HM-08).
  NivelAlerta? get alertaGeral => NivelAlerta.maior(alertaRio, alertaChuva);

  /// Valor atual de uma variável ([Variavel.chuva] = acumulado de 24h).
  double? valor(Variavel variavel) => switch (variavel) {
        Variavel.nivelRio => nivelRio,
        Variavel.chuva => chuva.mm24,
        Variavel.temperatura => temperatura,
        Variavel.sensacaoTermica => sensacaoTermica,
        Variavel.umidade => umidade,
        Variavel.pressao => pressao,
        Variavel.ventoVelocidadeMedia => ventoVelocidadeMedia,
        Variavel.ventoVelocidadeMaxima => ventoVelocidadeMaxima,
        Variavel.ventoDirecao => ventoDirecao,
        Variavel.radiacaoSolar => radiacaoSolar,
      };
}
