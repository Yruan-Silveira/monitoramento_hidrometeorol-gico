package com.example.monitoramentohidrometeorologico.data;

import android.content.Context;

import androidx.annotation.NonNull;

/**
 * Ponto único para as telas obterem o repositório.
 *
 * <pre>
 * EstacaoRepository repo = RepositoryProvider.get(this);
 * repo.listarEstacoes(false, new Callback&lt;ResultadoEstacoes&gt;() { ... });
 * </pre>
 */
public final class RepositoryProvider {

    /**
     * {@code true}: telas usam dados falsos (semanas 1–3 do cronograma).
     * {@code false}: telas usam a API real. Trocar na semana 4 (integração).
     * As notificações (WorkManager) usam sempre a API real.
     */
    public static final boolean USAR_MOCK = true;

    private static MockEstacaoRepository mock;

    private RepositoryProvider() {
    }

    @NonNull
    public static synchronized EstacaoRepository get(@NonNull Context context) {
        if (USAR_MOCK) {
            if (mock == null) mock = new MockEstacaoRepository(context);
            return mock;
        }
        return RemoteEstacaoRepository.getInstance(context);
    }

    /** Sempre o repositório real, independente da chave acima. */
    @NonNull
    public static RemoteEstacaoRepository real(@NonNull Context context) {
        return RemoteEstacaoRepository.getInstance(context);
    }
}
