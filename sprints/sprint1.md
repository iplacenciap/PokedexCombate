# Sprint 1

## Roles

|Integrante|Rol|
|-|-|
|Ignacio Placencia Palma|Scrum Master|
|Benjamin Antonio Rivas Sepulveda|Product Owner|
|Daniel Esteban Ortiz Estrada|Desarrollo|
|Gerhec Ain Parra Gavilán|Desarrollo|

## Revisión

### Lo que terminamos

* \#34 Obtener un Pokémon aleatorio

  * Se implementó la selección y búsqueda de un Pokémon aleatorio.
  * Se reutilizó la lógica de búsqueda existente para obtener su información completa.
  * Se creó un botón reutilizable y se integró a la pantalla de inicio.
  * La funcionalidad fue desarrollada con pruebas automatizadas siguiendo TDD.
* \#26 Búsqueda de Pokémon unificada

  * Se implementó una única interfaz de búsqueda para centralizar la búsqueda de Pokémon.
  * Se incorporó una carga inicial de los Pokémon para permitir realizar filtrados sin consultar nuevamente a la PokeAPI por cada cambio.
  * Se implementaron filtros por nombre, tipo y generación, permitiendo combinar más de un filtro simultáneamente.
  * Se incorporó el acceso desde los resultados a la información completa de cada Pokémon.
  * Se agregaron mensajes para búsquedas sin resultados y errores durante la obtención de datos.
* \#27 Paginación de resultados

  * Se implementó la visualización paginada de los resultados de búsqueda.
  * Se creó un gestor encargado de calcular la cantidad de páginas y seleccionar los Pokémon correspondientes a cada página.
  * Se integraron controles para avanzar y retroceder entre las páginas disponibles.
  * Se incorporó la navegación desde los resultados hacia la información detallada de cada Pokémon.
  * Se agregaron pruebas automatizadas para comprobar los cálculos, estados y funcionamiento de la paginación.

### Lo que no alcanzamos a terminar

* No quedaron historias de usuario del Sprint 1 sin terminar, logramos con éxito todo lo planificado.

## Retrospectiva

### Resultado de las mejoras del Sprint 0

Durante el Sprint 0 se propuso mejorar la planificación inicial del trabajo y establecer fechas internas para evitar concentrar el desarrollo cerca de la entrega.

* La planificación inicial se realizó en la primera semana y permitió definir roles, historias de usuario y trabajo para el Sprint 1. Sin embargo, durante el desarrollo se detectaron diferencias de interpretación respecto al alcance de una historia de usuario en particular, lo que provocó retrasos en la implementación.
* La distribución del trabajo permitió comenzar funcionalidades con anticipación, pero algunas integraciones, revisiones y correcciones volvieron a concentrarse cerca del cierre del sprint, por lo que la mejora relacionada con evitar trabajo de última hora se cumplió solo parcialmente.

### Qué funcionó

* La división del trabajo temprana, permitió desarrollar distintas funcionalidades en paralelo.
* Se implementaron nuevas técnicas para el desarrollo de funcionalidades como es el TDD.
* Se incorporaron pruebas automatizadas en distintas funcionalidades para comprobar su funcionamiento antes de integrarlas que fueron útiles para corroborar la correcta integración de ramas a la rama principal.
* La comunicación durante la reunión de cierre permitió aclarar diferencias de interpretación respecto a historias de usuario y acordar cómo continuar el trabajo a futuras entregas.
* Se consiguió obtener avances concretos a lo largo del sprint en fechas no cercanas al cierre de este.

### Qué no funcionó

* Faltó registrar de forma consistente (por ejemplo, de manera escrita) los acuerdos y decisiones tomadas durante las reuniones, lo cual dio lugar a interpretaciones vagas de acuerdos.
* Algunas integraciones y correcciones se realizaron cerca del cierre del sprint, dejando menos tiempo para detectar y solucionar errores.
* Faltó coordinación cuando distintas historias de usuario o cambios de código estaban a cargo de más de un integrante.
* Existió una diferencia de interpretación sobre el alcance de la búsqueda unificada (HU-4), que fue aclarada durante la reunión de la última semana.

### Plan de acción

* \[ ] Después de cada reunión, cada integrante dejará un registro breve con los acuerdos, cambios y decisiones propuestas por ellos mismos mediante la reunión, para dejar registro de estas al cual posteriormente se puede consultar o aclarar en caso de que queden dudas
* \[ ] La reunión inicial dedicada al Sprint Planning será realizada la primera semana del Sprint, sin excepciones.
* \[ ] Para la segunda reunión ya deberán estar definidos como mínimo las User Stories, los miembros a cargo de tales, y las tareas relacionadas.
* \[ ] Cada integrante avisará cuando termine una funcionalidad o necesite una revisión de Pull Request (obligatorio antes de integrar ramas). Los cambios importantes de alcance serán conversados con el equipo antes de ser implementados.

### Lo que planeamos construir a continuación

* Incorporar texto predictivo para facilitar la búsqueda de Pokémon.
* Comenzar el desarrollo del modo PokeGuesser, sentando una base funcional de este mismo.
* Hacer análisis de posible refactorización de pantallas, de ser óptimo separar componentes en widgets reutilizables para mejorar la organización, de no serlo dejar tal y como está.

