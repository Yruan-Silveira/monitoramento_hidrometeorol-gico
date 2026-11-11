package com.example.monitoramentohidrometeorologico.model;

import androidx.annotation.Nullable;

import java.util.Date;

/**
 * Leitura mais recente de uma estação (HM-03), vinda da consulta {@code tags_data}.
 *
 * <p>Todo valor numérico é {@code Double} e pode ser {@code null}: a API devolve
 * {@code value: null} quando a estação não mandou a medida nos últimos 20 minutos ou não
 * possui o sensor. A tela deve mostrar "—" nesses casos.
 * Unidades em {@link Unidades}.
 */
public class Medicao {

    /** Início do bloco de 5 minutos da leitura (horário de Brasília convertido para Date). */
    private Date dataHora;

    // Rio (m)
    private Double rioNivel;
    /** Valor atual menos a média da última hora: positivo subindo, negativo descendo. */
    private Double rioTendencia;
    private boolean rioHomologado = true;

    // Chuva acumulada (mm)
    private Double chuva5min;
    private Double chuva1h;
    private Double chuva3h;
    private Double chuva6h;
    private Double chuva12h;
    private Double chuva24h;
    private Double chuva48h;
    /**
     * Não vem no tags_data: o repositório calcula somando a série histórica das últimas 72h.
     * Preenchido em {@code buscarEstacao}; na lista de estações fica {@code null}.
     */
    private Double chuva72h;
    private Double chuva168h;
    private boolean chuvaHomologada = true;

    // Tempo
    private Double temperatura;
    private Double temperaturaMaximaDia;
    private Double temperaturaMinimaDia;
    private Double sensacaoTermica;
    private Double umidade;
    private Double pressao;
    private Double ventoVelocidadeMedia;
    private Double ventoVelocidadeMaxima;
    /** Graus, 0 = norte. */
    private Double ventoDirecao;
    private Double radiacaoSolar;

    @Nullable public Date getDataHora() { return dataHora; }
    public void setDataHora(Date dataHora) { this.dataHora = dataHora; }

    @Nullable public Double getRioNivel() { return rioNivel; }
    public void setRioNivel(Double rioNivel) { this.rioNivel = rioNivel; }

    @Nullable public Double getRioTendencia() { return rioTendencia; }
    public void setRioTendencia(Double rioTendencia) { this.rioTendencia = rioTendencia; }

    /** {@code false} indica sensor de rio com dado não homologado. */
    public boolean isRioHomologado() { return rioHomologado; }
    public void setRioHomologado(boolean rioHomologado) { this.rioHomologado = rioHomologado; }

    @Nullable public Double getChuva5min() { return chuva5min; }
    public void setChuva5min(Double chuva5min) { this.chuva5min = chuva5min; }

    @Nullable public Double getChuva1h() { return chuva1h; }
    public void setChuva1h(Double chuva1h) { this.chuva1h = chuva1h; }

    @Nullable public Double getChuva3h() { return chuva3h; }
    public void setChuva3h(Double chuva3h) { this.chuva3h = chuva3h; }

    @Nullable public Double getChuva6h() { return chuva6h; }
    public void setChuva6h(Double chuva6h) { this.chuva6h = chuva6h; }

    @Nullable public Double getChuva12h() { return chuva12h; }
    public void setChuva12h(Double chuva12h) { this.chuva12h = chuva12h; }

    @Nullable public Double getChuva24h() { return chuva24h; }
    public void setChuva24h(Double chuva24h) { this.chuva24h = chuva24h; }

    @Nullable public Double getChuva48h() { return chuva48h; }
    public void setChuva48h(Double chuva48h) { this.chuva48h = chuva48h; }

    @Nullable public Double getChuva72h() { return chuva72h; }
    public void setChuva72h(Double chuva72h) { this.chuva72h = chuva72h; }

    @Nullable public Double getChuva168h() { return chuva168h; }
    public void setChuva168h(Double chuva168h) { this.chuva168h = chuva168h; }

    /** {@code false} indica pluviômetro com dado não homologado. */
    public boolean isChuvaHomologada() { return chuvaHomologada; }
    public void setChuvaHomologada(boolean chuvaHomologada) { this.chuvaHomologada = chuvaHomologada; }

    @Nullable public Double getTemperatura() { return temperatura; }
    public void setTemperatura(Double temperatura) { this.temperatura = temperatura; }

    @Nullable public Double getTemperaturaMaximaDia() { return temperaturaMaximaDia; }
    public void setTemperaturaMaximaDia(Double v) { this.temperaturaMaximaDia = v; }

    @Nullable public Double getTemperaturaMinimaDia() { return temperaturaMinimaDia; }
    public void setTemperaturaMinimaDia(Double v) { this.temperaturaMinimaDia = v; }

    @Nullable public Double getSensacaoTermica() { return sensacaoTermica; }
    public void setSensacaoTermica(Double sensacaoTermica) { this.sensacaoTermica = sensacaoTermica; }

    @Nullable public Double getUmidade() { return umidade; }
    public void setUmidade(Double umidade) { this.umidade = umidade; }

    @Nullable public Double getPressao() { return pressao; }
    public void setPressao(Double pressao) { this.pressao = pressao; }

    @Nullable public Double getVentoVelocidadeMedia() { return ventoVelocidadeMedia; }
    public void setVentoVelocidadeMedia(Double v) { this.ventoVelocidadeMedia = v; }

    @Nullable public Double getVentoVelocidadeMaxima() { return ventoVelocidadeMaxima; }
    public void setVentoVelocidadeMaxima(Double v) { this.ventoVelocidadeMaxima = v; }

    @Nullable public Double getVentoDirecao() { return ventoDirecao; }
    public void setVentoDirecao(Double ventoDirecao) { this.ventoDirecao = ventoDirecao; }

    @Nullable public Double getRadiacaoSolar() { return radiacaoSolar; }
    public void setRadiacaoSolar(Double radiacaoSolar) { this.radiacaoSolar = radiacaoSolar; }
}
