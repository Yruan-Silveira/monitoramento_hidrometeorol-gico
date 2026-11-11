package com.example.monitoramentohidrometeorologico.notificacao;

import android.content.Context;

import androidx.work.BackoffPolicy;
import androidx.work.Constraints;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.ExistingWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

import java.util.concurrent.TimeUnit;

/**
 * Agenda a verificação periódica de alertas no WorkManager (HM-07).
 *
 * <p>15 minutos é o menor intervalo que o Android permite para tarefas periódicas.
 * O sistema pode atrasar a execução para poupar bateria (Doze), por isso o alerta é
 * "melhor esforço" — coerente com o caráter indicativo exigido na especificação.
 */
public final class AgendadorAlertas {

    private static final String NOME_PERIODICO = "verificacao_alertas";
    private static final String NOME_AGORA = "verificacao_alertas_agora";

    private AgendadorAlertas() {
    }

    private static Constraints comRede() {
        return new Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build();
    }

    /** Agenda a cada 15 min. Seguro chamar sempre que o app abre (mantém o agendamento existente). */
    public static void agendar(Context context) {
        PeriodicWorkRequest req = new PeriodicWorkRequest.Builder(
                VerificacaoAlertasWorker.class, 15, TimeUnit.MINUTES)
                .setConstraints(comRede())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .build();
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                NOME_PERIODICO, ExistingPeriodicWorkPolicy.KEEP, req);
    }

    /** Roda uma verificação imediata (útil para testar e depois de favoritar). */
    public static void executarAgora(Context context) {
        OneTimeWorkRequest req = new OneTimeWorkRequest.Builder(VerificacaoAlertasWorker.class)
                .setConstraints(comRede())
                .build();
        WorkManager.getInstance(context).enqueueUniqueWork(NOME_AGORA, ExistingWorkPolicy.REPLACE, req);
    }

    public static void cancelar(Context context) {
        WorkManager.getInstance(context).cancelUniqueWork(NOME_PERIODICO);
    }
}
