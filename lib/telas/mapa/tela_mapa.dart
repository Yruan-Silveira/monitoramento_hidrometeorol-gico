import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../componentes/carregamento_estacoes.dart';
import '../../componentes/item_estacao.dart';
import '../../componentes/selo_nivel.dart';
import '../../componentes/situacao_dado.dart';
import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../dominio/modelos/variavel.dart';
import '../../nucleo/formatacao.dart';
import '../../nucleo/tema/cores.dart';

/// Mapa georreferenciado das estações (HM-02), com marcadores na cor do nível.
class TelaMapa extends StatelessWidget {
  const TelaMapa({super.key, this.mostrarMapaBase = true});

  /// Desligado nos testes, que não têm acesso à internet para baixar o mapa.
  final bool mostrarMapaBase;

  /// Centro aproximado do Rio Grande do Sul.
  static const _centroRS = LatLng(-30.0, -53.2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: CarregamentoEstacoes(
        construtor: (context, estacoes) {
          final noMapa = estacoes.where((e) => e.temCoordenadas).toList()
            // As mais graves por cima.
            ..sort((a, b) => (a.alerta?.index ?? -1).compareTo(b.alerta?.index ?? -1));
          final foraDoMapa = estacoes.length - noMapa.length;

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _centroRS,
                  initialZoom: 6,
                  initialCameraFit: noMapa.isEmpty
                      ? null
                      : CameraFit.coordinates(
                          coordinates: [for (final e in noMapa) LatLng(e.latitude!, e.longitude!)],
                          padding: const EdgeInsets.fromLTRB(32, 64, 32, 120),
                          maxZoom: 10,
                        ),
                  minZoom: 4,
                  maxZoom: 17,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  if (mostrarMapaBase)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.com.olhonorio.olho_no_rio',
                    ),
                  MarkerLayer(
                    markers: [
                      for (final estacao in noMapa)
                        Marker(
                          point: LatLng(estacao.latitude!, estacao.longitude!),
                          width: 32,
                          height: 32,
                          child: _Marcador(estacao: estacao),
                        ),
                    ],
                  ),
                  if (mostrarMapaBase)
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('Colaboradores do OpenStreetMap')],
                    ),
                ],
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _Legenda(foraDoMapa: foraDoMapa),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.estacao});

  final Estacao estacao;

  @override
  Widget build(BuildContext context) {
    final nivel = estacao.alerta;
    return Semantics(
      button: true,
      label: '${estacao.nome}: ${nivel?.rotulo ?? 'sem dado'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _mostrarResumo(context, estacao),
        child: Container(
          decoration: BoxDecoration(
            color: CoresApp.doNivel(nivel),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Icon(CoresApp.iconeDoNivel(nivel), size: 18, color: CoresApp.sobreNivel(nivel)),
        ),
      ),
    );
  }
}

void _mostrarResumo(BuildContext context, Estacao estacao) {
  final medicao = estacao.medicao;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (contexto) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(estacao.nome, style: Theme.of(contexto).textTheme.titleLarge)),
                SeloNivel(estacao.alerta),
              ],
            ),
            const SizedBox(height: 4),
            Text([estacao.codigo, ?estacao.regiao].join(' · ')),
            const SizedBox(height: 12),
            Text('Nível do rio: ${Formatar.variavel(Variavel.nivelRio, medicao.nivelRio)}'),
            Text('Chuva em 24 h: ${Formatar.variavel(Variavel.chuva, medicao.chuva.mm24)}'),
            const SizedBox(height: 8),
            AvisoSituacao(estacao: estacao),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(contexto);
                  abrirDetalhe(context, estacao.codigo);
                },
                child: const Text('Ver detalhes'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Legenda das cores (HM-06), recolhível para não cobrir o mapa.
class _Legenda extends StatefulWidget {
  const _Legenda({required this.foraDoMapa});

  final int foraDoMapa;

  @override
  State<_Legenda> createState() => _LegendaState();
}

class _LegendaState extends State<_Legenda> {
  var _aberta = true;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _aberta = !_aberta),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Legenda', style: Theme.of(context).textTheme.labelLarge),
                  Icon(_aberta ? Icons.expand_less : Icons.expand_more, size: 18),
                ],
              ),
              if (_aberta) ...[
                const SizedBox(height: 4),
                for (final nivel in <NivelAlerta?>[...NivelAlerta.values.reversed, null])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CoresApp.iconeDoNivel(nivel), size: 16, color: CoresApp.doNivel(nivel)),
                        const SizedBox(width: 6),
                        Text(nivel?.rotulo ?? 'Sem dado', style: estilo),
                      ],
                    ),
                  ),
                if (widget.foraDoMapa > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.foraDoMapa} sem localização\n(veja na lista)',
                    style: estilo?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
