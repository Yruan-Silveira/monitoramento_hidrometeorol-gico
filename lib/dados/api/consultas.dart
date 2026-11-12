// Textos das duas consultas que a API aceita, copiados sem edição de
// docs/api/tags_data.graphql e docs/api/historic.graphql.
//
// A API compara o texto campo por campo e recusa qualquer diferença com
// QUERY_NOT_ALLOWED. NÃO edite à mão: o teste `consultas_test.dart` confere
// que estes textos continuam iguais aos arquivos de docs/api.

/// Dados atuais de todas as estações. Sem variáveis.
const String consultaTagsData = r'''
query Tags_data {
  tags_data(clients: ["casa-militar-defesa-civil-rs"]) {
    qualle_meteorologia {
      codigo
      name {
        prefix
        general
        local
      }
      show
      timestamp
      position {
        bacia
        latitude
        longitude
        regiao
        altitude
        filtros {
          outros {
            crepdec {
              nome {
                value
              }
              codigo {
                value
              }
            }
          }
        }
      }
      data {
        rio {
          rio_alarmes {
            inundacao {
              ativo {
                value
              }
              status {
                value
              }
            }
          }
          rio_nome {
            value
          }
          rio_nivel {
            value
          }
          rio_nivel_tendencia {
            value
          }
          rio_area_drenagem {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        chuva {
          acumulado {
            min005 {
              value
            }
            h001 {
              value
            }
            h003 {
              value
            }
            h006 {
              value
            }
            h012 {
              value
            }
            h024 {
              value
            }
            h048 {
              value
            }
            h168 {
              value
            }
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        pressaoatmos {
          atual {
            value
          }
          historico {
            diaanterior {
              media {
                value
              }
            }
            diaatual {
              media {
                value
              }
            }
          }
          tendencia {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        senstermica {
          atual {
            value
          }
          historico {
            diaatual {
              media {
                value
              }
            }
            diaanterior {
              media {
                value
              }
            }
          }
          tendencia {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        radiacaosolar {
          atual {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        temperatura {
          atual {
            value
          }
          historico {
            diaanterior {
              media {
                value
              }
            }
            diaatual {
              media {
                value
              }
              maxima {
                value
              }
              minima {
                value
              }
            }
          }
          tendencia {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        umidade {
          atual {
            value
          }
          historico {
            diaanterior {
              media {
                value
              }
            }
            diaatual {
              media {
                value
              }
            }
          }
          tendencia {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
        vento {
          direcao {
            value
          }
          velocidade_maxima {
            value
          }
          velocidade_media {
            value
          }
          homologacao {
            relacao {
              valido {
                value
              }
            }
          }
        }
      }
      type
      filter {
        relacao {
          tem_chuva_acumulada
          tem_nivel_do_rio
          tem_pressao_atmosferica
          tem_sensacao_termica
          tem_umidade
          tem_vazao_do_rio
          tem_vento
        }
      }
      resource {
        estacao {
          estado {
            manutencao {
              value
            }
          }
        }
      }
    }
    proximaAtualizacaoEm
  }
}
''';

/// Série histórica de uma estação. Valores vão em `variables`.
const String consultaHistoric = r'''
query Historic($stationCode: String!, $startDate: String!, $endDate: String!, $interval: QueryInterval) {
  historic(
    system: Qualle_Hidrometeorologia
    client: "casa-militar-defesa-civil-rs"
    stationCode: $stationCode
    startDate: $startDate
    endDate: $endDate
    interval: $interval
    opts: { ordenacao: ASC }
  )
}
''';
