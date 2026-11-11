package com.example.monitoramentohidrometeorologico.data.remote;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.NivelAlerta;
import com.example.monitoramentohidrometeorologico.model.PontoHistorico;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;
import com.example.monitoramentohidrometeorologico.model.SituacaoDados;
import com.example.monitoramentohidrometeorologico.model.TipoEstacao;

import org.junit.Test;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

/** Conversão de respostas reais da API (salvas em src/test/resources) para os modelos. */
public class ConversorJsonTest {

    static String recurso(String nome) throws Exception {
        try (InputStream in = ConversorJsonTest.class.getClassLoader().getResourceAsStream(nome)) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return out.toString(StandardCharsets.UTF_8.name());
        }
    }

    @Test
    public void converteEstacaoCompleta() throws Exception {
        List<Estacao> lista = ConversorJson.converterEstacoes(recurso("tags_data_exemplo.json"));
        assertEquals(3, lista.size());

        Estacao e = lista.get(0);
        assertEquals("DCRS-00001", e.getCodigo());
        assertEquals("Igrejinha", e.getNome());
        assertEquals("Metropolitana de Porto Alegre", e.getRegiao());
        assertEquals("RS - Sinos", e.getBacia());
        assertEquals("METROPOLITANA", e.getCoordenadoria());
        assertEquals(-29.5743, e.getLatitude(), 0.0001);
        assertEquals(-50.7961, e.getLongitude(), 0.0001);
        assertEquals(TipoEstacao.HIDROMETEOROLOGICA, e.getTipo());
        assertFalse(e.isEmManutencao());

        assertEquals(27.31, e.getMedicaoAtual().getRioNivel(), 0.001);
        assertEquals(35.0, e.getMedicaoAtual().getChuva24h(), 0.001);
        assertEquals(21.87, e.getMedicaoAtual().getTemperatura(), 0.001);
        assertNull(e.getMedicaoAtual().getChuva72h()); // não vem no tags_data

        // rio normal (status 0), chuva 24h = 35 mm → atenção; vale o maior
        assertEquals(NivelAlerta.NORMAL, e.getNivelRio());
        assertEquals(NivelAlerta.ATENCAO, e.getNivelChuva());
        assertEquals(NivelAlerta.ATENCAO, e.getNivelGeral());
    }

    @Test
    public void timestampEmHorarioDeBrasilia() throws Exception {
        Estacao e = ConversorJson.converterEstacoes(recurso("tags_data_exemplo.json")).get(0);
        // 2026-11-10T20:50:00.000 em Brasília (UTC-3) = 23:50 UTC
        Date esperado = DatasApi.lerHorarioUtc("2026-11-10T23:50:00.000Z");
        assertEquals(esperado, e.getMedicaoAtual().getDataHora());

        Date poucoDepois = new Date(esperado.getTime() + 10 * 60_000L);
        Date muitoDepois = new Date(esperado.getTime() + 60 * 60_000L);
        assertEquals(SituacaoDados.OK, e.getSituacaoDados(poucoDepois));
        assertEquals(SituacaoDados.ATRASADO, e.getSituacaoDados(muitoDepois));
    }

    @Test
    public void estacaoSemLeitura() throws Exception {
        Estacao e = ConversorJson.converterEstacoes(recurso("tags_data_exemplo.json")).get(1);
        assertEquals("DCRS-00060", e.getCodigo());
        assertNull(e.getMedicaoAtual().getDataHora());
        assertNull(e.getMedicaoAtual().getRioNivel());
        assertEquals(SituacaoDados.SEM_DADOS, e.getSituacaoDados());
        assertEquals(NivelAlerta.SEM_DADOS, e.getNivelRio()); // status null
    }

    @Test
    public void estacaoSemLimiarCadastrado() throws Exception {
        Estacao e = ConversorJson.converterEstacoes(recurso("tags_data_exemplo.json")).get(2);
        assertEquals("DCRS-00007", e.getCodigo());
        assertEquals("Protásio Alves - Ipê", e.getNome()); // acentos preservados
        assertFalse(e.isLimiarRioCadastrado());
        assertEquals(NivelAlerta.SEM_DADOS, e.getNivelRio());
    }

    @Test
    public void proximaAtualizacaoEmUtc() throws Exception {
        Date d = ConversorJson.lerProximaAtualizacao(recurso("tags_data_exemplo.json"));
        assertNotNull(d);
        assertEquals(DatasApi.lerHorarioUtc("2026-11-10T23:57:50.000Z"), d);
    }

    @Test
    public void historicoComCamposAusentes() throws Exception {
        // na API real alguns itens simplesmente não trazem chuva_mm
        String json = "{\"data\":{\"historic\":{\"items\":["
                + "{\"ts\":\"2026-11-10T16:00:00.000\",\"codigo\":\"DCRS-00001\",\"rio_nivel\":27.34,\"chuva_mm\":1.5},"
                + "{\"ts\":\"2026-11-10T17:00:00.000\",\"codigo\":\"DCRS-00001\",\"rio_nivel\":27.33},"
                + "{\"ts\":\"2026-11-10T18:00:00.000\",\"codigo\":\"DCRS-00001\",\"rio_nivel\":null,\"chuva_mm\":2.0}"
                + "],\"totalCount\":3}}}";
        SerieHistorica s = ConversorJson.converterSerie(json, "DCRS-00001", new Date(), new Date(),
                IntervaloSerie.HOUR_1);
        assertEquals(3, s.getPontos().size());
        PontoHistorico p2 = s.getPontos().get(1);
        assertNull(p2.getChuvaMm());
        assertNull(s.getPontos().get(2).getRioNivel());
        assertEquals(3.5, s.getChuvaAcumulada(), 0.0001);
    }

    @Test
    public void historicoVazio() throws Exception {
        String json = "{\"data\":{\"historic\":{\"items\":[],\"totalCount\":0}}}";
        SerieHistorica s = ConversorJson.converterSerie(json, "X", new Date(), new Date(), IntervaloSerie.MIN_5);
        assertTrue(s.isVazia());
        assertNull(s.getChuvaAcumulada());
    }

    @Test
    public void jsonInvalido() {
        try {
            ConversorJson.converterEstacoes("<html>erro</html>");
            fail("deveria lançar ErroDados");
        } catch (ErroDados e) {
            assertEquals(ErroDados.Tipo.RESPOSTA_INVALIDA, e.getTipo());
        }
    }
}
