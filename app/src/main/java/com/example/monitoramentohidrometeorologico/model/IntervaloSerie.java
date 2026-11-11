package com.example.monitoramentohidrometeorologico.model;

/**
 * Agrupamento dos pontos da série histórica (variável {@code interval} da consulta historic).
 * O nome da constante é exatamente o valor enviado à API.
 */
public enum IntervaloSerie {
    MIN_5("5 minutos", 5),
    MIN_10("10 minutos", 10),
    HOUR_1("1 hora", 60),
    HOUR_3("3 horas", 180),
    HOUR_6("6 horas", 360),
    HOUR_12("12 horas", 720);

    private final String rotulo;
    private final int minutos;

    IntervaloSerie(String rotulo, int minutos) {
        this.rotulo = rotulo;
        this.minutos = minutos;
    }

    public String getRotulo() {
        return rotulo;
    }

    public int getMinutos() {
        return minutos;
    }

    /**
     * Sugere um intervalo que dá no máximo ~300 pontos para o período.
     * Evita pedir 3 meses em blocos de 5 minutos (mais de 25 mil pontos).
     */
    public static IntervaloSerie sugerirPara(long duracaoMs) {
        long horas = duracaoMs / (60 * 60 * 1000L);
        if (horas <= 6) return MIN_5;
        if (horas <= 24) return MIN_10;
        if (horas <= 24 * 7) return HOUR_1;
        if (horas <= 24 * 30) return HOUR_3;
        if (horas <= 24 * 60) return HOUR_6;
        return HOUR_12;
    }
}
