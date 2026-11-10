/// Variáveis que a API mede, com rótulo e unidade para telas e gráficos (HM-04).
enum Variavel {
  nivelRio('Nível do rio', 'm'),
  chuva('Chuva', 'mm'),
  temperatura('Temperatura', '°C'),
  sensacaoTermica('Sensação térmica', '°C'),
  umidade('Umidade relativa', '%'),
  pressao('Pressão atmosférica', 'hPa'),
  ventoVelocidadeMedia('Vento (média)', 'km/h'),
  ventoVelocidadeMaxima('Vento (rajada)', 'km/h'),
  ventoDirecao('Direção do vento', '°'),
  radiacaoSolar('Radiação solar', 'W/m²');

  const Variavel(this.rotulo, this.unidade);

  final String rotulo;
  final String unidade;
}
