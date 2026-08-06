# Football Pixel — auditoría técnica y documentación

**Fecha de revisión:** 5 de agosto de 2026  
**Motor:** Godot 4.6, renderizador 'gl_compatibility'  
**Estado estimado:** prototipo avanzado / vertical slice temprano; todavía no preparado para una beta estable.

## 1. Dictamen ejecutivo

Football Pixel ya tiene la forma de un manager de fútbol jugable: menú principal, creación de carrera, base de datos de clubes y jugadores, gestión de plantilla, calendario, simulación minuto a minuto y resumen postpartido. La dirección visual pixel/retro está clara y existe suficiente contenido inicial para probar un flujo completo.

El principal problema no es la falta de ideas, sino la falta de una fuente de verdad estable para el estado de carrera. La partida se guarda como un JSON con metadatos mientras la competición, los jugadores, la alineación y las estadísticas viven en una base SQLite global dentro de 'res://'. Eso provoca contaminación entre carreras, dificulta los guardados reales y amenaza la ejecución exportada, donde los recursos suelen ser de solo lectura.

Los bloqueadores más importantes son:

1. La pantalla de clasificaciones se referencia, pero 'scenes/career/clasificacion.tscn' no existe.
2. La alineación guardada no se usa al cargar los titulares del partido: el simulador hace 'SELECT ... LIMIT 11' sin ordenar por 'es_titular'.
3. El calendario es una herramienta separada y no se genera automáticamente al crear una carrera.
4. El generador de jugadores alternativo intenta insertar columnas que no existen en el esquema actual.
5. Las estadísticas de liga del archivo actual no coinciden con la agregación de partidos jugados.
6. No hay pruebas automatizadas, pipeline de validación ni documentación de arranque previa a esta auditoría.

La recomendación es estabilizar primero el núcleo de persistencia y el flujo 'nueva partida → calendario → alineación → partido → tabla → guardado'. Después conviene ampliar finanzas, cantera, empleados, temporadas y competiciones internacionales.

## 2. Alcance y evidencias

Se inspeccionaron:

- 'project.godot', configuración de autoloads, resolución e integración del addon SQLite.
- Las 11 escenas, 16 scripts GDScript y recursos del proyecto.
- Referencias de escenas y scripts para localizar rutas rotas.
- Flujo de menú, creación de partida, plantilla, partido y resumen.
- Esquema y datos de 'datos/PRUEBA.db' usando SQLite en modo de lectura.
- Estado de Git, historial y archivos de calidad del repositorio.

El repositorio tiene un único commit ('Primer commit'). El árbol de trabajo ya contenía una modificación en 'datos/PRUEBA.db'; se respetó y no se intentó revertir. 'datos/database.sqlite' existe, pero su tamaño es cero bytes y no está referenciado por el código.

La ejecución gráfica no se pudo validar en esta máquina porque el ejecutable 'godot'/'godot4' no está disponible en el PATH. Las conclusiones de comportamiento se basan en análisis estático y consistencia de la base de datos, no en una sesión manual dentro del motor.

## 3. Inventario del proyecto

| Área | Estado actual |
|---|---|
| Entrada | 'scenes/menus/menu_principal.tscn' |
| Escenas | 11 archivos '.tscn' |
| Scripts | 16 archivos '.gd' |
| Autoloads | 'DatabaseManager', 'GameManager' |
| Base principal | 'datos/PRUEBA.db', 126 976 bytes en la revisión |
| Base secundaria | 'datos/database.sqlite', 0 bytes, sin uso |
| Ligas | 6 |
| Clubes | 24, cuatro por liga |
| Jugadores | 552, 23 por club |
| Partidos | 72, doce por liga |
| Partidos jugados en el snapshot | 7 |
| Estadísticas de liga | 8 filas creadas de forma incremental |
| Addon nativo | 'godot-sqlite', con binarios Windows, Linux, macOS, Android, iOS y Web |
| Fuente visual | Fuente 'PressStart2P', assets SVG/PNG y dibujo procedural de campos |

## 4. Identidad de producto y bucle jugable

### Propuesta implícita

El proyecto apunta a un manager de fútbol de estética retro en el que el jugador dirige un club, configura su identidad, gestiona la plantilla y observa la resolución de los partidos mediante simulación narrativa.

### Bucle implementado

~~~mermaid
flowchart LR
    A[Menú principal] --> B[Crear partida]
    B --> C[Elegir liga y club]
    C --> D[Guardar identidad y generar plantillas]
    D --> E[Dashboard de carrera]
    E --> F[Gestionar plantilla]
    E --> G[Ir al partido]
    G --> H[Simulación de 90 minutos]
    H --> I[Guardar acta y estadísticas]
    I --> J[Resumen del partido]
    J --> E
    E --> K[Submenú de club]
~~~

### Lo que todavía no forma un bucle completo

- La nueva carrera no garantiza la creación del calendario.
- El calendario no tiene una vista de mantenimiento o regeneración integrada.
- El resultado del partido se guarda, pero el dashboard no filtra partidos ya jugados.
- La alineación se guarda en SQLite, pero el simulador no la consulta.
- El botón de clasificaciones lleva a una escena inexistente.
- Cantera, empleados, finanzas, instalaciones e historial solo muestran mensajes o no tienen acción implementada.

## 5. Arquitectura actual

### Capas observadas

~~~mermaid
flowchart TB
    UI[Escenas Control y scripts UI] --> GM[GameManager]
    UI --> DB[DatabaseManager]
    Match[Simulación de partido] --> DB
    Match --> GM
    Summary[Resumen de partido] --> GM
    Tools[Generadores de jugadores y calendarios] --> DB
    DB --> SQLite[(SQLite en res://datos/PRUEBA.db)]
    GM --> Save[(user://savegame.json)]
~~~

### 'DatabaseManager'

Está definido en 'scripts/autoload/DatabaseManager.gd'. Abre la base al iniciar el juego, ofrece 'execute', 'fetch_rows', escapado de texto y comillas para identificadores. También contiene una migración parcial para las columnas de pie preferido.

Fortaleza: concentra una parte importante del acceso a datos y permite que 'crear_partida.gd' inspeccione columnas antes de insertar jugadores.

Debilidad: buena parte del proyecto llama directamente a 'DatabaseManager.db.query', sin verificar errores ni estado de conexión. No hay transacciones, cierre explícito, inicialización de esquema completo, copia de base por partida ni preparación de consultas.

### 'GameManager'

Está definido en 'scripts/autoload/game_manager.gd'. Mantiene la identidad del manager y del club, el camino de escena actual y un puente temporal con los datos del último partido.

Fortaleza: simplifica la comunicación entre el simulador y el resumen.

Debilidad: el guardado solo serializa seis datos de carrera y 'save_version'; no serializa la base ni valida realmente la versión al cargar. La variable 'current_scene_path' no representa por sí sola el progreso de la competición.

### UI y escenas

La mayoría de escenas son 'Control' con layout de contenedores. Esto permite construir rápidamente interfaces de manager y facilita los cambios de estilo desde código. La plantilla genera tarjetas y slots dinámicos; el campo y la camiseta se dibujan con '_draw'.

El coste de esta estrategia es que varios controladores mezclan presentación, navegación, SQL, reglas de dominio y generación de estilos. Los casos más grandes son 'submenu_plantilla.gd' con 690 líneas, 'simulacion_partido.gd' con 396 y 'crear_partida.gd' con 379.

## 6. Mapa de escenas y responsabilidades

| Escena | Script | Responsabilidad | Estado |
|---|---|---|---|
| 'menus/menu_principal.tscn' | 'menus/menu_principal.gd' | Nueva partida, cargar y salir | Funcional básico |
| 'career/crear_partida.tscn' | 'career/crear_partida.gd' | Elegir liga/club, identidad visual y generar jugadores | Funcional, acoplada a DB global |
| 'career/menu_plantilla.tscn' | 'career/menu_plantilla.gd' | Dashboard, próximo partido y accesos | Funcional parcial; query de próximo partido incorrecta |
| 'career/submenu_plantilla.tscn' | 'career/submenu_plantilla.gd' | Formación, banca, drag & drop y guardado de once | Visualmente avanzada; reglas incompletas |
| 'career/submenu_club.tscn' | 'career/submenu_club.gd' | Accesos del club | Solo clasificaciones está conectada |
| 'match/simulacion_partido.tscn' | 'match/simulacion_partido.gd' | Simulación de 90 minutos | Jugable como prototipo; datos simplificados |
| 'match/resumen_partido.tscn' | 'match/resumen_partido.gd' | MVP, marcador y estadísticas | Funcional con datos temporales |
| 'tools/generador_jugadores.tscn' | 'tools/generador_jugadores.gd' | Herramienta para completar plantillas | Incompatible con el esquema actual |
| 'tools/generador_torneos.tscn' | 'tools/generador_torneos.gd' | Round-robin de temporada 1 | Algoritmo razonable, sin transacción ni integración |
| 'ui/fila_clasificacion.tscn' | 'ui/fila_clasificacion.gd' | Fila reutilizable para tabla | Existe, pero no tiene pantalla consumidora |
| 'debug/PRUEBA.tscn' | — | Nodo vacío de depuración | Sin utilidad documentada |

## 7. Modelo de datos actual

### Entidades

| Tabla | Propósito | Observaciones |
|---|---|---|
| 'ligas' | Catálogo de competiciones nacionales | 6 filas; contiene nombre, país y prestigio |
| 'equipos' | Clubes de cada liga | 24 filas; 'liga_id' tiene FK declarada, pero las foreign keys están desactivadas por defecto |
| 'jugadores' | Plantilla y estadísticas individuales | 552 filas; muchos atributos en una sola tabla |
| 'partidos' | Calendario y resultado | 72 filas; 'torneo_id' funciona realmente como ID de liga |
| 'estadisticas_liga' | Tabla agregada por club, torneo y temporada | Se crea al disputar un partido; no se recalcula desde 'partidos' |
| 'leyendas_retiradas' | Futuro historial de jugadores retirados | Vacía y sin consumidor |

### Relaciones lógicas

~~~mermaid
erDiagram
    LIGAS ||--o{ EQUIPOS : contiene
    EQUIPOS ||--o{ JUGADORES : posee
    EQUIPOS ||--o{ PARTIDOS : local
    EQUIPOS ||--o{ PARTIDOS : visitante
    EQUIPOS ||--o{ ESTADISTICAS_LIGA : resume
    LIGAS ||--o{ PARTIDOS : organiza
    LIGAS ||--o{ ESTADISTICAS_LIGA : agrupa
~~~

### Invariantes que conviene formalizar

- Cada club debe pertenecer a una liga existente.
- Un partido no puede enfrentar al mismo club consigo mismo.
- En una liga de cuatro equipos, una temporada de ida y vuelta debe tener 12 partidos.
- Cada club debe jugar seis partidos en esa temporada.
- Cada partido jugado debe afectar una sola vez a clasificación y estadísticas individuales.
- 'goles_local' y 'goles_visita' deben ser nulos mientras 'jugado = 0' y no nulos cuando 'jugado = 1'.
- Una alineación válida debe contener once jugadores distintos y un portero.
- Un jugador solo puede tener un club activo.

### Problemas de diseño de datos

- El nombre real de la base es 'PRUEBA.db', aunque 'DatabaseManager' lo trata como base de producción.
- 'database.sqlite' está vacío y aumenta la ambigüedad del proyecto.
- Hay nombres duplicados de jugador dentro de algunos clubes; no existe un identificador visible o dorsal persistente para diferenciarlos.
- 'PlayerGeneration' genera 'media', 'overall', 'dorsal', 'titular', 'pie_preferido' y 'uso_pie_malo', pero varias de esas columnas no están en la tabla actual. El camino de creación de partida lo tolera al ser schema-aware; el generador de herramientas no.
- Hay nombres de columna con espacios y acentos conceptuales, como 'pie preferido' y 'uso de pie malo'. Funcionan con comillas, pero complican consultas, migraciones y análisis.
- No hay índices explícitos para 'partidos(equipo_local_id, equipo_visita_id, jugado, temporada, jornada)' ni 'jugadores(equipo_id)'.
- La mayoría de tablas no declara foreign keys; el chequeo realizado mostró 'PRAGMA foreign_keys = 0'.
- Las estadísticas son derivadas, pero se mutan incrementalmente y pueden quedar desincronizadas.

## 8. Flujo técnico detallado

### Crear partida

1. 'menu_principal.gd' carga 'crear_partida.tscn'.
2. 'crear_partida.gd' carga ligas y clubes desde SQLite.
3. Al elegir club, rellena presidente, estadio y configuración visual.
4. Al confirmar, actualiza el club elegido y genera jugadores faltantes para todos los clubes.
5. Asigna el club y el manager a 'GameManager'.
6. Guarda un JSON en 'user://savegame.json'.
7. Cambia al dashboard.

Riesgo: el proceso no crea ni verifica un calendario. El estado inicial depende del contenido preexistente de 'PRUEBA.db'.

### Gestión de plantilla

'submenu_plantilla.gd' mantiene tres estructuras en memoria:

- 'plantilla_jugadores': todos los jugadores del club.
- 'once_actual': mapa 'slot → jugador'.
- 'banca_actual': jugadores restantes.

La primera formación se autocompleta ordenando por media y buscando posiciones compatibles. El drag & drop permite intercambiar jugadores, pero 'puede_soltar_en_slot' solo valida que el jugador exista; no valida que la posición del jugador corresponda al slot.

Al guardar, se actualizan 'es_titular' y 'rol_tactico' en SQLite. Sin embargo, el simulador no utiliza esos campos al cargar los once.

### Simular partido

1. Busca el primer partido no jugado del club.
2. Carga datos de ambos equipos.
3. Carga 11 jugadores con 'LIMIT 11'.
4. Avanza un minuto por segundo.
5. Calcula poder mediante pase, control, visión, moral, reputación, localía y estilo táctico.
6. Decide intentos y goles de forma aleatoria.
7. Actualiza marcador y comentarios.
8. Al minuto 90, actualiza 'partidos', 'estadisticas_liga' y estadísticas individuales.
9. Pasa datos temporales a 'GameManager' y abre el resumen.

Defectos funcionales del flujo:

- La selección de titulares no respeta la alineación guardada.
- El índice cero se usa como portero al registrar porterías a cero, aunque el SQL no garantiza ese orden.
- El MVP se elige del equipo ganador o local en empate, pero sus goles se asignan con una condición que solo mira 'goles_local'.
- 'mvp_asistencias' nunca se asigna en el simulador.
- Posesión, tiros y faltas son números aleatorios; no derivan de eventos reales de la simulación.
- Las actualizaciones se ejecutan fuera de una transacción y los errores se ignoran.

### Guardado y carga

'GameManager.save_game' guarda:

- versión del guardado;
- ID del club;
- nombre del manager;
- nombre del club;
- uniforme serializado;
- escena a reanudar.

No guarda calendario, resultados, clasificación, jugadores, alineación, dinero, temporada ni historial. Esos datos permanecen en la base global del proyecto.

## 9. Fortalezas

### Producto y gameplay

- El proyecto tiene una fantasía de producto reconocible y un tono visual coherente.
- El flujo de creación de club incluye liga, nombre, presidente, estadio, uniforme y escudo.
- La gestión de plantilla ya tiene una interacción de alto valor para un manager: formación visual, banca, ficha de jugador y drag & drop.
- La simulación minuto a minuto da feedback continuo y crea una transición natural al resumen.
- La tabla de estadísticas del partido y el MVP aportan una buena base para profundizar en la identidad de cada club.

### Ingeniería

- La estructura de carpetas separa 'autoload', 'career', 'match', 'core', 'tools' y 'ui'.
- Los autoloads elegidos son razonables para un prototipo: persistencia y estado global quedan centralizados.
- 'PlayerGeneration' encapsula la generación de jugadores, posiciones, estilos, potencial, edad y atributos.
- El generador de calendario implementa un round-robin de ida y vuelta válido para el tamaño actual de las ligas; el snapshot tiene 12 partidos por liga y no muestra referencias de equipos inválidas.
- 'crear_partida.gd' intenta adaptarse al esquema consultando 'PRAGMA table_info', un enfoque útil durante una migración temprana.
- El addon SQLite incluye binarios para varias plataformas, lo que reduce trabajo de integración inicial.
- Los campos de juego se dibujan de forma procedural y no dependen de una gran cantidad de sprites.
- El código utiliza nombres de funciones descriptivos y comentarios de intención, algo valioso para una base todavía en evolución.

## 10. Deficiencias priorizadas

### P0 — bloqueadores del vertical slice

| ID | Evidencia | Impacto | Acción recomendada |
|---|---|---|---|
| P0-01 | 'submenu_club.gd:13' y ':137' apuntan a 'res://scenes/career/clasificacion.tscn'; el archivo no existe | El botón de clasificaciones rompe la navegación | Crear la escena y su controlador, o deshabilitar el botón hasta tenerla |
| P0-02 | 'DatabaseManager.gd:4' abre 'res://datos/PRUEBA.db' | El estado de carrera es global; en una exportación puede no ser escribible | Copiar una base plantilla a 'user://saves/<id>.db' al crear la partida |
| P0-03 | 'submenu_plantilla.gd:626-643' guarda once; 'simulacion_partido.gd:96-105' carga 'LIMIT 11' | La decisión principal del usuario no tiene efecto en el partido | Consultar 'es_titular = 1', ordenar por 'rol_tactico' y validar portero/once |
| P0-04 | 'crear_partida.gd' genera jugadores, pero no llama al generador de calendario | Una instalación limpia puede quedarse sin próximo partido | Crear calendario como parte de la nueva partida y verificar sus invariantes |

### P1 — riesgos de datos y lógica

| ID | Evidencia | Impacto | Acción recomendada |
|---|---|---|---|
| P1-01 | 'menu_plantilla.gd:82-103' no incluye 'p.jugado = 0' | El dashboard puede presentar como próximo un partido ya terminado | Añadir filtro de estado y ordenar por temporada/jornada/ID |
| P1-02 | 'generador_jugadores.gd:48-61' inserta todas las claves de 'PlayerGeneration'; el esquema carece de 'media', 'overall', 'dorsal', 'titular', 'pie_preferido' y 'uso_pie_malo' | La herramienta falla cuando necesita insertar jugadores faltantes | Reutilizar el inserter schema-aware de 'crear_partida' o centralizarlo en un servicio |
| P1-03 | La base revisada tiene 7 partidos jugados; la agregación de 'partidos' no coincide con 'estadisticas_liga' para los clubes 40 y 43 | Clasificaciones y datos históricos no son confiables | Hacer el acta idempotente o recalcular la clasificación desde partidos terminados |
| P1-04 | 'simulacion_partido.gd:154-239' ejecuta muchas escrituras directas y no valida errores | Un fallo intermedio puede dejar marcador, tabla y jugadores en estados distintos | Envolver el acta en 'BEGIN/COMMIT', hacer 'ROLLBACK' ante error y comprobar filas afectadas |
| P1-05 | 'DatabaseManager.gd:66-96' usa el nombre nuevo también donde debería usar los campos legacy | La migración de columnas antiguas no copia datos correctamente | Separar 'legacy_name' y 'canonical_name' y cubrir la migración con una prueba |
| P1-06 | 'submenu_plantilla.gd:430-439' valida solo ID; no usa 'matches' de la formación | Se puede colocar cualquier jugador en cualquier posición | Validar compatibilidad, permitir posiciones secundarias y mostrar feedback visual |
| P1-07 | 'submenu_plantilla.gd:618-621' reconstruye el once al cambiar formación | El usuario pierde ajustes manuales al cambiar de formación | Migrar jugadores por compatibilidad y conservar cambios cuando sea posible |
| P1-08 | 'game_manager.gd:45-54' guarda metadatos, no estado de simulación | Cargar partida no restaura realmente una carrera | Definir un 'SaveService' por archivo SQLite o por snapshot transaccional |
| P1-09 | 'game_manager.gd:64-75' lee 'save_version', pero no valida ni migra su valor | Los cambios futuros del formato pueden romper partidas | Implementar migradores por versión y rechazar versiones desconocidas con mensaje claro |

### P2 — deuda de producto y mantenimiento

| ID | Evidencia | Impacto | Acción recomendada |
|---|---|---|---|
| P2-01 | 'menu_plantilla.gd:108-109' deja cantera y empleados como mensajes | El dashboard promete sistemas que no existen | Ocultar módulos no disponibles o implementar una primera versión funcional |
| P2-02 | 'submenu_club.gd' solo conecta regresar y clasificaciones | Finanzas, instalaciones e historial parecen botones muertos | Conectar pantallas placeholder coherentes o marcar funciones como futuras |
| P2-03 | No hay tests, README, CI, 'export_presets.cfg' ni lint configurado | Cada cambio depende de validación manual | Añadir documentación operativa y una suite mínima de invariantes |
| P2-04 | 'project.godot' fija 1920×1080 y 'window/resizable=false' | Mala adaptación a portátiles, ventanas pequeñas y dispositivos distintos | Usar escalado configurable, anchors y pruebas de 1280×720/1600×900 |
| P2-05 | 'partidos.torneo_id' representa un ID de liga, no un torneo genérico | Complica Champions, copas y múltiples competiciones | Crear 'torneos' o renombrar la semántica antes de ampliar el modelo |
| P2-06 | SQL, navegación, estilo y reglas están mezclados en controladores grandes | Aumenta el coste de cambiar reglas y probarlas | Extraer servicios de dominio y repositorios SQLite |
| P2-07 | El DB principal es un fixture vivo y el repo solo tiene un commit | No hay historial de migraciones ni datos reproducibles | Versionar semillas, migraciones y herramientas de regeneración deterministas |

## 11. Riesgos de diseño de juego

### Simulación

La fórmula actual sirve para prototipar, pero aún no ofrece un modelo táctico consistente. El poder usa principalmente pase, control, visión y moral para todos los jugadores; la posición y la mayoría de atributos generados no afectan de forma diferenciada a la probabilidad de evento. El resultado puede sentirse aleatorio aunque el jugador haya invertido en la plantilla.

Evolución recomendada:

1. Definir ratings derivados por línea: portería, defensa, mediocampo y ataque.
2. Incorporar formación, rol, cansancio, localía, reputación y estilo como modificadores separados.
3. Generar eventos con una semilla por partido para poder reproducir bugs.
4. Guardar tiros, ocasiones, goles, tarjetas y asistencias como eventos, no como números independientes al final.
5. Calcular MVP y valoración a partir de esos eventos.

### Progresión

La base ya contiene 'edad', 'calidad_potencial', 'valor', 'salario', 'energia' y 'moral', pero todavía no hay paso de jornada/temporada, envejecimiento, recuperación, contratos, mercado, lesiones o entrenamiento que transforme esos datos en decisiones de juego.

### Economía y retención

Los botones de finanzas y empleados apuntan a una dirección de producto correcta, pero el jugador todavía no tiene decisiones económicas reales. Antes de añadir muchos sistemas conviene decidir el núcleo de retención:

- ¿La satisfacción viene de ganar partidos?
- ¿De desarrollar jóvenes?
- ¿De mejorar infraestructura?
- ¿De ascender por divisiones?
- ¿De construir una dinastía histórica?

Esa decisión debe guiar qué tablas y qué pantallas se implementan primero.

## 12. Arquitectura objetivo recomendada

### Servicios de dominio

Extraer la lógica de los controladores en servicios pequeños:

- 'CareerService': crear carrera, seleccionar club y avanzar jornada.
- 'SquadService': cargar plantilla, validar alineación, guardar once y aplicar cambios.
- 'FixtureService': generar calendario, consultar próximo partido y cerrar jornada.
- 'MatchSimulationService': simular con RNG semillado y devolver un 'MatchResult'.
- 'LeagueService': actualizar o recalcular clasificación.
- 'PlayerGenerationService': generar datos y persistir usando un único inserter.
- 'SaveService': crear/copiar bases por partida, migrar y cargar saves.

### Repositorios

Usar una interfaz de repositorio sobre SQLite:

- 'LeagueRepository'
- 'TeamRepository'
- 'PlayerRepository'
- 'FixtureRepository'
- 'StandingsRepository'
- 'SaveRepository'

Los controladores de escena deberían coordinar UI y servicios, no construir SQL.

### Persistencia recomendada

1. Mantener una base semilla solo como recurso de lectura.
2. Al crear partida, copiarla a 'user://saves/<save_id>/career.sqlite'.
3. Ejecutar migraciones numeradas antes de cargar.
4. Guardar 'save.json' con versión, nombre, fecha y ruta del DB.
5. Nunca usar 'res://' como destino de escritura.
6. Añadir un botón de respaldo y, si es posible, dos slots manuales.

### Esquema recomendado

- Normalizar nombres de columnas a 'snake_case' ASCII.
- Añadir 'dorsal', 'media' o elegir oficialmente 'calidad_actual' como único campo.
- Elegir un único par para pie preferido y pie malo.
- Añadir foreign keys para jugadores, partidos y estadísticas.
- Crear índices para consultas de calendario y plantilla.
- Añadir restricción única para '(temporada, torneo_id, jornada, equipo_local_id, equipo_visita_id)' o una clave equivalente.
- Crear tabla 'competitions'/'torneos' si habrá ligas, copas y torneos internacionales.
- Crear tabla 'match_events' si el resumen depende de eventos reproducibles.

## 13. Roadmap priorizado

### Fase 0 — hacer el vertical slice confiable

Objetivo: una partida nueva funciona desde cero y puede continuar tras reiniciar.

- Resolver o desactivar clasificaciones hasta tener escena real.
- Mover la base activa a 'user://'.
- Implementar creación de calendario desde nueva partida.
- Filtrar próximos partidos no jugados.
- Cargar exactamente el once guardado y validar portero.
- Arreglar MVP, asistencias y portero por posición.
- Hacer el acta transaccional e idempotente.
- Añadir un botón de reset de datos de desarrollo, separado de los saves.

### Fase 1 — datos y herramientas

Objetivo: los datos pueden regenerarse y auditarse.

- Unificar el inserter de jugadores.
- Crear migraciones numeradas y eliminar columnas duplicadas.
- Recalcular clasificación desde partidos terminados como comando de reparación.
- Añadir validadores de base: conteo de plantillas, fixtures, referencias, resultados y stats.
- Hacer el generador de calendario repetible sin duplicados y con transacción.
- Eliminar o documentar 'database.sqlite' vacío.

### Fase 2 — núcleo de carrera

Objetivo: el resultado de un partido cambia la carrera.

- Avance de jornada y temporada.
- Energía, moral y recuperación.
- Finanzas mínimas: presupuesto, salarios y premios.
- Historial de partidos, posiciones y temporadas.
- Clasificación operativa con desempates definidos.

### Fase 3 — decisiones de manager

Objetivo: la plantilla y la táctica importan.

- Compatibilidad de posiciones y roles.
- Tácticas y estilos que modifiquen eventos de forma comprensible.
- Lesiones, sanciones y rotación.
- Cantera, empleados e instalaciones en versiones pequeñas pero funcionales.

### Fase 4 — contenido y pulido

Objetivo: producto presentable.

- Más formaciones y competición de copa.
- Audio, feedback, transiciones y accesibilidad.
- Escalado para distintas resoluciones.
- Guardados múltiples, backup y recuperación de errores.
- Exportaciones Windows/Linux/Web verificadas.

## 14. Plan de pruebas recomendado

### Pruebas automatizables de dominio

- 'PlayerGeneration': posiciones válidas, atributos entre 1 y 99, potencial mayor o igual a calidad actual.
- 'FixtureService': una liga de cuatro equipos produce 12 partidos; cada pareja juega dos veces; seis fechas por club.
- 'SquadService': once con once IDs distintos, portero obligatorio, posiciones compatibles y banca sin titulares.
- 'LeagueService': puntos 3/1/0, goles a favor/contra, desempate y operación repetida sin duplicar.
- 'SaveService': crear, cargar, migrar y rechazar versiones futuras.
- 'DatabaseManager': errores SQL devuelven fallo; transacciones hacen rollback.

### Pruebas de integración

1. Base vacía → migración → semilla válida.
2. Nueva partida → base privada → calendario → 23 jugadores por club.
3. Cambiar once → guardar → cerrar escena → cargar → misma alineación.
4. Jugar partido → resultado único → tabla consistente con el acta.
5. Jugar dos partidos → dashboard muestra el siguiente pendiente.
6. Cerrar y abrir el juego → carrera y SQLite corresponden al mismo slot.
7. Crear segunda carrera → no modifica la primera.

### Pruebas manuales de UX

- Ventana 1920×1080, 1600×900 y 1280×720.
- Teclado y ratón sin depender solo de drag & drop.
- Botón atrás en cada escena.
- Error visible cuando no hay DB, calendario o plantilla.
- Nombres con apóstrofes, acentos y cadenas largas.
- Guardar durante una pantalla intermedia y recuperar.
- Repetir generadores sin crear duplicados.

## 15. Criterios de aceptación para una primera beta

- Una instalación limpia arranca sin editar la base manualmente.
- Nueva partida crea un slot aislado y no pisa otras carreras.
- El calendario se genera y muestra un próximo partido pendiente.
- La alineación elegida participa realmente en el partido.
- Un partido terminado solo se puede cerrar una vez.
- La clasificación coincide con la suma de partidos jugados.
- La pantalla de clasificaciones existe y tiene navegación de retorno.
- Las herramientas de desarrollo no pueden corromper el save activo sin confirmación.
- El juego puede exportarse y escribir en la ruta de usuario.
- Hay al menos pruebas de dominio para calendario, alineación, guardado y clasificación.

## 16. Guía operativa provisional

### Abrir el proyecto

1. Instalar Godot 4.6 o una versión compatible con 'config/features'.
2. Abrir la carpeta del proyecto, no un archivo '.tscn' aislado.
3. Confirmar que el addon 'godot-sqlite' carga la extensión nativa de la plataforma.
4. Ejecutar la escena principal desde 'project.godot'.

### Herramientas de desarrollo

Las escenas 'tools/generador_jugadores.tscn' y 'tools/generador_torneos.tscn' no están enlazadas desde el menú principal. Para usarlas durante desarrollo se pueden abrir individualmente desde el editor, después de hacer una copia de 'datos/PRUEBA.db'.

No se recomienda ejecutar el generador de jugadores actual en una base con plantillas incompletas hasta corregir su inserción schema-aware.

### Datos y respaldos

Mientras la base siga dentro de 'res://', hacer una copia del archivo antes de probar generadores o simulaciones. El estado actual de 'PRUEBA.db' contiene resultados y estadísticas de desarrollo, por lo que no debe confundirse con una semilla limpia.

## 17. Conclusión

La base es prometedora para continuar: hay una identidad visual, un loop reconocible, datos suficientes y una primera capa de simulación. El trabajo prioritario debe centrarse en coherencia de estado, no en agregar más pantallas. Cuando el proyecto tenga una base privada por partida, alineaciones respetadas, calendario integrado, actas transaccionales y clasificación derivable, estará en una posición mucho más sólida para añadir economía, cantera y temporadas.

La secuencia recomendada es: **persistencia privada → calendario → alineación real → acta idempotente → clasificación → pruebas → sistemas de carrera**.
