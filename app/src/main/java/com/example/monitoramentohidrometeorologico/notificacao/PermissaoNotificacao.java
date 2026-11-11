package com.example.monitoramentohidrometeorologico.notificacao;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.activity.ComponentActivity;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.ContextCompat;

/**
 * Permissão de notificação (Android 13+ exige pedir ao usuário; antes disso já é concedida).
 *
 * <p>Uso numa Activity:
 * <pre>
 * // em onCreate, ANTES de a Activity aparecer:
 * ActivityResultLauncher&lt;String&gt; pedido = PermissaoNotificacao.registrar(this);
 * // quando fizer sentido (ex.: ao favoritar a primeira estação):
 * PermissaoNotificacao.pedirSeNecessario(this, pedido);
 * </pre>
 */
public final class PermissaoNotificacao {

    private PermissaoNotificacao() {
    }

    public static boolean concedida(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true;
        return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    /** Registra o pedido de permissão. Precisa ser chamado em onCreate. */
    public static ActivityResultLauncher<String> registrar(ComponentActivity activity) {
        return activity.registerForActivityResult(new ActivityResultContracts.RequestPermission(),
                concedida -> {
                    if (concedida) AgendadorAlertas.agendar(activity);
                });
    }

    /** Mostra o diálogo do sistema se a permissão ainda não foi dada. */
    public static void pedirSeNecessario(Context context, ActivityResultLauncher<String> launcher) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !concedida(context)) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS);
        }
    }
}
