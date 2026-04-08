param(
    [string]$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Add-Type -AssemblyName System.Windows.Forms.DataVisualization

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Format-Decimal {
    param(
        [double]$Value,
        [int]$Digits = 2
    )

    return [math]::Round($Value, $Digits).ToString("N$Digits", [System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-Integer {
    param([double]$Value)

    return [math]::Round($Value, 0).ToString("N0", [System.Globalization.CultureInfo]::InvariantCulture)
}

function New-ChartBase {
    param(
        [string]$Title,
        [int]$Width = 1400,
        [int]$Height = 820
    )

    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = $Width
    $chart.Height = $Height
    $chart.BackColor = [System.Drawing.Color]::White
    $chart.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::BrightPastel
    $chart.BorderlineColor = [System.Drawing.Color]::FromArgb(210, 210, 210)
    $chart.BorderlineDashStyle = [System.Windows.Forms.DataVisualization.Charting.ChartDashStyle]::Solid
    $chart.BorderlineWidth = 1
    $titleObject = $chart.Titles.Add($Title)
    $titleObject.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $titleObject.ForeColor = [System.Drawing.Color]::FromArgb(31, 41, 55)
    return $chart
}

function Save-Chart {
    param(
        [System.Windows.Forms.DataVisualization.Charting.Chart]$Chart,
        [string]$Path
    )

    $Chart.SaveImage($Path, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
    $Chart.Dispose()
}

function New-DoughnutChart {
    param(
        [string]$Path,
        [string]$Title,
        [hashtable]$Values
    )

    $chart = New-ChartBase -Title $Title
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "Main"
    $chartArea.BackColor = [System.Drawing.Color]::White
    $chart.ChartAreas.Add($chartArea)

    $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend "Legend"
    $legend.Docking = [System.Windows.Forms.DataVisualization.Charting.Docking]::Right
    $legend.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $chart.Legends.Add($legend)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series "Resultados"
    $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Doughnut
    $series.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $series.LabelForeColor = [System.Drawing.Color]::FromArgb(31, 41, 55)
    $series["PieLabelStyle"] = "Outside"
    $series["DoughnutRadius"] = "58"
    $series.IsValueShownAsLabel = $true
    $series.Label = "#VALX: #VALY"

    foreach ($entry in $Values.GetEnumerator()) {
        [void]$series.Points.AddXY($entry.Key, $entry.Value)
    }

    $series.Points[0].Color = [System.Drawing.Color]::FromArgb(34, 197, 94)
    $series.Points[1].Color = [System.Drawing.Color]::FromArgb(239, 68, 68)
    $chart.Series.Add($series)
    Save-Chart -Chart $chart -Path $Path
}

function New-BarChart {
    param(
        [string]$Path,
        [string]$Title,
        [string]$SeriesName,
        [object[]]$Labels,
        [double[]]$Values,
        [string]$AxisTitle,
        [bool]$Logarithmic = $false
    )

    $chart = New-ChartBase -Title $Title
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "Main"
    $chartArea.BackColor = [System.Drawing.Color]::White
    $chartArea.AxisX.Interval = 1
    $chartArea.AxisX.MajorGrid.Enabled = $false
    $chartArea.AxisX.LabelStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chartArea.AxisY.Title = $AxisTitle
    $chartArea.AxisY.TitleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $chartArea.AxisY.LabelStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $chartArea.AxisY.IsLogarithmic = $Logarithmic
    $chart.ChartAreas.Add($chartArea)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series $SeriesName
    $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
    $series.IsValueShownAsLabel = $true
    $series.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $series.Color = [System.Drawing.Color]::FromArgb(37, 99, 235)
    $series.LabelForeColor = [System.Drawing.Color]::FromArgb(31, 41, 55)

    for ($i = 0; $i -lt $Labels.Count; $i++) {
        $pointIndex = $series.Points.AddXY($Labels[$i], $Values[$i])
        $series.Points[$pointIndex].Label = [math]::Round($Values[$i], 2).ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }

    $chart.Series.Add($series)
    Save-Chart -Chart $chart -Path $Path
}

function New-MonitoringChart {
    param(
        [string]$Path,
        [string]$Title,
        [object[]]$Rows
    )

    $chart = New-ChartBase -Title $Title -Width 1600 -Height 860
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "Main"
    $chartArea.BackColor = [System.Drawing.Color]::White
    $chartArea.AxisX.LabelStyle.Format = "HH:mm"
    $chartArea.AxisX.IntervalType = [System.Windows.Forms.DataVisualization.Charting.DateTimeIntervalType]::Minutes
    $chartArea.AxisX.Interval = 5
    $chartArea.AxisX.LabelStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chartArea.AxisX.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(235, 235, 235)
    $chartArea.AxisY.Title = "VUs"
    $chartArea.AxisY.TitleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $chartArea.AxisY.Minimum = 0
    $chartArea.AxisY.Maximum = 160
    $chartArea.AxisY.Interval = 20
    $chartArea.AxisY.LabelStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(235, 235, 235)
    $chartArea.AxisY2.Enabled = [System.Windows.Forms.DataVisualization.Charting.AxisEnabled]::True
    $chartArea.AxisY2.Title = "http_reqs/s"
    $chartArea.AxisY2.TitleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $chartArea.AxisY2.Minimum = 0
    $chartArea.AxisY2.Maximum = 100
    $chartArea.AxisY2.Interval = 10
    $chartArea.AxisY2.LabelStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chart.ChartAreas.Add($chartArea)

    $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend "Legend"
    $legend.Docking = [System.Windows.Forms.DataVisualization.Charting.Docking]::Bottom
    $legend.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $chart.Legends.Add($legend)

    $vusSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series "VUs"
    $vusSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $vusSeries.XValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::DateTime
    $vusSeries.BorderWidth = 4
    $vusSeries.Color = [System.Drawing.Color]::FromArgb(16, 185, 129)
    $vusSeries.Legend = "Legend"

    $reqSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series "http_reqs/s"
    $reqSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $reqSeries.XValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::DateTime
    $reqSeries.BorderWidth = 4
    $reqSeries.Color = [System.Drawing.Color]::FromArgb(37, 99, 235)
    $reqSeries.YAxisType = [System.Windows.Forms.DataVisualization.Charting.AxisType]::Secondary
    $reqSeries.Legend = "Legend"

    foreach ($row in $Rows) {
        $timestamp = [DateTime]::Parse($row.timestamp)
        [void]$vusSeries.Points.AddXY($timestamp.ToOADate(), [double]$row.vus)
        [void]$reqSeries.Points.AddXY($timestamp.ToOADate(), [double]$row.http_reqs_per_s)
    }

    $chart.Series.Add($vusSeries)
    $chart.Series.Add($reqSeries)
    Save-Chart -Chart $chart -Path $Path
}

$exerciseDir = Join-Path $RootDir "ejercicio-2"
$dataDir = Join-Path $exerciseDir "datos"
$sourceDir = Join-Path $exerciseDir "fuente"
$graphsDir = Join-Path $exerciseDir "graficas"

Ensure-Directory -Path $exerciseDir
Ensure-Directory -Path $sourceDir
Ensure-Directory -Path $graphsDir

$summaryData = Get-Content -Raw -Path (Join-Path $dataDir "summary-metrics.json") | ConvertFrom-Json
$monitoringRows = Import-Csv -Path (Join-Path $dataDir "monitoreo-aproximado.csv")
$summary = $summaryData.summary
$referencePoint = $summaryData.monitoring.reference_point

$totalRequests = [double]$summary.http_reqs.total
$requestsPerSecond = [double]$summary.http_reqs.rate
$approxDurationSeconds = $totalRequests / $requestsPerSecond
$approxDurationMinutes = [math]::Floor($approxDurationSeconds / 60)
$approxDurationRemainingSeconds = [math]::Round($approxDurationSeconds % 60, 2)
$waitingSharePct = ($summary.http_req_waiting.avg_ms / $summary.http_req_duration.avg_ms) * 100
$successfulRatePct = [double]$summary.checks.success_rate_pct
$failedRatePct = [double]$summary.http_req_failed.rate_pct
$failCount = [int]$summary.http_req_failed.count
$successCount = [int]$summary.checks.success_count
$stageFailureRows = @($summary.stage_failures)
$stage1Failures = ($stageFailureRows | Where-Object { $_.stage -eq "stage_1" } | Measure-Object -Property count -Sum).Sum
$total5xx = ($stageFailureRows | Where-Object { $_.status -eq "HTTP5xx" } | Measure-Object -Property count -Sum).Sum
$stage1SharePct = ($stage1Failures / $failCount) * 100
$fiveXxSharePct = ($total5xx / $failCount) * 100
$observedReqPerVu = [double]$referencePoint.http_reqs_per_s / [double]$referencePoint.vus
$minObservedReq = (($monitoringRows | Measure-Object -Property http_reqs_per_s -Minimum).Minimum)
$typicalObservedReqLow = 75
$typicalObservedReqHigh = 85
$latencyGapMs = [double]$summary.http_req_duration.avg_ms - [double]$summary.http_req_duration_expected.avg_ms

$globalChartPath = Join-Path $graphsDir "resultado-global.png"
$latencyChartPath = Join-Path $graphsDir "perfil-latencia.png"
$stageErrorChartPath = Join-Path $graphsDir "errores-por-etapa.png"
$monitoringChartPath = Join-Path $graphsDir "reconstruccion-monitoreo.png"

New-DoughnutChart -Path $globalChartPath -Title "Resultado global de la prueba" -Values ([ordered]@{
    "Exitosas" = $successCount
    "Fallidas" = $failCount
})

New-BarChart -Path $latencyChartPath -Title "Perfil de latencia observado" -SeriesName "Latencia" -Labels @("Min", "Mediana", "Promedio", "P90", "P95", "Max") -Values @(
    [double]$summary.http_req_duration.min_ms,
    [double]$summary.http_req_duration.med_ms,
    [double]$summary.http_req_duration.avg_ms,
    [double]$summary.http_req_duration.p90_ms,
    [double]$summary.http_req_duration.p95_ms,
    [double]$summary.http_req_duration.max_ms
) -AxisTitle "Milisegundos (escala logaritmica)" -Logarithmic $true

New-BarChart -Path $stageErrorChartPath -Title "Errores visibles por etapa" -SeriesName "Errores" -Labels @("Stage 0 5xx", "Stage 1 4xx", "Stage 1 5xx", "Stage 2 5xx") -Values @(
    [double]$stageFailureRows[0].count,
    [double]$stageFailureRows[1].count,
    [double]$stageFailureRows[2].count,
    [double]$stageFailureRows[3].count
) -AxisTitle "Cantidad de errores" -Logarithmic $false

New-MonitoringChart -Path $monitoringChartPath -Title "Reconstruccion aproximada del monitoreo entregado" -Rows $monitoringRows

$summaryHtmlPath = Join-Path $sourceDir "InformeResultados.html"
$docPath = Join-Path $exerciseDir "InformeResultados.doc"
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$globalChartUri = [System.Uri]::new($globalChartPath).AbsoluteUri
$latencyChartUri = [System.Uri]::new($latencyChartPath).AbsoluteUri
$stageErrorChartUri = [System.Uri]::new($stageErrorChartPath).AbsoluteUri
$monitoringChartUri = [System.Uri]::new($monitoringChartPath).AbsoluteUri

$durationFormula = "{0} / {1} = {2} s aprox. {3} min {4} s" -f (Format-Integer $totalRequests), (Format-Decimal $requestsPerSecond 6), (Format-Decimal $approxDurationSeconds 2), $approxDurationMinutes, (Format-Decimal $approxDurationRemainingSeconds 2)
$waitingFormula = "{0} / {1} x 100 = {2}%" -f (Format-Decimal $summary.http_req_waiting.avg_ms 2), (Format-Decimal $summary.http_req_duration.avg_ms 2), (Format-Decimal $waitingSharePct 2)
$stage1Formula = "{0} / {1} x 100 = {2}%" -f (Format-Integer $stage1Failures), (Format-Integer $failCount), (Format-Decimal $stage1SharePct 2)
$fiveXxFormula = "{0} / {1} x 100 = {2}%" -f (Format-Integer $total5xx), (Format-Integer $failCount), (Format-Decimal $fiveXxSharePct 2)
$reqPerVuFormula = "{0} / {1} = {2} req/s por VU" -f (Format-Decimal $referencePoint.http_reqs_per_s 2), (Format-Integer $referencePoint.vus), (Format-Decimal $observedReqPerVu 2)

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>InformeResultados</title>
  <style>
    body {
      font-family: Calibri, "Segoe UI", sans-serif;
      color: #1f2937;
      margin: 34px 42px;
      line-height: 1.42;
      font-size: 11pt;
    }

    h1, h2, h3 {
      color: #0f4c81;
      margin-bottom: 8px;
    }

    h1 {
      font-size: 24pt;
      text-align: center;
      margin-top: 0;
    }

    h2 {
      font-size: 16pt;
      border-bottom: 1px solid #cfd8e3;
      padding-bottom: 4px;
      margin-top: 26px;
    }

    h3 {
      font-size: 13pt;
      margin-top: 18px;
    }

    p {
      margin: 8px 0;
      text-align: justify;
    }

    ul {
      margin: 8px 0 8px 20px;
      padding: 0;
    }

    li {
      margin: 6px 0;
    }

    .intro {
      background: #eef5fb;
      border: 1px solid #d3e1ef;
      border-radius: 8px;
      padding: 16px 18px;
      margin: 18px 0 22px;
    }

    .metrics {
      width: 100%;
      border-collapse: collapse;
      margin: 12px 0 18px;
    }

    .metrics th,
    .metrics td {
      border: 1px solid #d7dde5;
      padding: 8px 10px;
      vertical-align: top;
    }

    .metrics th {
      background: #f3f7fb;
      text-align: left;
    }

    .formula {
      background: #f9fafb;
      border-left: 4px solid #0f4c81;
      padding: 10px 12px;
      font-family: Consolas, "Courier New", monospace;
      margin: 10px 0 14px;
      white-space: pre-wrap;
    }

    .chart {
      margin: 18px 0 24px;
      text-align: center;
      page-break-inside: avoid;
    }

    .chart img {
      max-width: 100%;
      border: 1px solid #d7dde5;
    }

    .caption {
      font-size: 9.5pt;
      color: #4b5563;
      margin-top: 6px;
    }

    .callout {
      background: #fff7ed;
      border: 1px solid #fed7aa;
      border-radius: 8px;
      padding: 14px 16px;
      margin: 16px 0;
    }

    .small {
      font-size: 9.5pt;
      color: #4b5563;
    }
  </style>
</head>
<body>
  <h1>Informe de Resultados</h1>
  <p style="text-align:center;"><strong>Ejercicio 2 - Analisis de una prueba de carga</strong></p>
  <p style="text-align:center;">Generado: $generatedAt</p>

  <div class="intro">
    <p>Este informe analiza la evidencia entregada en dos fuentes: el resumen textual de <strong>k6</strong> y el diagrama de monitoreo con la relacion entre <strong>usuarios virtuales</strong> y <strong>peticiones por segundo</strong>. El objetivo es interpretar con rigor lo que muestran los datos, explicar el hallazgo central y proponer causas probables del cuello de botella junto con acciones de mejora.</p>
  </div>

  <h2>1. Datos basicos de la prueba</h2>
  <table class="metrics">
    <tr>
      <th>Dato</th>
      <th>Valor observado</th>
      <th>Lectura</th>
    </tr>
    <tr>
      <td>Tipo de prueba</td>
      <td>Prueba de carga por etapas con fase principal sostenida</td>
      <td>Se interpreta asi por la presencia de metricas por <code>stage</code>, un maximo de 140 VUs y un tramo principal visible de carga alta en el diagrama.</td>
    </tr>
    <tr>
      <td>Herramienta</td>
      <td>k6</td>
      <td>Las metricas visibles corresponden al formato tipico de salida de k6: <code>http_req_duration</code>, <code>http_req_waiting</code>, <code>vus</code> y <code>vus_max</code>.</td>
    </tr>
    <tr>
      <td>Volumen total</td>
      <td>$(Format-Integer $totalRequests) peticiones</td>
      <td>Es una corrida larga y suficientemente pesada para observar degradacion sostenida.</td>
    </tr>
    <tr>
      <td>Throughput promedio</td>
      <td>$(Format-Decimal $requestsPerSecond 6) req/s</td>
      <td>El sistema movio bastante volumen, pero ese promedio oculta una fase de caida fuerte a mitad de la ejecucion.</td>
    </tr>
    <tr>
      <td>Maximo de VUs</td>
      <td>$(Format-Integer $summary.vus.max) VUs</td>
      <td>La grafica confirma una fase sostenida en 140 VUs.</td>
    </tr>
    <tr>
      <td>Resultado global</td>
      <td>$(Format-Decimal $successfulRatePct 2)% exitosas y $(Format-Decimal $failedRatePct 2)% fallidas</td>
      <td>La prueba no colapsa por completo, pero tampoco es completamente estable.</td>
    </tr>
  </table>

  <h3>Calculo de duracion aproximada</h3>
  <div class="formula">$durationFormula</div>
  <p>La ejecucion duro aproximadamente <strong>63 minutos</strong>. Esa duracion es coherente con la ventana temporal visible en la grafica, que muestra un tramo extendido de actividad antes de la caida final por cierre de la prueba.</p>

  <h2>2. Resultados a primera vista</h2>
  <p>A primera vista la prueba deja una impresion mixta. Por un lado, el volumen total de peticiones es alto y el throughput promedio supera las 73 peticiones por segundo, lo que indica que el sistema fue capaz de procesar una carga importante. Por otro lado, el porcentaje de fallos llega a <strong>2.44%</strong>, y la latencia maxima se dispara hasta <strong>29.93 s</strong>. Eso significa que, aunque la mayor parte de la ejecucion fue productiva, existen sintomas claros de saturacion o inestabilidad bajo carga alta.</p>

  <div class="chart">
    <img src="$globalChartUri" alt="Resultado global de la prueba">
    <div class="caption">Figura 1. Relacion entre peticiones exitosas y fallidas observadas en el resumen de k6.</div>
  </div>

  <h2>3. Resultados detallados</h2>
  <table class="metrics">
    <tr>
      <th>Metrica</th>
      <th>Valor</th>
      <th>Interpretacion</th>
    </tr>
    <tr>
      <td>Latencia promedio</td>
      <td>$(Format-Decimal $summary.http_req_duration.avg_ms 2) ms</td>
      <td>El promedio no es desastroso, pero ya muestra una carga perceptible sobre el servicio.</td>
    </tr>
    <tr>
      <td>Latencia mediana</td>
      <td>$(Format-Decimal $summary.http_req_duration.med_ms 2) ms</td>
      <td>La mitad de las peticiones respondio en menos de 613 ms, lo que sugiere que el sistema fue razonablemente rapido en condiciones normales.</td>
    </tr>
    <tr>
      <td>P90 / P95</td>
      <td>$(Format-Decimal ($summary.http_req_duration.p90_ms / 1000) 2) s / $(Format-Decimal ($summary.http_req_duration.p95_ms / 1000) 2) s</td>
      <td>El 10% y el 5% mas lento ya entran en una zona claramente degradada. La cola de latencia existe y es relevante.</td>
    </tr>
    <tr>
      <td>Latencia maxima</td>
      <td>$(Format-Decimal ($summary.http_req_duration.max_ms / 1000) 2) s</td>
      <td>Es el dato mas duro de la distribucion. Un maximo cercano a 30 segundos indica episodios extremos de espera.</td>
    </tr>
    <tr>
      <td>Tiempo de espera del servidor</td>
      <td>$(Format-Decimal $summary.http_req_waiting.avg_ms 2) ms promedio</td>
      <td>Practicamente coincide con la latencia total; por tanto, el tiempo se consume esperando respuesta del backend, no en la red del cliente.</td>
    </tr>
    <tr>
      <td>Red y conexion</td>
      <td>Bloqueo 0.01 ms, conexion 0.00 ms, TLS 0.01 ms, envio 0.04 ms, recepcion 0.42 ms</td>
      <td>Estas metricas son minimas. No hay evidencia fuerte de que la red sea el principal cuello de botella.</td>
    </tr>
    <tr>
      <td>Errores por tipo</td>
      <td>$(Format-Integer $total5xx) errores 5xx y 769 errores 4xx</td>
      <td>La falla dominante es de servidor, no de cliente.</td>
    </tr>
  </table>

  <h3>Relacion entre waiting y duration</h3>
  <div class="formula">$waitingFormula</div>
  <p>El promedio de <code>http_req_waiting</code> representa aproximadamente el <strong>$(Format-Decimal $waitingSharePct 2)%</strong> del promedio total de <code>http_req_duration</code>. Esta es una evidencia fuerte de que la mayor parte del tiempo se pierde dentro del servicio o de sus dependencias. En otras palabras, el problema principal no parece estar en el envio, en la recepcion ni en el establecimiento de la conexion.</p>
  <p>Adicionalmente, la diferencia entre el promedio global de latencia y el promedio de las respuestas esperadas es de <strong>$(Format-Decimal $latencyGapMs 2) ms</strong>. Eso refuerza la idea de que el problema no solo afecta a las respuestas fallidas, sino que ya presiona a la experiencia general de la transaccion.</p>

  <div class="chart">
    <img src="$latencyChartUri" alt="Perfil de latencia">
    <div class="caption">Figura 2. Perfil de latencia en escala logaritmica. La cola larga se hace evidente al comparar mediana, promedio y maximo.</div>
  </div>

  <h2>4. Relacion entre el resumen de terminal y la grafica</h2>
  <p>La terminal aporta el panorama agregado de toda la corrida: <strong>73.176857 req/s</strong> en promedio, <strong>276650</strong> peticiones totales, <strong>2.44%</strong> de error y una latencia con una cola larga significativa. La grafica, por su parte, aporta el comportamiento temporal que el resumen por si solo no puede mostrar.</p>
  <p>El punto visible del diagrama en <strong>2025-04-24 02:02:00</strong> indica <strong>140 VUs</strong> y <strong>82.6 req/s</strong>. Eso es totalmente coherente con el promedio de 73.18 req/s del resumen, porque la grafica tambien muestra una caida intermedia pronunciada del throughput. Dicho de otra manera: el sistema si alcanza una banda cercana a <strong>$typicalObservedReqLow-$typicalObservedReqHigh req/s</strong> bajo 140 VUs, pero no logra sostenerla sin sobresaltos durante toda la ejecucion.</p>
  <p>La reconstruccion aproximada del diagrama muestra tambien que el throughput cae hasta una zona cercana a <strong>$(Format-Decimal $minObservedReq 2) req/s</strong> sin que desaparezca la carga. Esa oscilacion es la pieza visual que explica por que un punto puntual de 82.6 req/s puede convivir con un promedio global inferior.</p>

  <h3>Relacion puntual entre VUs y throughput</h3>
  <div class="formula">$reqPerVuFormula</div>
  <p>Ese calculo no representa una ley universal del sistema, pero ayuda a describir el punto visible del diagrama. La relacion de ese instante es cercana a <strong>0.59 req/s por VU</strong>. Lo importante no es el numero exacto, sino que el servicio, aun con 140 VUs activos, presenta fluctuaciones fuertes y no una curva estable de rendimiento.</p>

  <div class="chart">
    <img src="$monitoringChartUri" alt="Reconstruccion del monitoreo">
    <div class="caption">Figura 3. Reconstruccion aproximada del monitoreo entregado. Se usa como apoyo visual, no como telemetria cruda. Muestra una fase estable, una caida fuerte a mitad de la corrida y una recuperacion posterior.</div>
  </div>

  <h2>5. Analisis de errores por etapa</h2>
  <p>El reparto de errores no esta distribuido de forma uniforme. Casi toda la carga fallida se concentra en <strong>stage_1</strong>, que por contexto se interpreta como la fase principal de la prueba.</p>

  <h3>Concentracion de fallos en la etapa principal</h3>
  <div class="formula">$stage1Formula</div>
  <p>Esto significa que <strong>stage_1 concentra practicamente todos los errores</strong>. La lectura operativa es clara: el sistema no falla de manera aleatoria al inicio o al final; falla sobre todo cuando esta sometido al tramo fuerte de carga.</p>

  <h3>Peso de los errores 5xx dentro del total</h3>
  <div class="formula">$fiveXxFormula</div>
  <p>Que casi el <strong>$(Format-Decimal $fiveXxSharePct 2)%</strong> de las fallas sean <strong>5xx</strong> desplaza el foco hacia el servidor o sus dependencias. Los 4xx existen, pero son secundarios frente a la magnitud del problema del lado backend.</p>

  <div class="chart">
    <img src="$stageErrorChartUri" alt="Errores por etapa">
    <div class="caption">Figura 4. La etapa principal concentra la mayor parte de los errores y, dentro de ella, dominan claramente los 5xx.</div>
  </div>

  <h2>6. Posibles cuellos de botella y causas probables</h2>
  <p>Con la evidencia disponible no es posible demostrar una causa raiz unica. Sin embargo, si es posible jerarquizar causas probables y distinguir entre afirmaciones sustentadas y especulaciones razonables.</p>

  <h3>6.1 Evidencia directa observable</h3>
  <ul>
    <li><strong>Dominio del tiempo de espera del servidor.</strong> El promedio de <code>http_req_waiting</code> es casi igual al de <code>http_req_duration</code>. Esto apunta a saturacion dentro del backend.</li>
    <li><strong>Presencia dominante de errores 5xx.</strong> La mayor parte de los fallos son respuestas de servidor, no errores del cliente.</li>
    <li><strong>Caida del throughput con 140 VUs activos.</strong> El diagrama muestra una fase en la que el ritmo de peticiones cae con fuerza mientras la carga se mantiene alta. Eso sugiere degradacion de la capacidad efectiva del sistema.</li>
    <li><strong>Cola larga de latencia.</strong> La diferencia entre mediana, promedio, p95 y maximo confirma que existe un subconjunto de peticiones muy afectadas por la saturacion.</li>
  </ul>

  <h3>6.2 Causas probables en un escenario real</h3>
  <ul>
    <li><strong>Saturacion de CPU o de hilos del servidor.</strong> Es compatible con tiempos de espera altos, throughput inestable y 5xx durante la fase principal.</li>
    <li><strong>Cuello de botella en base de datos.</strong> Consultas lentas, bloqueos o limites de conexiones pueden incrementar el waiting y provocar degradacion general del servicio.</li>
    <li><strong>Agotamiento de pools.</strong> Pools de conexiones HTTP, base de datos o threads demasiado pequenos pueden generar cola interna aunque la red externa se vea sana.</li>
    <li><strong>Dependencia externa inestable.</strong> Si la transaccion depende de otro servicio, la aplicacion puede responder tarde o fallar aun cuando el endpoint expuesto sea el que aparece como 5xx.</li>
    <li><strong>Ausencia de una capa de balanceo o resiliencia al frente del servicio.</strong> El material entregado no muestra evidencia de un load balancer o de mecanismos de distribucion; si en un escenario real esa capa no existiera, la degradacion bajo carga sostenida podria amplificarse.</li>
    <li><strong>Configuracion deficiente bajo carga sostenida.</strong> Timeouts, limites de workers o garbage collection agresivo tambien podrian explicar un comportamiento que se degrada y luego se recupera.</li>
  </ul>

  <h3>6.3 Que se puede afirmar y que no</h3>
  <div class="callout">
    <p><strong>Se puede afirmar con evidencia:</strong> el cuello de botella no parece ser la red del cliente; la degradacion aparece principalmente en la etapa principal; el throughput cae en ciertos tramos aun con alta concurrencia; y la mayor parte del problema se manifiesta como espera y errores 5xx.</p>
    <p><strong>No se puede afirmar con certeza solo con esta evidencia:</strong> si la causa exacta fue CPU, base de datos, pool de conexiones, dependencia externa u otra capa de infraestructura. Esas causas deben tratarse como hipotesis razonables hasta validarlas con telemetria adicional del backend.</p>
  </div>

  <h2>7. Punto mas importante del analisis</h2>
  <p>El punto mas importante es que <strong>el sistema si procesa un volumen alto, pero no lo hace de forma estable bajo la carga principal</strong>. La evidencia conjunta de k6 y del diagrama muestra una mezcla de tres senales: caida visible del throughput, concentracion de errores 5xx en la etapa fuerte y tiempos de espera del servidor que explican casi toda la latencia. En conjunto, eso describe un cuello de botella del lado servidor o de sus dependencias, no un problema primario de red.</p>

  <h2>8. Conclusiones</h2>
  <ul>
    <li>La prueba movio un volumen considerable de peticiones y demuestra que el sistema tiene cierta capacidad de procesamiento, pero no una estabilidad completa bajo carga alta.</li>
    <li>El promedio de 73.18 req/s es real, pero no representa estabilidad continua; la grafica deja ver una degradacion marcada a mitad de la ejecucion.</li>
    <li>El comportamiento de <code>http_req_waiting</code> sugiere que el mayor tiempo se pierde dentro del backend y no en la red del cliente.</li>
    <li>La etapa principal concentra practicamente todos los errores, y dentro de ellos dominan de forma clara los 5xx.</li>
    <li>La evidencia disponible permite hablar de saturacion o degradacion del servidor, pero no permite aislar una causa raiz unica sin telemetria interna adicional.</li>
  </ul>

  <h2>9. Recomendaciones</h2>
  <p>En un escenario real, estas serian las acciones mas utiles para diagnosticar mejor el problema y reducir la posibilidad de recurrencia.</p>
  <ul>
    <li>Correlacionar la ventana de la prueba con metricas de CPU, memoria, hilos, pool de conexiones y base de datos para validar la causa exacta del waiting elevado.</li>
    <li>Revisar logs de aplicacion y de infraestructura en la fase equivalente a <code>stage_1</code>, donde se concentra el 99.96% de los errores.</li>
    <li>Analizar especificamente los <strong>5xx</strong> para identificar si provienen de saturacion, timeouts, dependencias externas o errores de negocio mal controlados.</li>
    <li>Ejecutar una nueva prueba escalonada con puntos intermedios de concurrencia para ubicar con mayor precision el umbral donde empieza la degradacion.</li>
    <li>Si se confirma presion sobre base de datos, revisar indices, tiempos de consulta y limites de conexiones; si se confirma presion sobre la aplicacion, revisar workers, timeouts y politica de escalado.</li>
    <li>Mantener en el informe una distincion clara entre evidencia y especulacion para no sobreinterpretar los datos disponibles.</li>
  </ul>

  <p class="small">Fuente de datos: transcripcion del resumen de k6 y reconstruccion aproximada del diagrama de monitoreo entregado. La reconstruccion grafica se incluye como apoyo visual y no sustituye a la telemetria original.</p>
</body>
</html>
"@

Set-Content -Path $summaryHtmlPath -Value $html -Encoding UTF8

function Add-WordParagraph {
    param(
        [object]$Selection,
        [string]$Text,
        [int]$Size = 11,
        [bool]$Bold = $false,
        [int]$Alignment = 3,
        [int]$After = 6,
        [string]$FontName = "Calibri"
    )

    $Selection.Font.Name = $FontName
    $Selection.Font.Size = $Size
    $Selection.Font.Bold = if ($Bold) { 1 } else { 0 }
    $Selection.ParagraphFormat.Alignment = $Alignment
    $Selection.ParagraphFormat.SpaceAfter = $After
    $Selection.TypeText($Text)
    $Selection.TypeParagraph()
}

function Add-WordBullet {
    param(
        [object]$Selection,
        [string]$Text
    )

    Add-WordParagraph -Selection $Selection -Text ("• " + $Text) -Size 11 -Bold $false -Alignment 3 -After 4
}

function Add-WordBullet {
    param(
        [object]$Selection,
        [string]$Text
    )

    Add-WordParagraph -Selection $Selection -Text ("- " + $Text) -Size 11 -Bold $false -Alignment 3 -After 4
}

function Add-WordImage {
    param(
        [object]$Selection,
        [string]$Path,
        [int]$Width = 430,
        [string]$Caption
    )

    $Selection.ParagraphFormat.Alignment = 1
    $shape = $Selection.InlineShapes.AddPicture($Path)
    $shape.Width = $Width
    $Selection.TypeParagraph()
    if ($Caption) {
        Add-WordParagraph -Selection $Selection -Text $Caption -Size 9 -Bold $false -Alignment 1 -After 10
    }
}

$word = $null
$document = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Add()
    $selection = $word.Selection

    Add-WordParagraph -Selection $selection -Text "Informe de Resultados" -Size 24 -Bold $true -Alignment 1 -After 3
    Add-WordParagraph -Selection $selection -Text "Ejercicio 2 - Analisis de una prueba de carga" -Size 13 -Bold $true -Alignment 1 -After 3
    Add-WordParagraph -Selection $selection -Text ("Generado: " + $generatedAt) -Size 10 -Bold $false -Alignment 1 -After 14

    Add-WordParagraph -Selection $selection -Text "Este informe analiza la evidencia entregada en dos fuentes: el resumen textual de k6 y el diagrama de monitoreo con la relacion entre usuarios virtuales y peticiones por segundo. El objetivo es interpretar con rigor lo que muestran los datos, explicar el hallazgo central y proponer causas probables del cuello de botella junto con acciones de mejora." -Size 11 -Bold $false -Alignment 3 -After 12

    Add-WordParagraph -Selection $selection -Text "1. Datos basicos de la prueba" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordBullet -Selection $selection -Text "Tipo de prueba: se interpreta como una prueba de carga por etapas con una fase principal sostenida, debido a la presencia de metricas por stage, un maximo de 140 VUs y un tramo principal visible de alta concurrencia en el diagrama."
    Add-WordBullet -Selection $selection -Text "Herramienta: k6, por el formato de salida y las metricas visibles como http_req_duration, http_req_waiting, vus y vus_max."
    Add-WordBullet -Selection $selection -Text ("Volumen total: " + (Format-Integer $totalRequests) + " peticiones.")
    Add-WordBullet -Selection $selection -Text ("Throughput promedio: " + (Format-Decimal $requestsPerSecond 6) + " req/s.")
    Add-WordBullet -Selection $selection -Text ("Carga maxima visible: " + (Format-Integer $summary.vus.max) + " VUs.")
    Add-WordBullet -Selection $selection -Text ("Resultado global: " + (Format-Decimal $successfulRatePct 2) + "% exitosas y " + (Format-Decimal $failedRatePct 2) + "% fallidas.")
    Add-WordParagraph -Selection $selection -Text "Calculo de duracion aproximada:" -Size 12 -Bold $true -Alignment 0 -After 4
    Add-WordParagraph -Selection $selection -Text $durationFormula -Size 10 -Bold $false -Alignment 0 -After 8 -FontName "Consolas"
    Add-WordParagraph -Selection $selection -Text "La ejecucion duro aproximadamente 63 minutos. Esa duracion es coherente con la ventana temporal visible en la grafica, que muestra un tramo extendido de actividad antes de la caida final por cierre de la prueba." -Size 11 -Bold $false -Alignment 3 -After 10

    Add-WordParagraph -Selection $selection -Text "2. Resultados a primera vista" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text "A primera vista la prueba deja una impresion mixta. El volumen total de peticiones es alto y el throughput promedio supera las 73 peticiones por segundo, lo que indica que el sistema fue capaz de procesar una carga importante. Sin embargo, el porcentaje de fallos llega a 2.44% y la latencia maxima se dispara hasta 29.93 segundos. En consecuencia, la corrida fue productiva, pero no completamente estable bajo carga alta." -Size 11 -Bold $false -Alignment 3 -After 10
    Add-WordImage -Selection $selection -Path $globalChartPath -Width 360 -Caption "Figura 1. Relacion entre peticiones exitosas y fallidas observadas en el resumen de k6."

    Add-WordParagraph -Selection $selection -Text "3. Resultados detallados" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordBullet -Selection $selection -Text ("Latencia promedio: " + (Format-Decimal $summary.http_req_duration.avg_ms 2) + " ms. Muestra una presion real sobre el servicio.")
    Add-WordBullet -Selection $selection -Text ("Latencia mediana: " + (Format-Decimal $summary.http_req_duration.med_ms 2) + " ms. La mitad de las peticiones responde por debajo de ese umbral, por lo que el problema no afecta igual a todas las solicitudes.")
    Add-WordBullet -Selection $selection -Text ("P90 y P95: " + (Format-Decimal ($summary.http_req_duration.p90_ms / 1000) 2) + " s y " + (Format-Decimal ($summary.http_req_duration.p95_ms / 1000) 2) + " s. Esto revela una cola de latencia claramente degradada.")
    Add-WordBullet -Selection $selection -Text ("Latencia maxima: " + (Format-Decimal ($summary.http_req_duration.max_ms / 1000) 2) + " s. Es un valor extremo que evidencia episodios severos de espera.")
    Add-WordBullet -Selection $selection -Text ("Tiempo de espera del servidor: " + (Format-Decimal $summary.http_req_waiting.avg_ms 2) + " ms promedio. Practicamente coincide con la latencia total.")
    Add-WordBullet -Selection $selection -Text "Red y conexion: bloqueo, conexion, TLS, envio y recepcion se mantienen en valores despreciables frente al waiting. No hay evidencia fuerte de que la red del cliente sea el cuello de botella principal."
    Add-WordParagraph -Selection $selection -Text "Relacion entre waiting y duration:" -Size 12 -Bold $true -Alignment 0 -After 4
    Add-WordParagraph -Selection $selection -Text $waitingFormula -Size 10 -Bold $false -Alignment 0 -After 8 -FontName "Consolas"
    Add-WordParagraph -Selection $selection -Text ("La diferencia entre el promedio global de latencia y el promedio de las respuestas esperadas es de " + (Format-Decimal $latencyGapMs 2) + " ms. Eso refuerza la idea de que la presion del sistema ya contamina la experiencia general de la transaccion y no solo los casos fallidos.") -Size 11 -Bold $false -Alignment 3 -After 10
    Add-WordImage -Selection $selection -Path $latencyChartPath -Width 430 -Caption "Figura 2. Perfil de latencia en escala logaritmica. La cola larga se hace evidente al comparar mediana, promedio y maximo."

    Add-WordParagraph -Selection $selection -Text "4. Relacion entre el resumen de terminal y la grafica" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text ("La terminal aporta el panorama agregado: " + (Format-Decimal $requestsPerSecond 6) + " req/s en promedio, " + (Format-Integer $totalRequests) + " peticiones totales, 2.44% de error y una latencia con cola larga. La grafica aporta lo que el resumen no puede mostrar: la evolucion temporal de la prueba.") -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordParagraph -Selection $selection -Text ("El punto visible del diagrama en 2025-04-24 02:02:00 indica 140 VUs y " + (Format-Decimal $referencePoint.http_reqs_per_s 2) + " req/s. Ese valor es coherente con el promedio de 73.18 req/s porque la grafica tambien muestra una caida intermedia pronunciada del throughput. En otras palabras, el sistema si alcanza una banda cercana a " + $typicalObservedReqLow + "-" + $typicalObservedReqHigh + " req/s bajo 140 VUs, pero no logra sostenerla sin sobresaltos durante toda la ejecucion.") -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordParagraph -Selection $selection -Text ("La reconstruccion aproximada del diagrama muestra que el throughput cae hasta una zona cercana a " + (Format-Decimal $minObservedReq 2) + " req/s sin que desaparezca la carga. Esa oscilacion explica por que un punto puntual de 82.6 req/s puede convivir con un promedio general inferior.") -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordParagraph -Selection $selection -Text "Relacion puntual entre VUs y throughput:" -Size 12 -Bold $true -Alignment 0 -After 4
    Add-WordParagraph -Selection $selection -Text $reqPerVuFormula -Size 10 -Bold $false -Alignment 0 -After 8 -FontName "Consolas"
    Add-WordImage -Selection $selection -Path $monitoringChartPath -Width 470 -Caption "Figura 3. Reconstruccion aproximada del monitoreo entregado. Se usa como apoyo visual y no como telemetria cruda."

    Add-WordParagraph -Selection $selection -Text "5. Analisis de errores por etapa" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text "El reparto de errores no esta distribuido de forma uniforme. Casi toda la carga fallida se concentra en stage_1, que por contexto se interpreta como la fase principal de la prueba." -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordParagraph -Selection $selection -Text "Concentracion de fallos en la etapa principal:" -Size 12 -Bold $true -Alignment 0 -After 4
    Add-WordParagraph -Selection $selection -Text $stage1Formula -Size 10 -Bold $false -Alignment 0 -After 8 -FontName "Consolas"
    Add-WordParagraph -Selection $selection -Text "Esto significa que stage_1 concentra practicamente todos los errores. La lectura operativa es clara: el sistema no falla de manera aleatoria al inicio o al final; falla sobre todo cuando esta sometido al tramo fuerte de carga." -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordParagraph -Selection $selection -Text "Peso de los errores 5xx dentro del total:" -Size 12 -Bold $true -Alignment 0 -After 4
    Add-WordParagraph -Selection $selection -Text $fiveXxFormula -Size 10 -Bold $false -Alignment 0 -After 8 -FontName "Consolas"
    Add-WordParagraph -Selection $selection -Text "Que casi nueve de cada diez fallos sean 5xx desplaza el foco hacia el servidor o sus dependencias. Los 4xx existen, pero son secundarios frente a la magnitud del problema del lado backend." -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordImage -Selection $selection -Path $stageErrorChartPath -Width 420 -Caption "Figura 4. La etapa principal concentra la mayor parte de los errores y, dentro de ella, dominan claramente los 5xx."

    Add-WordParagraph -Selection $selection -Text "6. Posibles cuellos de botella y causas probables" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text "Con la evidencia disponible no es posible demostrar una causa raiz unica. Sin embargo, si es posible jerarquizar causas probables y distinguir entre afirmaciones sustentadas y especulaciones razonables." -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordBullet -Selection $selection -Text "Evidencia directa observable: el promedio de http_req_waiting es practicamente igual al de http_req_duration, lo que apunta a saturacion dentro del backend."
    Add-WordBullet -Selection $selection -Text "Evidencia directa observable: la mayor parte de los fallos son 5xx y la etapa principal concentra casi todos los errores."
    Add-WordBullet -Selection $selection -Text "Evidencia directa observable: el throughput cae con 140 VUs activos, por lo que la degradacion no depende de una falta de carga, sino de una perdida de capacidad efectiva del sistema."
    Add-WordBullet -Selection $selection -Text "Hipotesis razonable: saturacion de CPU o de hilos del servidor."
    Add-WordBullet -Selection $selection -Text "Hipotesis razonable: cuello de botella en base de datos, ya sea por consultas lentas, bloqueos o limites de conexiones."
    Add-WordBullet -Selection $selection -Text "Hipotesis razonable: agotamiento de pools de conexiones o workers insuficientes."
    Add-WordBullet -Selection $selection -Text "Hipotesis razonable: dependencia externa inestable o timeouts encadenados."
    Add-WordBullet -Selection $selection -Text "Hipotesis razonable: ausencia de una capa de balanceo o resiliencia al frente del servicio. El material entregado no muestra evidencia de un load balancer o de mecanismos de distribucion; si en un escenario real esa capa no existiera, la degradacion bajo carga sostenida podria amplificarse."
    Add-WordParagraph -Selection $selection -Text "Con esta evidencia se puede afirmar que el cuello de botella parece estar del lado servidor o de sus dependencias. Lo que no se puede afirmar con certeza, solo con este material, es si la causa exacta fue CPU, base de datos, pool de conexiones o una dependencia externa concreta." -Size 11 -Bold $false -Alignment 3 -After 10

    Add-WordParagraph -Selection $selection -Text "7. Punto mas importante del analisis" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text "El punto mas importante es que el sistema si procesa un volumen alto, pero no lo hace de forma estable bajo la carga principal. La evidencia conjunta de k6 y del diagrama muestra una mezcla de tres senales: caida visible del throughput, concentracion de errores 5xx en la etapa fuerte y tiempos de espera del servidor que explican casi toda la latencia. En conjunto, eso describe un cuello de botella del lado servidor o de sus dependencias, no un problema primario de red." -Size 11 -Bold $false -Alignment 3 -After 10

    Add-WordParagraph -Selection $selection -Text "8. Conclusiones" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordBullet -Selection $selection -Text "La prueba movio un volumen considerable de peticiones y demuestra que el sistema tiene cierta capacidad de procesamiento, pero no una estabilidad completa bajo carga alta."
    Add-WordBullet -Selection $selection -Text "El promedio de 73.18 req/s es real, pero no representa estabilidad continua; la grafica deja ver una degradacion marcada a mitad de la ejecucion."
    Add-WordBullet -Selection $selection -Text "El comportamiento de http_req_waiting sugiere que el mayor tiempo se pierde dentro del backend y no en la red del cliente."
    Add-WordBullet -Selection $selection -Text "La etapa principal concentra practicamente todos los errores, y dentro de ellos dominan de forma clara los 5xx."
    Add-WordBullet -Selection $selection -Text "La evidencia disponible permite hablar de saturacion o degradacion del servidor, pero no permite aislar una causa raiz unica sin telemetria interna adicional."

    Add-WordParagraph -Selection $selection -Text "9. Recomendaciones" -Size 16 -Bold $true -Alignment 0 -After 8
    Add-WordParagraph -Selection $selection -Text "En un escenario real, estas serian las acciones mas utiles para diagnosticar mejor el problema y reducir la posibilidad de recurrencia." -Size 11 -Bold $false -Alignment 3 -After 8
    Add-WordBullet -Selection $selection -Text "Correlacionar la ventana de la prueba con metricas de CPU, memoria, hilos, pools de conexiones y base de datos para validar la causa exacta del waiting elevado."
    Add-WordBullet -Selection $selection -Text "Revisar logs de aplicacion y de infraestructura en la fase equivalente a stage_1, donde se concentra el 99.96% de los errores."
    Add-WordBullet -Selection $selection -Text "Analizar especificamente los 5xx para identificar si provienen de saturacion, timeouts, dependencias externas o errores de negocio mal controlados."
    Add-WordBullet -Selection $selection -Text "Ejecutar una nueva prueba escalonada con puntos intermedios de concurrencia para ubicar con mayor precision el umbral donde empieza la degradacion."
    Add-WordBullet -Selection $selection -Text "Si se confirma presion sobre base de datos, revisar indices, tiempos de consulta y limites de conexiones; si se confirma presion sobre la aplicacion, revisar workers, timeouts y politica de escalado."
    Add-WordBullet -Selection $selection -Text "Mantener una distincion clara entre evidencia y especulacion para no sobreinterpretar los datos disponibles."

    Add-WordParagraph -Selection $selection -Text "Fuente de datos: transcripcion del resumen de k6 y reconstruccion aproximada del diagrama de monitoreo entregado. La reconstruccion grafica se incluye como apoyo visual y no sustituye a la telemetria original." -Size 9 -Bold $false -Alignment 3 -After 0
    $document.SaveAs([string]$docPath, [ref]0)
    $document.Close()
}
finally {
    if ($document -ne $null) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($document) | Out-Null
    }
    if ($word -ne $null) {
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
