import 'package:flutter/material.dart';

import '../estacoes/tela_estacoes.dart';
import '../inicio/tela_inicio.dart';
import '../mapa/tela_mapa.dart';
import '../sobre/tela_sobre.dart';

/// Navegação principal: barra inferior com as quatro abas. Cada aba mantém
/// seu estado (busca, filtros, posição do mapa) ao trocar de aba.
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key, this.mostrarMapaBase = true});

  final bool mostrarMapaBase;

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  var _aba = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _aba,
        children: [
          const TelaInicio(),
          const TelaEstacoes(),
          TelaMapa(mostrarMapaBase: widget.mostrarMapaBase),
          const TelaSobre(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (aba) => setState(() => _aba = aba),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Estações'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'Sobre'),
        ],
      ),
    );
  }
}
