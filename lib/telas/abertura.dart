import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../versao.dart';
import 'menu.dart';

class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key, required this.duracao});

  final Duration duracao;

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duracao, _irParaMenu);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // decodifica as imagens já no primeiro frame (evita o "pisca" ao abrir)
    precacheImage(const AssetImage('assets/images/icone_app.png'), context);
    precacheImage(const AssetImage('assets/images/logo_hsi.png'), context);
  }

  void _irParaMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const TelaMenu(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          // toque pula a abertura
          onTap: () {
            _timer?.cancel();
            _irParaMenu();
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(width: double.infinity, child: _conteudo()),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Column(
      children: [
        const Spacer(flex: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset(
            'assets/images/icone_app.png',
            width: 160,
            height: 160,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          nomeApp,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(flex: 3),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: corDestaque),
        ),
        const Spacer(),
        const RodapeEmpresa(),
      ],
    );
  }
}
