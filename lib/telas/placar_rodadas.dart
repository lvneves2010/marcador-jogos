import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';

/// Placar "Nós × Eles" somando pontos rodada a rodada até uma meta.
/// Usado pelo buraco e pelo dominó; cada jogo salva com sua [chave].
class TelaPlacarRodadas extends StatefulWidget {
  const TelaPlacarRodadas({
    super.key,
    required this.titulo,
    required this.chave,
    required this.metaPadrao,
  });

  final String titulo;
  final String chave;
  final int metaPadrao;

  @override
  State<TelaPlacarRodadas> createState() => _TelaPlacarRodadasState();
}

class _TelaPlacarRodadasState extends State<TelaPlacarRodadas> {
  static const corNos = Colors.blue;
  static const corEles = Colors.red;

  List<int> _nos = [];
  List<int> _eles = [];
  late int _meta = widget.metaPadrao;

  String get _kNos => '${widget.chave}_nos';
  String get _kEles => '${widget.chave}_eles';
  String get _kMeta => '${widget.chave}_meta';

  int get _totalNos => _nos.fold(0, (a, b) => a + b);
  int get _totalEles => _eles.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    List<int> ler(String k) =>
        (prefs.getStringList(k) ?? []).map(int.parse).toList();
    if (!mounted) return;
    setState(() {
      _nos = ler(_kNos);
      _eles = ler(_kEles);
      _meta = prefs.getInt(_kMeta) ?? widget.metaPadrao;
    });
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kNos, _nos.map((e) => '$e').toList());
    await prefs.setStringList(_kEles, _eles.map((e) => '$e').toList());
    await prefs.setInt(_kMeta, _meta);
  }

  /// Texto de vitória quando alguém chegou na meta (vence o maior total).
  String? get _resultado {
    if (_totalNos < _meta && _totalEles < _meta) return null;
    if (_totalNos == _totalEles) return 'Empate!';
    return _totalNos > _totalEles ? 'Nós vencemos!' : 'Eles venceram!';
  }

  Future<void> _novaRodada() async {
    final rodada = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _DialogoRodada(numero: _nos.length + 1),
    );
    if (rodada == null) return;
    setState(() {
      _nos.add(rodada.$1);
      _eles.add(rodada.$2);
    });
    _salvar();
  }

  void _desfazer() {
    if (_nos.isEmpty) return;
    setState(() {
      _nos.removeLast();
      _eles.removeLast();
    });
    _salvar();
  }

  Future<void> _novoJogo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo jogo'),
        content: const Text('Zerar o placar e apagar as rodadas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zerar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    void zerar() {
      if (!mounted) return;
      setState(() {
        _nos = [];
        _eles = [];
      });
      _salvar();
    }

    _resultado != null ? Anuncios.aoTerminarPartida(zerar) : zerar();
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

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            tooltip: 'Desfazer última rodada',
            icon: const Icon(Icons.undo),
            onPressed: _nos.isEmpty ? null : _desfazer,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                _Total(nome: 'Nós', total: _totalNos, cor: corNos),
                _Total(nome: 'Eles', total: _totalEles, cor: corEles),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _editarMeta,
            icon: const Icon(Icons.flag, size: 18),
            label: Text('Meta: $_meta pontos'),
          ),
          if (resultado != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resultado,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: _nos.isEmpty
                ? const Center(child: Text('Nenhuma rodada ainda'))
                : ListView.builder(
                    // mais recente no topo
                    itemCount: _nos.length,
                    itemBuilder: (_, i) {
                      final r = _nos.length - 1 - i;
                      return ListTile(
                        dense: true,
                        leading: Text('${r + 1}ª'),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _fmt(_nos[r]),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: corNos,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _fmt(_eles[r]),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: corEles,
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

class _Total extends StatelessWidget {
  const _Total({required this.nome, required this.total, required this.cor});

  final String nome;
  final int total;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            nome,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          FittedBox(
            child: Text(
              '$total',
              style: Theme.of(context).textTheme.displayMedium
                  ?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para lançar os pontos de uma rodada (aceita negativos).
class _DialogoRodada extends StatefulWidget {
  const _DialogoRodada({required this.numero});

  final int numero;

  @override
  State<_DialogoRodada> createState() => _DialogoRodadaState();
}

class _DialogoRodadaState extends State<_DialogoRodada> {
  final _nos = _CampoPontos();
  final _eles = _CampoPontos();

  @override
  void dispose() {
    _nos.ctrl.dispose();
    _eles.ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.numero}ª rodada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _campo('Nós', _nos, autofocus: true),
          const SizedBox(height: 12),
          _campo('Eles', _eles),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (_nos.valor, _eles.valor)),
          child: const Text('Lançar'),
        ),
      ],
    );
  }

  Widget _campo(String rotulo, _CampoPontos c, {bool autofocus = false}) {
    return Row(
      children: [
        // muitos teclados numéricos não têm o sinal de menos: botão ±
        Tooltip(
          message: 'Trocar sinal',
          child: SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => c.negativo = !c.negativo),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                foregroundColor: c.negativo ? Colors.red : Colors.green,
                side: BorderSide(
                  color: c.negativo ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Text(
                c.negativo ? '−' : '+',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: c.ctrl,
            autofocus: autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: rotulo, hintText: '0'),
          ),
        ),
      ],
    );
  }
}

class _CampoPontos {
  final ctrl = TextEditingController();
  bool negativo = false;

  int get valor {
    final v = int.tryParse(ctrl.text) ?? 0;
    return negativo ? -v : v;
  }
}
