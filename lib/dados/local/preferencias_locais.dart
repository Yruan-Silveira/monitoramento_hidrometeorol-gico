import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dominio/modelos/nivel_alerta.dart';

/// Códigos das estações favoritas (HM-05), guardados no aparelho.
class FavoritosLocal {
  static const String chave = 'favoritos';

  Future<Set<String>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    // a tarefa em segundo plano roda em outro isolate: relê do disco
    await prefs.reload();
    return {...?prefs.getStringList(chave)};
  }

  Future<void> definir(String codigo, {required bool favorito}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final atuais = {...?prefs.getStringList(chave)};
    final mudou = favorito ? atuais.add(codigo) : atuais.remove(codigo);
    if (mudou) await prefs.setStringList(chave, atuais.toList()..sort());
  }
}

/// Último nível visto de cada favorita, para a verificação em segundo plano
/// só notificar quando o nível SOBE (HM-07) e não repetir a notificação.
class NiveisNotificados {
  static const String chave = 'ultimos_niveis';

  /// Código → nível. Nível `null` = estava sem dado.
  Future<Map<String, NivelAlerta?>> ler() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final texto = prefs.getString(chave);
    if (texto == null) return {};
    try {
      final mapa = jsonDecode(texto);
      if (mapa is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in mapa.entries)
          key.toString(): value is int ? NivelAlerta.doStatusRio(value) : null,
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> salvar(Map<String, NivelAlerta?> niveis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chave,
      jsonEncode({for (final MapEntry(:key, :value) in niveis.entries) key: value?.index}),
    );
  }
}
