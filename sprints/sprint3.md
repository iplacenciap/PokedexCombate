# Sprint 3

## Roles

|Integrante|Rol|
|-|-|
|Gerhec Ain Parra Gavilán|Product Owner|
|Benjamin Antonio Rivas Sepulveda|Scrum Master|
|Ignacio Placencia Palma|Desarrollo|
|Daniel Esteban Ortiz Estrada|Desarrollo|

## Revisión

### Lo que terminamos

* \#81 Perfil y seguimiento persistente del progreso del jugador

  * Se implementó un perfil de jugador con nombre editable y guardado local.
  * Se registran partidas, victorias y derrotas de PokéGuesser y Memorice.
  * En Memorice también se guarda el progreso por dificultad y el mejor combo.
  * El perfil muestra Pokémonedas, avance de colección y Pokémon favoritos.
* \#82 Memorice - Minijuego

  * Se implementó el juego de parejas con Pokémon seleccionados al azar.
  * Se agregaron cuatro dificultades, con distintos tamaños de tablero y tiempos.
  * Se incorporaron la fase inicial para memorizar las cartas, el temporizador, el conteo de errores y los combos.
  * La partida finaliza con victoria si se encuentran todos los pares o con derrota si se agota el tiempo.
* \#102 Sistema de monedas y recompensas por minijuegos

  * Se agregaron Pokémonedas al perfil y se guardan con el progreso del jugador.
  * Se implementaron recompensas en los minijuegos.
  * La recompensa depende del minijuego, del resultado y de los intentos incorrectos o de la dificultad.
  * Se implementó la lógica para descontar monedas y revertir el saldo si una operación falla.
* \#112 Gacha - Canjear Pokemonedas

  * Se implementó una tirada de un Pokémon aleatorio con un costo de 400 Pokémonedas.
  * El Pokémon obtenido se muestra y se añade a la colección.
  * Si el Pokémon obtenido es repetido, se devuelven 200 Pokémonedas.
  * Si la tirada falla durante el proceso, se reembolsa el costo.
* \#124 Pokémon Coleccionables

  * Se implementó un álbum para consultar los Pokémon obtenidos y los faltantes.
  * La colección se guarda localmente.
  * Se agregaron filtros por tipo, generación y favoritos.
  * Se ordenan los Pokémon nuevos, obtenidos y pendientes.
  * Se muestra la cantidad de Pokémon obtenidos y en total según los filtros aplicados.
  * Se puede abrir el detalle de cada Pokémon.

### Lo que no alcanzamos a terminar

* Sistema de logros según el progreso del jugador en los minijuegos. Se decidió postergar su desarrollo para el siguiente sprint.

## Retrospectiva

### Resultado de las mejoras del Sprint 2

En el sprint 2 se propuso estimar las tareas en grupo, planificar durante la primera semana y comenzar a mostrar avances desde el inicio.

* La estimación grupal de story points ayudó a distribuir las tareas. Sin embargo, subestimamos el esfuerzo total requerido. 
### Qué funcionó

* A diferencia de los sprints anteriores, el trabajo se distribuyó de manera más equilibrada durante el plazo.
* Se mantuvieron avances a lo largo del sprint, en vez de concentrar la mayor parte del trabajo al final.
* La división del trabajo permitió avanzar en distintas funcionalidades en paralelo.
### Qué no funcionó

* La carga de trabajo que asumimos al inicio del sprint fue demasiado alta. Subestimamos el esfuerzo necesario para realizar algunas historias de usuario, lo que provocó que a mitad del sprint tuviéramos que reorganizar la distribución del trabajo.

### Plan de acción

* \[ ] Durante la primera semana del sprint, analizar entre todos la complejidad y alcance de las historias de usuario antes de comprometerlas.
* \[ ] Dividir las funcionalidades grandes en tareas o historias más pequeñas y estimarlas en conjunto durante la planificación.
* \[ ] Al finalizar la primera semana, revisar el avance y la carga de trabajo del equipo para ajustar las prioridades a tiempo, si es necesario.


### Lo que planeamos construir a continuación

* Implementar un sistema de logros basado en el progreso del usuario.
* Crear un quiz sobre los Pokémon, con preguntas acerca de sus tipos, habilidades, evoluciones y características.
* Crear un minijuego para adivinar el Pokémon a partir de su grito.
* Crear una tienda de sobres que permita obtener Pokémon coleccionables aleatorios. 