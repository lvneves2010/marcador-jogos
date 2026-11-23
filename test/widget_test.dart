import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marcador_jogos/main.dart';
import 'package:marcador_jogos/telas/domino.dart';
import 'package:marcador_jogos/telas/pingue_pongue.dart';
import 'package:marcador_jogos/telas/placar_livre.dart';
import 'package:marcador_jogos/telas/placar_rodadas.dart';
import 'package:marcador_jogos/telas/truco.dart';

Widget _app(Widget tela) => MaterialApp(home: tela);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Marcador de Jogos',
      packageName: 'br.com.hsi.marcadorjogos',
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
      expect(find.text('Canastra'), findsOneWidget);
      expect(find.text('Tranca'), findsOneWidget);
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

    testWidgets('menu abre canastra, tranca, pingue-pongue e placar livre', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp(duracaoAbertura: Duration.zero));
      await tester.pumpAndSettle();
      for (final (opcao, titulo, detalhe) in [
        ('Canastra', 'Placar de Canastra', 'Meta: 5000 pontos'),
        ('Tranca', 'Placar de Tranca', 'Meta: 3000 pontos'),
        ('Pingue-pongue', 'Pingue-pongue', 'Games de 11 · melhor de 3'),
        (
          'Placar livre',
          'Placar Livre',
          '2 jogadores · Sem meta · maior vence',
        ),
      ]) {
        await tester.scrollUntilVisible(find.text(opcao), 100);
        await tester.tap(find.text(opcao));
        await tester.pumpAndSettle();
        expect(find.text(titulo), findsWidgets);
        expect(find.text(detalhe), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
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

  group('pingue-pongue', () {
    PartidaPingue jogar(String seq, {int meta = 11, int melhorDe = 3}) =>
        PartidaPingue(
          pontos: [for (final c in seq.split('')) int.parse(c)],
          meta: meta,
          melhorDe: melhorDe,
        );

    test('game exige 2 de vantagem', () {
      // 10 × 10, depois 11 × 10: ainda não fechou
      final p = jogar('${'01' * 10}0');
      expect(p.placar, [11, 10]);
      expect(p.games, [0, 0]);
      final fechou = jogar('${'01' * 10}00');
      expect(fechou.games, [1, 0]);
      expect(fechou.placar, [0, 0]);
      expect(fechou.parciais, [(12, 10)]);
    });

    test('saque troca a cada 2 pontos e a cada ponto no 10 × 10', () {
      expect(jogar('').sacador, 0);
      expect(jogar('0').sacador, 0);
      expect(jogar('01').sacador, 1);
      expect(jogar('011').sacador, 1);
      expect(jogar('0110').sacador, 0);
      final deuce = '01' * 10; // 10 × 10, 20 pontos: volta para quem começou
      expect(jogar(deuce).sacador, 0);
      expect(jogar('${deuce}0').sacador, 1);
      expect(jogar('${deuce}01').sacador, 0);
    });

    test('game de 21 troca o saque a cada 5 pontos', () {
      expect(jogar('0000', meta: 21).sacador, 0);
      expect(jogar('00000', meta: 21).sacador, 1);
    });

    test('2º game começa com o outro sacando e melhor de 3 termina', () {
      final g1 = '0' * 11;
      expect(jogar(g1).sacador, 1);
      final p = jogar(g1 + '1' * 11 + '0' * 11);
      expect(p.games, [2, 1]);
      expect(p.vencedor, 0);
      // pontos depois do fim são ignorados
      expect(jogar('${g1 * 2}1').placar, [0, 0]);
      expect(jogar(g1, melhorDe: 1).vencedor, 0);
    });

    testWidgets('toque no lado soma ponto, desfaz e salva', (tester) async {
      await tester.pumpWidget(_app(const TelaPinguePongue()));
      await tester.pumpAndSettle();
      expect(find.text('Saque'), findsOneWidget);

      // antes do 1º ponto, o jogador 2 pode começar sacando
      await tester.tap(find.text('Começar sacando'));
      await tester.pump();
      expect(find.text('Começar sacando'), findsOneWidget); // agora no 1

      await tester.tap(find.text('Games: 0').first);
      await tester.tap(find.text('Games: 0').first);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Começar sacando'), findsNothing);

      await tester.tap(find.byTooltip('Desfazer último ponto'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('pingue_pontos'), ['0']);
      expect(prefs.getInt('pingue_saque'), 1);
    });
  });

  group('placar livre', () {
    testWidgets('3 jogadores, menor vence ao chegar na meta', (tester) async {
      await tester.pumpWidget(_app(const TelaPlacarLivre()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.tap(find.text('Menos pontos'));
      await tester.enterText(find.byType(TextField), '100');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.text('3 jogadores · Até 100 pontos · menor vence'),
        findsOneWidget,
      );
      expect(find.text('Jogador 3'), findsOneWidget);

      Future<void> rodada(List<String> v) async {
        await tester.tap(find.text('Rodada'));
        await tester.pumpAndSettle();
        for (var j = 0; j < v.length; j++) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Jogador ${j + 1}'),
            v[j],
          );
        }
        await tester.tap(find.text('Lançar'));
        await tester.pumpAndSettle();
      }

      await rodada(['40', '10', '30']);
      expect(find.textContaining('venceu'), findsNothing);
      await rodada(['70', '20', '5']);
      expect(find.text('Jogador 2 venceu!'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('livre_rodadas'), ['40,10,30', '70,20,5']);
      expect(prefs.getBool('livre_menor_vence'), true);
      expect(prefs.getInt('livre_meta'), 100);

      await tester.tap(find.byTooltip('Desfazer última rodada'));
      await tester.pumpAndSettle();
      expect(find.textContaining('venceu'), findsNothing);
    });
  });
}
