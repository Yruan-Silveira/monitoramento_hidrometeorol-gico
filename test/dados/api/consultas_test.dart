import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/api/consultas.dart';

/// A API recusa (QUERY_NOT_ALLOWED) qualquer texto de consulta diferente do
/// cadastrado. Espaços e quebras de linha não importam; o resto tem que ser
/// idêntico aos arquivos de docs/api.
String _normalizar(String texto) => texto.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  test('tags_data é igual a docs/api/tags_data.graphql', () {
    final arquivo = File('docs/api/tags_data.graphql').readAsStringSync();
    expect(_normalizar(consultaTagsData), _normalizar(arquivo));
  });

  test('historic é igual a docs/api/historic.graphql', () {
    final arquivo = File('docs/api/historic.graphql').readAsStringSync();
    expect(_normalizar(consultaHistoric), _normalizar(arquivo));
  });
}
