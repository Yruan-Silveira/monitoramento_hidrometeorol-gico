package com.example.monitoramentohidrometeorologico.data;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.monitoramentohidrometeorologico.data.local.CacheEstacoes;
import com.example.monitoramentohidrometeorologico.data.local.FavoritosStore;
import com.example.monitoramentohidrometeorologico.data.remote.ConversorJson;
import com.example.monitoramentohidrometeorologico.data.remote.DatasApi;
import com.example.monitoramentohidrometeorologico.data.remote.HidroApiClient;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;

import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Set;

/**
 * Implementação REAL do {@link EstacaoRepository} (Pessoa A): API + cache + favoritos.
 *
 * <p>Além dos métodos assíncronos do contrato, oferece versões {@code ...Sync} que bloqueiam
 * a thread — usadas pelo {@code VerificacaoAlertasWorker}, que já roda em segundo plano.
 */
public class RemoteEstacaoRepository implements EstacaoRepository {

    private static final String TAG = "RemoteEstacaoRepo";

    /** A API atualiza a cada 5 minutos. */
    private static final long VALIDADE_PADRAO_MS = 5 * 60 * 1000L;
    /** Margem de segurança no limite de 3 meses do histórico. */
    private static final long MARGEM_HISTORICO_MS = 5 * 60 * 1000L;

    private static volatile RemoteEstacaoRepository instancia;

    private final HidroApiClient api;
    private final CacheEstacoes cache;
    private final FavoritosStore favoritos;

    private final Object trava = new Object();
    private ResultadoEstacoes emMemoria;
    private long validoAteMs;

    public static RemoteEstacaoRepository getInstance(Context context) {
        if (instancia == null) {
            synchronized (RemoteEstacaoRepository.class) {
                if (instancia == null) {
                    instancia = new RemoteEstacaoRepository(new HidroApiClient(),
                            new CacheEstacoes(context), new FavoritosStore(context),
                            context.getApplicationContext());
                }
            }
        }
        return instancia;
    }

    private final Context appContext;

    RemoteEstacaoRepository(HidroApiClient api, CacheEstacoes cache, FavoritosStore favoritos,
                            @Nullable Context appContext) {
        this.api = api;
        this.cache = cache;
        this.favoritos = favoritos;
        this.appContext = appContext;
    }

    /**
     * Sem rede, falha na hora em vez de esperar o timeout do DNS (que pode passar de 40 s)
     * — assim a tela cai no cache imediatamente.
     */
    private void exigirRede() throws ErroDados {
        if (appContext == null) return;
        ConnectivityManager cm = (ConnectivityManager) appContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        if (cm == null) return;
        Network rede = cm.getActiveNetwork();
        NetworkCapabilities cap = rede == null ? null : cm.getNetworkCapabilities(rede);
        if (cap == null || !cap.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
            throw new ErroDados(ErroDados.Tipo.SEM_INTERNET);
        }
    }

    // ================================================================ contrato (assíncrono)

    @Override
    public void listarEstacoes(boolean forcarAtualizacao, @NonNull Callback<ResultadoEstacoes> callback) {
        TarefaAsync.executar(() -> listarEstacoesSync(forcarAtualizacao), callback);
    }

    @Override
    public void buscarEstacao(@NonNull String codigo, @NonNull Callback<Estacao> callback) {
        TarefaAsync.executar(() -> buscarEstacaoSync(codigo), callback);
    }

    @Override
    public void buscarSerieHistorica(@NonNull String codigo, @NonNull Date inicio, @NonNull Date fim,
                                     @NonNull IntervaloSerie intervalo,
                                     @NonNull Callback<SerieHistorica> callback) {
        TarefaAsync.executar(() -> buscarSerieHistoricaSync(codigo, inicio, fim, intervalo), callback);
    }

    @NonNull
    @Override
    public Set<String> getFavoritos() {
        return favoritos.getTodos();
    }

    @Override
    public boolean isFavorita(@NonNull String codigo) {
        return favoritos.contem(codigo);
    }

    @Override
    public void setFavorita(@NonNull String codigo, boolean favorita) {
        favoritos.definir(codigo, favorita);
    }

    // ===================================================================== versões síncronas

    /**
     * Lista as estações. Ordem de tentativa:
     * <ol>
     *   <li>memória, se ainda não há dado novo na API (e não foi pedido forçar);</li>
     *   <li>cache em disco recente (app acabou de abrir);</li>
     *   <li>API — e guarda no cache;</li>
     *   <li>se a API falhar: cache antigo, marcado com {@code doCache=true} e o motivo.</li>
     * </ol>
     * Só lança {@link ErroDados} se a API falhar e não houver nenhum cache.
     */
    @NonNull
    public ResultadoEstacoes listarEstacoesSync(boolean forcarAtualizacao) throws ErroDados {
        synchronized (trava) {
            long agora = System.currentTimeMillis();

            if (!forcarAtualizacao && emMemoria != null && !emMemoria.isDoCache() && agora < validoAteMs) {
                return emMemoria;
            }
            if (!forcarAtualizacao && emMemoria == null) {
                ResultadoEstacoes doDisco = lerCache(null);
                if (doDisco != null && agora - cache.getAtualizadoEmMs() < VALIDADE_PADRAO_MS) {
                    guardarEmMemoria(doDisco, agora);
                    return emMemoria;
                }
            }

            try {
                exigirRede();
                String json = api.buscarTagsDataJson();
                List<Estacao> estacoes = ConversorJson.converterEstacoes(json);
                if (estacoes.isEmpty()) throw new ErroDados(ErroDados.Tipo.RESPOSTA_VAZIA);
                Date proxima = ConversorJson.lerProximaAtualizacao(json);
                cache.salvar(json, agora);
                guardarEmMemoria(new ResultadoEstacoes(estacoes, new Date(agora), proxima, false, null), agora);
                return emMemoria;
            } catch (ErroDados erro) {
                Log.w(TAG, "API falhou, tentando cache: " + erro.getMessage());
                ResultadoEstacoes doCache = lerCache(erro);
                if (doCache == null) throw erro;
                emMemoria = doCache;
                return doCache;
            }
        }
    }

    /** Estação com leitura atual e chuva de 72h calculada pelo histórico. */
    @NonNull
    public Estacao buscarEstacaoSync(@NonNull String codigo) throws ErroDados {
        Estacao estacao = encontrar(listarEstacoesSync(false).getEstacoes(), codigo);
        if (estacao == null) throw new ErroDados(ErroDados.Tipo.ESTACAO_NAO_ENCONTRADA);
        if (estacao.isTemChuva()) {
            try {
                estacao.getMedicaoAtual().setChuva72h(buscarChuvaAcumuladaSync(codigo, 72));
            } catch (ErroDados e) {
                // sem o mm72 o nível de chuva usa só mm24 e mm48; não impede mostrar a estação
                Log.w(TAG, "Não foi possível calcular chuva 72h de " + codigo + ": " + e.getMessage());
            }
        }
        return estacao;
    }

    /**
     * Chuva acumulada nas últimas {@code horas} horas, somando a série histórica em blocos
     * de 1 hora. É assim que se obtém o mm72, que o tags_data não fornece.
     * Conferido: a soma bate com os acumulados h024/h048/h168 da própria API.
     */
    @Nullable
    public Double buscarChuvaAcumuladaSync(@NonNull String codigo, int horas) throws ErroDados {
        Date fim = new Date();
        Date inicio = new Date(fim.getTime() - horas * 60L * 60L * 1000L);
        return buscarSerieHistoricaSync(codigo, inicio, fim, IntervaloSerie.HOUR_1).getChuvaAcumulada();
    }

    @NonNull
    public SerieHistorica buscarSerieHistoricaSync(@NonNull String codigo, @NonNull Date inicio,
                                                   @NonNull Date fim, @NonNull IntervaloSerie intervalo)
            throws ErroDados {
        Date agora = new Date();
        Date fimAjustado = fim.after(agora) ? agora : fim;
        Date limite = limiteHistorico(agora);
        // a tela pode pedir "3 meses" exatos: ajusta para dentro do limite em vez de falhar
        Date inicioAjustado = inicio.before(limite) ? limite : inicio;
        if (!inicioAjustado.before(fimAjustado)) {
            throw new ErroDados(ErroDados.Tipo.PARAMETRO_INVALIDO,
                    "Período inválido: a data inicial deve ser anterior à final e estar nos últimos 3 meses.");
        }
        exigirRede();
        String json = api.buscarHistoricoJson(codigo, inicioAjustado, fimAjustado, intervalo);
        return ConversorJson.converterSerie(json, codigo, inicioAjustado, fimAjustado, intervalo);
    }

    /** Data mais antiga aceita pela consulta historic (3 meses atrás + margem). */
    public static Date limiteHistorico(Date agora) {
        Calendar c = Calendar.getInstance(DatasApi.FUSO_BRASILIA);
        c.setTime(agora);
        c.add(Calendar.MONTH, -3);
        return new Date(c.getTimeInMillis() + MARGEM_HISTORICO_MS);
    }

    // ============================================================================== interno

    private void guardarEmMemoria(ResultadoEstacoes r, long agora) {
        emMemoria = r;
        long ate = agora + VALIDADE_PADRAO_MS;
        Date proxima = r.getProximaAtualizacao();
        // usa proximaAtualizacaoEm da API se for coerente (entre agora e 10 min)
        if (proxima != null && proxima.getTime() > agora && proxima.getTime() < agora + 2 * VALIDADE_PADRAO_MS) {
            ate = proxima.getTime();
        }
        validoAteMs = ate;
    }

    @Nullable
    private ResultadoEstacoes lerCache(@Nullable ErroDados motivo) {
        String json = cache.lerJson();
        if (json == null) return null;
        try {
            List<Estacao> estacoes = ConversorJson.converterEstacoes(json);
            return new ResultadoEstacoes(estacoes, new Date(cache.getAtualizadoEmMs()),
                    ConversorJson.lerProximaAtualizacao(json), motivo != null, motivo);
        } catch (ErroDados e) {
            Log.w(TAG, "Cache corrompido, descartando", e);
            cache.limpar();
            return null;
        }
    }

    @Nullable
    static Estacao encontrar(List<Estacao> estacoes, String codigo) {
        for (Estacao e : estacoes) {
            if (codigo.equals(e.getCodigo())) return e;
        }
        return null;
    }
}
