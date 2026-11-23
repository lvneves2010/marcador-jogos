import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';
import 'dialogos.dart';

/// Placar "Nós × Eles" somando pontos rodada a rodada até uma meta.
/// Usado pelo buraco, canastra e tranca; cada jogo salva com sua [chave].
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
    final rodada = await showDialog<List<int>>(
      context: context,
      builder: (_) =>
          DialogoRodada(numero: _nos.length + 1, nomes: const ['Nós', 'Eles']),
    );
    if (rodada == null) return;
    setState(() {
      _nos.add(rodada[0]);
      _eles.add(rodada[1]);
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
    if (!await confirmar(
      context,
      'Novo jogo',
      'Zerar o placar e apagar as rodadas?',
      ok: 'Zerar',
    )) {
      return;
    }
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
    final nova = await pedirNumero(
      context,
      titulo: 'Meta de pontos',
      rotulo: 'Jogo termina em',
      inicial: _meta,
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
