import 'package:flutter/material.dart';

import '../../componentes/selo_nivel.dart';
import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../dominio/regras/classificacao_chuva.dart';
import '../../nucleo/formatacao.dart';

/// Tela explicativa (HM-10): fontes dos dados, como os níveis são
/// calculados, limites dos indicadores e o caráter indicativo dos alertas.
///
/// Os textos devem ser validados pelo responsável técnico antes da entrega.
class TelaSobre extends StatelessWidget {
  const TelaSobre({super.key, this.comVoltar = false});

  /// Aberta a partir do detalhe (com seta de voltar) ou pela aba.
  final bool comVoltar;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre os dados'), automaticallyImplyLeading: comVoltar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Aviso(),
          const _Secao(
            icone: Icons.sensors,
            titulo: 'De onde vêm os dados',
            texto: 'As medições vêm da Rede Hidrometeorológica da Defesa Civil do Rio Grande do Sul '
                '(Casa Militar), com cerca de 130 estações. Cada estação mede nível do rio, chuva e '
                'condições do tempo. Os dados são atualizados a cada 5 minutos e o histórico cobre '
                'os últimos 3 meses.\n\n'
                'O app mostra os valores como a Defesa Civil os publica. Sensores podem falhar ou '
                'enviar dados ainda não homologados.',
          ),
          _Secao(
            icone: Icons.water,
            titulo: 'Situação do rio',
            texto: 'Calculada pela Defesa Civil, comparando o nível medido com as cotas de atenção, '
                'alerta e inundação de cada estação. Vale o nível mais alto atingido. Estações sem '
                'cota cadastrada não têm situação do rio.',
            extra: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final nivel in NivelAlerta.values) SeloNivel(nivel, rotulo: nivel.rotuloRio),
                const SeloNivel(null),
              ],
            ),
          ),
          _Secao(
            icone: Icons.water_drop,
            titulo: 'Nível pela chuva acumulada',
            texto: 'Calculado pelo app com a tabela abaixo. Basta uma das três condições; vale o '
                'maior nível atingido.',
            extra: const _TabelaChuva(),
            rodape: 'Na lista e no mapa, o nível usa só 24 e 48 horas, porque a chuva de 72 horas é '
                'calculada a partir do histórico e só aparece no detalhe de cada estação.',
          ),
          const _Secao(
            icone: Icons.flood,
            titulo: 'Risco de alagamento (indicativo)',
            texto: 'É o mais grave entre a situação do rio e o nível pela chuva. É um cruzamento '
                'simples, feito pelo app: não é um modelo de previsão e não considera relevo, '
                'drenagem urbana nem previsão do tempo.',
          ),
          _Secao(
            icone: Icons.schedule,
            titulo: 'Dados atrasados ou ausentes',
            texto: 'Uma leitura com mais de ${Estacao.limiteAtraso.inMinutes} minutos é marcada '
                'como atrasada. Quando um sensor não envia dados, o valor aparece como "—" e a '
                'estação fica cinza. Sem internet, o app mostra os últimos dados recebidos e avisa '
                'de que horário eles são.',
          ),
          const _Secao(
            icone: Icons.map,
            titulo: 'Mapa',
            texto: 'Mapa base © colaboradores do OpenStreetMap. Estações sem coordenadas aparecem '
                'só na lista.',
          ),
          const SizedBox(height: 16),
          Text(
            'Olho no Rio · trabalho acadêmico de Dispositivos Móveis. '
            'Não é um canal oficial da Defesa Civil.',
            style: estilo.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      color: esquema.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign, color: esquema.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Os alertas deste app são indicativos. Não são previsão garantida de enchente e '
                'não substituem os comunicados oficiais da Defesa Civil.\n\n'
                'Em emergência, ligue 199 (Defesa Civil) ou 193 (Bombeiros).',
                style: TextStyle(color: esquema.onErrorContainer, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.icone, required this.titulo, required this.texto, this.extra, this.rodape});

  final IconData icone;
  final String titulo;
  final String texto;
  final Widget? extra;
  final String? rodape;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: estilo.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(texto),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
          if (rodape != null) ...[const SizedBox(height: 8), Text(rodape!, style: estilo.bodySmall)],
        ],
      ),
    );
  }
}

/// Tabela de limiares de chuva, montada a partir de [limiaresChuva] para
/// nunca divergir da regra usada no cálculo.
class _TabelaChuva extends StatelessWidget {
  const _TabelaChuva();

  @override
  Widget build(BuildContext context) {
    final cabecalho = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
    String mm(double v) => '≥ ${Formatar.numero(v, casas: 0)}';
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Text('Nível', style: cabecalho),
            Text('24 h (mm)', style: cabecalho),
            Text('48 h (mm)', style: cabecalho),
            Text('72 h (mm)', style: cabecalho),
          ],
        ),
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Align(alignment: Alignment.centerLeft, child: SeloNivel(NivelAlerta.normal))),
            Text('< 30'),
            Text('< 50'),
            Text('< 60'),
          ],
        ),
        for (final limiar in limiaresChuva)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(alignment: Alignment.centerLeft, child: SeloNivel(limiar.nivel)),
              ),
              Text(mm(limiar.mm24)),
              Text(mm(limiar.mm48)),
              Text(mm(limiar.mm72)),
            ],
          ),
      ],
    );
  }
}
