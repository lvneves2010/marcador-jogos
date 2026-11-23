import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pergunta sim/não. Retorna true só se o usuário confirmar.
Future<bool> confirmar(
  BuildContext context,
  String titulo,
  String texto, {
  String ok = 'OK',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Pede um número inteiro não negativo. Retorna null se cancelar.
Future<int?> pedirNumero(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  required int inicial,
}) {
  final ctrl = TextEditingController(text: '$inicial');
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: rotulo),
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
}

/// Pede um nome de jogador/dupla. Retorna null se cancelar ou ficar vazio.
Future<String?> pedirNome(BuildContext context, String inicial) async {
  final ctrl = TextEditingController(text: inicial);
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
  final t = nome?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// Diálogo para lançar os pontos de uma rodada, um campo por jogador
/// (aceita negativos). Retorna a lista de pontos, na ordem de [nomes].
class DialogoRodada extends StatefulWidget {
  const DialogoRodada({super.key, required this.numero, required this.nomes});

  final int numero;
  final List<String> nomes;

  @override
  State<DialogoRodada> createState() => _DialogoRodadaState();
}

class _DialogoRodadaState extends State<DialogoRodada> {
  late final _campos = [for (final _ in widget.nomes) _CampoPontos()];

  @override
  void dispose() {
    for (final c in _campos) {
      c.ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.numero}ª rodada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _campos.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _campo(
                widget.nomes[i],
                _campos[i],
                autofocus: i == 0,
                ultimo: i == _campos.length - 1,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _lancar, child: const Text('Lançar')),
      ],
    );
  }

  void _lancar() => Navigator.pop(context, [for (final c in _campos) c.valor]);

  Widget _campo(
    String rotulo,
    _CampoPontos c, {
    bool autofocus = false,
    bool ultimo = false,
  }) {
    return Row(
      children: [
        // muitos teclados numéricos não têm o sinal de menos: botão ±
        // fora da ordem de foco: o "próximo" do teclado vai direto ao campo
        // do jogador seguinte (o toque continua funcionando)
        ExcludeFocus(
          child: Tooltip(
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
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: c.ctrl,
            autofocus: autofocus,
            keyboardType: TextInputType.number,
            // ✓ do teclado pula para o próximo jogador; no último, lança
            textInputAction: ultimo
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: ultimo ? (_) => _lancar() : null,
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
