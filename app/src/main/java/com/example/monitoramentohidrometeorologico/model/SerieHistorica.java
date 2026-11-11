package com.example.monitoramentohidrometeorologico.model;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * Série histórica de uma estação num período (HM-04). Pontos em ordem cronológica.
 */
public class SerieHistorica {

    private final String codigoEstacao;
    private final Date inicio;
    private final Date fim;
    private final IntervaloSerie intervalo;
    private final List<PontoHistorico> pontos;

    public SerieHistorica(String codigoEstacao, Date inicio, Date fim, IntervaloSerie intervalo,
                          List<PontoHistorico> pontos) {
        this.codigoEstacao = codigoEstacao;
        this.inicio = inicio;
        this.fim = fim;
        this.intervalo = intervalo;
        this.pontos = pontos == null ? new ArrayList<>() : pontos;
    }

    public String getCodigoEstacao() { return codigoEstacao; }
    public Date getInicio() { return inicio; }
    public Date getFim() { return fim; }
    public IntervaloSerie getIntervalo() { return intervalo; }

    @NonNull
    public List<PontoHistorico> getPontos() {
        return Collections.unmodifiableList(pontos);
    }

    public boolean isVazia() {
        return pontos.isEmpty();
    }

    /** Soma da chuva de todos os pontos (mm), ou {@code null} se nenhum ponto tem chuva. */
    @Nullable
    public Double getChuvaAcumulada() {
        double soma = 0;
        boolean temValor = false;
        for (PontoHistorico p : pontos) {
            if (p.getChuvaMm() != null) {
                soma += p.getChuvaMm();
                temValor = true;
            }
        }
        return temValor ? soma : null;
    }
}
