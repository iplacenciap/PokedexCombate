# Sprint 2

## Roles

|Integrante|Rol|
|-|-|
|Ignacio Placencia Palma|Product Owner|
|Daniel Esteban Ortiz Estrada|Scrum Master|
|Benjamin Antonio Rivas Sepúlveda|Desarrollo|
|Gerhec Ain Parra Gavilán|Desarrollo|

## Revisión

### Lo que terminamos

* \#47 Navegación Global mediante Barra de Menú Superior

  * Se creó un widget de barra menú reutilizable.
  * Se creó un widget reutilizable de placeholder para secciones en construcción.
  * Se implementó una página principal como MainLayout para poder integrar la barra de menú y los widgets de secciones correspondientes.
  * Se logró implementar la navegación por diferentes secciones conservando el estado de cada una durante la sesión.

* \#52 Minijuego de adivinanza PokéGuesser

  * Se implementó la lógica del juego con estados que permiten una interfaz dinámica dependiendo de estos.
  * El juego establece un sistema de adivinanza con 7 intentos fallidos como máximo, señalándole al usuario tales intentos en la interfaz.
  * La partida finaliza a la hora de que los intentos se acaben, resultando esto en una derrota, o se adivine el Pokémon correspondiente, resultando en una victoria, abriendo casos separados ante cada una.
  * En caso de derrota, se muestra una pantalla con el Pokémon que se tenía que adivinar y se da la opción a reintentar la partida, de hacerse esto se restablece la lista de Pokémon intentados junto con escogerse un Pokémon distinto al de la partida anterior.
  * En caso de una victoria, muestra un mensaje señalando la victoria, dando la opción a reintentar partida con un mensaje exclusivo distinto al de caso de derrota, de accederse al reintento, paralelamente a la derrota, se restablece la lista de Pokémon intentados y se inicia una nueva partida con un Pokémon distinto al de la partida anterior a adivinar.
  * Se incorporó el acceso desde los resultados a la información completa de cada Pokémon.
  * Se agregaron mensajes para búsquedas sin resultados y errores durante la obtención de datos.

* \#66 Generador de pistas para PokéGuesser

  * Se implementó la generación de pistas a partir de los datos del pokemon.
  * Las pistas contienen detalles como peso, altura, habilidades, tipo, generación, etc.
  * Las pistas poseen valores alternativos para manejar los casos en los que la API no proporciona detalles.

* \#56 Búsqueda con texto predictivo y cambios en panel de filtrado

  * La lista de resultados se actualiza mientras el usuario escribe el nombre del pokémon.
  * Se reemplazó el botón general de búsqueda (que se usaba anteriormente para aplicar filtros) por un botón dedicado para aplicar los filtros.

### Lo que no alcanzamos a terminar

* No quedaron historias de usuario del Sprint 2 sin terminar, logramos con éxito todo lo planificado.

## Retrospectiva

### Resultado de las mejoras del Sprint 1

Durante el Sprint 1 se reiteró acerca de la planificación temprana del desarrollo, la división de roles y definición de Historias de Usuarios con sus respectivas tareas, para tratar de reducir las implementaciones al final del Sprint.

* Debido al compromiso de registrar los cambios y acuerdos de cada reunión durante el sprint, se evitaron confusiones y malas interpretaciones respecto a implementaciones de las historias de usuario en general.
* Al definir los roles, historias de usuario y tareas durante la primera semana de manera clara, se logró desarrollar el producto en paralelo sin depender de que otras historias de usuario terminaran para seguir con otra.
* No hubo bloqueos debido a los pull requests atómicos y revisión temprana por parte de los demás integrantes del equipo.
### Qué funcionó

* Igualmente que en el sprint anterior, la división del trabajo y definición de roles durante la primera semana, permitió desarrollar distintas funcionalidades en paralelo y que distintas user stories pudieran completarse sin depender de las otras.
* Se utilizó TDD como técnica de desarrollo para tener funcionalidades verificables y seguras.
* La coordinación a través de las reuniones y Whatsapp fue un éxito, cumpliendo con lo propuesto respecto a dejar por escrito el detalle de cada reunión que tuvimos, lo que permitió poder aclarar puntos a tiempo y evitar diferencias.
* Se logró realizar pull requests más atómicos a lo largo del sprint (generalmente por cada task) para poder mejorar la revisión y avance seguro en el desarrollo del producto. Lo anterior permitió incluso poder visualizar deuda técnica y solicitar cambios que no implicaran mayor costo.
* Debido al equilibrio en los story points del sprint, se logró pagar deuda técnica durante el sprint actual, sin extenderla a próximos sprints.

### Qué no funcionó

* A pesar de que los User Stories y tasks ya estaban bien definidos a la 2da semana, al igual que en sprints anteriores, el trabajo se concentró aunque con mejora, en la última semana.
* Al igual que el sprint anterior, algunas correcciones se realizaron cerca del cierre del sprint, aunque no fueron críticas en el sentido de ser nuevas implementaciones, sino ajustes para la entrega y presentación del producto.
* Algunos integrantes del equipo quedaron con poca carga de trabajo debido a una mala estimación de story points.

### Plan de acción

* \[ ] Los story points se estimarán entre los integrantes del equipo durante la primera reunión del sprint para equilibrar la carga de trabajo a lo largo del sprint.
* \[ ] Se reitera que la reunión inicial dedicada al Sprint Planning será realizada la primera semana del Sprint, sin excepciones.
* \[ ] Se deberá tener a lo menos un avance (aunque sea mínimo), desde la primera semana del sprint, para evitar trabajo concentrado al final del sprint.

### Lo que planeamos construir a continuación

* Incorporar memorize como un nuevo minijuego en la app.
* Implementar un sistema de logros dependiendo del progreso del usuario en los minijuegos.
* Se sostiene un compromiso para la refactorización y mejoras en el diseño de la app.