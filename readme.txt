REPOSITORIO DE EJERCICIOS DE PERFORMANCE

1. Objetivo del repositorio

Este repositorio contiene la solucion de dos ejercicios de analisis y performance:

- Ejercicio 1: prueba de carga del servicio de login con k6.
- Ejercicio 2: analisis tecnico de resultados de una prueba de carga ya ejecutada.

La documentacion se deja en formato .txt porque asi fue solicitada en el reto.

2. Versiones y tecnologias usadas

- Git: 2.52.0.windows.1
- k6: 1.7.1
- PowerShell: 5.1.26100.7920
- Microsoft Word: 16.0
- Sistema operativo de referencia: Windows 10.0.26200.0
- Libreria de visualizacion del reporte HTML del Ejercicio 1: Chart.js 4.4.3 por CDN
- Libreria de graficas del Ejercicio 2: System.Windows.Forms.DataVisualization

3. Estructura principal del proyecto

- data/credentials.csv: credenciales parametrizadas para el login del Ejercicio 1
- k6/login-load-test.js: script principal de la prueba de carga del login
- scripts/generate-report.ps1: generador del reporte HTML del Ejercicio 1
- scripts/generate-ejercicio-2-report.ps1: generador del informe, graficas y fuente del Ejercicio 2
- reports/: salidas y reportes del Ejercicio 1
- ejercicio-2/InformeResultados.doc: entregable principal del Ejercicio 2
- ejercicio-2/fuente/: fuente HTML y referencia de texto del informe del Ejercicio 2
- ejercicio-2/graficas/: graficas incluidas en el informe del Ejercicio 2
- ejercicio-2/insumos/: resumen transcrito y referencia del diagrama entregado
- ejercicio-2/datos/: datos estructurados usados para construir el informe del Ejercicio 2
- readme.txt: instrucciones de ejecucion y revision
- conclusiones.txt: hallazgos y conclusiones del Ejercicio 1

4. Flujo Git usado

- main: rama de liberacion
- develop: rama de integracion
- feature/implementar-prueba-carga-login-k6: rama de implementacion del Ejercicio 1
- feature/analisis-resultados-ejercicio-2: rama de implementacion del Ejercicio 2

La integracion se hace respetando gitflow:

- las features integran primero a develop
- develop integra despues a main

5. Ejercicio 1 - Prueba de carga del login con k6

Objetivo:

Ejecutar una prueba de carga sobre https://fakestoreapi.com/auth/login usando datos parametrizados desde CSV, con un escenario que alcance al menos 20 TPS y valide:

- tiempo de respuesta maximo de 1.5 segundos
- tasa de error menor al 3 por ciento

Archivos clave:

- data/credentials.csv
- k6/login-load-test.js
- reports/smoke-summary.json
- reports/smoke-report.html
- reports/load-summary.json
- reports/load-report.html
- conclusiones.txt

Preparacion del entorno:

1. Clonar el repositorio.
2. Entrar a la carpeta del proyecto.
3. Verificar herramientas:

   git --version
   k6 version
   powershell -Command "$PSVersionTable.PSVersion.ToString()"

Ejecucion de la prueba de humo:

1. Ejecutar:

   k6 run --summary-export reports/smoke-summary.json -e TEST_TYPE=smoke -e ITERATIONS=5 k6/login-load-test.js

2. Generar el reporte visual:

   powershell -ExecutionPolicy Bypass -File .\scripts\generate-report.ps1 -SummaryPath .\reports\smoke-summary.json -OutputPath .\reports\smoke-report.html -Title "Prueba de humo del login"

3. Revisar los resultados:

   reports/smoke-summary.json
   reports/smoke-report.html

Ejecucion de la prueba de carga:

1. Ejecutar la prueba principal:

   k6 run --summary-export reports/load-summary.json -e TEST_TYPE=load -e DURATION=1m k6/login-load-test.js

2. Generar el reporte visual:

   powershell -ExecutionPolicy Bypass -File .\scripts\generate-report.ps1 -SummaryPath .\reports\load-summary.json -OutputPath .\reports\load-report.html -Title "Prueba de carga del login"

3. Revisar:

   reports/load-summary.json
   reports/load-report.html
   conclusiones.txt

Parametros importantes del script de k6:

- BASE_URL: URL base del servicio. Valor por defecto: https://fakestoreapi.com
- TEST_TYPE: smoke o load. Valor por defecto: load
- TPS: tasa objetivo por segundo. Valor por defecto: 21
- DURATION: duracion de la prueba de carga. Valor por defecto: 1m
- LATENCY_LIMIT_MS: umbral maximo permitido por transaccion. Valor por defecto: 1500
- PRE_ALLOCATED_VUS: VUs iniciales del escenario. Valor por defecto: 40
- MAX_VUS: techo de VUs. Valor por defecto: 120

Notas de reproduccion del Ejercicio 1:

- El script toma las credenciales desde data/credentials.csv.
- La API publica de Fake Store responde con estado HTTP 201 y token cuando el login es exitoso.
- El escenario principal se deja en 21 TPS para mantener margen sobre el minimo solicitado de 20 TPS.
- Los reportes HTML usan Chart.js desde CDN, por lo que conviene abrirlos con acceso a internet.

6. Ejercicio 2 - Analisis de resultados de una prueba de carga

Objetivo:

Analizar un resumen textual de resultados y un diagrama de monitoreo entregados como evidencia, y consolidar los hallazgos en un archivo InformeResultados.doc con conclusiones, recomendaciones, calculos basicos y apoyo grafico.

Entregable principal:

- ejercicio-2/InformeResultados.doc

Archivos clave:

- ejercicio-2/insumos/textSummary.txt
- ejercicio-2/insumos/diagrama-monitoreo-referencia.txt
- ejercicio-2/datos/summary-metrics.json
- ejercicio-2/datos/monitoreo-aproximado.csv
- ejercicio-2/graficas/resultado-global.png
- ejercicio-2/graficas/perfil-latencia.png
- ejercicio-2/graficas/errores-por-etapa.png
- ejercicio-2/graficas/reconstruccion-monitoreo.png
- ejercicio-2/fuente/InformeResultados.html
- scripts/generate-ejercicio-2-report.ps1

Como revisar el Ejercicio 2:

1. Abrir directamente:

   ejercicio-2/InformeResultados.doc

2. Si se quiere revisar la version fuente del contenido:

   ejercicio-2/fuente/InformeResultados.html

3. Si se quieren inspeccionar los insumos originales y estructurados:

   ejercicio-2/insumos/
   ejercicio-2/datos/
   ejercicio-2/graficas/

Como regenerar el informe del Ejercicio 2:

1. Verificar que el entorno sea Windows y tenga Microsoft Word instalado.
2. Ejecutar:

   powershell -ExecutionPolicy Bypass -File .\scripts\generate-ejercicio-2-report.ps1

3. Revisar:

   ejercicio-2/InformeResultados.doc
   ejercicio-2/fuente/InformeResultados.html
   ejercicio-2/graficas/

Notas de reproduccion del Ejercicio 2:

- El resumen de terminal fue transcrito a ejercicio-2/insumos/textSummary.txt.
- El diagrama de monitoreo fue reconstruido de forma aproximada en ejercicio-2/datos/monitoreo-aproximado.csv para poder generar una grafica legible.
- La grafica reconstruida se usa como apoyo visual. No reemplaza la telemetria original de la prueba.
- El informe diferencia entre evidencia directa y causas probables para no sobreinterpretar los datos.

7. Resultado esperado del repositorio

Al revisar este repositorio se debe poder:

- ejecutar y validar el Ejercicio 1
- abrir y revisar el InformeResultados.doc del Ejercicio 2
- rastrear los insumos, datos transformados y graficas usados para construir el informe
- reproducir los artefactos principales con los scripts incluidos
