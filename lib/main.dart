import 'package:flutter/material.dart';

import 'anuncios.dart';
import 'telas/abertura.dart';

const nomeApp = 'Marcador de Jogos';
const corDestaque = Color(0xFFFFA000);

void main() {
  runApp(const MyApp());
  // consentimento + SDK de anúncios em segundo plano (não atrasa a abertura)
  Anuncios.iniciar();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.duracaoAbertura = const Duration(seconds: 3)});

  /// Tempo que a tela de abertura fica visível antes de ir para o menu.
  final Duration duracaoAbertura;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nomeApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TelaAbertura(duracao: duracaoAbertura),
    );
  }
}
