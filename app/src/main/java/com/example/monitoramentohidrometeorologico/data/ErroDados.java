package com.example.monitoramentohidrometeorologico.data;

import androidx.annotation.NonNull;

/**
 * Falha ao obter dados (HM-09). {@link #getMensagemUsuario()} já vem pronta para a tela.
 */
public class ErroDados extends Exception {

    public enum Tipo {
        SEM_INTERNET("Sem conexão com a internet."),
        TIMEOUT("O serviço demorou demais para responder. Tente novamente."),
        SERVICO_INDISPONIVEL("Serviço de dados indisponível no momento."),
        LIMITE_REQUISICOES("Muitas consultas em pouco tempo. Aguarde um minuto."),
        ACESSO_NEGADO("A API recusou o acesso."),
        CONSULTA_RECUSADA("A API recusou a consulta."),
        PARAMETRO_INVALIDO("Período ou parâmetro inválido."),
        RESPOSTA_VAZIA("A API não retornou dados."),
        RESPOSTA_INVALIDA("Resposta da API em formato inesperado."),
        ESTACAO_NAO_ENCONTRADA("Estação não encontrada."),
        DESCONHECIDO("Erro inesperado ao carregar os dados.");

        private final String mensagemPadrao;

        Tipo(String mensagemPadrao) {
            this.mensagemPadrao = mensagemPadrao;
        }

        public String getMensagemPadrao() {
            return mensagemPadrao;
        }
    }

    private final Tipo tipo;
    private final String mensagemUsuario;

    public ErroDados(@NonNull Tipo tipo) {
        this(tipo, tipo.getMensagemPadrao(), null);
    }

    public ErroDados(@NonNull Tipo tipo, String mensagemUsuario) {
        this(tipo, mensagemUsuario, null);
    }

    public ErroDados(@NonNull Tipo tipo, String mensagemUsuario, Throwable causa) {
        super(tipo + ": " + (mensagemUsuario == null ? tipo.getMensagemPadrao() : mensagemUsuario), causa);
        this.tipo = tipo;
        this.mensagemUsuario = mensagemUsuario == null ? tipo.getMensagemPadrao() : mensagemUsuario;
    }

    @NonNull
    public Tipo getTipo() {
        return tipo;
    }

    @NonNull
    public String getMensagemUsuario() {
        return mensagemUsuario;
    }

    /** Erros em que vale a pena mostrar um botão "Tentar novamente". */
    public boolean isTemporario() {
        return tipo == Tipo.SEM_INTERNET || tipo == Tipo.TIMEOUT
                || tipo == Tipo.SERVICO_INDISPONIVEL || tipo == Tipo.LIMITE_REQUISICOES;
    }
}
