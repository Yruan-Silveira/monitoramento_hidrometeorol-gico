import 'package:flutter/material.dart';

import '../../componentes/barra_atualizacao.dart';
import '../../componentes/carregamento_estacoes.dart';
import '../../componentes/item_estacao.dart';
import '../../componentes/mensagem_falha.dart';
import '../../dominio/modelos/estacao.dart';
import '../../nucleo/estado/estado_estacoes.dart';
import '../inicio/tela_inicio.dart';
import 'filtro_estacoes.dart';

/// Lista de estações (HM-02) com busca e filtros (HM-05).
class TelaEstacoes extends StatefulWidget {
  const TelaEstacoes({super.key});

  @override
  State<TelaEstacoes> createState() => _TelaEstacoesState();
}

class _TelaEstacoesState extends State<TelaEstacoes> {
  final _busca = TextEditingController();
  var _filtro = const FiltroEstacoes();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _abrirFiltros(List<Estacao> estacoes) async {
    final novo = await showModalBottomSheet<FiltroEstacoes>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PainelFiltros(estacoes: estacoes, inicial: _filtro),
    );
    if (novo != null) setState(() => _filtro = novo);
  }

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Estações')),
      body: CarregamentoEstacoes(
        construtor: (context, estacoes) {
          final resultado = _filtro.aplicar(estacoes, favoritos: estado.favoritos)..sort(ordenarPorGravidade);
          final ativos = _filtro.quantidadeAtivos;
          return Column(
            children: [
              const BarraAtualizacao(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busca,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar por município ou código',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _busca.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() {
                                    _busca.clear();
                                    _filtro = _filtro.comTexto('');
                                  }),
                                ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (texto) => setState(() => _filtro = _filtro.comTexto(texto)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Filtros',
                      onPressed: () => _abrirFiltros(estacoes),
                      icon: Badge(
                        isLabelVisible: ativos > 0,
                        label: Text('$ativos'),
                        child: const Icon(Icons.filter_list),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${resultado.length} de ${estacoes.length} estações',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    if (ativos > 0)
                      TextButton(
                        onPressed: () => setState(() => _filtro = _filtro.semFiltros()),
                        child: const Text('Limpar filtros'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => estado.atualizar(forcar: true),
                  child: resultado.isEmpty
                      ? ListView(children: const [
                          MensagemVazia(icone: Icons.search_off, texto: 'Nenhuma estação encontrada.'),
                        ])
                      : ListView.builder(
                          itemCount: resultado.length,
                          itemBuilder: (_, i) => ItemEstacao(estacao: resultado[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PainelFiltros extends StatefulWidget {
  const _PainelFiltros({required this.estacoes, required this.inicial});

  final List<Estacao> estacoes;
  final FiltroEstacoes inicial;

  @override
  State<_PainelFiltros> createState() => _PainelFiltrosState();
}

class _PainelFiltrosState extends State<_PainelFiltros> {
  late String? _regiao = widget.inicial.regiao;
  late String? _bacia = widget.inicial.bacia;
  late String? _coordenadoria = widget.inicial.coordenadoria;
  late TipoEstacao? _tipo = widget.inicial.tipo;
  late bool _soComCota = widget.inicial.soComCota;
  late bool _soFavoritas = widget.inicial.soFavoritas;

  FiltroEstacoes get _resultado => FiltroEstacoes(
        texto: widget.inicial.texto,
        regiao: _regiao,
        bacia: _bacia,
        coordenadoria: _coordenadoria,
        tipo: _tipo,
        soComCota: _soComCota,
        soFavoritas: _soFavoritas,
      );

  @override
  Widget build(BuildContext context) {
    final estacoes = widget.estacoes;
    // O filtro por tipo só aparece quando há mais de um tipo na rede.
    final tipos = {for (final e in estacoes) e.tipo}.toList()..sort((a, b) => a.index.compareTo(b.index));

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _Menu(
              rotulo: 'Região',
              valor: _regiao,
              opcoes: FiltroEstacoes.opcoes(estacoes, (e) => e.regiao),
              aoMudar: (v) => setState(() => _regiao = v),
            ),
            _Menu(
              rotulo: 'Bacia hidrográfica',
              valor: _bacia,
              opcoes: FiltroEstacoes.opcoes(estacoes, (e) => e.bacia),
              aoMudar: (v) => setState(() => _bacia = v),
            ),
            _Menu(
              rotulo: 'Coordenadoria da Defesa Civil',
              valor: _coordenadoria,
              opcoes: FiltroEstacoes.opcoes(estacoes, (e) => e.coordenadoria),
              aoMudar: (v) => setState(() => _coordenadoria = v),
            ),
            if (tipos.length > 1)
              _Menu(
                rotulo: 'Tipo de estação',
                valor: _tipo?.rotulo,
                opcoes: [for (final t in tipos) t.rotulo],
                aoMudar: (v) => setState(() => _tipo = tipos.where((t) => t.rotulo == v).firstOrNull),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só com cota de inundação'),
              subtitle: const Text('Estações em que a Defesa Civil acompanha o nível do rio'),
              value: _soComCota,
              onChanged: (v) => setState(() => _soComCota = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só favoritas'),
              value: _soFavoritas,
              onChanged: (v) => setState(() => _soFavoritas = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, widget.inicial.semFiltros()),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _resultado),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu suspenso com a opção "Todas".
class _Menu extends StatelessWidget {
  const _Menu({required this.rotulo, required this.valor, required this.opcoes, required this.aoMudar});

  final String rotulo;
  final String? valor;
  final List<String> opcoes;
  final ValueChanged<String?> aoMudar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder(), isDense: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: valor,
            isExpanded: true,
            isDense: true,
            items: [
              const DropdownMenuItem<String?>(child: Text('Todas')),
              for (final opcao in opcoes)
                DropdownMenuItem<String?>(value: opcao, child: Text(opcao, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: aoMudar,
          ),
        ),
      ),
    );
  }
}
