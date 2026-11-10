# Placar de Truco (marcador-truco)

App Flutter simples para marcar o placar de uma partida de truco ("Nós" × "Eles", até 12 pontos), com o placar salvo localmente via `shared_preferences`. Projeto pessoal do Leonardo, escrito por volta de 2020 e nunca atualizado desde então.

- Repo: https://github.com/lvneves2010/marcador-truco (público, branch `master`). O push funciona pelo Git Credential Manager da máquina.
- Estrutura: [lib/main.dart](lib/main.dart) (MaterialApp, nome e cores da marca) → [lib/telas/abertura.dart](lib/telas/abertura.dart) (logo HSI + versão, ~3 s) → [lib/telas/menu.dart](lib/telas/menu.dart) (escolha do placar) → [truco.dart](lib/telas/truco.dart) [domino.dart](lib/telas/domino.dart) (2 a 4 jogadores, botão + de 1 ponto por toque, até 12) e [placar_rodadas.dart](lib/telas/placar_rodadas.dart) (buraco até 3000, lançamento por rodada; parametrizado por `chave`/`metaPadrao`). Testes em [test/widget_test.dart](test/widget_test.dart).
- Chaves no SharedPreferences: truco `counter` (nós) e `counter2` (eles); buraco `buraco_nos`, `buraco_eles` (lista de pontos por rodada) e `buraco_meta`; dominó `domino_jogadores`, `domino_pontos`, `domino_nomes`, `domino_historico` (índices de quem pontuou, para desfazer).
- Nome exibido: "Marcador de Jogos" (`android:label` no AndroidManifest, `nomeApp` em `lib/main.dart`). Empresa: Help Soluções em Informática (HSI).
- Ícone do app: cartas de baralho (J/K/Q de paus no feltro verde), redesenhado em alta resolução a partir do ícone original de 192 px. Fontes em `assets/icon/` (icone.png, icone_fundo/icone_frente.png do adaptive icon e o script `gerar_icone.py`); ícones Android/iOS regerados com `dart run flutter_launcher_icons`. Ícone da Play Store (512×512, PNG 32 bits): `store/icone_playstore_512.png`. **O logo HSI não é o ícone do app** (a empresa terá outros apps): ele aparece só no rodapé (`RodapeEmpresa` em `lib/versao.dart`: completo na abertura, `compacto: true` = logo + número da versão nas demais telas), em `assets/images/logo_hsi.png` (script `assets/icon/gerar_logo_hsi.py`).
- Versão: `version:` do pubspec; o rodapé/abertura mostram só a parte antes do `+`.

## Objetivos deste ciclo de trabalho

1. **Compatibilidade com aparelhos novos.** O APK antigo instalava no Redmi Note 8 e no Redmi Note 11, mas o Redmi Note 15 recusa a instalação dizendo que o app é "incompatível".
2. **Publicar na Google Play Store.**
3. **Trocar o ícone pelo logo da empresa do Leonardo.** O arquivo do logo ainda não foi fornecido: peça antes de começar essa parte e confirme qual é a empresa/marca.

**Decisões (nov/2026):** publicar **só na Google Play** por enquanto (iOS fica de fora: não mexer em `ios/` além do necessário). A conta da Play será de **organização**, em nome da empresa do Leonardo: LEONARDO VINICIUS NEVES LTDA, nome fantasia Help Soluções em Informática (HSI), CNPJ 31.412.990/0001-07 (exige D-U-N-S).

Trabalhe nessa ordem: o (1) é pré-requisito para o (2), e o ícone entra antes do primeiro upload para a loja.

## Estado atual (tudo muito defasado)

| Item | Atual | Observação |
|---|---|---|
| Dart SDK | `>=2.7.0 <3.0.0` | sem null safety (`Key key`, sem `?`/`required`) |
| shared_preferences | `^0.5.4+8` | API antiga |
| cupertino_icons | `^0.1.3` | |
| compileSdk / targetSdk | 28 / 28 | |
| minSdk | 16 | |
| AGP / Gradle / Kotlin | 3.5.0 / 5.6.2 / 1.3.50 | `jcenter()`, `apply plugin` imperativo |
| applicationId | `com.example.marcador_truco` | **a Play Store rejeita `com.example.*`** |
| Application class | `io.flutter.app.FlutterApplication` | removida no Flutter atual |
| Assinatura release | `signingConfig signingConfigs.debug` | `key.properties` já está no `.gitignore`, mas não existe |

## Hipóteses para o "incompatível" no Redmi Note 15

Ainda não foi diagnosticado. Antes de corrigir, confirme a causa com o aparelho conectado (`adb devices`, `adb shell getprop ro.product.cpu.abilist`, `adb shell getconf PAGE_SIZE`, `adb install -r app.apk` para ver o código de erro exato). As candidatas, da mais provável para a menos:

- **Só 64 bits.** Aparelhos novos podem rodar só `arm64-v8a`, e um APK antigo gerado só com `armeabi-v7a` não instala neles.
- **Páginas de memória de 16 KB.** No Android 15+ as `.so` nativas (o `libflutter.so` antigo) precisam estar alinhadas a 16 KB. Os Flutter/AGP atuais já fazem isso.
- **targetSdk antigo demais** para a versão do Android do aparelho.

As três se resolvem do mesmo jeito: atualizar para um Flutter estável recente e gerar o build com a toolchain atual.

## Abordagem recomendada para a migração

O salto de versão é grande demais para atualizar arquivo por arquivo. É mais seguro:

1. Gerar um projeto novo com `flutter create --org <org> --project-name marcador_truco --platforms android,ios .`, num diretório temporário ou por cima deste numa branch. O `--org` define o applicationId: combine com o Leonardo, por exemplo `br.com.<empresa>`. **O applicationId não pode mudar depois da publicação.**
2. Copiar a lógica de `lib/main.dart` e migrar para null safety (Dart 3).
3. Atualizar `shared_preferences` para a versão atual, mantendo as mesmas chaves.
4. Manter `android:label` = "Placar de Truco".
5. Rodar `flutter analyze` e `flutter test`, corrigindo o widget test para refletir o app de verdade.
6. Testar num aparelho/emulador recente (API 35/36) e, se possível, também num antigo.

Trabalhe numa branch (por exemplo `modernizacao`), não direto na `master`. Commit e push só quando o Leonardo pedir.

## Play Store: o que o build precisa ter

- Um **Android App Bundle** (`flutter build appbundle --release`), não APK.
- O targetSdk exigido pela Play no momento: confira a exigência atual em developer.android.com/google-play/requirements/target-sdk em vez de assumir um número.
- Suporte a páginas de 16 KB (já vem com a toolchain atual).
- Assinatura com **upload key** própria: um keystore `.jks` gerado com `keytool`, mais `android/key.properties` apontando para ele. **Nunca commitar o keystore nem o `key.properties`.** Oriente o Leonardo a guardar backup dos dois fora do repo; se perder o upload key, só dá para recuperar pelo suporte da Play.
- `versionCode` incrementado a cada envio (o `version: x.y.z+N` no `pubspec.yaml`).
- Fora do código, o Leonardo cuida no Play Console: conta de desenvolvedor, política de privacidade (o app não coleta dados, mas a Play exige a URL; dá para hospedar no site pessoal dele em `C:\repos\leoneves-site`), formulário de Data safety, classificação de conteúdo, ícone 512×512, feature graphic 1024×500 e screenshots. Contas pessoais novas precisam de teste fechado com testadores antes de ir para produção. Confirme a regra atual no Play Console.

## Ícone / logo

- Use o pacote `flutter_launcher_icons` (dev_dependency) para gerar os ícones Android (incluindo **adaptive icon**: foreground + background) e iOS a partir de um único arquivo-fonte.
- Arquivo-fonte ideal: PNG quadrado de 1024×1024, com o logo dentro da área segura central (~66%) por causa da máscara do adaptive icon. Salve-o em `assets/icon/`.
- Opcional: aplicar o logo/cores também na splash (`flutter_native_splash`) e no tema do app. Pergunte antes.

## Ambiente nesta máquina (Windows 11)

- Flutter estável instalado em `C:\src\flutter` (**não está no PATH**: use `export PATH=/c/src/flutter/bin:$PATH`), com `flutter config --jdk-dir` apontando para o JBR do Android Studio.
- Android SDK em `%LOCALAPPDATA%\Android\Sdk`, com platforms 33–36 e build-tools até 36.1.0. O `platform-tools` (adb) já está no PATH.
- Java no PATH: OpenJDK 11 (sdkman). **O AGP atual exige JDK 17+.** Use o JBR do Android Studio, se existir, ou instale o 17/21 e aponte com `flutter config --jdk-dir`.
- O build de iOS precisa de macOS e não roda aqui. Não mexa em `ios/` além do que o `flutter create` gerar, a menos que o Leonardo peça.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run                          # aparelho conectado via USB (depuração USB ligada)
# APK para instalar direto no celular (um por arquitetura; o Note 15 usa o arm64-v8a)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
# AAB para a Play Store (a Play entrega só a arquitetura de cada aparelho)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info   --dart-define=ADMOB_BANNER_ANDROID=<id do bloco de anúncio real>
```

- `--split-debug-info` guarda os símbolos fora do app (libapp ~17% menor); guarde a pasta de cada versão publicada para conseguir ler stack traces de crashes.
- O APK "universal" (`flutter build apk --release` sem `--split-per-abi`) tem ~50 MB porque leva 3 arquiteturas; não use para distribuir.

## Publicidade (AdMob)

- Código em [lib/anuncios.dart](lib/anuncios.dart): consentimento UMP (GDPR/LGPD) → `MobileAds.initialize()` → `BannerAnuncio` (banner adaptativo ancorado) dentro de `BarraInferior` (banner + rodapé compacto) no menu e nas telas de jogo. Não há anúncio na abertura.
- **Interstitial** (`Anuncios.aoTerminarPartida`): só ao tocar "novo jogo" depois de uma partida TERMINADA (truco 12, dominó 12, buraco na meta); no máximo 1 a cada 3 min e nenhum nos 3 primeiros minutos de uso; se não houver anúncio carregado, segue sem esperar. Para testar sem esperar: `--dart-define=INTERVALO_INTERSTITIAL_SEG=5`. Produção: `--dart-define=ADMOB_INTERSTITIAL_ANDROID=...`.
- Banner: padrão 320×50; `--dart-define=BANNER_GRANDE=true` usa o adaptativo grande.
- Sem parâmetros, usa os **IDs de teste do Google**. Produção: App ID em `android/gradle.properties` (`admobAppId=ca-app-pub-...~...`, vira placeholder no manifesto) e IDs de bloco via `--dart-define=ADMOB_BANNER_ANDROID=...` / `ADMOB_BANNER_IOS=...`. iOS: trocar `GADApplicationIdentifier` no `ios/Runner/Info.plist`.
- `android/app/proguard-rules.pro` tem regras do R8 para o WorkManager/Room do SDK de anúncios. **Sem elas o release fecha ao abrir** (`Failed to create an instance of androidx.work.impl.WorkDatabase`). Sempre teste o build release no aparelho depois de adicionar plugins nativos.
- Com anúncios, na Play Console: marcar "Contém anúncios", Data safety declarando ID de publicidade/dados do dispositivo coletados pelo SDK, e a política de privacidade precisa mencionar o AdMob.
