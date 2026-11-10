import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';

/// Placar de dominó para 2 a 4 jogadores/duplas: cada toque no (+) soma
/// 1 ponto (rodada de 2 pontos = dois toques). Vence quem chegar à meta
/// (12 por padrão, ajustável tocando em "Jogo até N pontos").
class TelaDomino extends StatefulWidget {
  const TelaDomino({super.key});

  static const metaPadrao = 12;
  static const minJogadores = 2;
  static const maxJogadores = 4;

  @override
  State<TelaDomino> createState() => _TelaDominoState();
}

class _TelaDominoState extends State<TelaDomino> {
  static const _cores = [Colors.blue, Colors.red, Colors.green, Colors.orange];
  static const _kQtd = 'domino_jogadores';
  static const _kPontos = 'domino_pontos';
  static const _kNomes = 'domino_nomes';
  static const _kHistorico = 'domino_historico';
  static const _kMeta = 'domino_meta';

  int _qtd = 2;
  int _meta = TelaDomino.metaPadrao;
  List<int> _pontos = [0, 0];
  List<String> _nomes = _nomesPadrao(2);

  /// índices dos jogadores que pontuaram, em ordem (para desfazer).
  List<int> _historico = [];

  static List<String> _nomesPadrao(int n) =>
      n == 2 ? ['Nós', 'Eles'] : List.generate(n, (i) => 'Jogador ${i + 1}');

  int? get _vencedor {
    for (var i = 0; i < _qtd; i++) {
      if (_pontos[i] >= _meta) return i;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final qtd = (prefs.getInt(_kQtd) ?? 2).clamp(
      TelaDomino.minJogadores,
      TelaDomino.maxJogadores,
    );
    List<int> ints(String k) =>
        (prefs.getStringList(k) ?? []).map(int.parse).toList();
    final pontos = ints(_kPontos);
    final nomes = prefs.getStringList(_kNomes) ?? [];
    if (!mounted) return;
    setState(() {
      _qtd = qtd;
      _pontos = pontos.length == qtd ? pontos : List.filled(qtd, 0);
      _nomes = nomes.length == qtd ? nomes : _nomesPadrao(qtd);
      _historico = ints(_kHistorico).where((i) => i < qtd).toList();
      _meta = prefs.getInt(_kMeta) ?? TelaDomino.metaPadrao;
    });
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kQtd, _qtd);
    await prefs.setInt(_kMeta, _meta);
    await prefs.setStringList(_kPontos, _pontos.map((e) => '$e').toList());
    await prefs.setStringList(_kNomes, _nomes);
    await prefs.setStringList(
      _kHistorico,
      _historico.map((e) => '$e').toList(),
    );
  }

  void _somar(int i) {
    if (_vencedor != null) return;
    setState(() {
      _pontos[i]++;
      _historico.add(i);
    });
    _salvar();
  }

  void _desfazer() {
    if (_historico.isEmpty) return;
    setState(() {
      final i = _historico.removeLast();
      if (_pontos[i] > 0) _pontos[i]--;
    });
    _salvar();
  }

  Future<bool> _confirmar(String titulo, String texto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _novoJogo() async {
    if (_historico.isNotEmpty &&
        !await _confirmar('Novo jogo', 'Zerar o placar de todos?')) {
      return;
    }
    void zerar() {
      if (!mounted) return;
      setState(() {
        _pontos = List.filled(_qtd, 0);
        _historico = [];
      });
      _salvar();
    }

    _vencedor != null ? Anuncios.aoTerminarPartida(zerar) : zerar();
  }

  Future<void> _mudarQtd(int qtd) async {
    if (qtd == _qtd) return;
    if (_historico.isNotEmpty &&
        !await _confirmar(
          'Mudar para $qtd jogadores',
          'O placar atual será zerado.',
        )) {
      return;
    }
    setState(() {
      final padrao = _nomesPadrao(qtd);
      // mantém nomes já personalizados; completa com o padrão
      _nomes = List.generate(qtd, (i) {
        final atual = i < _nomes.length ? _nomes[i] : null;
        final eraPadrao = atual == null || _nomesPadrao(_qtd).contains(atual);
        return eraPadrao ? padrao[i] : atual;
      });
      _qtd = qtd;
      _pontos = List.filled(qtd, 0);
      _historico = [];
    });
    _salvar();
  }

  Future<void> _editarMeta() async {
    final ctrl = TextEditingController(text: '$_meta');
    final nova = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meta de pontos'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Jogo termina em'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (nova == null || nova <= 0) return;
    setState(() => _meta = nova);
    _salvar();
  }

  Future<void> _renomear(int i) async {
    final ctrl = TextEditingController(text: _nomes[i]);
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (nome == null || nome.trim().isEmpty) return;
    setState(() => _nomes[i] = nome.trim());
    _salvar();
  }

  @override
  Widget build(BuildContext context) {
    final vencedor = _vencedor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placar de Dominó'),
        actions: [
          IconButton(
            tooltip: 'Desfazer último ponto',
            icon: const Icon(Icons.undo),
            onPressed: _historico.isEmpty ? null : _desfazer,
          ),
          IconButton(
            tooltip: 'Novo jogo',
            icon: const Icon(Icons.autorenew),
            onPressed: _novoJogo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (vencedor == null)
            TextButton.icon(
              onPressed: _editarMeta,
              icon: const Icon(Icons.flag, size: 18),
              label: Text('Jogo até $_meta pontos'),
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
          for (var i = 0; i < _qtd; i++)
            Expanded(
              child: _LinhaJogador(
                nome: _nomes[i],
                pontos: _pontos[i],
                cor: _cores[i],
                destaque: vencedor == i,
                onMais: vencedor == null ? () => _somar(i) : null,
                onNome: () => _renomear(i),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.group, size: 20),
                const SizedBox(width: 8),
                const Text('Jogadores:'),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (
                        var n = TelaDomino.minJogadores;
                        n <= TelaDomino.maxJogadores;
                        n++
                      )
                        ButtonSegment(value: n, label: Text('$n')),
                    ],
                    selected: {_qtd},
                    onSelectionChanged: (s) => _mudarQtd(s.first),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BarraInferior(),
    );
  }
}

class _LinhaJogador extends StatelessWidget {
  const _LinhaJogador({
    required this.nome,
    required this.pontos,
    required this.cor,
    required this.destaque,
    required this.onMais,
    required this.onNome,
  });

  final String nome;
  final int pontos;
  final Color cor;
  final bool destaque;
  final VoidCallback? onMais;
  final VoidCallback onNome;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: destaque ? Colors.amber.shade100 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onNome,
                child: Row(
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
                    Icon(Icons.edit, size: 14, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
            // número cresce com o espaço da linha (2 jogadores = bem grande)
            LayoutBuilder(
              builder: (context, c) => Text(
                '$pontos',
                style: TextStyle(
                  fontSize: (c.maxHeight * 0.6).clamp(36.0, 120.0),
                  color: cor,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                heroTag: null,
                tooltip: 'Somar ponto para $nome',
                backgroundColor: onMais == null ? Colors.grey : cor,
                onPressed: onMais,
                child: const Icon(Icons.add, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
