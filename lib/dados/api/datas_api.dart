/// Conversão de horários entre o app e a API.
///
/// - `timestamp` (tags_data) e `ts` (historic) vêm SEM fuso e são de Brasília:
///   `2026-11-10T20:35:00.000`.
/// - `proximaAtualizacaoEm` vem em UTC, com `Z`.
/// - `startDate` e `endDate` da historic vão como `AAAA-MM-DD HH:MM:SS`, em
///   horário de Brasília.
///
/// Brasília está em UTC−3 o ano todo (o horário de verão acabou em 2019).
library;

const Duration _deslocamentoBrasilia = Duration(hours: -3);

final RegExp _temFuso = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

/// Lê um horário da API. Sem fuso, assume Brasília. Devolve no fuso do
/// aparelho, ou `null` se o valor estiver ausente ou inválido.
DateTime? lerHorarioApi(Object? valor) {
  if (valor is! String) return null;
  var texto = valor.trim();
  if (texto.isEmpty) return null;
  if (!_temFuso.hasMatch(texto)) texto = '$texto-03:00';
  return DateTime.tryParse(texto)?.toLocal();
}

/// Formata um instante para `startDate`/`endDate` da consulta historic.
String formatarParaApi(DateTime instante) {
  final b = instante.toUtc().add(_deslocamentoBrasilia);
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${b.year.toString().padLeft(4, '0')}-${dois(b.month)}-${dois(b.day)} '
      '${dois(b.hour)}:${dois(b.minute)}:${dois(b.second)}';
}
