package com.example.monitoramentohidrometeorologico.model;

import androidx.annotation.ColorRes;
import androidx.annotation.Nullable;

import com.example.monitoramentohidrometeorologico.R;

/**
 * Nível de alerta de uma estação (HM-01, HM-06).
 *
 * <p>Dois critérios geram um nível:
 * <ul>
 *   <li><b>Rio</b>: a API já compara o nível medido com as cotas da Defesa Civil e devolve
 *       {@code rio_alarmes.inundacao.status} (0 a 3). Ver {@link #porStatusRio(Boolean, Integer)}.</li>
 *   <li><b>Chuva</b>: o app aplica a tabela da especificação sobre a chuva acumulada
 *       (mm24, mm48, mm72). Ver {@link #porChuva(Double, Double, Double)}.</li>
 * </ul>
 * Em ambos os casos vale o <b>maior nível atingido</b>.
 */
public enum NivelAlerta {

    /** Sem leitura recente, ou estação sem limiar cadastrado. */
    SEM_DADOS(-1, "Sem dados", "Sem dados", R.color.nivel_sem_dados),
    NORMAL(0, "Normal", "Normalidade", R.color.nivel_normal),
    ATENCAO(1, "Atenção", "Atenção inundação", R.color.nivel_atencao),
    ALERTA(2, "Alerta", "Alerta inundação", R.color.nivel_alerta),
    EMERGENCIA(3, "Emergência", "Inundação", R.color.nivel_emergencia);

    /*
     * Limiares de chuva acumulada (mm) da especificação — tabela "Referência dos níveis".
     * Linha = nível (ATENÇÃO, ALERTA, EMERGÊNCIA); coluna = janela (24h, 48h, 72h).
     */
    public static final double[] LIMIAR_ATENCAO = {30, 50, 60};
    public static final double[] LIMIAR_ALERTA = {50, 70, 90};
    public static final double[] LIMIAR_EMERGENCIA = {80, 100, 120};

    private final int gravidade;
    private final String rotulo;
    private final String rotuloRio;
    @ColorRes
    private final int corRes;

    NivelAlerta(int gravidade, String rotulo, String rotuloRio, @ColorRes int corRes) {
        this.gravidade = gravidade;
        this.rotulo = rotulo;
        this.rotuloRio = rotuloRio;
        this.corRes = corRes;
    }

    /** -1 (sem dados) a 3 (emergência). Útil para ordenar estações pela gravidade. */
    public int getGravidade() {
        return gravidade;
    }

    /** Texto curto para mostrar ao usuário: "Normal", "Atenção", "Alerta", "Emergência". */
    public String getRotulo() {
        return rotulo;
    }

    /** Nome usado pela Defesa Civil para o nível do rio: "Normalidade", "Atenção inundação"... */
    public String getRotuloRio() {
        return rotuloRio;
    }

    /** Cor do nível (res/values/colors.xml). Use {@code ContextCompat.getColor(ctx, nivel.getCorRes())}. */
    @ColorRes
    public int getCorRes() {
        return corRes;
    }

    public boolean maisGraveQue(NivelAlerta outro) {
        return outro == null || this.gravidade > outro.gravidade;
    }

    /** Devolve o mais grave dos dois (regra "vale o maior nível atingido"). */
    public static NivelAlerta maior(@Nullable NivelAlerta a, @Nullable NivelAlerta b) {
        if (a == null) return b == null ? SEM_DADOS : b;
        if (b == null) return a;
        return a.gravidade >= b.gravidade ? a : b;
    }

    /**
     * Nível do rio a partir de {@code rio_alarmes.inundacao} da API.
     *
     * @param ativo  {@code false} = estação sem limiar cadastrado
     * @param status 0 normalidade, 1 atenção, 2 alerta, 3 inundação, {@code null} = sem leitura recente
     */
    public static NivelAlerta porStatusRio(@Nullable Boolean ativo, @Nullable Integer status) {
        if (ativo == null || !ativo || status == null) return SEM_DADOS;
        switch (status) {
            case 0: return NORMAL;
            case 1: return ATENCAO;
            case 2: return ALERTA;
            case 3: return EMERGENCIA;
            default: return SEM_DADOS;
        }
    }

    /**
     * Nível pela chuva acumulada. Qualquer condição verdadeira ativa o nível e vale o maior.
     * Valores {@code null} são ignorados; se os três forem nulos, devolve {@link #SEM_DADOS}.
     */
    public static NivelAlerta porChuva(@Nullable Double mm24, @Nullable Double mm48, @Nullable Double mm72) {
        if (mm24 == null && mm48 == null && mm72 == null) return SEM_DADOS;
        if (atinge(LIMIAR_EMERGENCIA, mm24, mm48, mm72)) return EMERGENCIA;
        if (atinge(LIMIAR_ALERTA, mm24, mm48, mm72)) return ALERTA;
        if (atinge(LIMIAR_ATENCAO, mm24, mm48, mm72)) return ATENCAO;
        return NORMAL;
    }

    private static boolean atinge(double[] limiar, Double mm24, Double mm48, Double mm72) {
        return (mm24 != null && mm24 >= limiar[0])
                || (mm48 != null && mm48 >= limiar[1])
                || (mm72 != null && mm72 >= limiar[2]);
    }
}
