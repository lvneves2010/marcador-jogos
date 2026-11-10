import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marcador_truco/main.dart';
import 'package:marcador_truco/telas/domino.dart';
import 'package:marcador_truco/telas/placar_rodadas.dart';
import 'package:marcador_truco/telas/truco.dart';

Widget _app(Widget tela) => MaterialApp(home: tela);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Marcador de Jogos',
      packageName: 'com.example.marcador_truco',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('abertura e menu', () {
    testWidgets('abertura mostra empresa e versão e vai para o menu', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.text('Help Soluções em Informática'), findsOneWidget);
      expect(find.text('Marcador de Jogos'), findsOneWidget);
      expect(find.text('versão 1.0.1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Escolha o placar'), findsOneWidget);
      expect(find.text('Truco'), findsOneWidget);
      expect(find.text('Buraco'), findsOneWidget);
      expect(find.text('Dominó'), findsOneWidget);
      // menu: rodapé compacto (logo + número da versão)
      expect(find.text('1.0.1'), findsOneWidget);
      expect(find.text('Help Soluções em Informática'), findsNothing);
    });

    testWidgets('menu abre o truco', (tester) async {
      await tester.pumpWidget(const MyApp(duracaoAbertura: Duration.zero));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Truco'));
      await tester.pumpAndSettle();
      expect(find.text('Placar de Truco'), findsOneWidget);
    });
  });

  group('truco', () {
    testWidgets('placar começa zerado e soma pontos', (tester) async {
      await tester.pumpWidget(_app(const TelaTruco()));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.arrow_upward).first);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Truco').last);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.autorenew));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('carrega placar salvo', (tester) async {
      SharedPreferences.setMockInitialValues({'counter': 7, 'counter2': 11});
      await tester.pumpWidget(_app(const TelaTruco()));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
    });
  });

  group('placar por rodadas', () {
    const buraco = TelaPlacarRodadas(
      titulo: 'Placar de Buraco',
      chave: 'buraco',
      metaPadrao: 3000,
    );

    testWidgets('lança rodadas, aceita negativo, desfaz e salva', (
      tester,
    ) async {
      await tester.pumpWidget(_app(buraco));
      await tester.pumpAndSettle();
      expect(find.text('Meta: 3000 pontos'), findsOneWidget);

      await tester.tap(find.text('Rodada'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nós'), '850');
      await tester.enterText(find.widgetWithText(TextField, 'Eles'), '120');
      await tester.tap(find.byTooltip('Trocar sinal').last); // Eles negativo
      await tester.pump();
      await tester.tap(find.text('Lançar'));
      await tester.pumpAndSettle();

      expect(find.text('850'), findsOneWidget);
      expect(find.text('-120'), findsNWidgets(2)); // total e rodada

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('buraco_nos'), ['850']);
      expect(prefs.getStringList('buraco_eles'), ['-120']);

      await tester.tap(find.byTooltip('Desfazer última rodada'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma rodada ainda'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    });
  });

  group('dominó', () {
    testWidgets('soma com (+), desfaz e declara vencedor em 12', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const TelaDomino()));
      await tester.pumpAndSettle();
      expect(find.text('Nós'), findsOneWidget);
      expect(find.text('Eles'), findsOneWidget);
      expect(find.text('Jogo até 12 pontos'), findsOneWidget);

      final maisNos = find.byTooltip('Somar ponto para Nós');
      Finder placarNos(String v) =>
          find.descendant(of: find.byType(Card).first, matching: find.text(v));
      await tester.tap(maisNos);
      await tester.tap(maisNos);
      await tester.pump();
      expect(placarNos('2'), findsOneWidget);

      await tester.tap(find.byTooltip('Desfazer último ponto'));
      await tester.pump();
      expect(placarNos('1'), findsOneWidget);

      for (var k = 0; k < 11; k++) {
        await tester.tap(maisNos);
      }
      await tester.pump();
      expect(placarNos('12'), findsOneWidget);
      expect(find.text('Nós venceu!'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('domino_pontos'), ['12', '0']);

      // novo jogo após partida terminada (ponto do interstitial): sem anúncio
      // carregado, zera na hora
      await tester.tap(find.byTooltip('Novo jogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(placarNos('0'), findsOneWidget);
      expect(find.text('Jogo até 12 pontos'), findsOneWidget);
    });

    testWidgets('meta do dominó é ajustável e fica salva', (tester) async {
      await tester.pumpWidget(_app(const TelaDomino()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jogo até 12 pontos'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Jogo até 3 pontos'), findsOneWidget);

      final maisEles = find.byTooltip('Somar ponto para Eles');
      for (var k = 0; k < 3; k++) {
        await tester.tap(maisEles);
      }
      await tester.pump();
      expect(find.text('Eles venceu!'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('domino_meta'), 3);
    });

    testWidgets('muda para 4 jogadores', (tester) async {
      await tester.pumpWidget(_app(const TelaDomino()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      for (var n = 1; n <= 4; n++) {
        expect(find.text('Jogador $n'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Somar ponto para Jogador 3'));
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('domino_jogadores'), 4);
      expect(prefs.getStringList('domino_pontos'), ['0', '0', '1', '0']);
    });
  });
}
