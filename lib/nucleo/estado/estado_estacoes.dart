import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../dominio/modelos/estacao.dart';
import '../../dominio/repositorios/estacao_repository.dart';

/// Estado compartilhado pelas telas: a última leitura das estações, os
/// favoritos e se há carregamento ou falha em andamento.
///
/// Fica acima do `Navigator` (ver `main.dart`), então qualquer tela o
/// encontra com [EstadoEstacoes.de].
class EstadoEstacoes extends ChangeNotifier {
  EstadoEstacoes(this.repositorio, {this.intervaloAtualizacao = const Duration(minutes: 5)});

  final EstacaoRepository repositorio;

  /// De quanto em quanto tempo a lista se atualiza sozinha enquanto o app
  /// está aberto. A API publica dado novo a cada 5 minutos. `null` desliga.
  final Duration? intervaloAtualizacao;

  LeituraEstacoes? _leitura;
  FalhaRepositorio? _falha;
  bool _carregando = false;
  Set<String> _favoritos = {};
  Timer? _temporizador;
  bool _descartado = false;

  /// Última leitura bem-sucedida. Continua disponível se uma atualização
  /// posterior falhar.
  LeituraEstacoes? get leitura => _leitura;

  /// Falha da última tentativa, ou `null` se ela deu certo.
  FalhaRepositorio? get falha => _falha;

  bool get carregando => _carregando;

  List<Estacao> get estacoes => _leitura?.estacoes ?? const [];

  Set<String> get favoritos => Set.unmodifiable(_favoritos);

  List<Estacao> get favoritas => [
        for (final estacao in estacoes)
          if (_favoritos.contains(estacao.codigo)) estacao,
      ];

  bool ehFavorita(String codigo) => _favoritos.contains(codigo);

  Estacao? estacao(String codigo) {
    for (final estacao in estacoes) {
      if (estacao.codigo == codigo) return estacao;
    }
    return null;
  }

  /// Carrega favoritos e estações e liga a atualização automática.
  Future<void> iniciar() async {
    try {
      _favoritos = await repositorio.listarFavoritos();
    } on FalhaRepositorio {
      // Sem favoritos salvos: segue com a lista vazia.
    }
    await atualizar();
    final intervalo = intervaloAtualizacao;
    if (intervalo != null && !_descartado) {
      _temporizador = Timer.periodic(intervalo, (_) => atualizar());
    }
  }

  /// Busca as estações de novo. Se falhar, mantém a leitura anterior e
  /// registra a [falha] para as telas avisarem.
  Future<void> atualizar({bool forcar = false}) async {
    if (_carregando || _descartado) return;
    _carregando = true;
    notifyListeners();
    try {
      _leitura = await repositorio.listarEstacoes(forcarAtualizacao: forcar);
      _falha = null;
    } on FalhaRepositorio catch (falha) {
      _falha = falha;
    } finally {
      _carregando = false;
      if (!_descartado) notifyListeners();
    }
  }

  Future<void> alternarFavorito(String codigo) async {
    final favorita = !ehFavorita(codigo);
    await repositorio.definirFavorito(codigo, favorito: favorita);
    if (favorita) {
      _favoritos.add(codigo);
    } else {
      _favoritos.remove(codigo);
    }
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }

  /// O estado mais próximo na árvore; reconstrói quem chamou quando muda.
  static EstadoEstacoes de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EscopoEstacoes>()!.notifier!;
}

/// Disponibiliza o [EstadoEstacoes] para a árvore de widgets.
class EscopoEstacoes extends InheritedNotifier<EstadoEstacoes> {
  const EscopoEstacoes({super.key, required EstadoEstacoes estado, required super.child})
      : super(notifier: estado);
}
