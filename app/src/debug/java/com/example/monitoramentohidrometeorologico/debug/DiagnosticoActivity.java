package com.example.monitoramentohidrometeorologico.debug;

import android.graphics.Typeface;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.monitoramentohidrometeorologico.data.Callback;
import com.example.monitoramentohidrometeorologico.data.ErroDados;
import com.example.monitoramentohidrometeorologico.data.EstacaoRepository;
import com.example.monitoramentohidrometeorologico.data.RepositoryProvider;
import com.example.monitoramentohidrometeorologico.data.ResultadoEstacoes;
import com.example.monitoramentohidrometeorologico.model.Estacao;
import com.example.monitoramentohidrometeorologico.model.IntervaloSerie;
import com.example.monitoramentohidrometeorologico.model.Medicao;
import com.example.monitoramentohidrometeorologico.model.NivelAlerta;
import com.example.monitoramentohidrometeorologico.model.PontoHistorico;
import com.example.monitoramentohidrometeorologico.model.SerieHistorica;
import com.example.monitoramentohidrometeorologico.notificacao.AgendadorAlertas;
import com.example.monitoramentohidrometeorologico.notificacao.NotificacaoHelper;
import com.example.monitoramentohidrometeorologico.notificacao.PermissaoNotificacao;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Ferramenta da Pessoa A (só na build debug) para testar e demonstrar a camada de dados
 * com a API REAL: estações, histórico, favoritos, cache e notificações.
 * Não é uma tela do produto — as telas são da Pessoa B.
 */
public class DiagnosticoActivity extends AppCompatActivity {

    private static final String ESTACAO_TESTE = "DCRS-00001";

    private TextView saida;
    private EstacaoRepository repo;
    private ActivityResultLauncher<String> pedidoPermissao;
    private final SimpleDateFormat hora = new SimpleDateFormat("dd/MM HH:mm", Locale.getDefault());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        repo = RepositoryProvider.real(this);
        pedidoPermissao = PermissaoNotificacao.registrar(this);

        LinearLayout coluna = new LinearLayout(this);
        coluna.setOrientation(LinearLayout.VERTICAL);
        int p = (int) (16 * getResources().getDisplayMetrics().density);
        coluna.setPadding(p, p, p, p);

        botao(coluna, "1. Carregar estações (API real)", v -> carregar(false));
        botao(coluna, "2. Forçar atualização", v -> carregar(true));
        botao(coluna, "3. Detalhe " + ESTACAO_TESTE + " (com chuva 72h)", v -> detalhe());
        botao(coluna, "4. Histórico 24h de " + ESTACAO_TESTE, v -> historico());
        botao(coluna, "5. Favoritar/desfavoritar " + ESTACAO_TESTE, v -> alternarFavorito());
        botao(coluna, "6. Pedir permissão de notificação", v -> {
            PermissaoNotificacao.pedirSeNecessario(this, pedidoPermissao);
            log("Permissão concedida: " + PermissaoNotificacao.concedida(this));
        });
        botao(coluna, "7. Enviar notificação de teste", v ->
                log(NotificacaoHelper.enviarNotificacaoTeste(this)
                        ? "Notificação de teste enviada."
                        : "Não enviada: permissão negada ou notificações desativadas."));
        botao(coluna, "8. Rodar verificação de alertas agora", v -> {
            AgendadorAlertas.executarAgora(this);
            log("Worker enfileirado. Veja o Logcat com a tag VerificacaoAlertas.");
        });

        saida = new TextView(this);
        saida.setTypeface(Typeface.MONOSPACE);
        saida.setTextIsSelectable(true);
        saida.setPadding(0, p, 0, 0);
        coluna.addView(saida);

        ScrollView rolagem = new ScrollView(this);
        rolagem.addView(coluna);
        setContentView(rolagem);
        ViewCompat.setOnApplyWindowInsetsListener(rolagem, (v, insets) -> {
            Insets barras = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(barras.left, barras.top, barras.right, barras.bottom);
            return insets;
        });
        log("Modo das telas: " + (RepositoryProvider.USAR_MOCK ? "MOCK" : "API real")
                + " (esta tela usa sempre a API real)");
    }

    private void carregar(boolean forcar) {
        log("Carregando...");
        repo.listarEstacoes(forcar, new Callback<ResultadoEstacoes>() {
            @Override
            public void onSucesso(ResultadoEstacoes r) {
                Map<NivelAlerta, Integer> contagem = new EnumMap<>(NivelAlerta.class);
                for (Estacao e : r.getEstacoes()) {
                    NivelAlerta n = e.getNivelGeral();
                    Integer atual = contagem.get(n);
                    contagem.put(n, atual == null ? 1 : atual + 1);
                }
                StringBuilder sb = new StringBuilder();
                sb.append(r.getEstacoes().size()).append(" estações | atualizado às ")
                        .append(fmt(r.getAtualizadoEm()));
                if (r.isDoCache()) {
                    sb.append("\nCACHE: ").append(r.getAvisoErro() == null ? ""
                            : r.getAvisoErro().getMensagemUsuario());
                }
                sb.append("\nPróxima atualização da API: ").append(fmt(r.getProximaAtualizacao()));
                sb.append("\nPor nível: ").append(contagem);
                for (Estacao e : r.getEstacoes()) {
                    if (e.getNivelGeral().getGravidade() >= NivelAlerta.ATENCAO.getGravidade()) {
                        sb.append("\n  ").append(e.getCodigo()).append(" ").append(e.getNomeCompleto())
                                .append(" → ").append(e.getNivelGeral().getRotulo());
                    }
                }
                log(sb.toString());
            }

            @Override
            public void onErro(ErroDados erro) {
                log("ERRO " + erro.getTipo() + ": " + erro.getMensagemUsuario());
            }
        });
    }

    private void detalhe() {
        log("Buscando " + ESTACAO_TESTE + "...");
        repo.buscarEstacao(ESTACAO_TESTE, new Callback<Estacao>() {
            @Override
            public void onSucesso(Estacao e) {
                Medicao m = e.getMedicaoAtual();
                log(e + "\n  " + e.getTipo().getRotulo() + " | " + e.getRegiao() + " | bacia " + e.getBacia()
                        + "\n  lat/lon " + e.getLatitude() + ", " + e.getLongitude()
                        + "\n  leitura " + fmt(m.getDataHora()) + " | " + e.getSituacaoDados().getMensagem()
                        + "\n  rio " + m.getRioNivel() + " m (tend. " + m.getRioTendencia() + ") → "
                        + e.getNivelRio().getRotuloRio()
                        + "\n  chuva 24h/48h/72h " + m.getChuva24h() + " / " + m.getChuva48h() + " / "
                        + m.getChuva72h() + " mm → " + e.getNivelChuva().getRotulo()
                        + "\n  temp " + m.getTemperatura() + " °C | umid " + m.getUmidade() + " %"
                        + "\n  NÍVEL GERAL: " + e.getNivelGeral().getRotulo());
            }

            @Override
            public void onErro(ErroDados erro) {
                log("ERRO " + erro.getTipo() + ": " + erro.getMensagemUsuario());
            }
        });
    }

    private void historico() {
        Date fim = new Date();
        Date inicio = new Date(fim.getTime() - 24 * 3600_000L);
        IntervaloSerie intervalo = IntervaloSerie.sugerirPara(fim.getTime() - inicio.getTime());
        log("Histórico 24h, intervalo " + intervalo.getRotulo() + "...");
        repo.buscarSerieHistorica(ESTACAO_TESTE, inicio, fim, intervalo, new Callback<SerieHistorica>() {
            @Override
            public void onSucesso(SerieHistorica s) {
                List<PontoHistorico> pts = s.getPontos();
                StringBuilder sb = new StringBuilder(pts.size() + " pontos | chuva total "
                        + s.getChuvaAcumulada() + " mm");
                for (int i = Math.max(0, pts.size() - 5); i < pts.size(); i++) {
                    PontoHistorico pt = pts.get(i);
                    sb.append("\n  ").append(fmt(pt.getDataHora())).append("  rio ")
                            .append(pt.getRioNivel()).append(" m  chuva ").append(pt.getChuvaMm()).append(" mm");
                }
                log(sb.toString());
            }

            @Override
            public void onErro(ErroDados erro) {
                log("ERRO " + erro.getTipo() + ": " + erro.getMensagemUsuario());
            }
        });
    }

    private void alternarFavorito() {
        boolean nova = !repo.isFavorita(ESTACAO_TESTE);
        repo.setFavorita(ESTACAO_TESTE, nova);
        log((nova ? "Favoritada" : "Removida dos favoritos") + ". Favoritas: " + repo.getFavoritos());
        if (nova) PermissaoNotificacao.pedirSeNecessario(this, pedidoPermissao);
    }

    private void botao(LinearLayout pai, String texto, View.OnClickListener acao) {
        Button b = new Button(this);
        b.setText(texto);
        b.setAllCaps(false);
        b.setOnClickListener(acao);
        pai.addView(b);
    }

    private String fmt(Date d) {
        return d == null ? "—" : hora.format(d);
    }

    private void log(String texto) {
        saida.setText(texto + "\n\n" + saida.getText());
    }
}
