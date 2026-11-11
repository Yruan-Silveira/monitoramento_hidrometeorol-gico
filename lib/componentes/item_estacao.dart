import 'package:flutter/material.dart';

import '../dominio/modelos/estacao.dart';
import '../dominio/modelos/variavel.dart';
import '../nucleo/estado/estado_estacoes.dart';
import '../nucleo/formatacao.dart';
import '../nucleo/tema/cores.dart';
import '../telas/detalhe/tela_detalhe.dart';
import 'situacao_dado.dart';

/// Linha de estação usada na tela inicial e na lista: nível (cor, ícone e
/// texto), nome, medidas principais, situação do dado e botão de favoritar.
/// Tocar abre o detalhe.
class ItemEstacao extends StatelessWidget {
  const ItemEstacao({super.key, required this.estacao});

  final Estacao estacao;

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    final favorita = estado.ehFavorita(estacao.codigo);
    final nivel = estacao.alerta;
    final medicao = estacao.medicao;
    final tema = Theme.of(context);

    final medidas = [
      if (medicao.nivelRio != null) 'Rio ${Formatar.variavel(Variavel.nivelRio, medicao.nivelRio)}',
      if (medicao.chuva.mm24 != null) 'Chuva 24 h ${Formatar.variavel(Variavel.chuva, medicao.chuva.mm24)}',
    ];
    final situacao = textoSituacao(estacao, DateTime.now());

    return ListTile(
      onTap: () => abrirDetalhe(context, estacao.codigo),
      leading: CircleAvatar(
        backgroundColor: CoresApp.doNivel(nivel),
        foregroundColor: CoresApp.sobreNivel(nivel),
        child: Icon(CoresApp.iconeDoNivel(nivel)),
      ),
      title: Text(estacao.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nivel?.rotulo ?? 'Sem dado',
            style: tema.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (medidas.isNotEmpty) Text(medidas.join(' · ')),
          if (situacao != null)
            Text(situacao, style: TextStyle(color: tema.colorScheme.tertiary, fontStyle: FontStyle.italic)),
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: favorita ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
        icon: Icon(favorita ? Icons.star : Icons.star_border),
        color: favorita ? CoresApp.atencao : null,
        onPressed: () => estado.alternarFavorito(estacao.codigo),
      ),
    );
  }
}

/// Abre a tela de detalhe de uma estação.
void abrirDetalhe(BuildContext context, String codigo) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelaDetalhe(codigo: codigo)));
}
