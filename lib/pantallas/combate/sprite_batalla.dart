import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';

import 'elementos_batalla.dart';

class SpriteBatalla extends StatefulWidget {
  const SpriteBatalla(this.pokemon, {super.key, required this.deEspaldas});

  final Combatiente pokemon;
  final bool deEspaldas;

  @override
  State<SpriteBatalla> createState() => _SpriteBatallaState();
}

class _SpriteBatallaState extends State<SpriteBatalla> {
  ImageStream? _flujo;
  ImageInfo? _imagen;
  Rect? _recorte;
  bool _sinSprite = false;
  late final _escucha = ImageStreamListener(_mostrar, onError: _mostrarArte);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cargar();
  }

  @override
  void didUpdateWidget(SpriteBatalla anterior) {
    super.didUpdateWidget(anterior);
    if (widget.pokemon.idPokemon != anterior.pokemon.idPokemon ||
        widget.deEspaldas != anterior.deEspaldas) {
      _cargar();
    }
  }

  void _cargar() {
    final lado = widget.deEspaldas ? 'back/' : '';
    final flujo = NetworkImage(
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
      'sprites/pokemon/$lado${widget.pokemon.idPokemon}.png',
    ).resolve(createLocalImageConfiguration(context));
    if (flujo.key == _flujo?.key) return;
    _flujo?.removeListener(_escucha);
    _imagen?.dispose();
    _imagen = null;
    _recorte = null;
    _sinSprite = false;
    _flujo = flujo;
    flujo.addListener(_escucha);
  }

  Future<void> _mostrar(ImageInfo imagen, bool sincrono) async {
    final flujo = _flujo;
    final ui.Image fotograma = imagen.image;
    Rect? recorte;
    try {
      final datos = await fotograma.toByteData();
      if (datos != null) {
        var izquierda = fotograma.width;
        var derecha = -1;
        var arriba = fotograma.height;
        var abajo = -1;
        for (var y = 0; y < fotograma.height; y++) {
          for (var x = 0; x < fotograma.width; x++) {
            final alpha = datos.getUint8((y * fotograma.width + x) * 4 + 3);
            if (alpha < 32) continue;
            if (x < izquierda) izquierda = x;
            if (x > derecha) derecha = x;
            if (y < arriba) arriba = y;
            abajo = y;
          }
        }
        if (derecha >= izquierda) {
          recorte = Rect.fromLTRB(
            izquierda.toDouble(),
            arriba.toDouble(),
            derecha + 1.0,
            abajo + 1.0,
          );
        }
      }
    } catch (_) {
      recorte = null;
    }
    if (!mounted || flujo != _flujo) {
      imagen.dispose();
      return;
    }
    setState(() {
      _imagen?.dispose();
      _imagen = imagen;
      _recorte =
          recorte ??
          Rect.fromLTWH(
            0,
            0,
            fotograma.width.toDouble(),
            fotograma.height.toDouble(),
          );
    });
  }

  void _mostrarArte(Object error, StackTrace? stack) {
    if (mounted) setState(() => _sinSprite = true);
  }

  @override
  void dispose() {
    _flujo?.removeListener(_escucha);
    _imagen?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sinSprite) return ArteCombatiente(widget.pokemon);
    final imagen = _imagen;
    if (imagen == null) return const SizedBox.expand();
    return CustomPaint(
      painter: _SpriteAlineado(imagen.image, _recorte!),
      child: const SizedBox.expand(),
    );
  }
}

class _SpriteAlineado extends CustomPainter {
  const _SpriteAlineado(this.imagen, this.recorte);

  final ui.Image imagen;
  final Rect recorte;

  @override
  void paint(Canvas canvas, Size size) {
    final ajustado = applyBoxFit(BoxFit.contain, recorte.size, size);
    final destino = Alignment.bottomCenter.inscribe(
      ajustado.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      imagen,
      recorte,
      destino,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _SpriteAlineado anterior) =>
      anterior.imagen != imagen || anterior.recorte != recorte;
}
