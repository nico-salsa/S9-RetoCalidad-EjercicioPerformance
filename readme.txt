EJERCICIO 1 - PRUEBA DE CARGA DEL LOGIN CON K6

1. Versiones usadas en esta implementacion

- Git: 2.52.0.windows.1
- k6: 1.7.1
- PowerShell: 5.1.26100.7920
- Sistema operativo de referencia: Windows 10.0.26200.0
- Libreria de visualizacion del reporte HTML: Chart.js 4.4.3 por CDN

2. Estructura del proyecto

- data/credentials.csv: datos de entrada del login
- k6/login-load-test.js: script principal de prueba
- scripts/generate-report.ps1: generador del reporte visual en HTML
- reports/: resultados exportados por k6 y reportes generados
- readme.txt: instrucciones de ejecucion
- conclusiones.txt: hallazgos y cierre del ejercicio

3. Flujo Git usado

- main: rama de liberacion
- develop: rama de integracion
- feature/implementar-prueba-carga-login-k6: rama de implementacion del ejercicio

4. Preparacion del entorno

1. Clonar el repositorio.
2. Entrar a la carpeta del proyecto.
3. Verificar las herramientas:
   git --version
   k6 version
   powershell -Command "$PSVersionTable.PSVersion.ToString()"

5. Ejecucion de la prueba de humo

1. Ejecutar:
   k6 run --summary-export reports/smoke-summary.json -e TEST_TYPE=smoke -e ITERATIONS=5 k6/login-load-test.js
2. Generar el reporte visual:
   powershell -ExecutionPolicy Bypass -File .\scripts\generate-report.ps1 -SummaryPath .\reports\smoke-summary.json -OutputPath .\reports\smoke-report.html -Title "Prueba de humo del login"
3. Revisar:
   reports/smoke-summary.json
   reports/smoke-report.html

6. Ejecucion de la prueba de carga

1. Ejecutar la prueba principal:
   k6 run --summary-export reports/load-summary.json -e TEST_TYPE=load -e DURATION=1m k6/login-load-test.js
2. Generar el reporte visual:
   powershell -ExecutionPolicy Bypass -File .\scripts\generate-report.ps1 -SummaryPath .\reports\load-summary.json -OutputPath .\reports\load-report.html -Title "Prueba de carga del login"
3. Revisar:
   reports/load-summary.json
   reports/load-report.html
   conclusiones.txt

7. Parametros importantes

- BASE_URL: permite cambiar la URL base del servicio. Valor por defecto: https://fakestoreapi.com
- TEST_TYPE: smoke o load. Valor por defecto: load
- TPS: tasa objetivo por segundo. Valor por defecto: 21
- DURATION: duracion de la prueba de carga. Valor por defecto: 1m
- LATENCY_LIMIT_MS: umbral maximo permitido por transaccion. Valor por defecto: 1500
- PRE_ALLOCATED_VUS: VUs iniciales del escenario. Valor por defecto: 40
- MAX_VUS: techo de VUs. Valor por defecto: 120

8. Notas de reproduccion

- El script toma las credenciales desde data/credentials.csv.
- La API publica de Fake Store responde con estado HTTP 201 y token cuando el login es exitoso.
- El escenario principal se deja en 21 TPS para mantener un margen sobre el minimo solicitado de 20 TPS y evitar que el promedio final de k6 quede justo en el borde.
- Los reportes HTML se apoyan en Chart.js desde CDN; por eso conviene abrirlos con acceso a internet.
