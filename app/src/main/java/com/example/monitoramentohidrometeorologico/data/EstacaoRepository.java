package com.example.monitoramentohidrometeorologico.data;

import androidx.annotation.NonNull;

import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;

import java.util.Date;
import java.util.Set;

/**
 * CONTRATO entre Pessoa A (dados) e Pessoa B (telas) — Etapa 0.
 *
 * <p>As telas só conversam com esta interface. Obtenha a instância com
 * {@link RepositoryProvider#get(android.content.Context)}; ela devolve o mock ou o real.
 *
 * <p>Os métodos com {@link Callback} rodam em segundo plano e respondem na thread principal.
 * <b>Não altere esta interface sem avisar a outra pessoa.</b>
 */
public interface EstacaoRepository {

    /**
     * Todas as estações com a leitura atual (HM-01, HM-02, HM-03).
     *
     * @param forcarAtualizacao {@code false} usa o cache se ainda não há dado novo na API
     *                          (a API só atualiza a cada 5 minutos); {@code true} sempre consulta
     *                          (ex.: "puxar para atualizar").
     */
    void listarEstacoes(boolean forcarAtualizacao, @NonNull Callback<ResultadoEstacoes> callback);

    /**
     * Uma estação com a leitura atual e a chuva das últimas 72h já calculada
     * ({@code medicaoAtual.getChuva72h()}), para a tela de detalhe (HM-03).
     */
    void buscarEstacao(@NonNull String codigo, @NonNull Callback<Estacao> callback);

    /**
     * Série histórica de uma estação (HM-04). A API só tem os últimos 3 meses.
     *
     * @param intervalo agrupamento dos pontos; use {@link IntervaloSerie#sugerirPara(long)}
     *                  se não quiser escolher.
     */
    void buscarSerieHistorica(@NonNull String codigo, @NonNull Date inicio, @NonNull Date fim,
                              @NonNull IntervaloSerie intervalo,
                              @NonNull Callback<SerieHistorica> callback);

    // ------------------------------------------------------------ favoritos (HM-05, HM-07)

    /** Códigos das estações favoritas. Leitura rápida, pode chamar na thread principal. */
    @NonNull
    Set<String> getFavoritos();

    boolean isFavorita(@NonNull String codigo);

    /** Marca/desmarca favorita. As favoritas são vigiadas pelas notificações (HM-07). */
    void setFavorita(@NonNull String codigo, boolean favorita);
}
