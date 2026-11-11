package com.example.monitoramentohidrometeorologico.data;

import android.content.Context;

import androidx.annotation.NonNull;

import com.example.monitoramentohidrometeorologico.data.remote.ConversorJson;
import com.example.monitoramentohidrometeorologico.data.remote.DatasApi;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.PontoHistorico;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Repositório FALSO para a Pessoa B construir as telas sem depender da rede (Etapa 0).
 *
 * <p>Usa 8 estações reais (assets/mock/tags_data.json) com valores ajustados para cobrir
 * todos os casos que as telas precisam mostrar:
 * <ul>
 *   <li>DCRS-00001 Igrejinha — normal</li>
 *   <li>DCRS-00008 Nova Roma — atenção (rio)</li>
 *   <li>DCRS-00009 Imigrante — atenção (chuva 24h = 34,6 mm)</li>
 *   <li>DCRS-00014 Barão de Cotegipe — alerta</li>
 *   <li>DCRS-00026 Nova Palma — emergência</li>
 *   <li>DCRS-00041 Bagé — dado atrasado (3h sem leitura)</li>
 *   <li>DCRS-00050 Arroio Grande — em manutenção</li>
 *   <li>DCRS-00007 Protásio Alves — sem limiar de rio cadastrado</li>
 * </ul>
 * Responde com ~0,6 s de atraso para a tela poder mostrar o indicador de carregamento.
 */
public class MockEstacaoRepository implements EstacaoRepository {

    private static final long ATRASO_MS = 600;

    private final Context context;
    private final Set<String> favoritos = new HashSet<>();

    public MockEstacaoRepository(Context context) {
        this.context = context.getApplicationContext();
        favoritos.add("DCRS-00001");
        favoritos.add("DCRS-00026");
    }

    @Override
    public void listarEstacoes(boolean forcarAtualizacao, @NonNull Callback<ResultadoEstacoes> callback) {
        responder(callback, () -> {
            Date agora = new Date();
            return new ResultadoEstacoes(carregar(), agora,
                    new Date(agora.getTime() + 5 * 60 * 1000L), false, null);
        });
    }

    @Override
    public void buscarEstacao(@NonNull String codigo, @NonNull Callback<Estacao> callback) {
        responder(callback, () -> {
            Estacao e = RemoteEstacaoRepository.encontrar(carregar(), codigo);
            if (e == null) throw new ErroDados(ErroDados.Tipo.ESTACAO_NAO_ENCONTRADA);
            Double mm48 = e.getMedicaoAtual().getChuva48h();
            if (mm48 != null) e.getMedicaoAtual().setChuva72h(mm48 * 1.15);
            return e;
        });
    }

    @Override
    public void buscarSerieHistorica(@NonNull String codigo, @NonNull Date inicio, @NonNull Date fim,
                                     @NonNull IntervaloSerie intervalo,
                                     @NonNull Callback<SerieHistorica> callback) {
        responder(callback, () -> {
            if (!inicio.before(fim)) throw new ErroDados(ErroDados.Tipo.PARAMETRO_INVALIDO);
            return gerarSerie(codigo, inicio, fim, intervalo);
        });
    }

    @NonNull
    @Override
    public Set<String> getFavoritos() {
        return new HashSet<>(favoritos);
    }

    @Override
    public boolean isFavorita(@NonNull String codigo) {
        return favoritos.contains(codigo);
    }

    @Override
    public void setFavorita(@NonNull String codigo, boolean favorita) {
        if (favorita) favoritos.add(codigo);
        else favoritos.remove(codigo);
    }

    // ------------------------------------------------------------------------------ interno

    private <T> void responder(Callback<T> callback, TarefaAsync.Trabalho<T> trabalho) {
        TarefaAsync.naPrincipal(() -> {
            try {
                callback.onSucesso(trabalho.executar());
            } catch (ErroDados e) {
                callback.onErro(e);
            }
        }, ATRASO_MS);
    }

    private List<Estacao> carregar() throws ErroDados {
        String json;
        try (InputStream in = context.getAssets().open("mock/tags_data.json")) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            json = out.toString(StandardCharsets.UTF_8.name());
        } catch (IOException e) {
            throw new ErroDados(ErroDados.Tipo.DESCONHECIDO, "Mock não encontrado", e);
        }
        long agora = System.currentTimeMillis();
        json = json.replace("__AGORA__", formatarBrasilia(agora - 2 * 60 * 1000L))
                .replace("__ATRASADO__", formatarBrasilia(agora - 3 * 60 * 60 * 1000L))
                .replace("__PROXIMA__", "");
        return ConversorJson.converterEstacoes(json);
    }

    private static String formatarBrasilia(long ms) {
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US);
        f.setTimeZone(DatasApi.FUSO_BRASILIA);
        return f.format(new Date(ms));
    }

    /** Série sintética: nível do rio oscilando e pancadas de chuva, sempre igual por estação. */
    private static SerieHistorica gerarSerie(String codigo, Date inicio, Date fim, IntervaloSerie intervalo) {
        List<PontoHistorico> pontos = new ArrayList<>();
        long passo = intervalo.getMinutos() * 60_000L;
        int semente = Math.abs(codigo.hashCode() % 100);
        double base = 1.5 + semente / 20.0;
        double total = 0;
        int i = 0;
        for (long t = inicio.getTime(); t <= fim.getTime() && i < 2000; t += passo, i++) {
            double horas = (t - inicio.getTime()) / 3_600_000.0;
            PontoHistorico p = new PontoHistorico();
            p.setDataHora(new Date(t));
            p.setRioNivel(round(base + 0.8 * Math.sin(horas / 12.0) + 0.1 * Math.sin(horas)));
            double chuva = ((i + semente) % 17 < 3) ? round(2.0 + (i % 5) * 1.3) : 0.0;
            chuva = chuva * intervalo.getMinutos() / 60.0;
            total += chuva;
            p.setChuvaMm(round(chuva));
            p.setChuvaTotal(round(total));
            p.setTemperatura(round(20 + 6 * Math.sin((horas - 9) / 24.0 * 2 * Math.PI)));
            p.setUmidade(round(70 - 15 * Math.sin((horas - 9) / 24.0 * 2 * Math.PI)));
            pontos.add(p);
        }
        return new SerieHistorica(codigo, inicio, fim, intervalo, pontos);
    }

    private static double round(double v) {
        return Math.round(v * 100.0) / 100.0;
    }
}
