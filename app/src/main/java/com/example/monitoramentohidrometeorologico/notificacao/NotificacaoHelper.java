package com.example.monitoramentohidrometeorologico.notificacao;

import android.annotation.SuppressLint;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.example.monitoramentohidrometeorologico.R;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.Medicao;
import com.example.monitoramentohidrometeorologico.model.NivelAlerta;

import java.util.Locale;

/**
 * Cria o canal e envia as notificações locais (HM-07).
 *
 * <p>Ao tocar na notificação o app abre pela tela inicial com o extra
 * {@link #EXTRA_CODIGO_ESTACAO}; a Pessoa B pode lê-lo para abrir direto o detalhe da estação.
 */
public final class NotificacaoHelper {

    public static final String CANAL_ALERTAS = "alertas_estacoes";
    public static final String EXTRA_CODIGO_ESTACAO = "codigo_estacao";
    private static final int ID_TESTE = 1;

    private static final String AVISO = "Alerta indicativo, não substitui os comunicados da Defesa Civil.";

    private NotificacaoHelper() {
    }

    /** Cria o canal de notificação (Android 8+). Pode chamar várias vezes. */
    public static void criarCanal(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationChannel canal = new NotificationChannel(CANAL_ALERTAS,
                context.getString(R.string.canal_alertas_nome), NotificationManager.IMPORTANCE_HIGH);
        canal.setDescription(context.getString(R.string.canal_alertas_descricao));
        NotificationManager nm = context.getSystemService(NotificationManager.class);
        if (nm != null) nm.createNotificationChannel(canal);
    }

    /** O app pode mostrar notificações? (permissão concedida e não bloqueadas pelo usuário) */
    public static boolean podeNotificar(Context context) {
        return PermissaoNotificacao.concedida(context)
                && NotificationManagerCompat.from(context).areNotificationsEnabled();
    }

    /** Avisa que o nível de uma estação favorita subiu. */
    public static boolean notificarSubidaDeNivel(Context context, Estacao estacao, NivelAlerta anterior) {
        NivelAlerta nivel = estacao.getNivelGeral();
        String titulo = nivel.getRotulo() + " — " + estacao.getNomeCompleto();
        StringBuilder texto = new StringBuilder();
        texto.append("Nível subiu de ").append(anterior.getRotulo().toLowerCase(Locale.ROOT))
                .append(" para ").append(nivel.getRotulo().toLowerCase(Locale.ROOT)).append(". ");
        Medicao m = estacao.getMedicaoAtual();
        if (estacao.getNivelRio() != NivelAlerta.SEM_DADOS) {
            texto.append("Rio: ").append(estacao.getNivelRio().getRotuloRio());
            if (m.getRioNivel() != null) {
                texto.append(String.format(Locale.US, " (%.2f m)", m.getRioNivel()));
            }
            texto.append(". ");
        }
        if (m.getChuva24h() != null) {
            texto.append(String.format(Locale.US, "Chuva 24h: %.1f mm. ", m.getChuva24h()));
        }
        texto.append(AVISO);
        return enviar(context, estacao.getCodigo().hashCode(), titulo, texto.toString(),
                nivel, estacao.getCodigo());
    }

    /** Notificação de teste (critério de aceite: "demonstrar recepção de notificação de teste"). */
    public static boolean enviarNotificacaoTeste(Context context) {
        return enviar(context, ID_TESTE, "Notificação de teste",
                "As notificações de alerta estão funcionando. " + AVISO, NivelAlerta.ATENCAO, null);
    }

    @SuppressLint("MissingPermission") // verificado em podeNotificar()
    private static boolean enviar(Context context, int id, String titulo, String texto,
                                  NivelAlerta nivel, String codigoEstacao) {
        if (!podeNotificar(context)) return false;
        criarCanal(context);

        NotificationCompat.Builder b = new NotificationCompat.Builder(context, CANAL_ALERTAS)
                .setSmallIcon(R.drawable.ic_stat_alerta)
                .setColor(ContextCompat.getColor(context, nivel.getCorRes()))
                .setContentTitle(titulo)
                .setContentText(texto)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(texto))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true);

        Intent abrir = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (abrir != null) {
            abrir.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            if (codigoEstacao != null) abrir.putExtra(EXTRA_CODIGO_ESTACAO, codigoEstacao);
            b.setContentIntent(PendingIntent.getActivity(context, id, abrir,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));
        }
        try {
            NotificationManagerCompat.from(context).notify(id, b.build());
            return true;
        } catch (SecurityException e) {
            return false;
        }
    }
}
