import 'package:flutter/foundation.dart';

import '../dados/local/preferencias_locais.dart';
import '../dominio/modelos/estacao.dart';
import '../dominio/modelos/nivel_alerta.dart';
import '../dominio/repositorios/estacao_repository.dart';

/// Uma favorita cujo nível subiu desde a última verificação (HM-07).
class AvisoSubida {
  const AvisoSubida({required this.estacao, required this.anterior, required this.atual});

  final Estacao estacao;

  /// Nível na verificação anterior; `null` = primeira vez ou estava sem dado.
  final NivelAlerta? anterior;
  final NivelAlerta atual;
}

/// Compara os níveis atuais das favoritas com os da última verificação.
///
/// Regras:
/// - só avisa a partir de [NivelAlerta.atencao] e só quando o nível SOBE;
/// - estação com dado atrasado, sem leitura ou em manutenção é ignorada (não
///   avisa e não mexe no nível guardado), para não avisar com dado velho;
/// - favorita vista pela primeira vez conta como se estivesse "normal": se já
///   estiver em atenção ou acima, avisa uma vez.
///
/// Devolve os avisos e os níveis que devem ser guardados para a próxima vez.
({List<AvisoSubida> avisos, Map<String, NivelAlerta?> niveis}) detectarSubidas({
  required Map<String, NivelAlerta?> anteriores,
  required Iterable<Estacao> favoritas,
  required DateTime agora,
}) {
  final avisos = <AvisoSubida>[];
  final niveis = <String, NivelAlerta?>{};
  for (final estacao in favoritas) {
    final codigo = estacao.codigo;
    if (estacao.situacao(agora) != SituacaoDado.atual) {
      if (anteriores.containsKey(codigo)) niveis[codigo] = anteriores[codigo];
      continue;
    }
    final atual = estacao.alerta;
    final anterior = anteriores[codigo];
    final base = (anterior ?? NivelAlerta.normal).index;
    if (atual != null && atual.index >= NivelAlerta.atencao.index && atual.index > base) {
      avisos.add(AvisoSubida(estacao: estacao, anterior: anterior, atual: atual));
    }
    niveis[codigo] = atual;
  }
  return (avisos: avisos, niveis: niveis);
}

/// Busca os dados das favoritas, detecta subidas de nível e dispara as
/// notificações. Roda na tarefa periódica (a cada 15 min) e também pode ser
/// chamado com o app aberto.
class VerificadorAlertas {
  VerificadorAlertas({
    required this.repositorio,
    required this.notificar,
    NiveisNotificados? niveis,
    DateTime Function()? agora,
  })  : _niveis = niveis ?? NiveisNotificados(),
        _agora = agora ?? DateTime.now;

  final EstacaoRepository repositorio;
  final Future<void> Function(AvisoSubida aviso) notificar;
  final NiveisNotificados _niveis;
  final DateTime Function() _agora;

  /// Faz uma verificação e devolve quantas notificações foram enviadas.
  ///
  /// Lança [FalhaRepositorio] se a API falhar. Se só houver cache, não
  /// notifica (dado velho).
  Future<int> verificar() async {
    final favoritos = await repositorio.listarFavoritos();
    if (favoritos.isEmpty) {
      await _niveis.salvar({});
      return 0;
    }

    final leitura = await repositorio.listarEstacoes(forcarAtualizacao: true);
    if (leitura.doCache) {
      debugPrint('VerificadorAlertas: só há cache, verificação adiada');
      return 0;
    }

    final favoritas = <Estacao>[];
    for (final estacao in leitura.estacoes) {
      if (!favoritos.contains(estacao.codigo)) continue;
      try {
        // buscarEstacao acrescenta a chuva de 72 h, que entra na classificação
        favoritas.add(await repositorio.buscarEstacao(estacao.codigo));
      } on FalhaRepositorio {
        favoritas.add(estacao);
      }
    }

    final resultado = detectarSubidas(
      anteriores: await _niveis.ler(),
      favoritas: favoritas,
      agora: _agora(),
    );
    await _niveis.salvar(resultado.niveis);
    for (final aviso in resultado.avisos) {
      await notificar(aviso);
    }
    debugPrint('VerificadorAlertas: ${favoritas.length} favorita(s), ${resultado.avisos.length} aviso(s)');
    return resultado.avisos.length;
  }
}
