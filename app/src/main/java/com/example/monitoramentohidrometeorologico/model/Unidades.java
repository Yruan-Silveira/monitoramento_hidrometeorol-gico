package com.example.monitoramentohidrometeorologico.model;

/** Unidades de cada métrica, conforme o dicionário da API (HM-04: identificação de unidades). */
public final class Unidades {
    public static final String NIVEL_RIO = "m";
    public static final String CHUVA = "mm";
    public static final String INTENSIDADE_CHUVA = "mm/h";
    public static final String TEMPERATURA = "°C";
    public static final String UMIDADE = "%";
    public static final String PRESSAO = "hPa";
    public static final String VENTO = "km/h";
    public static final String DIRECAO_VENTO = "°";
    public static final String RADIACAO = "W/m²";

    private Unidades() {
    }
}
