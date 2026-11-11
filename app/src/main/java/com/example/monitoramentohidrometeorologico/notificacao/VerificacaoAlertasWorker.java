package com.example.monitoramentohidrometeorologico.notificacao;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.data.RemoteEstacaoRepository;
import com.example.monitoramentohidrometeorologico.data.RepositoryProvider;
import com.example.monitoramentohidrometeorologico.data.ResultadoEstacoes;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.NivelAlerta;
import com.example.monitoramentohidrometeorologico.model.SituacaoDados;

import java.util.Set;

/**
 * Tarefa periódica (HM-07): consulta a API, olha as estações favoritas e notifica quando o
 * nível de alguma SOBE em relação à última verificação.
 *
 * <ul>
 *   <li>Só notifica a partir de ATENÇÃO (subir de "sem dados" para "normal" não avisa).</li>
 *   <li>Não notifica com dado atrasado, em manutenção ou vindo do cache (API fora do ar).</li>
 *   <li>Se o nível descer, guarda o novo nível: uma nova subida volta a notificar.</li>
 * </ul>
 */
public class VerificacaoAlertasWorker extends Worker {

    private static final String TAG = "VerificacaoAlertas";
    private static final String PREFS = "ultimos_niveis";

    public VerificacaoAlertasWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        Context ctx = getApplicationContext();
        RemoteEstacaoRepository repo = RepositoryProvider.real(ctx);
        Set<String> favoritas = repo.getFavoritos();
        if (favoritas.isEmpty()) return Result.success();

        ResultadoEstacoes resultado;
        try {
            resultado = repo.listarEstacoesSync(true);
        } catch (ErroDados e) {
            Log.w(TAG, "Sem dados para verificar: " + e.getMessage());
            return e.isTemporario() ? Result.retry() : Result.failure();
        }
        if (resultado.isDoCache()) {
            Log.w(TAG, "API indisponível; não notifica com dado antigo");
            return Result.retry();
        }

        SharedPreferences ultimos = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = ultimos.edit();
        int notificadas = 0;

        for (Estacao estacao : resultado.getEstacoes()) {
            String codigo = estacao.getCodigo();
            if (!favoritas.contains(codigo)) continue;
            if (estacao.getSituacaoDados() != SituacaoDados.OK) continue;

            if (estacao.isTemChuva()) {
                try {
                    estacao.getMedicaoAtual().setChuva72h(repo.buscarChuvaAcumuladaSync(codigo, 72));
                } catch (ErroDados e) {
                    Log.w(TAG, "Sem chuva 72h para " + codigo + ": " + e.getMessage());
                }
            }

            NivelAlerta atual = estacao.getNivelGeral();
            if (atual == NivelAlerta.SEM_DADOS) continue;
            NivelAlerta anterior = lerNivel(ultimos, codigo);

            if (atual.getGravidade() >= NivelAlerta.ATENCAO.getGravidade() && atual.maisGraveQue(anterior)) {
                if (NotificacaoHelper.notificarSubidaDeNivel(ctx, estacao, anterior)) notificadas++;
            }
            editor.putString(codigo, atual.name());
        }
        // remove estações que deixaram de ser favoritas
        for (String codigo : ultimos.getAll().keySet()) {
            if (!favoritas.contains(codigo)) editor.remove(codigo);
        }
        editor.apply();
        Log.i(TAG, "Verificação concluída: " + favoritas.size() + " favoritas, " + notificadas + " notificações");
        return Result.success();
    }

    private static NivelAlerta lerNivel(SharedPreferences prefs, String codigo) {
        String nome = prefs.getString(codigo, NivelAlerta.NORMAL.name());
        try {
            return NivelAlerta.valueOf(nome);
        } catch (IllegalArgumentException e) {
            return NivelAlerta.NORMAL;
        }
    }
}
