import 'dados/mock/estacao_repository_mock.dart';
import 'dominio/repositorios/estacao_repository.dart';

/// Único ponto onde se escolhe a implementação do repositório.
///
/// Na semana 4, a Pessoa A troca o mock pelo repositório real aqui e nenhuma
/// tela precisa mudar.
EstacaoRepository criarRepositorio() => EstacaoRepositoryMock();
