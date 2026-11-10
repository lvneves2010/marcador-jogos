# Marcador de Jogos

Placar de truco, dominó e buraco no celular, sem complicação: toque para somar pontos, desfaça o último lance e comece uma nova partida. O placar fica salvo no aparelho.

Um app da **Help Soluções em Informática (HSI)**, feito em Flutter. Antes este projeto se chamava "Placar de Truco" (`marcador-truco`).

## Rodando

Requer o Flutter estável e o Android SDK.

```bash
flutter pub get
flutter run                        # celular conectado por USB
flutter build apk --release --split-per-abi
```

Detalhes de arquitetura, anúncios e publicação: [CLAUDE.md](CLAUDE.md).
