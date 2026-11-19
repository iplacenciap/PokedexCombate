# Proyecto Pokédex

Aplicación desarrollada en Flutter que utiliza la PokeAPI para consultar y visualizar información de distintos Pokémon
La aplicación permite buscar y filtrar Pokémon desde una misma interfaz, además de visualizar información detallada como su nombre, ID, imagen, tipos, altura, peso, habilidades, estadísticas, descripción y generación

## Integrantes

- Ignacio Placencia
- Benjamin Rivas
- Daniel Ortiz
- Gerhec Parra

## Funcionalidades

- Búsqueda unificada de Pokémon.
- Búsqueda por nombre.
- Filtros por tipo y generación.
- Combinación de múltiples filtros de búsqueda.
- Selección de un Pokémon para visualizar su información completa.
- Obtención de un Pokémon aleatorio.
- Lista de resultados paginada.
- Manejo de búsquedas sin resultados y errores de conexión.
- Colección, favoritos y Gacha.
- Minijuegos PokéGuesser y Memorice, con su progreso en el perfil.

## Combate de referencia (P1)

En la aplicación, abre **Combates → Iniciar duelo de prueba**. Juegas
con Charmander y Squirtle contra Pidgey y Geodude. Al elegir un cambio,
el rival todavía ejecuta su acción del turno. Si un Pokémon se debilita y
quedan reservas, el reemplazo se realiza entre turnos.

La escena conserva la pradera, las plataformas y el HUD del prototipo.
La franja de diálogo anuncia el movimiento antes del impacto y la barra
de PS se actualiza después. El motor administra las acciones válidas,
los PP, el daño por tipos y el resultado. La práctica usa equipos
predefinidos y el rival selecciona la primera acción disponible.

### Puntos de integración

- `MotorCombate` recibe las acciones de ambos bandos y devuelve el estado
  del duelo y sus eventos en orden. Los estados del motor se pueden probar
  sin montar la interfaz.
- `PantallaBatalla` recibe los dos equipos. El parámetro opcional
  `elegirAccionRival` permite conectar una estrategia que reciba el estado y
  las acciones disponibles. Al pulsar **Continuar** al finalizar, la ruta
  devuelve el `EstadoCombate` final. `ganador` identifica el bando ganador
  y vale `null` cuando el resultado final es empate.
- `PantallaDueloPrueba` conecta la demo a la navegación de la Pokédex y
  permite abrir el duelo con equipos fijos para desarrollar en paralelo.

## Ejecución

Abre esta carpeta en VS Code y ejecuta los comandos desde la raíz del proyecto.
La versión de referencia se verificó con Flutter 3.50.0 y Dart 3.14.0.

```bash
flutter pub get
flutter run -d chrome
```

La app usa servicios externos para el catálogo y los sprites.
El duelo de prueba define sus equipos localmente.

## Pruebas

```bash
flutter test
flutter build web
```

## Versiones de origen

- Interfaz y perfil de [PokedexInterfaz](https://github.com/iplacenciap/PokedexInterfaz/tree/34e8cf77f390cab72b74b731c16aac1b727a3cc3).
- Motor y pantalla adaptados del [prototipo de combates](https://github.com/iplacenciap/PokedexPrueba/tree/16ab8b13c9cbf5a5ee798e2dfbd2b309a6ec6998).
