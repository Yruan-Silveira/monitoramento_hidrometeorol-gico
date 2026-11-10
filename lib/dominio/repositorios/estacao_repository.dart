import '../modelos/estacao.dart';
import '../modelos/serie_historica.dart';

/// De onde veio a leitura entregue às telas.
enum OrigemDados {
  /// Buscada na API agora.
  rede,

  /// Cópia guardada no aparelho (a API falhou ou ainda não há dado novo).
  cache,
}

/// Resultado de [EstacaoRepository.listarEstacoes]: as estações mais os
/// dados que a tela precisa para mostrar "atualizado às HH:MM" (HM-09).
class LeituraEstacoes {
  const LeituraEstacoes({
    required this.estacoes,
    required this.atualizadoEm,
    this.proximaAtualizacaoEm,
    this.origem = OrigemDados.rede,
  });

  final List<Estacao> estacoes;

  /// Quando estes dados foram obtidos da API (não quando foram lidos do cache).
  final DateTime atualizadoEm;

  /// Quando a API promete dado novo. Antes disso não adianta consultar.
  final DateTime? proximaAtualizacaoEm;

  final OrigemDados origem;

  bool get doCache => origem == OrigemDados.cache;
}

/// Motivo de uma falha, para a tela escolher a mensagem (HM-09).
enum TipoFalha {
  /// Aparelho sem internet.
  semConexao,

  /// A API não respondeu a tempo.
  tempoEsgotado,

  /// A API respondeu com erro (5xx, consulta recusada, etc.).
  servicoIndisponivel,

  /// Passou do limite de 120 requisições por minuto.
  limiteExcedido,

  /// Estação inexistente.
  naoEncontrado,

  /// Período fora do que a API aceita (só os últimos 3 meses).
  periodoInvalido,

  /// A resposta veio num formato inesperado.
  respostaInvalida,
}

/// Única exceção que o repositório lança para as telas.
class FalhaRepositorio implements Exception {
  const FalhaRepositorio(this.tipo, [this.detalhe]);

  final TipoFalha tipo;

  /// Texto técnico para log; não mostrar ao usuário.
  final String? detalhe;

  @override
  String toString() => 'FalhaRepositorio(${tipo.name}${detalhe == null ? '' : ': $detalhe'})';
}

/// Contrato entre as telas (Pessoa B) e a camada de dados (Pessoa A).
///
/// As telas só conhecem esta interface. Há duas implementações:
/// `EstacaoRepositoryMock` (dados de exemplo) e a real, que consulta a API.
/// A troca é feita em um único lugar: `lib/injecao.dart`.
///
/// Todos os métodos lançam [FalhaRepositorio] em caso de erro.
///
/// Mudança nesta interface ou nos modelos só depois de avisar a dupla.
abstract interface class EstacaoRepository {
  /// Todas as estações com a leitura mais recente.
  ///
  /// A API sempre devolve a rede inteira; não há filtro no servidor. Busca e
  /// filtros (HM-05) são feitos na tela, sobre esta lista.
  ///
  /// Sem [forcarAtualizacao], a implementação pode devolver o cache enquanto
  /// ele ainda for válido. Se a rede falhar e houver cache, devolve o cache
  /// com `origem == OrigemDados.cache` em vez de lançar erro.
  Future<LeituraEstacoes> listarEstacoes({bool forcarAtualizacao = false});

  /// Uma estação pelo código. Lança [TipoFalha.naoEncontrado] se não existir.
  Future<Estacao> buscarEstacao(String codigo);

  /// Série de uma estação entre [inicio] e [fim], em ordem cronológica.
  ///
  /// A API só guarda os últimos 3 meses: [inicio] mais antigo que isso lança
  /// [TipoFalha.periodoInvalido].
  Future<SerieHistorica> buscarSerie(
    String codigo, {
    required DateTime inicio,
    required DateTime fim,
    IntervaloSerie intervalo = IntervaloSerie.hora1,
  });

  /// Códigos das estações favoritas, guardados no aparelho.
  Future<Set<String>> listarFavoritos();

  /// Marca ou desmarca uma estação como favorita.
  Future<void> definirFavorito(String codigo, {required bool favorito});
}
