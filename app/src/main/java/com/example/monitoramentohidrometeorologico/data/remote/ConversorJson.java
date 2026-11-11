package com.example.monitoramentohidrometeorologico.data.remote;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.Medicao;
import com.example.monitoramentohidrometeorologico.model.PontoHistorico;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Converte o JSON da API nos modelos do app.
 *
 * <p>O JSON da API é muito aninhado e cheio de nulos (ex.: {@code data.rio.rio_nivel.value}),
 * e na série histórica um campo pode simplesmente não existir. Por isso a leitura é feita
 * "à mão" com o helper {@link #caminho(JsonElement, String...)}, que devolve null em
 * qualquer ponto do caminho que faltar, em vez de lançar exceção.
 */
public final class ConversorJson {

    private ConversorJson() {
    }

    // --------------------------------------------------------------------------- tags_data

    /** Converte a resposta de {@code tags_data} na lista de estações. */
    @NonNull
    public static List<Estacao> converterEstacoes(@NonNull String json) throws ErroDados {
        JsonObject tagsData = objeto(caminho(ler(json), "data", "tags_data"));
        JsonElement lista = tagsData == null ? null : tagsData.get("qualle_meteorologia");
        if (lista == null || !lista.isJsonArray()) {
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_INVALIDA);
        }
        List<Estacao> estacoes = new ArrayList<>();
        for (JsonElement item : lista.getAsJsonArray()) {
            if (!item.isJsonObject()) continue;
            Estacao e = converterEstacao(item.getAsJsonObject());
            if (e != null) estacoes.add(e);
        }
        return estacoes;
    }

    /** Campo {@code proximaAtualizacaoEm} (UTC). Null se ausente. */
    @Nullable
    public static Date lerProximaAtualizacao(@NonNull String json) {
        try {
            return DatasApi.lerHorarioUtc(texto(caminho(ler(json), "data", "tags_data",
                    "proximaAtualizacaoEm")));
        } catch (ErroDados e) {
            return null;
        }
    }

    @Nullable
    static Estacao converterEstacao(JsonObject o) {
        String codigo = texto(o.get("codigo"));
        if (codigo == null) return null;
        // "show" vem como texto "true"/"false"; estações ocultas não aparecem no app
        if ("false".equalsIgnoreCase(texto(o.get("show")))) return null;

        Estacao e = new Estacao();
        e.setCodigo(codigo);
        e.setNome(texto(caminho(o, "name", "general")));
        e.setLocal(texto(caminho(o, "name", "local")));

        JsonElement pos = o.get("position");
        e.setBacia(texto(caminho(pos, "bacia")));
        e.setRegiao(texto(caminho(pos, "regiao")));
        e.setCoordenadoria(texto(caminho(pos, "filtros", "outros", "crepdec", "nome", "value")));
        Double lat = numero(caminho(pos, "latitude"));
        Double lon = numero(caminho(pos, "longitude"));
        e.setLatitude(lat == null ? 0 : lat);
        e.setLongitude(lon == null ? 0 : lon);
        e.setAltitude(numero(caminho(pos, "altitude")));

        JsonElement rel = caminho(o, "filter", "relacao");
        e.setTemNivelRio(booleano(caminho(rel, "tem_nivel_do_rio"), false));
        e.setTemChuva(booleano(caminho(rel, "tem_chuva_acumulada"), false));
        e.setTemPressao(booleano(caminho(rel, "tem_pressao_atmosferica"), false));
        e.setTemSensacaoTermica(booleano(caminho(rel, "tem_sensacao_termica"), false));
        e.setTemUmidade(booleano(caminho(rel, "tem_umidade"), false));
        e.setTemVazao(booleano(caminho(rel, "tem_vazao_do_rio"), false));
        e.setTemVento(booleano(caminho(rel, "tem_vento"), false));
        e.setEmManutencao(booleano(
                caminho(o, "resource", "estacao", "estado", "manutencao", "value"), false));

        JsonElement d = o.get("data");
        JsonElement inundacao = caminho(d, "rio", "rio_alarmes", "inundacao");
        e.setLimiarRioCadastrado(booleano(caminho(inundacao, "ativo", "value"), false));
        Double status = numero(caminho(inundacao, "status", "value"));
        e.setStatusRio(status == null ? null : status.intValue());

        Medicao m = new Medicao();
        m.setDataHora(DatasApi.lerHorarioBrasilia(texto(o.get("timestamp"))));

        m.setRioNivel(valor(d, "rio", "rio_nivel"));
        m.setRioTendencia(valor(d, "rio", "rio_nivel_tendencia"));
        m.setRioHomologado(booleano(
                caminho(d, "rio", "homologacao", "relacao", "valido", "value"), true));

        JsonElement acum = caminho(d, "chuva", "acumulado");
        m.setChuva5min(valor(acum, "min005"));
        m.setChuva1h(valor(acum, "h001"));
        m.setChuva3h(valor(acum, "h003"));
        m.setChuva6h(valor(acum, "h006"));
        m.setChuva12h(valor(acum, "h012"));
        m.setChuva24h(valor(acum, "h024"));
        m.setChuva48h(valor(acum, "h048"));
        m.setChuva168h(valor(acum, "h168"));
        m.setChuvaHomologada(booleano(
                caminho(d, "chuva", "homologacao", "relacao", "valido", "value"), true));

        m.setTemperatura(valor(d, "temperatura", "atual"));
        m.setTemperaturaMaximaDia(valor(d, "temperatura", "historico", "diaatual", "maxima"));
        m.setTemperaturaMinimaDia(valor(d, "temperatura", "historico", "diaatual", "minima"));
        m.setSensacaoTermica(valor(d, "senstermica", "atual"));
        m.setUmidade(valor(d, "umidade", "atual"));
        m.setPressao(valor(d, "pressaoatmos", "atual"));
        m.setVentoVelocidadeMedia(valor(d, "vento", "velocidade_media"));
        m.setVentoVelocidadeMaxima(valor(d, "vento", "velocidade_maxima"));
        m.setVentoDirecao(valor(d, "vento", "direcao"));
        m.setRadiacaoSolar(valor(d, "radiacaosolar", "atual"));

        e.setMedicaoAtual(m);
        return e;
    }

    // ---------------------------------------------------------------------------- historic

    /** Converte a resposta de {@code historic} na série histórica. */
    @NonNull
    public static SerieHistorica converterSerie(@NonNull String json, @NonNull String codigo,
                                                Date inicio, Date fim,
                                                IntervaloSerie intervalo) throws ErroDados {
        JsonElement items = caminho(ler(json), "data", "historic", "items");
        List<PontoHistorico> pontos = new ArrayList<>();
        if (items != null && items.isJsonArray()) {
            JsonArray arr = items.getAsJsonArray();
            for (JsonElement item : arr) {
                if (!item.isJsonObject()) continue;
                JsonObject i = item.getAsJsonObject();
                PontoHistorico p = new PontoHistorico();
                p.setDataHora(DatasApi.lerHorarioBrasilia(texto(i.get("ts"))));
                if (p.getDataHora() == null) continue;
                p.setRioNivel(numero(i.get("rio_nivel")));
                p.setRioVariacao(numero(i.get("rio_variacao")));
                p.setChuvaMm(numero(i.get("chuva_mm")));
                p.setChuvaTotal(numero(i.get("chuva_total")));
                p.setChuvaTaxaMedia(numero(i.get("chuva_taxa_med")));
                p.setChuvaTaxaMaxima(numero(i.get("chuva_taxa_max")));
                p.setTemperatura(numero(i.get("temp_media")));
                p.setSensacaoTermica(numero(i.get("sens_termica")));
                p.setUmidade(numero(i.get("umid_rel")));
                p.setPressao(numero(i.get("pres_atmos")));
                p.setVentoVelocidadeMedia(numero(i.get("vento_vel_med")));
                p.setVentoVelocidadeMaxima(numero(i.get("vento_vel_max")));
                p.setVentoDirecao(numero(i.get("vento_dir")));
                p.setRadiacao(numero(i.get("radiacao")));
                pontos.add(p);
            }
        } else if (caminho(ler(json), "data", "historic") == null) {
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_INVALIDA);
        }
        return new SerieHistorica(codigo, inicio, fim, intervalo, pontos);
    }

    // ----------------------------------------------------------------------------- helpers

    private static JsonElement ler(String json) throws ErroDados {
        try {
            return JsonParser.parseString(json);
        } catch (JsonParseException e) {
            throw new ErroDados(ErroDados.Tipo.RESPOSTA_INVALIDA, null, e);
        }
    }

    /** Navega por objetos aninhados; devolve null se qualquer parte faltar ou for null. */
    @Nullable
    static JsonElement caminho(@Nullable JsonElement raiz, String... chaves) {
        JsonElement atual = raiz;
        for (String chave : chaves) {
            if (atual == null || !atual.isJsonObject()) return null;
            atual = atual.getAsJsonObject().get(chave);
            if (atual == null || atual.isJsonNull()) return null;
        }
        return atual;
    }

    /** Lê {@code <caminho>.value} como número. */
    @Nullable
    private static Double valor(@Nullable JsonElement raiz, String... chaves) {
        String[] comValue = new String[chaves.length + 1];
        System.arraycopy(chaves, 0, comValue, 0, chaves.length);
        comValue[chaves.length] = "value";
        return numero(caminho(raiz, comValue));
    }

    @Nullable
    private static JsonObject objeto(@Nullable JsonElement el) {
        return el != null && el.isJsonObject() ? el.getAsJsonObject() : null;
    }

    @Nullable
    private static String texto(@Nullable JsonElement el) {
        if (el == null || el.isJsonNull() || !el.isJsonPrimitive()) return null;
        return el.getAsString();
    }

    @Nullable
    private static Double numero(@Nullable JsonElement el) {
        if (el == null || el.isJsonNull() || !el.isJsonPrimitive()) return null;
        try {
            double v = el.getAsDouble();
            return Double.isNaN(v) ? null : v;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static boolean booleano(@Nullable JsonElement el, boolean padrao) {
        if (el == null || el.isJsonNull() || !el.isJsonPrimitive()) return padrao;
        String s = el.getAsString();
        if ("true".equalsIgnoreCase(s)) return true;
        if ("false".equalsIgnoreCase(s)) return false;
        return padrao;
    }
}
