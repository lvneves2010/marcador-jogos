import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';
import 'dialogos.dart';

/// Placar genérico: 2 a 6 jogadores, pontos lançados por rodada, meta
/// opcional (0 = sem meta) e escolha de quem vence (maior ou menor total).
/// Serve para Uno, Copas, Pife, Mexe-mexe e o que mais o usuário inventar.
class TelaPlacarLivre extends StatefulWidget {
  const TelaPlacarLivre({super.key});

  static const minJogadores = 2;
  static const maxJogadores = 6;

  @override
  State<TelaPlacarLivre> createState() => _TelaPlacarLivreState();
}

class _TelaPlacarLivreState extends State<TelaPlacarLivre> {
  static const _cores = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  static const _kNomes = 'livre_nomes';
  static const _kRodadas = 'livre_rodadas';
  static const _kMeta = 'livre_meta';
  static const _kMenorVence = 'livre_menor_vence';

  List<String> _nomes = _nomesPadrao(2);

  /// cada rodada tem um valor por jogador, na ordem de [_nomes].
  List<List<int>> _rodadas = [];
  int _meta = 0;
  bool _menorVence = false;

  static List<String> _nomesPadrao(int n) =>
      List.generate(n, (i) => 'Jogador ${i + 1}');

  int get _qtd => _nomes.length;

  List<int> get _totais => [
    for (var j = 0; j < _qtd; j++) _rodadas.fold(0, (s, r) => s + r[j]),
  ];

  /// Índices dos vencedores (mais de um = empate), ou null se o jogo não
  /// terminou. Termina quando alguém chega na meta.
  List<int>? get _vencedores {
    final t = _totais;
    if (_meta <= 0 || !t.any((v) => v >= _meta)) return null;
    final melhor = _menorVence
        ? t.reduce((a, b) => a < b ? a : b)
        : t.reduce((a, b) => a > b ? a : b);
    return [
      for (var j = 0; j < _qtd; j++)
        if (t[j] == melhor) j,
    ];
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    var nomes = prefs.getStringList(_kNomes) ?? _nomesPadrao(2);
    if (nomes.length < TelaPlacarLivre.minJogadores ||
        nomes.length > TelaPlacarLivre.maxJogadores) {
      nomes = _nomesPadrao(2);
    }
    final rodadas = (prefs.getStringList(_kRodadas) ?? [])
        .map((r) => r.split(',').map(int.parse).toList())
        .where((r) => r.length == nomes.length)
        .toList();
    if (!mounted) return;
    setState(() {
      _nomes = nomes;
      _rodadas = rodadas;
      _meta = prefs.getInt(_kMeta) ?? 0;
      _menorVence = prefs.getBool(_kMenorVence) ?? false;
    });
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kNomes, _nomes);
    await prefs.setStringList(
      _kRodadas,
      _rodadas.map((r) => r.join(',')).toList(),
    );
    await prefs.setInt(_kMeta, _meta);
    await prefs.setBool(_kMenorVence, _menorVence);
  }

  Future<void> _novaRodada() async {
    final rodada = await showDialog<List<int>>(
      context: context,
      builder: (_) => DialogoRodada(numero: _rodadas.length + 1, nomes: _nomes),
    );
    if (rodada == null) return;
    setState(() => _rodadas.add(rodada));
    _salvar();
  }

  void _desfazer() {
    if (_rodadas.isEmpty) return;
    setState(() => _rodadas.removeLast());
    _salvar();
  }

  Future<void> _novoJogo() async {
    if (_rodadas.isNotEmpty &&
        !await confirmar(
          context,
          'Novo jogo',
          'Zerar o placar e apagar as rodadas?',
          ok: 'Zerar',
        )) {
      return;
    }
    void zerar() {
      if (!mounted) return;
      setState(() => _rodadas = []);
      _salvar();
    }

    _vencedores != null ? Anuncios.aoTerminarPartida(zerar) : zerar();
  }

  Future<void> _configurar() async {
    final cfg = await showDialog<_Config>(
      context: context,
      builder: (_) => _DialogoConfig(
        inicial: _Config(qtd: _qtd, meta: _meta, menorVence: _menorVence),
      ),
    );
    if (cfg == null || !mounted) return;
    final mudouQtd = cfg.qtd != _qtd;
    if (mudouQtd &&
        _rodadas.isNotEmpty &&
        !await confirmar(
          context,
          'Mudar para ${cfg.qtd} jogadores',
          'O placar atual será zerado.',
        )) {
      return;
    }
    setState(() {
      if (mudouQtd) {
        final padrao = _nomesPadrao(cfg.qtd);
        // mantém os nomes já escolhidos; completa com o padrão
        _nomes = [
          for (var j = 0; j < cfg.qtd; j++) j < _qtd ? _nomes[j] : padrao[j],
        ];
        _rodadas = [];
      }
      _meta = cfg.meta;
      _menorVence = cfg.menorVence;
    });
    _salvar();
  }

  Future<void> _renomear(int j) async {
    final nome = await pedirNome(context, _nomes[j]);
    if (nome == null) return;
    setState(() => _nomes[j] = nome);
    _salvar();
  }

  String get _resumoRegras {
    final meta = _meta > 0 ? 'Até $_meta pontos' : 'Sem meta';
    final vence = _menorVence ? 'menor vence' : 'maior vence';
    return '$meta · $vence';
  }

  @override
  Widget build(BuildContext context) {
    final vencedores = _vencedores;
    final totais = _totais;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placar Livre'),
        actions: [
          IconButton(
            tooltip: 'Desfazer última rodada',
            icon: const Icon(Icons.undo),
            onPressed: _rodadas.isEmpty ? null : _desfazer,
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
          TextButton.icon(
            onPressed: _configurar,
            icon: const Icon(Icons.tune, size: 18),
            label: Text('$_qtd jogadores · $_resumoRegras'),
          ),
          if (vencedores != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vencedores.length == 1
                    ? '${_nomes[vencedores.first]} venceu!'
                    : 'Empate: ${vencedores.map((j) => _nomes[j]).join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                // mesma largura da coluna "1ª, 2ª..." das rodadas, para alinhar
                const SizedBox(width: 32),
                for (var j = 0; j < _qtd; j++)
                  Expanded(
                    child: _CabecalhoJogador(
                      nome: _nomes[j],
                      total: totais[j],
                      cor: _cores[j],
                      destaque: vencedores?.contains(j) ?? false,
                      onNome: () => _renomear(j),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _rodadas.isEmpty
                ? const Center(child: Text('Nenhuma rodada ainda'))
                : ListView.builder(
                    // mais recente no topo; espaço no fim para o botão
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _rodadas.length,
                    itemBuilder: (_, i) {
                      final r = _rodadas.length - 1 - i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${r + 1}ª',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            for (var j = 0; j < _qtd; j++)
                              Expanded(
                                child: Text(
                                  _fmt(_rodadas[r][j]),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _cores[j],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BarraInferior(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaRodada,
        icon: const Icon(Icons.add),
        label: const Text('Rodada'),
      ),
    );
  }

  static String _fmt(int v) => v > 0 ? '+$v' : '$v';
}

class _CabecalhoJogador extends StatelessWidget {
  const _CabecalhoJogador({
    required this.nome,
    required this.total,
    required this.cor,
    required this.destaque,
    required this.onNome,
  });

  final String nome;
  final int total;
  final Color cor;
  final bool destaque;
  final VoidCallback onNome;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: destaque ? Colors.amber.shade100 : null,
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: cor, width: 3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onNome,
            child: Padding(
              padding: const EdgeInsets.all(4),
              // com 6 jogadores a coluna é estreita: encolhe em vez de cortar
              child: SizedBox(
                height: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    nome,
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cor),
                  ),
                ),
              ),
            ),
          ),
          // altura fixa: números longos encolhem sem desalinhar as colunas
          SizedBox(
            height: 48,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 36,
                  color: cor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Config {
  const _Config({
    required this.qtd,
    required this.meta,
    required this.menorVence,
  });

  final int qtd;
  final int meta;
  final bool menorVence;
}

class _DialogoConfig extends StatefulWidget {
  const _DialogoConfig({required this.inicial});

  final _Config inicial;

  @override
  State<_DialogoConfig> createState() => _DialogoConfigState();
}

class _DialogoConfigState extends State<_DialogoConfig> {
  late int _qtd = widget.inicial.qtd;
  late bool _menorVence = widget.inicial.menorVence;
  late final _meta = TextEditingController(
    text: widget.inicial.meta > 0 ? '${widget.inicial.meta}' : '',
  );

  @override
  void dispose() {
    _meta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Regras do jogo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jogadores'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (
                  var n = TelaPlacarLivre.minJogadores;
                  n <= TelaPlacarLivre.maxJogadores;
                  n++
                )
                  ButtonSegment(value: n, label: Text('$n')),
              ],
              selected: {_qtd},
              onSelectionChanged: (s) => setState(() => _qtd = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Quem vence'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Mais pontos')),
                ButtonSegment(value: true, label: Text('Menos pontos')),
              ],
              selected: {_menorVence},
              onSelectionChanged: (s) => setState(() => _menorVence = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meta,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Meta de pontos',
                helperText:
                    'O jogo termina quando alguém chegar nela. '
                    'Vazio = sem meta.',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _Config(
              qtd: _qtd,
              meta: int.tryParse(_meta.text.trim()) ?? 0,
              menorVence: _menorVence,
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
