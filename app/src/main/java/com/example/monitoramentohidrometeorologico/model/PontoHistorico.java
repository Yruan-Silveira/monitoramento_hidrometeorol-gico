package com.example.monitoramentohidrometeorologico.model;

import androidx.annotation.Nullable;

import java.util.Date;

/**
 * Um ponto da série histórica (um item da consulta {@code historic}).
 * Valores ausentes vêm como {@code null}. Unidades em {@link Unidades}.
 */
public class PontoHistorico {

    /** Início do bloco agrupado, horário de Brasília (HM-04: horário de medição). */
    private Date dataHora;
    private Double rioNivel;
    private Double rioVariacao;
    /** Chuva caída dentro deste bloco (mm). */
    private Double chuvaMm;
    /** Chuva acumulada desde o início da série (mm). */
    private Double chuvaTotal;
    private Double chuvaTaxaMedia;
    private Double chuvaTaxaMaxima;
    private Double temperatura;
    private Double sensacaoTermica;
    private Double umidade;
    private Double pressao;
    private Double ventoVelocidadeMedia;
    private Double ventoVelocidadeMaxima;
    private Double ventoDirecao;
    private Double radiacao;

    public Date getDataHora() { return dataHora; }
    public void setDataHora(Date dataHora) { this.dataHora = dataHora; }

    @Nullable public Double getRioNivel() { return rioNivel; }
    public void setRioNivel(Double v) { this.rioNivel = v; }

    @Nullable public Double getRioVariacao() { return rioVariacao; }
    public void setRioVariacao(Double v) { this.rioVariacao = v; }

    @Nullable public Double getChuvaMm() { return chuvaMm; }
    public void setChuvaMm(Double v) { this.chuvaMm = v; }

    @Nullable public Double getChuvaTotal() { return chuvaTotal; }
    public void setChuvaTotal(Double v) { this.chuvaTotal = v; }

    @Nullable public Double getChuvaTaxaMedia() { return chuvaTaxaMedia; }
    public void setChuvaTaxaMedia(Double v) { this.chuvaTaxaMedia = v; }

    @Nullable public Double getChuvaTaxaMaxima() { return chuvaTaxaMaxima; }
    public void setChuvaTaxaMaxima(Double v) { this.chuvaTaxaMaxima = v; }

    @Nullable public Double getTemperatura() { return temperatura; }
    public void setTemperatura(Double v) { this.temperatura = v; }

    @Nullable public Double getSensacaoTermica() { return sensacaoTermica; }
    public void setSensacaoTermica(Double v) { this.sensacaoTermica = v; }

    @Nullable public Double getUmidade() { return umidade; }
    public void setUmidade(Double v) { this.umidade = v; }

    @Nullable public Double getPressao() { return pressao; }
    public void setPressao(Double v) { this.pressao = v; }

    @Nullable public Double getVentoVelocidadeMedia() { return ventoVelocidadeMedia; }
    public void setVentoVelocidadeMedia(Double v) { this.ventoVelocidadeMedia = v; }

    @Nullable public Double getVentoVelocidadeMaxima() { return ventoVelocidadeMaxima; }
    public void setVentoVelocidadeMaxima(Double v) { this.ventoVelocidadeMaxima = v; }

    @Nullable public Double getVentoDirecao() { return ventoDirecao; }
    public void setVentoDirecao(Double v) { this.ventoDirecao = v; }

    @Nullable public Double getRadiacao() { return radiacao; }
    public void setRadiacao(Double v) { this.radiacao = v; }
}
