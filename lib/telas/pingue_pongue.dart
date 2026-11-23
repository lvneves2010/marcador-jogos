import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';
import 'dialogos.dart';

/// Estado de uma partida de pingue-pongue, calculado a partir da lista de
/// quem fez cada ponto (assim desfazer é só tirar o último).
///
/// Regras: game até [meta] (11 ou 21) com 2 de vantagem; partida em
/// "melhor de [melhorDe]" games. O saque troca a cada 2 pontos (5 no game
/// de 21) e a cada ponto depois do empate em 10×10 (20×20). Quem saca
/// primeiro alterna a cada game.
class PartidaPingue {
  PartidaPingue({
    required this.pontos,
    this.meta = 11,
    this.melhorDe = 3,
    this.saqueInicial = 0,
  }) {
    for (final p in pontos) {
      if (vencedor != null) break;
      placar[p]++;
      final a = placar[0], b = placar[1];
      if ((a >= meta || b >= meta) && (a - b).abs() >= 2) {
        final g = a > b ? 0 : 1;
        games[g]++;
        parciais.add((a, b));
        placar[0] = placar[1] = 0;
        if (games[g] >= gamesParaVencer) vencedor = g;
      }
    }
  }

  /// índice (0 ou 1) de quem fez cada ponto, em ordem.
  final List<int> pontos;
  final int meta;
  final int melhorDe;
  final int saqueInicial;

  /// pontos do game em andamento.
  final placar = [0, 0];

  /// games vencidos por cada jogador.
  final games = [0, 0];

  /// placar final de cada game já terminado.
  final List<(int, int)> parciais = [];

  /// quem venceu a partida, ou null se ainda não terminou.
  int? vencedor;

  int get gamesParaVencer => melhorDe ~/ 2 + 1;

  /// quem saca o próximo ponto.
  int get sacador {
    final primeiro = parciais.length.isEven ? saqueInicial : 1 - saqueInicial;
    final total = placar[0] + placar[1];
    final porVez = meta >= 21 ? 5 : 2;
    final empate = 2 * (meta - 1);
    final trocas = total < empate
        ? total ~/ porVez
        : empate ~/ porVez + (total - empate);
    return (primeiro + trocas) % 2;
  }
}

class TelaPinguePongue extends StatefulWidget {
  const TelaPinguePongue({super.key});

  @override
  State<TelaPinguePongue> createState() => _TelaPinguePongueState();
}

class _TelaPinguePongueState extends State<TelaPinguePongue> {
  static const _cores = [Colors.blue, Colors.red];
  static const _kNomes = 'pingue_nomes';
  static const _kPontos = 'pingue_pontos';
  static const _kMeta = 'pingue_meta';
  static const _kMelhorDe = 'pingue_melhor_de';
  static const _kSaque = 'pingue_saque';

  List<String> _nomes = ['Jogador 1', 'Jogador 2'];
  List<int> _pontos = [];
  int _meta = 11;
  int _melhorDe = 3;
  int _saqueInicial = 0;

  PartidaPingue get _partida => PartidaPingue(
    pontos: _pontos,
    meta: _meta,
    melhorDe: _melhorDe,
    saqueInicial: _saqueInicial,
  );

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final nomes = prefs.getStringList(_kNomes);
    final pontos = (prefs.getStringList(_kPontos) ?? [])
        .map(int.parse)
        .where((p) => p == 0 || p == 1)
        .toList();
    if (!mounted) return;
    setState(() {
      if (nomes != null && nomes.length == 2) _nomes = nomes;
      _pontos = pontos;
      _meta = prefs.getInt(_kMeta) ?? 11;
      _melhorDe = prefs.getInt(_kMelhorDe) ?? 3;
      _saqueInicial = prefs.getInt(_kSaque) ?? 0;
    });
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kNomes, _nomes);
    await prefs.setStringList(_kPontos, _pontos.map((e) => '$e').toList());
    await prefs.setInt(_kMeta, _meta);
    await prefs.setInt(_kMelhorDe, _melhorDe);
    await prefs.setInt(_kSaque, _saqueInicial);
  }

  void _ponto(int j) {
    if (_partida.vencedor != null) return;
    setState(() => _pontos.add(j));
    _salvar();
  }

  void _desfazer() {
    if (_pontos.isEmpty) return;
    setState(() => _pontos.removeLast());
    _salvar();
  }

  void _comecarSacando(int j) {
    setState(() => _saqueInicial = j);
    _salvar();
  }

  Future<void> _novoJogo() async {
    if (_pontos.isNotEmpty &&
        !await confirmar(context, 'Nova partida', 'Zerar o placar?')) {
      return;
    }
    final terminada = _partida.vencedor != null;
    void zerar() {
      if (!mounted) return;
      setState(() => _pontos = []);
      _salvar();
    }

    terminada ? Anuncios.aoTerminarPartida(zerar) : zerar();
  }

  Future<void> _configurar() async {
    final cfg = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _DialogoRegras(meta: _meta, melhorDe: _melhorDe),
    );
    if (cfg == null || !mounted) return;
    if (cfg == (_meta, _melhorDe)) return;
    if (_pontos.isNotEmpty &&
        !await confirmar(
          context,
          'Mudar as regras',
          'O placar atual será zerado.',
        )) {
      return;
    }
    setState(() {
      _meta = cfg.$1;
      _melhorDe = cfg.$2;
      _pontos = [];
    });
    _salvar();
  }

  Future<void> _renomear(int j) async {
    final nome = await pedirNome(context, _nomes[j]);
    if (nome == null) return;
    setState(() => _nomes[j] = nome);
    _salvar();
  }

  @override
  Widget build(BuildContext context) {
    final p = _partida;
    final vencedor = p.vencedor;
    final sacador = p.sacador;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingue-pongue'),
        actions: [
          IconButton(
            tooltip: 'Desfazer último ponto',
            icon: const Icon(Icons.undo),
            onPressed: _pontos.isEmpty ? null : _desfazer,
          ),
          IconButton(
            tooltip: 'Nova partida',
            icon: const Icon(Icons.autorenew),
            onPressed: _novoJogo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (vencedor == null)
            TextButton.icon(
              onPressed: _configurar,
              icon: const Icon(Icons.tune, size: 18),
              label: Text('Games de $_meta · melhor de $_melhorDe'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_nomes[vencedor]} venceu!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (p.parciais.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                p.parciais.map((g) => '${g.$1}-${g.$2}').join('  ·  '),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          for (var j = 0; j < 2; j++)
            Expanded(
              child: _LadoJogador(
                nome: _nomes[j],
                pontos: p.placar[j],
                games: p.games[j],
                cor: _cores[j],
                destaque: vencedor == j,
                saca: vencedor == null && sacador == j,
                // antes do 1º ponto dá para escolher quem começa sacando
                onComecarSacando: _pontos.isEmpty && sacador != j
                    ? () => _comecarSacando(j)
                    : null,
                onPonto: vencedor == null ? () => _ponto(j) : null,
                onNome: () => _renomear(j),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: const BarraInferior(),
    );
  }
}

class _LadoJogador extends StatelessWidget {
  const _LadoJogador({
    required this.nome,
    required this.pontos,
    required this.games,
    required this.cor,
    required this.destaque,
    required this.saca,
    required this.onComecarSacando,
    required this.onPonto,
    required this.onNome,
  });

  final String nome;
  final int pontos;
  final int games;
  final Color cor;
  final bool destaque;
  final bool saca;
  final VoidCallback? onComecarSacando;
  final VoidCallback? onPonto;
  final VoidCallback onNome;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      // cor sólida: com cor translúcida a sombra do Card aparece por trás
      color: destaque
          ? Colors.amber.shade100
          : Color.alphaBlend(cor.withValues(alpha: 0.06), Colors.white),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor, width: 2),
      ),
      // o lado inteiro é o botão de ponto: fácil de tocar no meio do jogo
      child: InkWell(
        onTap: onPonto,
        child: Semantics(
          button: true,
          label: 'Ponto para $nome',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: onNome,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                nome,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Games: $games',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      if (saca)
                        Row(
                          children: [
                            Icon(Icons.sports_tennis, size: 18, color: cor),
                            const SizedBox(width: 4),
                            Text(
                              'Saque',
                              style: TextStyle(
                                color: cor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else if (onComecarSacando != null)
                        OutlinedButton.icon(
                          onPressed: onComecarSacando,
                          icon: const Icon(Icons.sports_tennis, size: 16),
                          label: const Text('Começar sacando'),
                        ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) => Text(
                    '$pontos',
                    style: TextStyle(
                      fontSize: (c.maxHeight * 0.7).clamp(48.0, 140.0),
                      color: cor,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoRegras extends StatefulWidget {
  const _DialogoRegras({required this.meta, required this.melhorDe});

  final int meta;
  final int melhorDe;

  @override
  State<_DialogoRegras> createState() => _DialogoRegrasState();
}

class _DialogoRegrasState extends State<_DialogoRegras> {
  late int _meta = widget.meta;
  late int _melhorDe = widget.melhorDe;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Regras da partida'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pontos por game'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 11, label: Text('11')),
              ButtonSegment(value: 21, label: Text('21')),
            ],
            selected: {_meta},
            onSelectionChanged: (s) => setState(() => _meta = s.first),
          ),
          const SizedBox(height: 16),
          const Text('Partida em melhor de'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 7, label: Text('7')),
            ],
            selected: {_melhorDe},
            onSelectionChanged: (s) => setState(() => _melhorDe = s.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (_meta, _melhorDe)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
