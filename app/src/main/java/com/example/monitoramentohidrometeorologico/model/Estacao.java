package com.example.monitoramentohidrometeorologico.model;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Date;
import java.util.Objects;

/**
 * Estação da rede hidrometeorológica (HM-02, HM-03), com metadados e a leitura atual.
 */
public class Estacao {

    /** Identificador único, ex.: "DCRS-00001". Use como chave em favoritos e na navegação. */
    private String codigo;
    /** Nome da estação, normalmente o município, ex.: "Igrejinha". */
    private String nome;
    /** Complemento do nome (muitas vezes vazio). */
    private String local;
    private String bacia;
    /** Mesorregião, ex.: "Metropolitana de Porto Alegre" (filtro por região do HM-05). */
    private String regiao;
    /** Coordenadoria regional da Defesa Civil (CREPDEC), ex.: "METROPOLITANA". */
    private String coordenadoria;
    private double latitude;
    private double longitude;
    private Double altitude;

    private boolean temNivelRio;
    private boolean temChuva;
    private boolean temPressao;
    private boolean temSensacaoTermica;
    private boolean temUmidade;
    private boolean temVazao;
    private boolean temVento;
    private boolean emManutencao;

    /** {@code false} = a Defesa Civil não cadastrou cotas de inundação para esta estação. */
    private boolean limiarRioCadastrado;
    /** 0 a 3 conforme {@code rio_alarmes.inundacao.status}; {@code null} = sem leitura recente. */
    private Integer statusRio;

    private Medicao medicaoAtual = new Medicao();

    // ---------------------------------------------------------------- níveis de alerta (HM-06)

    /** Nível do rio informado pela API (comparação com as cotas da Defesa Civil). */
    @NonNull
    public NivelAlerta getNivelRio() {
        return NivelAlerta.porStatusRio(limiarRioCadastrado, statusRio);
    }

    /** Nível pela chuva acumulada (mm24, mm48 e, quando já calculado, mm72). */
    @NonNull
    public NivelAlerta getNivelChuva() {
        if (medicaoAtual == null) return NivelAlerta.SEM_DADOS;
        return NivelAlerta.porChuva(medicaoAtual.getChuva24h(), medicaoAtual.getChuva48h(),
                medicaoAtual.getChuva72h());
    }

    /**
     * Nível geral = o maior entre rio e chuva. É a indicação de potencial risco de alagamento
     * (HM-08) e a cor que a estação deve ter na tela inicial, lista e mapa.
     * Indicativo: não é previsão garantida nem substitui a Defesa Civil.
     */
    @NonNull
    public NivelAlerta getNivelGeral() {
        return NivelAlerta.maior(getNivelRio(), getNivelChuva());
    }

    // ------------------------------------------------------------- situação dos dados (HM-09)

    @NonNull
    public SituacaoDados getSituacaoDados() {
        return getSituacaoDados(new Date());
    }

    @NonNull
    public SituacaoDados getSituacaoDados(@NonNull Date agora) {
        if (emManutencao) return SituacaoDados.EM_MANUTENCAO;
        Date dataHora = medicaoAtual == null ? null : medicaoAtual.getDataHora();
        if (dataHora == null) return SituacaoDados.SEM_DADOS;
        if (agora.getTime() - dataHora.getTime() > SituacaoDados.LIMITE_ATRASO_MS) {
            return SituacaoDados.ATRASADO;
        }
        return SituacaoDados.OK;
    }

    @NonNull
    public TipoEstacao getTipo() {
        boolean temMeteorologia = temChuva || temPressao || temUmidade || temVento;
        return TipoEstacao.de(temNivelRio, temMeteorologia);
    }

    /** Nome para exibir: "Nome - Local" quando houver local. */
    @NonNull
    public String getNomeCompleto() {
        String n = nome == null ? codigo : nome;
        return (local == null || local.isEmpty()) ? n : n + " - " + local;
    }

    // ------------------------------------------------------------------- getters e setters

    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getLocal() { return local; }
    public void setLocal(String local) { this.local = local; }

    public String getBacia() { return bacia; }
    public void setBacia(String bacia) { this.bacia = bacia; }

    public String getRegiao() { return regiao; }
    public void setRegiao(String regiao) { this.regiao = regiao; }

    public String getCoordenadoria() { return coordenadoria; }
    public void setCoordenadoria(String coordenadoria) { this.coordenadoria = coordenadoria; }

    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }

    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }

    @Nullable public Double getAltitude() { return altitude; }
    public void setAltitude(Double altitude) { this.altitude = altitude; }

    public boolean isTemNivelRio() { return temNivelRio; }
    public void setTemNivelRio(boolean v) { this.temNivelRio = v; }

    public boolean isTemChuva() { return temChuva; }
    public void setTemChuva(boolean v) { this.temChuva = v; }

    public boolean isTemPressao() { return temPressao; }
    public void setTemPressao(boolean v) { this.temPressao = v; }

    public boolean isTemSensacaoTermica() { return temSensacaoTermica; }
    public void setTemSensacaoTermica(boolean v) { this.temSensacaoTermica = v; }

    public boolean isTemUmidade() { return temUmidade; }
    public void setTemUmidade(boolean v) { this.temUmidade = v; }

    public boolean isTemVazao() { return temVazao; }
    public void setTemVazao(boolean v) { this.temVazao = v; }

    public boolean isTemVento() { return temVento; }
    public void setTemVento(boolean v) { this.temVento = v; }

    public boolean isEmManutencao() { return emManutencao; }
    public void setEmManutencao(boolean v) { this.emManutencao = v; }

    public boolean isLimiarRioCadastrado() { return limiarRioCadastrado; }
    public void setLimiarRioCadastrado(boolean v) { this.limiarRioCadastrado = v; }

    @Nullable public Integer getStatusRio() { return statusRio; }
    public void setStatusRio(Integer statusRio) { this.statusRio = statusRio; }

    @NonNull public Medicao getMedicaoAtual() { return medicaoAtual; }
    public void setMedicaoAtual(Medicao medicaoAtual) {
        this.medicaoAtual = medicaoAtual == null ? new Medicao() : medicaoAtual;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Estacao)) return false;
        return Objects.equals(codigo, ((Estacao) o).codigo);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(codigo);
    }

    @NonNull
    @Override
    public String toString() {
        return codigo + " (" + getNomeCompleto() + ")";
    }
}
