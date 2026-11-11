package com.example.monitoramentohidrometeorologico.data;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Roda um trabalho em segundo plano e entrega o resultado na thread principal.
 * Usado pelos repositórios para que as telas não travem esperando a rede.
 */
final class TarefaAsync {

    interface Trabalho<T> {
        T executar() throws ErroDados;
    }

    private static final String TAG = "TarefaAsync";
    private static final ExecutorService EXECUTOR = Executors.newFixedThreadPool(3);
    private static final Handler PRINCIPAL = new Handler(Looper.getMainLooper());

    private TarefaAsync() {
    }

    static <T> void executar(Trabalho<T> trabalho, Callback<T> callback) {
        EXECUTOR.execute(() -> {
            try {
                T resultado = trabalho.executar();
                PRINCIPAL.post(() -> callback.onSucesso(resultado));
            } catch (ErroDados e) {
                Log.w(TAG, "Falha: " + e.getMessage(), e);
                PRINCIPAL.post(() -> callback.onErro(e));
            } catch (RuntimeException e) {
                Log.e(TAG, "Erro inesperado", e);
                ErroDados erro = new ErroDados(ErroDados.Tipo.DESCONHECIDO, null, e);
                PRINCIPAL.post(() -> callback.onErro(erro));
            }
        });
    }

    /** Entrega o resultado na thread principal depois de um atraso (usado pelo mock). */
    static void naPrincipal(Runnable r, long atrasoMs) {
        PRINCIPAL.postDelayed(r, atrasoMs);
    }
}
