package com.example.monitoramentohidrometeorologico.data.remote;

import androidx.annotation.NonNull;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;

import java.io.IOException;
import java.io.InterruptedIOException;
import java.net.ConnectException;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.SSLException;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;

/**
 * Cliente HTTP da API GraphQL da Defesa Civil RS (HM-02, HM-03, HM-04).
 *
 * <p>Métodos <b>síncronos</b>: bloqueiam até a resposta. Nunca chame na thread principal;
 * o repositório já cuida disso. Devolvem o JSON bruto (texto) para poder ser guardado no cache;
 * a conversão para os modelos fica em {@link ConversorJson}.
 *
 * <p>Toda falha vira {@link ErroDados} com um {@link ErroDados.Tipo} definido.
 */
public class HidroApiClient {

    /** Endereço de produção. Sempre HTTPS. */
    public static final String URL_PRODUCAO = "https://redehidrometeorologica.defesacivil.rs.gov.br/graphql";

    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final String url;
    private final OkHttpClient http;

    public HidroApiClient() {
        this(URL_PRODUCAO, criarHttpPadrao());
    }

    /** Construtor usado nos testes (MockWebServer) para apontar para outro endereço. */
    public HidroApiClient(@NonNull String url, @NonNull OkHttpClient http) {
        this.url = url;
        this.http = http;
    }

    public static OkHttpClient criarHttpPadrao() {
        return new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)   // a resposta de tags_data tem ~300 KB
                .writeTimeout(15, TimeUnit.SECONDS)
                .callTimeout(45, TimeUnit.SECONDS)
                .retryOnConnectionFailure(true)
                .build();
    }

    /** Consulta {@code tags_data}: leitura mais recente das ~130 estações. */
    @NonNull
    public String buscarTagsDataJson() throws ErroDados {
        JsonObject corpo = new JsonObject();
        corpo.addProperty("query", Queries.TAGS_DATA);
        return executar(corpo, "tags_data");
    }

    /** Consulta {@code historic}: série de uma estação. Período máximo: últimos 3 meses. */
    @NonNull
    public String buscarHistoricoJson(@NonNull String codigoEstacao, @NonNull Date inicio,
                                      @NonNull Date fim, @NonNull IntervaloSerie intervalo)
            throws ErroDados {
        JsonObject variaveis = new JsonObject();
        variaveis.addProperty("stationCode", codigoEstacao);
        variaveis.addProperty("startDate", DatasApi.formatarParaApi(inicio));
        variaveis.addProperty("endDate", DatasApi.formatarParaApi(fim));
        variaveis.addProperty("interval", intervalo.name());

        JsonObject corpo = new JsonObject();
        corpo.addProperty("query", Queries.HISTORIC);
        corpo.add("variables", variaveis);
        return executar(corpo, "historic");
    }

    // ------------------------------------------------------------------------------ interno

    private String executar(JsonObject corpo, String campoEsperado) throws ErroDados {
        Request request = new Request.Builder()
                .url(url)
                .post(RequestBody.create(corpo.toString(), JSON))
                .header("Accept", "application/json")
                .build();

        String texto;
        int codigoHttp;
        try (Response response = http.newCall(request).execute()) {
            codigoHttp = response.code();
            ResponseBody body = response.body();
            texto = body == null ? "" : decodificar(body.bytes());
        } catch (UnknownHostException | ConnectException e) {
            throw new ErroDados(ErroDados.Tipo.SEM_INTERNET, null, e);
        } catch (InterruptedIOException e) {
            // inclui SocketTimeoutException e o callTimeout do OkHttp
            throw new ErroDados(ErroDados.Tipo.TIMEOUT, null, e);
        } catch (SSLException e) {
            throw new ErroDados(ErroDados.Tipo.SERVICO_INDISPONIVEL,
                    "Falha na conexão segura (HTTPS) com o serviço.", e);
        } catch (IOException e) {
            throw new ErroDados(ErroDados.Tipo.SEM_INTERNET,
                    "Não foi possível conectar ao serviço.", e);
        }

        verificarResposta(codigoHttp, texto, campoEsperado);
        return texto;
    }

    /**
     * Verifica status HTTP, corpo vazio, JSON inválido e o bloco "errors" do GraphQL.
     * Estático para ser testado sem rede.
     */
    static void verificarResposta(int codigoHttp, String texto, String campoEsperado)
            throws ErroDados {
        if (codigoHttp == 429 || texto.contains("Too Many Requests")) {
            throw new ErroDados(ErroDados.Tipo.LIMITE_REQUISICOES);
        }
        if (codigoHttp >= 500) {
            throw new ErroDados(ErroDados.Tipo.SERVICO_INDISPONIVEL,
                    "Serviço de dados indisponível no momento (HTTP " + codigoHttp + ").");
        }
        if (texto.trim().isEmpty()) {
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_VAZIA);
        }

        JsonObject raiz;
        try {
            JsonElement el = JsonParser.parseString(texto);
            if (!el.isJsonObject()) throw new ErroDados(ErroDados.Tipo.RESPOSTA_INVALIDA);
            raiz = el.getAsJsonObject();
        } catch (JsonParseException | IllegalStateException e) {
            // ex.: página HTML de erro do servidor no lugar do JSON
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_INVALIDA, null, e);
        }

        if (raiz.has("errors") && raiz.get("errors").isJsonArray()) {
            JsonArray erros = raiz.getAsJsonArray("errors");
            if (erros.size() > 0) throw erroGraphQl(erros.get(0));
        }
        if (codigoHttp >= 400) {
            throw new ErroDados(ErroDados.Tipo.DESCONHECIDO, "Erro HTTP " + codigoHttp + ".");
        }

        JsonElement data = raiz.get("data");
        if (data == null || !data.isJsonObject()
                || data.getAsJsonObject().get(campoEsperado) == null
                || data.getAsJsonObject().get(campoEsperado).isJsonNull()) {
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_VAZIA);
        }
    }

    private static ErroDados erroGraphQl(JsonElement erro) {
        String mensagem = null;
        String codigo = null;
        if (erro.isJsonObject()) {
            JsonObject o = erro.getAsJsonObject();
            if (o.has("message") && o.get("message").isJsonPrimitive()) {
                mensagem = o.get("message").getAsString();
            }
            JsonElement ext = o.get("extensions");
            if (ext != null && ext.isJsonObject() && ext.getAsJsonObject().has("code")) {
                codigo = ext.getAsJsonObject().get("code").getAsString();
            }
        }
        if (mensagem != null && mensagem.contains("Too Many Requests")) {
            return new ErroDados(ErroDados.Tipo.LIMITE_REQUISICOES);
        }
        if (codigo == null) return new ErroDados(ErroDados.Tipo.DESCONHECIDO, mensagem);
        switch (codigo) {
            case "QUERY_NOT_ALLOWED":
            case "GRAPHQL_VALIDATION_FAILED":
                return new ErroDados(ErroDados.Tipo.CONSULTA_RECUSADA);
            case "FORBIDDEN":
            case "UNAUTHENTICATED":
                return new ErroDados(ErroDados.Tipo.ACESSO_NEGADO);
            case "BAD_REQUEST":
                // a mensagem da API explica o problema (ex.: data mínima aceita)
                return new ErroDados(ErroDados.Tipo.PARAMETRO_INVALIDO, mensagem);
            default:
                return new ErroDados(ErroDados.Tipo.DESCONHECIDO, mensagem);
        }
    }

    /**
     * A API às vezes envia mensagens de erro em ISO-8859-1 dizendo que é UTF-8
     * (acentos viravam "N�o"). Tenta UTF-8 e, se for inválido, usa ISO-8859-1.
     */
    static String decodificar(byte[] bytes) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes))
                    .toString();
        } catch (CharacterCodingException e) {
            return new String(bytes, StandardCharsets.ISO_8859_1);
        }
    }
}
