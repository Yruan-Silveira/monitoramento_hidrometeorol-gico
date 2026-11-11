package com.example.monitoramentohidrometeorologico.model;

/**
 * Tipo da estação (HM-02, filtro do HM-05).
 *
 * <p>A API marca todas as estações como "HidroMeteo"; o tipo real é deduzido dos sensores
 * que cada uma possui ({@code filter.relacao.tem_nivel_do_rio}, {@code tem_chuva_acumulada}...).
 */
public enum TipoEstacao {
    /** Mede só o nível do rio. */
    FLUVIOMETRICA("Fluviométrica"),
    /** Mede só chuva e/ou variáveis do tempo. */
    METEOROLOGICA("Meteorológica"),
    /** Mede rio e chuva. */
    HIDROMETEOROLOGICA("Hidrometeorológica");

    private final String rotulo;

    TipoEstacao(String rotulo) {
        this.rotulo = rotulo;
    }

    public String getRotulo() {
        return rotulo;
    }

    public static TipoEstacao de(boolean temNivelRio, boolean temMeteorologia) {
        if (temNivelRio && temMeteorologia) return HIDROMETEOROLOGICA;
        if (temNivelRio) return FLUVIOMETRICA;
        return METEOROLOGICA;
    }
}
