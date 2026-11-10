import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'versao.dart';

/// Publicidade (Google AdMob).
///
/// Sem parâmetros de build usa os IDs de TESTE do Google (seguros para
/// desenvolver; nunca clique em anúncios reais do próprio app).
/// Para produção, passe os IDs reais do AdMob no build:
///
///   flutter build appbundle --release \
///     --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/YYYY
///
/// e o App ID em android/gradle.properties (`admobAppId=ca-app-pub-XXXX~ZZZZ`).
class Anuncios {
  Anuncios._();

  /// Tamanho do banner: padrão 320×50 (pequeno). Com
  /// `--dart-define=BANNER_GRANDE=true` usa o adaptativo grande (largura toda,
  /// mais alto, costuma render mais).
  static const bannerGrande = bool.fromEnvironment('BANNER_GRANDE');

  // IDs de teste do Google (um para cada tipo de banner).
  static const _testeAndroid = bannerGrande
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/6300978111';
  static const _testeIos = bannerGrande
      ? 'ca-app-pub-3940256099942544/2435281174'
      : 'ca-app-pub-3940256099942544/2934735716';

  static const _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: _testeAndroid,
  );
  static const _bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: _testeIos,
  );

  static String get bannerId => Platform.isIOS ? _bannerIos : _bannerAndroid;

  static const _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712', // teste
  );
  static const _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910', // teste
  );

  /// Intervalo mínimo entre interstitials (e desde a abertura do app).
  /// Padrão 3 min; `--dart-define=INTERVALO_INTERSTITIAL_SEG=5` só p/ testar.
  static const intervaloInterstitial = Duration(
    seconds: int.fromEnvironment(
      'INTERVALO_INTERSTITIAL_SEG',
      defaultValue: 180,
    ),
  );

  static InterstitialAd? _interstitial;
  static bool _carregandoInterstitial = false;
  static DateTime _ultimoInterstitial = DateTime.now();

  /// true depois do consentimento e da inicialização do SDK.
  static final prontos = ValueNotifier<bool>(false);

  /// true quando o usuário precisa ter acesso às opções de privacidade
  /// (ex.: Europa/GDPR) — o menu mostra um botão nesse caso.
  static final precisaOpcoesPrivacidade = ValueNotifier<bool>(false);

  static bool _iniciando = false;

  /// Coleta o consentimento (UMP) e inicializa o SDK. Não bloqueia o app.
  static void iniciar() {
    if (_iniciando) return;
    _iniciando = true;
    _ultimoInterstitial = DateTime.now(); // nada de tela cheia logo ao abrir
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => _iniciarSdk());
      },
      (_) => _iniciarSdk(), // sem rede etc.: tenta com o consentimento anterior
    );
  }

  static Future<void> _iniciarSdk() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    precisaOpcoesPrivacidade.value =
        status == PrivacyOptionsRequirementStatus.required;
    if (prontos.value || !await ConsentInformation.instance.canRequestAds()) {
      return;
    }
    await MobileAds.instance.initialize();
    prontos.value = true;
    _carregarInterstitial();
  }

  static void abrirOpcoesPrivacidade() {
    ConsentForm.showPrivacyOptionsForm((_) => _iniciarSdk());
  }

  /// Deixa um interstitial pré-carregado para a próxima pausa natural.
  static void _carregarInterstitial() {
    if (!prontos.value || _interstitial != null || _carregandoInterstitial) {
      return;
    }
    _carregandoInterstitial = true;
    InterstitialAd.load(
      adUnitId: Platform.isIOS ? _interstitialIos : _interstitialAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _carregandoInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _carregandoInterstitial = false; // tenta de novo na próxima partida
        },
      ),
    );
  }

  /// Chamar quando o usuário começa um novo jogo depois de uma partida
  /// TERMINADA. Mostra o interstitial se houver um carregado e já passou o
  /// intervalo mínimo; em qualquer caso chama [continuar] (depois que o
  /// anúncio fecha, ou na hora se não houver anúncio).
  static void aoTerminarPartida(VoidCallback continuar) {
    final ad = _interstitial;
    final cedoDemais =
        DateTime.now().difference(_ultimoInterstitial) < intervaloInterstitial;
    if (ad == null || cedoDemais) {
      _carregarInterstitial();
      continuar();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ultimoInterstitial = DateTime.now();
        _carregarInterstitial();
        continuar();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _carregarInterstitial();
        continuar();
      },
    );
    ad.show();
  }
}

/// Banner adaptativo ancorado (largura da tela). Não ocupa espaço até
/// carregar; se não houver anúncio, simplesmente não aparece.
class BannerAnuncio extends StatefulWidget {
  const BannerAnuncio({super.key});

  @override
  State<BannerAnuncio> createState() => _BannerAnuncioState();
}

class _BannerAnuncioState extends State<BannerAnuncio> {
  BannerAd? _ad;
  bool _carregado = false;
  int? _larguraCarregada;

  @override
  void initState() {
    super.initState();
    Anuncios.prontos.addListener(_carregar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!Anuncios.prontos.value || !mounted) return;
    final largura = MediaQuery.sizeOf(context).width.truncate();
    if (largura == _larguraCarregada) return; // já carregado p/ esta largura
    _larguraCarregada = largura;

    final AdSize? size = Anuncios.bannerGrande
        ? await AdSize.getLargeAnchoredAdaptiveBannerAdSize(largura)
        : AdSize.banner;
    if (size == null || !mounted) return;

    await _ad?.dispose();
    _ad = BannerAd(
      adUnitId: Anuncios.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _carregado = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _carregado = false;
              _larguraCarregada = null;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    Anuncios.prontos.removeListener(_carregar);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_carregado || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

/// Barra inferior das telas internas: banner + rodapé compacto (logo e versão).
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [BannerAnuncio(), RodapeEmpresa(compacto: true)],
    );
  }
}
