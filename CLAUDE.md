# Marcador de Jogos

App Flutter para marcar placar de **truco, dominó e buraco**, da **Help Soluções em Informática (HSI)**. O placar fica salvo no aparelho via `shared_preferences`. Nasceu em 2020 como "Placar de Truco" e foi modernizado e renomeado em nov/2026.

- Repo: https://github.com/lvneves2010/marcador-jogos (público, branch `master`). Antes se chamava `marcador-truco`; o GitHub redireciona o endereço antigo.
- **Pasta de trabalho: `C:\repos\HSI\marcador-jogos`**, um clone limpo criado em 2026-11-10. A pasta antiga `C:\repos\HSI\marcador-truco` ficou só como backup.
- applicationId e namespace: `br.com.hsi.marcadorjogos`. Pacote Dart: `marcador_jogos`. **O applicationId não pode mudar depois de publicado na Play.** Até 2026-11-10 era `com.example.marcador_truco`; um app instalado com esse ID é outro app no Android e precisa ser desinstalado à parte (o placar salvo nele não migra). Para conferir: `adb shell pm list packages | grep -E "marcador"`.
- iOS fora do escopo: o bundle `app.marcadorTruco` em `ios/Runner.xcodeproj` ficou como estava.
- O que o clone **não** traz (está no `.gitignore`) e foi copiado à mão da pasta antiga:
  - `PLANO_LANCAMENTO_PLAYSTORE.md`: checklist da publicação, com dados da empresa e passos com o contador. Fica fora do git de propósito.
  - `android/gradlew`, `gradle-wrapper.jar` e `local.properties` são regerados pelo Flutter no primeiro build.
- Push no GitHub: a máquina tem duas contas do GitHub (pessoal e Jadlog). Por isso o remote usa `https://lvneves2010@github.com/...`, e os commits usam o e-mail pessoal (`git config user.email` local).
- Projetos irmãos em `C:\repos\HSI`: `planevento` e `kira` (Ionic + Capacitor, os mesmos padrões de rodapé HSI e AdMob) e `leoneves-site` (onde vai ficar a política de privacidade).

## Estrutura

- [lib/main.dart](lib/main.dart): MaterialApp, `nomeApp` e cores da marca.
- [lib/telas/abertura.dart](lib/telas/abertura.dart): abertura (~3 s; um toque pula) com o ícone e o rodapé completo da HSI.
- [lib/telas/menu.dart](lib/telas/menu.dart): escolha do placar.
- [lib/telas/truco.dart](lib/telas/truco.dart) e [lib/telas/domino.dart](lib/telas/domino.dart): 2 a 4 jogadores, + 1 ponto por toque, até 12.
- [lib/telas/placar_rodadas.dart](lib/telas/placar_rodadas.dart): buraco, até 3000, com lançamento por rodada (parametrizado por `chave`/`metaPadrao`).
- [lib/versao.dart](lib/versao.dart): `RodapeEmpresa` (logo HSI + versão; `compacto: true` mostra só o logo e o número).
- [lib/anuncios.dart](lib/anuncios.dart): AdMob.
- Testes em [test/widget_test.dart](test/widget_test.dart).
- Chaves no SharedPreferences: truco `counter` (nós) e `counter2` (eles); buraco `buraco_nos`, `buraco_eles` (lista de pontos por rodada) e `buraco_meta`; dominó `domino_jogadores`, `domino_pontos`, `domino_nomes` e `domino_historico` (índices de quem pontuou, para desfazer).
- Nome exibido: "Marcador de Jogos" (`android:label` no AndroidManifest e `nomeApp`). A tela de truco continua com o título "Placar de Truco".
- Versão: `version:` do pubspec. O rodapé e a abertura mostram só a parte antes do `+`.

## Stack

- Flutter estável 3.47 / Dart `^3.13`, `shared_preferences` 2.x, `package_info_plus` e `google_mobile_ads` 9.x.
- Android: compile/target do Flutter atual (SDK 36), Gradle Kotlin DSL (`android/app/build.gradle.kts`). Já suporta 64 bits e páginas de 16 KB; foi isso que fez o app voltar a instalar no Redmi Note 15.

## Ícone e logo

- Ícone do app: cartas de baralho (J/K/Q de paus no feltro verde). As fontes ficam em `assets/icon/` (`icone.png`, `icone_fundo.png`/`icone_frente.png` do adaptive icon, script `gerar_icone.py`). Para regerar: `dart run flutter_launcher_icons`. Ícone da Play Store (512×512): `store/icone_playstore_512.png`.
- **O logo HSI não é o ícone do app** (a empresa tem outros apps). Ele aparece só no rodapé: `assets/images/logo_hsi.png`, gerado por `assets/icon/gerar_logo_hsi.py`.

## Publicidade (AdMob)

- Fluxo: consentimento UMP (GDPR/LGPD) → `MobileAds.initialize()` → `BannerAnuncio` (banner ancorado) dentro de `BarraInferior` (banner + rodapé compacto), no menu e nas telas de jogo. Não há anúncio na abertura.
- **Interstitial** (`Anuncios.aoTerminarPartida`): aparece só ao tocar "novo jogo" depois de uma partida TERMINADA (truco 12, dominó 12, buraco na meta). No máximo 1 a cada 3 min, nenhum nos 3 primeiros minutos de uso, e se não houver anúncio carregado o app segue sem esperar. Para testar: `--dart-define=INTERVALO_INTERSTITIAL_SEG=5`.
- Banner: 320×50 por padrão; `--dart-define=BANNER_GRANDE=true` usa o adaptativo grande.
- Sem parâmetros, usa os **IDs de teste do Google**. Em produção: App ID em `android/gradle.properties` (`admobAppId=ca-app-pub-...~...`, vira placeholder no manifesto) e IDs de bloco via `--dart-define=ADMOB_BANNER_ANDROID=...` / `ADMOB_INTERSTITIAL_ANDROID=...`.
- `android/app/proguard-rules.pro` tem regras do R8 para o WorkManager/Room do SDK de anúncios. **Sem elas, o release fecha ao abrir.** Sempre teste o build release no aparelho depois de adicionar plugins nativos.

## Play Store (pendências)

Os passos detalhados ficam em `PLANO_LANCAMENTO_PLAYSTORE.md` (fora do git).

- Publicar **só na Google Play** por enquanto, com conta de **organização** em nome da HSI (LEONARDO VINICIUS NEVES LTDA, CNPJ 31.412.990/0001-07, exige D-U-N-S).
- **Assinatura de release: ainda usa a chave de debug** (`signingConfig = signingConfigs.getByName("debug")` no `build.gradle.kts`). Antes do primeiro envio, gere a upload key (`.jks`) e o `android/key.properties`, os dois no `.gitignore` e **nunca commitados**, no mesmo esquema do planevento e do kira. Guarde backup fora do repo.
- Envie **AAB** (`flutter build appbundle`) e suba o `version: x.y.z+N` a cada envio.
- No Play Console: marcar "Contém anúncios", preencher Data safety (ID de publicidade coletado pelo SDK), classificação de conteúdo, feature graphic 1024×500, screenshots e a URL da política de privacidade (que precisa mencionar o AdMob).

## Ambiente nesta máquina (Windows 11)

- Flutter em `C:\src\flutter`, **fora do PATH**: use `export PATH=/c/src/flutter/bin:$PATH`. O `flutter config --jdk-dir` aponta para o JBR do Android Studio.
- Android SDK em `%LOCALAPPDATA%\Android\Sdk`. O adb já está no PATH.
- Celular de testes: Xiaomi (modelo 25080RABDG, Android 16). Se a instalação via USB for cancelada, desbloqueie a tela e aceite o aviso.

## Comandos

```bash
export PATH=/c/src/flutter/bin:$PATH
flutter pub get
flutter analyze
flutter test
flutter run                          # celular conectado via USB
# APK para instalar direto (um por arquitetura; o celular de testes usa o arm64-v8a)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
# AAB para a Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info --dart-define=ADMOB_BANNER_ANDROID=<id real>
```

- Guarde a pasta do `--split-debug-info` de cada versão publicada: é com ela que dá para ler os stack traces de crashes.
- O APK "universal" (sem `--split-per-abi`) tem ~50 MB; não use para distribuir.
