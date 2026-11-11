package com.example.monitoramentohidrometeorologico.model;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/** Tabela de níveis da especificação (chuva acumulada; vale o maior nível atingido). */
public class NivelAlertaTest {

    @Test
    public void semChuvaRelevante_ehNormal() {
        assertEquals(NivelAlerta.NORMAL, NivelAlerta.porChuva(0.0, 0.0, 0.0));
        assertEquals(NivelAlerta.NORMAL, NivelAlerta.porChuva(29.9, 49.9, 59.9));
    }

    @Test
    public void limiaresDeAtencao_saoInclusivos() {
        assertEquals(NivelAlerta.ATENCAO, NivelAlerta.porChuva(30.0, 0.0, 0.0));
        assertEquals(NivelAlerta.ATENCAO, NivelAlerta.porChuva(0.0, 50.0, 0.0));
        assertEquals(NivelAlerta.ATENCAO, NivelAlerta.porChuva(0.0, 0.0, 60.0));
    }

    @Test
    public void limiaresDeAlerta() {
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.porChuva(50.0, 0.0, 0.0));
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.porChuva(0.0, 70.0, 0.0));
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.porChuva(0.0, 0.0, 90.0));
    }

    @Test
    public void limiaresDeEmergencia() {
        assertEquals(NivelAlerta.EMERGENCIA, NivelAlerta.porChuva(80.0, 0.0, 0.0));
        assertEquals(NivelAlerta.EMERGENCIA, NivelAlerta.porChuva(0.0, 100.0, 0.0));
        assertEquals(NivelAlerta.EMERGENCIA, NivelAlerta.porChuva(0.0, 0.0, 120.0));
    }

    @Test
    public void valeOMaiorNivelAtingido() {
        // mm24 dá atenção, mm72 dá emergência → emergência
        assertEquals(NivelAlerta.EMERGENCIA, NivelAlerta.porChuva(31.0, 10.0, 125.0));
    }

    @Test
    public void valoresNulosSaoIgnorados() {
        assertEquals(NivelAlerta.SEM_DADOS, NivelAlerta.porChuva(null, null, null));
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.porChuva(null, 75.0, null));
        // sem mm72 (lista de estações), decide só com mm24 e mm48
        assertEquals(NivelAlerta.NORMAL, NivelAlerta.porChuva(10.0, 20.0, null));
    }

    @Test
    public void statusDoRio() {
        assertEquals(NivelAlerta.NORMAL, NivelAlerta.porStatusRio(true, 0));
        assertEquals(NivelAlerta.ATENCAO, NivelAlerta.porStatusRio(true, 1));
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.porStatusRio(true, 2));
        assertEquals(NivelAlerta.EMERGENCIA, NivelAlerta.porStatusRio(true, 3));
        assertEquals(NivelAlerta.SEM_DADOS, NivelAlerta.porStatusRio(true, null));   // sem leitura recente
        assertEquals(NivelAlerta.SEM_DADOS, NivelAlerta.porStatusRio(false, 0));     // sem limiar cadastrado
    }

    @Test
    public void maiorEGravidade() {
        assertEquals(NivelAlerta.ALERTA, NivelAlerta.maior(NivelAlerta.ATENCAO, NivelAlerta.ALERTA));
        assertEquals(NivelAlerta.NORMAL, NivelAlerta.maior(NivelAlerta.SEM_DADOS, NivelAlerta.NORMAL));
        assertTrue(NivelAlerta.EMERGENCIA.maisGraveQue(NivelAlerta.ALERTA));
        assertFalse(NivelAlerta.ATENCAO.maisGraveQue(NivelAlerta.ATENCAO));
    }

    @Test
    public void sugestaoDeIntervalo() {
        long hora = 3600_000L;
        assertEquals(IntervaloSerie.MIN_5, IntervaloSerie.sugerirPara(6 * hora));
        assertEquals(IntervaloSerie.HOUR_1, IntervaloSerie.sugerirPara(72 * hora));
        assertEquals(IntervaloSerie.HOUR_12, IntervaloSerie.sugerirPara(90 * 24 * hora));
    }
}
