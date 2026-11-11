package com.example.monitoramentohidrometeorologico.data;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.monitoramentohidrometeorologico.model.Estacao;

import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * Lista de estações + informações de atualização (HM-09).
 *
 * <p>Se a API falhar e houver cache, o repositório devolve os dados guardados com
 * {@link #isDoCache()} = true e o motivo em {@link #getAvisoErro()}. A tela deve então
 * mostrar algo como "Serviço indisponível. Mostrando dados de HH:MM".
 */
public class ResultadoEstacoes {

    private final List<Estacao> estacoes;
    private final Date atualizadoEm;
    private final Date proximaAtualizacao;
    private final boolean doCache;
    private final ErroDados avisoErro;

    public ResultadoEstacoes(List<Estacao> estacoes, Date atualizadoEm, Date proximaAtualizacao,
                             boolean doCache, ErroDados avisoErro) {
        this.estacoes = estacoes == null ? Collections.emptyList() : estacoes;
        this.atualizadoEm = atualizadoEm;
        this.proximaAtualizacao = proximaAtualizacao;
        this.doCache = doCache;
        this.avisoErro = avisoErro;
    }

    @NonNull
    public List<Estacao> getEstacoes() {
        return Collections.unmodifiableList(estacoes);
    }

    /** Quando o app recebeu estes dados da API (para o "atualizado às HH:MM"). */
    public Date getAtualizadoEm() {
        return atualizadoEm;
    }

    /** Quando a API terá dados novos (campo proximaAtualizacaoEm). Pode ser null. */
    @Nullable
    public Date getProximaAtualizacao() {
        return proximaAtualizacao;
    }

    /** {@code true} se a API falhou e estes são dados antigos guardados no aparelho. */
    public boolean isDoCache() {
        return doCache;
    }

    /** Motivo de estar usando o cache; {@code null} quando os dados vieram da API. */
    @Nullable
    public ErroDados getAvisoErro() {
        return avisoErro;
    }
}
