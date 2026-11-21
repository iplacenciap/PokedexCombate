import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/equipos_duelo_prueba.dart';
import 'package:proyecto_pokedex/pantallas/combate/campo_batalla.dart';
import 'package:proyecto_pokedex/pantallas/combate/elementos_batalla.dart';
import 'package:proyecto_pokedex/pantallas/combate/escenario_batalla.dart';
import 'package:proyecto_pokedex/pantallas/combate/pantalla_batalla.dart';
import 'package:proyecto_pokedex/pantallas/combate/pradera_duelos.dart';
import 'package:proyecto_pokedex/pantallas/combate/sprite_batalla.dart';
import 'package:proyecto_pokedex/pantallas/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

void main() {
  for (final ancho in [360.0, 1060.0]) {
    testWidgets('juega la práctica desde la Pokédex con ancho $ancho', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(ancho, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: MainLayout()));
        await tester.pumpAndSettle();

        await tocar(tester, find.text('Combates'));
        await tocar(tester, find.text('Iniciar duelo de prueba'));
        expect(find.byType(PraderaDuelos), findsOneWidget);
        expect(find.text('Pidgey'), findsOneWidget);
        final ataque = find.byKey(const ValueKey('movimiento_batalla_0'));
        for (
          var turno = 0;
          turno < 5 && find.text('Geodude').evaluate().isEmpty;
          turno++
        ) {
          await tocar(tester, ataque);
          final instante = tester.widget<CampoBatalla>(
            find.byType(CampoBatalla),
          );
          expect(instante.jugador.ps, greaterThan(0));
        }

        expect(find.text('Geodude'), findsOneWidget);
        await tocar(tester, find.text('Cambiar de Pokémon'));
        await tocar(tester, find.widgetWithText(OutlinedButton, 'Squirtle'));
        await tocar(tester, find.text('Enviar a Squirtle'));
        expect(find.text('Pistola Agua'), findsOneWidget);
        for (
          var turno = 0;
          turno < 4 && ataque.evaluate().isNotEmpty;
          turno++
        ) {
          await tocar(tester, ataque);
        }
        expect(find.text('Victoria'), findsOneWidget);
        await tocar(tester, find.text('Continuar'));
        expect(find.text('Iniciar duelo de prueba'), findsOneWidget);

        await tocar(tester, find.byKey(const ValueKey('boton_perfil')));
        expect(find.text('Iniciar duelo de prueba'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets(
    'llena la ventana y solicita una reserva válida tras debilitarse',
    (tester) async {
      tester.view.physicalSize = const Size(1320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = equipoJugadorPrueba.integrantes.first;
      final debilitado = Combatiente(
        idPokemon: base.idPokemon,
        nombre: base.nombre,
        tipos: base.tipos,
        atributos: AtributosCombate(
          psMaximos: 1,
          ataque: 1,
          defensa: 1,
          ataqueEspecial: 1,
          defensaEspecial: 1,
          velocidad: 1,
        ),
        movimientos: base.movimientos,
      );
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: PantallaBatalla(
              nombreDuelo: 'Prueba de sustitución',
              nombreRival: 'Rival',
              equipo: EquipoCombate([
                debilitado,
                equipoJugadorPrueba.integrantes.last,
              ]),
              equipoRival: EquipoCombate([
                equipoJugadorPrueba.integrantes.last,
              ]),
            ),
          ),
        );
        expect(find.byType(PraderaDuelos), findsOneWidget);
        final escenario = tester.getSize(
          find.byKey(const ValueKey('escenario_batalla')),
        );
        expect(escenario.width, greaterThan(1200));
        expect(escenario.height, greaterThan(430));

        final spritesEnCancha = find.descendant(
          of: find.byType(CampoBatalla),
          matching: find.byType(SpriteBatalla),
        );
        final sprites = tester.widgetList<SpriteBatalla>(spritesEnCancha);
        expect(
          sprites.singleWhere((sprite) => sprite.deEspaldas).pokemon,
          debilitado,
        );
        expect(
          sprites.singleWhere((sprite) => !sprite.deEspaldas).pokemon,
          equipoJugadorPrueba.integrantes.last,
        );
        final bases = PosicionesCancha(escenario);
        final propia = bases.plataforma(jugador: true);
        final rival = bases.plataforma(jugador: false);
        expect(rival.left - propia.right, greaterThan(escenario.width * .20));
        expect(
          propia.center.dy - rival.center.dy,
          greaterThan(escenario.height * .30),
        );

        final fichas = find.byType(IndicadorEquipoBatalla);
        expect(fichas, findsNWidgets(2));
        expect(
          find.descendant(of: fichas, matching: find.byType(CustomPaint)),
          findsNWidgets(12),
        );
        expect(
          find.bySemanticsLabel(
            'Tu equipo. Disponibles: 2. Debilitados: 0. Huecos: 4.',
          ),
          findsOneWidget,
        );
        final primero = find.byKey(const ValueKey('movimiento_batalla_0'));
        final segundo = find.byKey(const ValueKey('movimiento_batalla_1'));
        expect(tester.getTopLeft(primero).dy, tester.getTopLeft(segundo).dy);
        expect(
          tester.getTopLeft(primero).dx,
          lessThan(tester.getTopLeft(segundo).dx),
        );
        await tocar(tester, primero);

        expect(spritesEnCancha, findsOneWidget);
        final indicadorTrasCaida = find.bySemanticsLabel(
          'Tu equipo. Disponibles: 1. Debilitados: 1. Huecos: 4.',
        );
        expect(indicadorTrasCaida, findsOneWidget);
        expect(find.text('Elige un reemplazo'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('movimiento_batalla_0')),
          findsNothing,
        );
        final primera = find.descendant(
          of: find.byKey(const ValueKey('reserva_batalla_0')),
          matching: find.byType(OutlinedButton),
        );
        expect(tester.widget<OutlinedButton>(primera).onPressed, isNull);
        final confirmar = find.byKey(const ValueKey('enviar_reserva_batalla'));
        expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
        await tocar(tester, find.byKey(const ValueKey('reserva_batalla_1')));
        await tocar(tester, confirmar);

        expect(find.text('Elige tu movimiento'), findsOneWidget);
        expect(find.textContaining('Turnos completados: 1'), findsOneWidget);
        expect(find.text('Enviaste a Squirtle.'), findsOneWidget);
        expect(indicadorTrasCaida, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );

  for (final reducir in [false, true]) {
    testWidgets(
      'deja leer el anuncio y el daño con movimiento reducido: $reducir',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reducir),
                child: child!,
              ),
              home: PantallaBatalla(
                nombreDuelo: 'Cruce elemental',
                nombreRival: 'Bruno',
                equipo: equipoJugadorPrueba,
                equipoRival: equipoRivalPrueba,
              ),
            ),
          );

          final boton = find.byKey(const ValueKey('movimiento_batalla_0'));
          final dialogo = find.byKey(const ValueKey('dialogo_batalla'));
          final ataque = find.byKey(const ValueKey('proyectil_fire'));
          final anuncio = find.descendant(
            of: dialogo,
            matching: find.text('Charmander usó Pirotecnia.'),
          );
          int psRival() =>
              tester.widget<CampoBatalla>(find.byType(CampoBatalla)).rival.ps;

          final psIniciales = psRival();
          await tester.ensureVisible(boton);
          await tester.pumpAndSettle();
          await tester.tap(boton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 530));
          expect(anuncio, findsOneWidget);
          expect(ataque, findsNothing);
          expect(psRival(), psIniciales);
          expect(tester.widget<FilledButton>(boton).onPressed, isNull);
          expect(find.textContaining('Turnos completados: 0'), findsOneWidget);

          await tester.pump(const Duration(milliseconds: 20));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          expect(ataque, reducir ? findsNothing : findsOneWidget);
          expect(
            psRival(),
            reducir ? lessThan(psIniciales) : equals(psIniciales),
          );

          if (!reducir) {
            await tester.pump(const Duration(milliseconds: 320));
            await tester.pump();
          }

          final dano = find.descendant(
            of: dialogo,
            matching: find.textContaining('Charmander usó Pirotecnia e infligió'),
          );
          final anuncioRival = find.descendant(
            of: dialogo,
            matching: find.textContaining('Pidgey usó'),
          );
          expect(dano, findsOneWidget);
          expect(psRival(), lessThan(psIniciales));
          await tester.pump(const Duration(milliseconds: 650));
          expect(dano, findsOneWidget);
          expect(anuncioRival, findsNothing);
          await tester.pump(const Duration(milliseconds: 210));
          await tester.pump();
          expect(dano, findsNothing);
          expect(anuncioRival, findsOneWidget);

          await tester.pumpAndSettle();
          expect(find.textContaining('Turnos completados: 1'), findsOneWidget);
          expect(
            find.textContaining('Charmander usó Pirotecnia'),
            findsOneWidget,
          );
          expect(ataque, findsNothing);
        });
      },
    );
  }
}
