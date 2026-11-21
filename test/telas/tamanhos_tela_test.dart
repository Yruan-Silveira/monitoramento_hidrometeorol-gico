import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/dominio/modelos/serie_historica.dart';
import 'package:olho_no_rio/main.dart';

/// Revisão de usabilidade em telas de tamanhos diferentes (entregável da
/// Pessoa B): percorre todas as telas em cada configuração. Qualquer conteúdo
/// que estoure a largura ou a altura disponível lança erro e reprova o teste.
///
/// Resultado da revisão em docs/usabilidade.md.
class _Configuracao {
  const _Configuracao(this.nome, this.largura, this.altura, {this.escalaFonte = 1.0});

  final String nome;

  /// Em dp (pixels independentes de densidade).
  final double largura;
  final double altura;

  /// Tamanho da fonte do sistema (Configurações > Tela > Tamanho da fonte).
  final double escalaFonte;
}

const configuracoes = [
  _Configuracao('celular pequeno (320 x 568)', 320, 568),
  _Configuracao('celular comum (360 x 640)', 360, 640),
  _Configuracao('celular grande (412 x 915)', 412, 915),
  _Configuracao('celular deitado (915 x 412)', 915, 412),
  _Configuracao('tablet 8" (800 x 1280)', 800, 1280),
  _Configuracao('tablet 10" deitado (1280 x 800)', 1280, 800),
  _Configuracao('celular comum, fonte 130%', 360, 640, escalaFonte: 1.3),
  _Configuracao('celular comum, fonte 200%', 360, 640, escalaFonte: 2.0),
];

/// Carrega a Roboto e os ícones que vêm com o Flutter. Sem isso o teste usa
/// a fonte padrão de testes (Ahem), bem mais larga que a do celular, e a
/// revisão apontaria problemas que não existem no aparelho.
Future<void> _carregarFontesReais() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null) return;
  final pasta = '$raiz/bin/cache/artifacts/material_fonts';
  final familias = {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-italic.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  };
  for (final familia in familias.entries) {
    final carregador = FontLoader(familia.key);
    for (final arquivo in familia.value) {
      final bytes = File('$pasta/$arquivo').readAsBytesSync();
      carregador.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await carregador.load();
  }
}

void main() {
  setUpAll(_carregarFontesReais);

  for (final c in configuracoes) {
    testWidgets('todas as telas cabem em: ${c.nome}', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = Size(c.largura * 2, c.altura * 2);
      tester.platformDispatcher.textScaleFactorTestValue = c.escalaFonte;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(OlhoNoRioApp(
        repositorio: EstacaoRepositoryMock(atraso: Duration.zero),
        mostrarMapaBase: false,
        atualizacaoAutomatica: null,
      ));
      await tester.pumpAndSettle();

      Future<void> aba(String nome) async {
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(nome)));
        await tester.pumpAndSettle();
      }

      // Rola até o fim da lista visível (até parar de andar), para montar
      // todos os itens.
      Future<void> rolarAteOFim() async {
        final rolagem = find.byType(Scrollable).last;
        for (var i = 0; i < 60; i++) {
          final posicao = tester.state<ScrollableState>(rolagem).position;
          if (posicao.pixels >= posicao.maxScrollExtent) break;
          await tester.drag(rolagem, Offset(0, -c.altura * 0.8), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      }

      // Início
      await rolarAteOFim();

      // Estações + painel de filtros
      await aba('Estações');
      await rolarAteOFim();
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      // Com fonte grande o botão fica abaixo da dobra: o painel rola até ele.
      await tester.ensureVisible(find.text('Aplicar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(find.text('Aplicar'), findsNothing);

      // Mapa + resumo ao tocar num marcador
      await aba('Mapa');
      // Marcadores próximos se sobrepõem no zoom inicial: toca no primeiro
      // que estiver por cima.
      final marcador = find.bySemanticsLabel(RegExp(r'^DCRS|: ')).hitTestable();
      expect(marcador, findsWidgets, reason: 'nenhum marcador tocável no mapa');
      {
        await tester.tap(marcador.first);
        await tester.pumpAndSettle();
        // O botão "Ver detalhes" precisa ser alcançável, rolando se preciso.
        await tester.ensureVisible(find.text('Ver detalhes'));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Ver detalhes'))).pop();
        await tester.pumpAndSettle();
      }

      // Sobre
      await aba('Sobre');
      await rolarAteOFim();

      // Detalhe de uma estação com todos os cartões, em cada período e variável
      await aba('Estações');
      await tester.enterText(find.byType(TextField), 'montenegro');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Montenegro').hitTestable().first);
      await tester.pumpAndSettle();
      await rolarAteOFim();
      for (final variavel in ['Chuva', 'Temperatura', 'Nível do rio']) {
        final chip = find.widgetWithText(ChoiceChip, variavel);
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        for (final periodo in ['72 h', '7 dias', '30 dias', '24 h']) {
          final botao = find.descendant(of: find.byType(SegmentedButton<PeriodoSerie>), matching: find.text(periodo));
          await tester.ensureVisible(botao);
          await tester.tap(botao);
          await tester.pumpAndSettle();
        }
      }
    });
  }
}
