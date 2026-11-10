import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';
import 'package:olho_no_rio/main.dart';

void main() {
  testWidgets('a tela inicial lista as estações do mock com o nível de cada uma', (tester) async {
    await tester.pumpWidget(OlhoNoRioApp(repositorio: EstacaoRepositoryMock(atraso: Duration.zero)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Olho no Rio'), findsOneWidget);
    expect(find.text('Montenegro'), findsOneWidget);
    expect(find.text('Emergência'), findsOneWidget);
    expect(find.textContaining('Atualizado às'), findsOneWidget);
  });

  testWidgets('sem conexão, mostra a mensagem e o botão de tentar de novo', (tester) async {
    await tester.pumpWidget(
      OlhoNoRioApp(repositorio: EstacaoRepositoryMock(atraso: Duration.zero, falha: TipoFalha.semConexao)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
