import '../dominio/modelos/variavel.dart';

/// Formatação de números, horas e unidades no padrão brasileiro.
abstract final class Formatar {
  /// Número com vírgula decimal. `null` vira "—".
  static String numero(double? valor, {int casas = 1}) {
    if (valor == null) return '—';
    return valor.toStringAsFixed(casas).replaceAll('.', ',');
  }

  /// Valor com unidade, nas casas decimais adequadas à variável.
  static String variavel(Variavel variavel, double? valor) {
    if (valor == null) return '—';
    if (variavel == Variavel.ventoDirecao) {
      return '${valor.round()}° (${pontoCardeal(valor)})';
    }
    return '${numero(valor, casas: casasDecimais(variavel))} ${variavel.unidade}';
  }

  /// Nível do rio com centímetros; o resto com uma casa.
  static int casasDecimais(Variavel variavel) => switch (variavel) {
        Variavel.nivelRio => 2,
        Variavel.ventoDirecao || Variavel.radiacaoSolar => 0,
        _ => 1,
      };

  static String hora(DateTime data) => '${_dois(data.hour)}:${_dois(data.minute)}';

  static String dia(DateTime data) => '${_dois(data.day)}/${_dois(data.month)}';

  static String diaHora(DateTime data) => '${dia(data)} às ${hora(data)}';

  /// "agora", "há 12 min", "há 3 h", "há 2 dias".
  static String tempoDesde(DateTime data, DateTime agora) {
    final diferenca = agora.difference(data);
    if (diferenca.inMinutes < 1) return 'agora';
    if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
    final dias = diferenca.inDays;
    return 'há $dias ${dias == 1 ? 'dia' : 'dias'}';
  }

  /// Direção do vento em graus (0 = norte) para N, NE, L, SE, S, SO, O, NO.
  static String pontoCardeal(double graus) {
    const pontos = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
    return pontos[((graus % 360) / 45).round() % 8];
  }

  static String _dois(int valor) => valor.toString().padLeft(2, '0');
}
