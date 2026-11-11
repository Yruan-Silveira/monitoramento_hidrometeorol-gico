package com.example.monitoramentohidrometeorologico.data.remote;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.net.ServerSocket;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import okio.Buffer;

/**
 * Testes de integração do cliente HTTP com uma API simulada (MockWebServer):
 * resposta normal, sem internet, API lenta, resposta vazia e erros da API.
 */
public class HidroApiClientTest {

    private MockWebServer servidor;
    private HidroApiClient cliente;

    @Before
    public void setUp() throws Exception {
        servidor = new MockWebServer();
        servidor.start();
        OkHttpClient http = new OkHttpClient.Builder()
                .readTimeout(1, TimeUnit.SECONDS)
                .callTimeout(3, TimeUnit.SECONDS)
                .build();
        cliente = new HidroApiClient(servidor.url("/graphql").toString(), http);
    }

    @After
    public void tearDown() throws Exception {
        servidor.shutdown();
    }

    private ErroDados.Tipo erroDe(ThrowingRunnable r) {
        try {
            r.run();
            fail("deveria lançar ErroDados");
            return null;
        } catch (ErroDados e) {
            return e.getTipo();
        }
    }

    interface ThrowingRunnable {
        void run() throws ErroDados;
    }

    @Test
    public void respostaNormal_eConsultaEnviadaCorretamente() throws Exception {
        servidor.enqueue(new MockResponse().setBody(ConversorJsonTest.recurso("tags_data_exemplo.json")));
        String json = cliente.buscarTagsDataJson();
        assertEquals(3, ConversorJson.converterEstacoes(json).size());

        RecordedRequest req = servidor.takeRequest();
        assertEquals("POST", req.getMethod());
        JsonObject corpo = JsonParser.parseString(req.getBody().readUtf8()).getAsJsonObject();
        assertEquals(Queries.TAGS_DATA, corpo.get("query").getAsString());
    }

    @Test
    public void historicoEnviaVariaveisNoFormatoDaApi() throws Exception {
        servidor.enqueue(new MockResponse().setBody("{\"data\":{\"historic\":{\"items\":[],\"totalCount\":0}}}"));
        // 2026-10-13 15:00 UTC = 12:00 em Brasília
        Date inicio = DatasApi.lerHorarioUtc("2026-10-13T15:00:00.000Z");
        Date fim = DatasApi.lerHorarioUtc("2026-10-13T21:00:00.000Z");
        cliente.buscarHistoricoJson("DCRS-00001", inicio, fim, IntervaloSerie.HOUR_1);

        JsonObject corpo = JsonParser.parseString(servidor.takeRequest().getBody().readUtf8()).getAsJsonObject();
        JsonObject vars = corpo.getAsJsonObject("variables");
        assertEquals("DCRS-00001", vars.get("stationCode").getAsString());
        assertEquals("2026-10-13 12:00:00", vars.get("startDate").getAsString());
        assertEquals("2026-10-13 18:00:00", vars.get("endDate").getAsString());
        assertEquals("HOUR_1", vars.get("interval").getAsString());
        assertEquals(Queries.HISTORIC, corpo.get("query").getAsString());
    }

    @Test
    public void semInternet() throws Exception {
        int portaFechada;
        try (ServerSocket s = new ServerSocket(0)) {
            portaFechada = s.getLocalPort();
        }
        HidroApiClient offline = new HidroApiClient("http://127.0.0.1:" + portaFechada + "/graphql",
                new OkHttpClient());
        assertEquals(ErroDados.Tipo.SEM_INTERNET, erroDe(offline::buscarTagsDataJson));
    }

    @Test
    public void apiLenta_viraTimeout() {
        servidor.enqueue(new MockResponse().setBody("{}").setHeadersDelay(5, TimeUnit.SECONDS));
        assertEquals(ErroDados.Tipo.TIMEOUT, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void respostaVazia() {
        servidor.enqueue(new MockResponse().setBody(""));
        assertEquals(ErroDados.Tipo.RESPOSTA_VAZIA, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void dataNula_ehRespostaVazia() {
        servidor.enqueue(new MockResponse().setBody("{\"data\":null}"));
        assertEquals(ErroDados.Tipo.RESPOSTA_VAZIA, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void servidorFora() {
        servidor.enqueue(new MockResponse().setResponseCode(503).setBody("<html>Service Unavailable</html>"));
        assertEquals(ErroDados.Tipo.SERVICO_INDISPONIVEL, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void htmlNoLugarDeJson() {
        servidor.enqueue(new MockResponse().setBody("<html>manutenção</html>"));
        assertEquals(ErroDados.Tipo.RESPOSTA_INVALIDA, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void limiteDeRequisicoes() {
        servidor.enqueue(new MockResponse().setBody(
                "{\"errors\":[{\"message\":\"ThrottlerException: Too Many Requests\"}],\"data\":null}"));
        assertEquals(ErroDados.Tipo.LIMITE_REQUISICOES, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void consultaRecusada() {
        servidor.enqueue(new MockResponse().setBody(
                "{\"errors\":[{\"message\":\"Operação bloqueada.\",\"extensions\":{\"code\":\"QUERY_NOT_ALLOWED\"}}],\"data\":null}"));
        assertEquals(ErroDados.Tipo.CONSULTA_RECUSADA, erroDe(cliente::buscarTagsDataJson));
    }

    @Test
    public void periodoInvalido_trazMensagemDaApiComAcentos() throws Exception {
        // a API real manda esta mensagem em ISO-8859-1
        String msg = "Não é possível consultar dados anteriores a 2026-08-10 20:55:06.";
        String corpo = "{\"errors\":[{\"message\":\"" + msg + "\",\"extensions\":{\"code\":\"BAD_REQUEST\"}}],\"data\":null}";
        servidor.enqueue(new MockResponse()
                .setHeader("Content-Type", "application/json; charset=utf-8")
                .setBody(new Buffer().write(corpo.getBytes(StandardCharsets.ISO_8859_1))));
        try {
            cliente.buscarHistoricoJson("DCRS-00001", new Date(0), new Date(), IntervaloSerie.HOUR_1);
            fail();
        } catch (ErroDados e) {
            assertEquals(ErroDados.Tipo.PARAMETRO_INVALIDO, e.getTipo());
            assertEquals(msg, e.getMensagemUsuario());
        }
    }

    @Test
    public void errosTemporarios() {
        assertTrue(new ErroDados(ErroDados.Tipo.SEM_INTERNET).isTemporario());
        assertTrue(new ErroDados(ErroDados.Tipo.TIMEOUT).isTemporario());
        assertTrue(!new ErroDados(ErroDados.Tipo.CONSULTA_RECUSADA).isTemporario());
    }
}
