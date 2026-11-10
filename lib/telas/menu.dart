import 'package:flutter/material.dart';

import '../main.dart';
import '../anuncios.dart';
import 'domino.dart';
import 'placar_rodadas.dart';
import 'truco.dart';

class TelaMenu extends StatelessWidget {
  const TelaMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(nomeApp),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: Anuncios.precisaOpcoesPrivacidade,
            builder: (_, precisa, _) => precisa
                ? IconButton(
                    tooltip: 'Privacidade e anúncios',
                    icon: const Icon(Icons.privacy_tip_outlined),
                    onPressed: Anuncios.abrirOpcoesPrivacidade,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Escolha o placar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _OpcaoJogo(
            titulo: 'Truco',
            descricao: 'Nós × Eles, até 12 pontos',
            icone: Icons.style,
            cor: Colors.blue,
            destino: () => const TelaTruco(),
          ),
          _OpcaoJogo(
            titulo: 'Buraco',
            descricao: 'Pontos por rodada, até 3000',
            icone: Icons.layers,
            cor: Colors.green.shade700,
            destino: () => const TelaPlacarRodadas(
              titulo: 'Placar de Buraco',
              chave: 'buraco',
              metaPadrao: 3000,
            ),
          ),
          _OpcaoJogo(
            titulo: 'Dominó',
            descricao: '2 a 4 jogadores, até 12 pontos',
            icone: Icons.grid_view,
            cor: Colors.deepOrange,
            destino: () => const TelaDomino(),
          ),
        ],
      ),
      bottomNavigationBar: const BarraInferior(),
    );
  }
}

class _OpcaoJogo extends StatelessWidget {
  const _OpcaoJogo({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.destino,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final Widget Function() destino;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: cor,
          child: Icon(icone, color: Colors.white, size: 28),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => destino())),
      ),
    );
  }
}
