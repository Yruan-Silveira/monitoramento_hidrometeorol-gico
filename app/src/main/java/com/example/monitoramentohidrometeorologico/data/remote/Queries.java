package com.example.monitoramentohidrometeorologico.data.remote;

/**
 * Texto EXATO das duas consultas GraphQL permitidas pela API da Defesa Civil RS.
 *
 * <p>Copiado do guia oficial (sistemas.defesacivil.rs.gov.br/api-redehidrometeorologica).
 * A API recusa (QUERY_NOT_ALLOWED) qualquer consulta com campos a mais, a menos ou em outra
 * ordem. <b>Não edite</b> estes textos; se a API mudar, copie de novo do guia.
 * Espaços e quebras de linha não fazem diferença.
 */
public final class Queries {

    /** Identificador do cliente aceito pela API. */
    public static final String CLIENTE = "casa-militar-defesa-civil-rs";

    /** Situação mais recente de todas as estações (sem variáveis). */
    public static final String TAGS_DATA =
            "query Tags_data {\n" +
            "  tags_data(clients: [\"casa-militar-defesa-civil-rs\"]) {\n" +
            "    qualle_meteorologia {\n" +
            "      codigo\n" +
            "      name {\n" +
            "        prefix\n" +
            "        general\n" +
            "        local\n" +
            "      }\n" +
            "      show\n" +
            "      timestamp\n" +
            "      position {\n" +
            "        bacia\n" +
            "        latitude\n" +
            "        longitude\n" +
            "        regiao\n" +
            "        altitude\n" +
            "        filtros {\n" +
            "          outros {\n" +
            "            crepdec {\n" +
            "              nome {\n" +
            "                value\n" +
            "              }\n" +
            "              codigo {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "      }\n" +
            "      data {\n" +
            "        rio {\n" +
            "          rio_alarmes {\n" +
            "            inundacao {\n" +
            "              ativo {\n" +
            "                value\n" +
            "              }\n" +
            "              status {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "          rio_nome {\n" +
            "            value\n" +
            "          }\n" +
            "          rio_nivel {\n" +
            "            value\n" +
            "          }\n" +
            "          rio_nivel_tendencia {\n" +
            "            value\n" +
            "          }\n" +
            "          rio_area_drenagem {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        chuva {\n" +
            "          acumulado {\n" +
            "            min005 {\n" +
            "              value\n" +
            "            }\n" +
            "            h001 {\n" +
            "              value\n" +
            "            }\n" +
            "            h003 {\n" +
            "              value\n" +
            "            }\n" +
            "            h006 {\n" +
            "              value\n" +
            "            }\n" +
            "            h012 {\n" +
            "              value\n" +
            "            }\n" +
            "            h024 {\n" +
            "              value\n" +
            "            }\n" +
            "            h048 {\n" +
            "              value\n" +
            "            }\n" +
            "            h168 {\n" +
            "              value\n" +
            "            }\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        pressaoatmos {\n" +
            "          atual {\n" +
            "            value\n" +
            "          }\n" +
            "          historico {\n" +
            "            diaanterior {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "            diaatual {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "          tendencia {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        senstermica {\n" +
            "          atual {\n" +
            "            value\n" +
            "          }\n" +
            "          historico {\n" +
            "            diaatual {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "            diaanterior {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "          tendencia {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        radiacaosolar {\n" +
            "          atual {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        temperatura {\n" +
            "          atual {\n" +
            "            value\n" +
            "          }\n" +
            "          historico {\n" +
            "            diaanterior {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "            diaatual {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "              maxima {\n" +
            "                value\n" +
            "              }\n" +
            "              minima {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "          tendencia {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        umidade {\n" +
            "          atual {\n" +
            "            value\n" +
            "          }\n" +
            "          historico {\n" +
            "            diaanterior {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "            diaatual {\n" +
            "              media {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "          tendencia {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "        vento {\n" +
            "          direcao {\n" +
            "            value\n" +
            "          }\n" +
            "          velocidade_maxima {\n" +
            "            value\n" +
            "          }\n" +
            "          velocidade_media {\n" +
            "            value\n" +
            "          }\n" +
            "          homologacao {\n" +
            "            relacao {\n" +
            "              valido {\n" +
            "                value\n" +
            "              }\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "      }\n" +
            "      type\n" +
            "      filter {\n" +
            "        relacao {\n" +
            "          tem_chuva_acumulada\n" +
            "          tem_nivel_do_rio\n" +
            "          tem_pressao_atmosferica\n" +
            "          tem_sensacao_termica\n" +
            "          tem_umidade\n" +
            "          tem_vazao_do_rio\n" +
            "          tem_vento\n" +
            "        }\n" +
            "      }\n" +
            "      resource {\n" +
            "        estacao {\n" +
            "          estado {\n" +
            "            manutencao {\n" +
            "              value\n" +
            "            }\n" +
            "          }\n" +
            "        }\n" +
            "      }\n" +
            "    }\n" +
            "    proximaAtualizacaoEm\n" +
            "  }\n" +
            "}\n";

    /** Série de uma estação. Variáveis: stationCode, startDate, endDate, interval. */
    public static final String HISTORIC =
            "query Historic($stationCode: String!, $startDate: String!, $endDate: String!, $interval: QueryInterval) {\n" +
            "  historic(\n" +
            "    system: Qualle_Hidrometeorologia\n" +
            "    client: \"casa-militar-defesa-civil-rs\"\n" +
            "    stationCode: $stationCode\n" +
            "    startDate: $startDate\n" +
            "    endDate: $endDate\n" +
            "    interval: $interval\n" +
            "    opts: { ordenacao: ASC }\n" +
            "  )\n" +
            "}\n";

    private Queries() {
    }
}
