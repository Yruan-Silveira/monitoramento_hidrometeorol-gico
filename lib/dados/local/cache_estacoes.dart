import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Última resposta da tags_data guardada no aparelho, para o app abrir e
/// mostrar dados sem internet (HM-09).
class RespostaGuardada {
  const RespostaGuardada(this.json, this.obtidoEm);

  final Map<String, dynamic> json;

  /// Quando a resposta veio da API.
  final DateTime obtidoEm;
}

/// Guarda a resposta inteira num arquivo da área privada do app.
///
/// A escrita é atômica (arquivo temporário + renomear): se o app morrer no
/// meio, o cache anterior continua válido.
class CacheEstacoes {
  CacheEstacoes({Future<Directory> Function()? pasta}) : _pasta = pasta ?? getApplicationSupportDirectory;

  static const String nomeArquivo = 'cache_tags_data.json';
  static const int _versao = 1;

  final Future<Directory> Function() _pasta;

  Future<File> _arquivo() async => File('${(await _pasta()).path}${Platform.pathSeparator}$nomeArquivo');

  Future<void> salvar(Map<String, dynamic> json, DateTime obtidoEm) async {
    final arquivo = await _arquivo();
    final temporario = File('${arquivo.path}.tmp');
    final conteudo = jsonEncode({
      'versao': _versao,
      'obtidoEm': obtidoEm.toUtc().toIso8601String(),
      'resposta': json,
    });
    await temporario.writeAsString(conteudo, flush: true);
    await temporario.rename(arquivo.path);
  }

  /// A resposta guardada, ou `null` se não houver ou estiver corrompida
  /// (nesse caso o arquivo é apagado).
  Future<RespostaGuardada?> ler() async {
    final arquivo = await _arquivo();
    if (!await arquivo.exists()) return null;
    try {
      final conteudo = jsonDecode(await arquivo.readAsString());
      if (conteudo is Map<String, dynamic> && conteudo['versao'] == _versao) {
        final obtidoEm = DateTime.tryParse(conteudo['obtidoEm']?.toString() ?? '');
        final resposta = conteudo['resposta'];
        if (obtidoEm != null && resposta is Map<String, dynamic>) {
          return RespostaGuardada(resposta, obtidoEm.toLocal());
        }
      }
    } on FormatException {
      // cai no limpar abaixo
    }
    await limpar();
    return null;
  }

  Future<void> limpar() async {
    final arquivo = await _arquivo();
    if (await arquivo.exists()) await arquivo.delete();
  }
}
