package com.example.monitoramentohidrometeorologico;

import android.app.Application;

import com.example.monitoramentohidrometeorologico.notificacao.AgendadorAlertas;
import com.example.monitoramentohidrometeorologico.notificacao.NotificacaoHelper;

/**
 * Inicialização do app: cria o canal de notificação e agenda a verificação de alertas.
 */
public class HidroApp extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        NotificacaoHelper.criarCanal(this);
        AgendadorAlertas.agendar(this);
    }
}
