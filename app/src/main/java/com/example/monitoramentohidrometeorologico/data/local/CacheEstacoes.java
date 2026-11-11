package com.example.monitoramentohidrometeorologico.data.local;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Cache local da última resposta de {@code tags_data} (HM-09).
 *
 * <p>Guarda o JSON bruto num arquivo privado do app (~300 KB) e o horário em que foi recebido
 * em SharedPreferences. Assim o app abre mostrando os últimos dados mesmo sem internet.
 */
public class CacheEstacoes {

    private static final String TAG = "CacheEstacoes";
    private static final String ARQUIVO = "cache_tags_data.json";
    private static final String PREFS = "cache_estacoes";
    private static final String CHAVE_ATUALIZADO_EM = "atualizado_em";

    private final File arquivo;
    private final SharedPreferences prefs;

    public CacheEstacoes(Context context) {
        Context app = context.getApplicationContext();
        this.arquivo = new File(app.getFilesDir(), ARQUIVO);
        this.prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public synchronized void salvar(String json, long atualizadoEmMs) {
        // grava num temporário e renomeia: se o app morrer no meio, o cache antigo continua válido
        File tmp = new File(arquivo.getPath() + ".tmp");
        try (OutputStream out = new FileOutputStream(tmp)) {
            out.write(json.getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            Log.w(TAG, "Falha ao gravar cache", e);
            return;
        }
        if (arquivo.exists() && !arquivo.delete()) {
            Log.w(TAG, "Não foi possível substituir o cache");
        }
        if (tmp.renameTo(arquivo)) {
            prefs.edit().putLong(CHAVE_ATUALIZADO_EM, atualizadoEmMs).apply();
        }
    }

    /** JSON guardado, ou null se não houver cache. */
    @Nullable
    public synchronized String lerJson() {
        if (!arquivo.exists()) return null;
        try (InputStream in = new FileInputStream(arquivo)) {
            byte[] bytes = new byte[(int) arquivo.length()];
            int lidos = 0;
            while (lidos < bytes.length) {
                int n = in.read(bytes, lidos, bytes.length - lidos);
                if (n < 0) break;
                lidos += n;
            }
            return new String(bytes, 0, lidos, StandardCharsets.UTF_8);
        } catch (IOException e) {
            Log.w(TAG, "Falha ao ler cache", e);
            return null;
        }
    }

    /** Quando o cache foi recebido da API (ms), ou 0 se não houver. */
    public long getAtualizadoEmMs() {
        return prefs.getLong(CHAVE_ATUALIZADO_EM, 0L);
    }

    public synchronized void limpar() {
        //noinspection ResultOfMethodCallIgnored
        arquivo.delete();
        prefs.edit().clear().apply();
    }
}
