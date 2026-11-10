import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Texto "versão x.y.z" lido do build (vem do `version:` do pubspec.yaml).
class TextoVersao extends StatelessWidget {
  const TextoVersao({super.key, this.style, this.prefixo = 'versão '});

  final TextStyle? style;
  final String prefixo;

  static final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snap) => Text(
        snap.hasData ? '$prefixo${snap.data!.version}' : '',
        style: style ?? Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Rodapé discreto com o logo da empresa ao lado do nome e da versão.
/// [compacto] mostra só o logo e o número da versão (menu e telas de jogo).
class RodapeEmpresa extends StatelessWidget {
  const RodapeEmpresa({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compacto ? 6 : 10),
        child: Opacity(
          opacity: 0.75,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_hsi.png',
                width: compacto ? 20 : 26,
                height: compacto ? 20 : 26,
              ),
              SizedBox(width: compacto ? 6 : 8),
              if (compacto)
                TextoVersao(style: estilo, prefixo: '')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Help Soluções em Informática', style: estilo),
                    TextoVersao(style: estilo),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
