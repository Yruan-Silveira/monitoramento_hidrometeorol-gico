import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/main.dart';
import 'package:olho_no_rio/telas/sobre/tela_sobre.dart';

/// Botão "Enviar notificação de teste" da tela "Sobre", usado para demonstrar
/// o critério de aceite de notificação. O envio real é trocado por uma função
/// falsa: o teste confere só a tela.
void main() {
  final botao = find.text('Enviar notificação de teste');

  Future<void> abrirSobre(WidgetTester tester, {Future<bool> Function()? enviar}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      OlhoNoRioApp(
        repositorio: EstacaoRepositoryMock(atraso: Duration.zero),
        mostrarMapaBase: false,
        atualizacaoAutomatica: null,
        enviarNotificacaoTeste: enviar,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Sobre')));
    await tester.pumpAndSettle();
  }

  // A lista da tela "Sobre" (as outras abas também têm listas, fora de vista).
  final listaSobre = find.descendant(of: find.byType(TelaSobre), matching: find.byType(Scrollable)).first;

  Future<void> tocarNoBotao(WidgetTester tester) async {
    await tester.scrollUntilVisible(botao, 300, scrollable: listaSobre);
    // scrollUntilVisible para quando o botão é montado, ainda fora da tela.
    await tester.ensureVisible(botao);
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  testWidgets('envia a notificação e confirma', (tester) async {
    var chamadas = 0;
    await abrirSobre(
      tester,
      enviar: () async {
        chamadas++;
        return true;
      },
    );

    await tocarNoBotao(tester);

    expect(chamadas, 1);
    expect(find.text('Notificação enviada. Confira a barra de notificações.'), findsOneWidget);
  });

  testWidgets('com notificações bloqueadas, explica como liberar', (tester) async {
    await abrirSobre(tester, enviar: () async => false);

    await tocarNoBotao(tester);

    expect(find.textContaining('Notificações bloqueadas'), findsOneWidget);
  });

  testWidgets('se o envio falhar, avisa sem travar a tela', (tester) async {
    await abrirSobre(tester, enviar: () async => throw Exception('sem plugin'));

    await tocarNoBotao(tester);

    expect(find.text('Não foi possível enviar a notificação neste aparelho.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.ancestor(of: botao, matching: find.byType(FilledButton))).onPressed,
      isNotNull,
    );
  });

  testWidgets('sem a função de envio, o botão não aparece', (tester) async {
    await abrirSobre(tester);
    await tester.scrollUntilVisible(find.text('Notificações'), 300, scrollable: listaSobre);
    expect(find.text('Notificações'), findsOneWidget);
    expect(botao, findsNothing);
  });
}
