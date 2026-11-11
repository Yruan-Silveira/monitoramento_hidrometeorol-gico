package com.example.monitoramentohidrometeorologico.model;

/**
 * Situação dos dados de uma estação (HM-09). Diz se a leitura pode ser mostrada como atual.
 */
public enum SituacaoDados {
    OK("Dados atualizados"),
    ATRASADO("Dados atrasados: a estação não envia leitura há mais de 20 minutos"),
    SEM_DADOS("Estação sem leitura disponível"),
    EM_MANUTENCAO("Estação em manutenção");

    /**
     * A API atualiza a cada 5 minutos e considera ausente a medida que não chega há 20 minutos.
     * Passando disso a leitura é tratada como atrasada.
     */
    public static final long LIMITE_ATRASO_MS = 20 * 60 * 1000L;

    private final String mensagem;

    SituacaoDados(String mensagem) {
        this.mensagem = mensagem;
    }

    /** Mensagem pronta para mostrar ao usuário. */
    public String getMensagem() {
        return mensagem;
    }
}
