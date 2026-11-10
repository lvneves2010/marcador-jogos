import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../anuncios.dart';

class TelaTruco extends StatefulWidget {
  const TelaTruco({super.key, this.title = 'Placar de Truco'});

  final String title;

  @override
  State<TelaTruco> createState() => _TelaTrucoState();
}

class _TelaTrucoState extends State<TelaTruco> {
  int _counter = 0;
  int _counter2 = 0;
  bool nosGanhamos = false;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  //Loading counter value on start
  Future<void> _loadCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _counter = (prefs.getInt('counter') ?? 0);
      _counter2 = (prefs.getInt('counter2') ?? 0);
    });
  }

  void _incrementCounterUs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter < 12) {
        _counter = (prefs.getInt('counter') ?? 0) + 1;
        prefs.setInt('counter', _counter);
      }
    });
  }

  void _incrementTrucoUs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter < 12) {
        _counter = (prefs.getInt('counter') ?? 0) + 3;
        prefs.setInt('counter', _counter);
      }
      if (_counter >= 12) {
        _counter = 12;
        prefs.setInt('counter', _counter);
        nosGanhamos = true;
      }
    });
  }

  void _decrementCounterUs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter > 0) {
        _counter = (prefs.getInt('counter') ?? 0) - 1;
        prefs.setInt('counter', _counter);
      }
    });
  }

  void _incrementCounterThem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter2 < 12) {
        _counter2 = (prefs.getInt('counter2') ?? 0) + 1;
        prefs.setInt('counter2', _counter2);
      }
    });
  }

  void _incrementTrucoThem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter2 < 12) {
        _counter2 = (prefs.getInt('counter2') ?? 0) + 3;
        prefs.setInt('counter2', _counter2);
      }
      if (_counter2 >= 12) {
        _counter2 = 12;
        prefs.setInt('counter2', _counter2);
        nosGanhamos = true;
      }
    });
  }

  void _decrementCounterThem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_counter2 > 0) {
        _counter2 = (prefs.getInt('counter2') ?? 0) - 1;
        prefs.setInt('counter2', _counter2);
      }
    });
  }

  bool get _partidaTerminada => _counter >= 12 || _counter2 >= 12;

  void _resetCounter() {
    // depois de uma partida terminada é uma pausa natural: pode haver anúncio
    if (_partidaTerminada) {
      Anuncios.aoTerminarPartida(_zerar);
    } else {
      _zerar();
    }
  }

  void _zerar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _counter = 0;
      _counter2 = 0;
      prefs.setInt('counter', _counter);
      prefs.setInt('counter2', _counter2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Text('Nós', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$_counter', style: Theme.of(context).textTheme.displayLarge),
            Row(
              children: <Widget>[
                Spacer(),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: _incrementCounterUs,
                  child: Icon(Icons.arrow_upward),
                ),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: _incrementTrucoUs,
                  child: Text('Truco'),
                ),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: _decrementCounterUs,
                  child: Icon(Icons.arrow_downward),
                ),
                Spacer(),
              ],
            ),
            Spacer(),
            Text('Eles', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$_counter2', style: Theme.of(context).textTheme.displayLarge),
            Row(
              children: <Widget>[
                Spacer(),
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.red,
                  onPressed: _incrementCounterThem,
                  child: Icon(Icons.arrow_upward),
                ),
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.red,
                  onPressed: _incrementTrucoThem,
                  child: Text('Truco'),
                ),
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.red,
                  onPressed: _decrementCounterThem,
                  child: Icon(Icons.arrow_downward),
                ),
                Spacer(),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: const BarraInferior(),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: Colors.red,
        onPressed: _resetCounter,
        tooltip: 'novo jogo',
        child: Icon(Icons.autorenew),
      ),
    );
  }
}
