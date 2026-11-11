package com.example.monitoramentohidrometeorologico.data.remote;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;

import org.junit.Assume;
import org.junit.Test;

import java.util.Date;
import java.util.List;

/**
 * Teste de integração com a API REAL da Defesa Civil RS.
 * Confirma que as consultas continuam aceitas e que a estação de teste DCRS-00001 traz dados
 * (critério de aceite 1). Sem internet o teste é ignorado em vez de falhar.
 */
public class ApiRealIntegracaoTest {

    private final HidroApiClient api = new HidroApiClient();

    private String chamar(Chamada c) throws ErroDados {
        try {
            return c.executar();
        } catch (ErroDados e) {
            Assume.assumeFalse("Sem internet: teste ignorado",
                    e.getTipo() == ErroDados.Tipo.SEM_INTERNET || e.getTipo() == ErroDados.Tipo.TIMEOUT);
            throw e;
        }
    }

    interface Chamada {
        String executar() throws ErroDados;
    }

    @Test
    public void tagsData_trazEstacaoDeTeste() throws Exception {
        String json = chamar(api::buscarTagsDataJson);
        List<Estacao> estacoes = ConversorJson.converterEstacoes(json);
        assertTrue("esperado ~130 estações", estacoes.size() > 50);

        Estacao teste = null;
        for (Estacao e : estacoes) if ("DCRS-00001".equals(e.getCodigo())) teste = e;
        assertNotNull("estação de teste DCRS-00001", teste);
        assertNotNull("horário da leitura", teste.getMedicaoAtual().getDataHora());
        assertNotNull(ConversorJson.lerProximaAtualizacao(json));
    }

    @Test
    public void historic_ultimas6Horas() throws Exception {
        Date fim = new Date();
        Date inicio = new Date(fim.getTime() - 6 * 3600_000L);
        String json = chamar(() -> api.buscarHistoricoJson("DCRS-00001", inicio, fim, IntervaloSerie.HOUR_1));
        SerieHistorica s = ConversorJson.converterSerie(json, "DCRS-00001", inicio, fim, IntervaloSerie.HOUR_1);
        assertFalse(s.isVazia());
        assertNotNull(s.getPontos().get(0).getDataHora());
    }

    @Test
    public void historic_maisDe3Meses_ehRecusado() throws Exception {
        Date fim = new Date();
        Date inicio = new Date(fim.getTime() - 120L * 24 * 3600_000L);
        try {
            chamar(() -> api.buscarHistoricoJson("DCRS-00001", inicio, fim, IntervaloSerie.HOUR_12));
            throw new AssertionError("a API deveria recusar");
        } catch (ErroDados e) {
            assertEquals(ErroDados.Tipo.PARAMETRO_INVALIDO, e.getTipo());
        }
    }
}
