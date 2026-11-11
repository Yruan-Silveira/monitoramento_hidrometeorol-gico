package com.example.monitoramentohidrometeorologico.data.remote;

import androidx.annotation.Nullable;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Conversão das datas da API. Atenção aos fusos:
 * <ul>
 *   <li>{@code timestamp} e {@code ts}: horário de Brasília, sem fuso no texto
 *       ("2026-10-14T08:40:00.000").</li>
 *   <li>{@code proximaAtualizacaoEm}: UTC ("2026-11-10T23:57:50.000Z").</li>
 *   <li>Variáveis startDate/endDate: "AAAA-MM-DD HH:MM:SS" em horário de Brasília.</li>
 * </ul>
 * SimpleDateFormat não é thread-safe, por isso cada chamada cria o seu.
 */
public final class DatasApi {

    public static final TimeZone FUSO_BRASILIA = TimeZone.getTimeZone("America/Sao_Paulo");
    private static final TimeZone UTC = TimeZone.getTimeZone("UTC");

    private DatasApi() {
    }

    /** "2026-10-14T08:40:00.000" (Brasília) → Date. Devolve null se vazio ou inválido. */
    @Nullable
    public static Date lerHorarioBrasilia(@Nullable String texto) {
        return ler(texto, FUSO_BRASILIA);
    }

    /** "2026-11-10T23:57:50.000Z" (UTC) → Date. Devolve null se vazio ou inválido. */
    @Nullable
    public static Date lerHorarioUtc(@Nullable String texto) {
        if (texto != null && texto.endsWith("Z")) texto = texto.substring(0, texto.length() - 1);
        return ler(texto, UTC);
    }

    /** Date → "AAAA-MM-DD HH:MM:SS" em horário de Brasília (variáveis da consulta historic). */
    public static String formatarParaApi(Date data) {
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);
        f.setTimeZone(FUSO_BRASILIA);
        return f.format(data);
    }

    @Nullable
    private static Date ler(@Nullable String texto, TimeZone fuso) {
        if (texto == null || texto.trim().isEmpty()) return null;
        String[] formatos = {"yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"};
        for (String formato : formatos) {
            SimpleDateFormat f = new SimpleDateFormat(formato, Locale.US);
            f.setTimeZone(fuso);
            f.setLenient(false);
            try {
                return f.parse(texto.trim());
            } catch (ParseException ignorada) {
                // tenta o próximo formato
            }
        }
        return null;
    }
}
