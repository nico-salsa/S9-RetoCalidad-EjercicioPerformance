param(
    [Parameter(Mandatory = $true)]
    [string]$SummaryPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [string]$Title = "Reporte de rendimiento"
)

function Get-MetricValue {
    param(
        [object]$Metrics,
        [string]$Name,
        [string]$Field,
        [double]$Default = 0
    )

    $metricProperty = $Metrics.PSObject.Properties[$Name]
    if ($null -eq $metricProperty) {
        return $Default
    }

    $metricSource = $metricProperty.Value
    if ($metricSource.PSObject.Properties["values"]) {
        $metricSource = $metricSource.values
    }

    $valueProperty = $metricSource.PSObject.Properties[$Field]
    if ($null -eq $valueProperty) {
        return $Default
    }

    return [double]$valueProperty.Value
}

$summary = Get-Content -Raw -Path $SummaryPath | ConvertFrom-Json
$metrics = $summary.metrics
$requests = [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_reqs" -Field "count"), 0)
$tps = [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_reqs" -Field "rate"), 2)
$latencyAverage = [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "avg"), 2)
$latencyP95 = [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "p(95)"), 2)
$latencyMax = [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "max"), 2)
$failedRate = [math]::Round(((Get-MetricValue -Metrics $metrics -Name "failed_transactions" -Field "value") * 100), 2)
$slowRate = [math]::Round(((Get-MetricValue -Metrics $metrics -Name "slow_transactions" -Field "value") * 100), 2)
$successRate = [math]::Round(((Get-MetricValue -Metrics $metrics -Name "successful_logins" -Field "value") * 100), 2)
$checksPasses = [math]::Round((Get-MetricValue -Metrics $metrics -Name "checks" -Field "passes"), 0)
$checksFails = [math]::Round((Get-MetricValue -Metrics $metrics -Name "checks" -Field "fails"), 0)
$durationLabels = @("min", "avg", "med", "p90", "p95", "max")
$durationData = @(
    [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "min"), 2),
    $latencyAverage,
    [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "med"), 2),
    [math]::Round((Get-MetricValue -Metrics $metrics -Name "http_req_duration" -Field "p(90)"), 2),
    $latencyP95,
    $latencyMax
)
$qualityLabels = @("TPS", "Error %", "Lentas %", "Exito %")
$qualityData = @($tps, $failedRate, $slowRate, $successRate)
$durationLabelsJson = $durationLabels | ConvertTo-Json -Compress
$durationDataJson = $durationData | ConvertTo-Json -Compress
$qualityLabelsJson = $qualityLabels | ConvertTo-Json -Compress
$qualityDataJson = $qualityData | ConvertTo-Json -Compress
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$Title</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4efe7;
      --panel: #fffaf2;
      --panel-strong: #f6ead8;
      --ink: #1f2933;
      --muted: #5d6a75;
      --accent: #005f73;
      --accent-soft: #0a9396;
      --warning: #bb3e03;
      --ok: #2a9d8f;
      --border: #d9c7af;
      --shadow: 0 18px 40px rgba(31, 41, 51, 0.08);
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-family: "Segoe UI", "Trebuchet MS", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top left, rgba(10, 147, 150, 0.16), transparent 28%),
        radial-gradient(circle at top right, rgba(187, 62, 3, 0.12), transparent 24%),
        linear-gradient(180deg, #f7f1e8 0%, #f2ece2 100%);
      min-height: 100vh;
    }

    .wrap {
      max-width: 1180px;
      margin: 0 auto;
      padding: 36px 20px 44px;
    }

    .hero {
      background: linear-gradient(140deg, rgba(0, 95, 115, 0.96), rgba(10, 147, 150, 0.9));
      color: #fefcf8;
      border-radius: 24px;
      padding: 28px;
      box-shadow: var(--shadow);
      border: 1px solid rgba(255, 255, 255, 0.12);
    }

    .hero h1 {
      margin: 0 0 10px;
      font-size: clamp(1.8rem, 4vw, 3rem);
      line-height: 1.05;
    }

    .hero p {
      margin: 0;
      color: rgba(254, 252, 248, 0.82);
      max-width: 760px;
      line-height: 1.5;
    }

    .grid {
      display: grid;
      gap: 18px;
      margin-top: 22px;
    }

    .cards {
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    }

    .charts {
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    }

    .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 22px;
      box-shadow: var(--shadow);
      padding: 22px;
    }

    .card strong {
      display: block;
      font-size: 2rem;
      line-height: 1;
      margin-bottom: 10px;
      color: var(--accent);
    }

    .card span {
      display: block;
      font-size: 0.96rem;
      color: var(--muted);
    }

    .section-title {
      margin: 0 0 14px;
      font-size: 1.1rem;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      color: var(--muted);
    }

    .status {
      display: grid;
      gap: 12px;
    }

    .status-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 14px 16px;
      border-radius: 16px;
      background: var(--panel-strong);
      border: 1px solid rgba(0, 95, 115, 0.08);
    }

    .status-row b {
      font-size: 1.05rem;
    }

    .status-row span {
      color: var(--muted);
    }

    .pill {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 104px;
      padding: 7px 12px;
      border-radius: 999px;
      font-weight: 700;
      color: #fff;
    }

    .pill.ok {
      background: var(--ok);
    }

    .pill.warn {
      background: var(--warning);
    }

    .meta {
      margin-top: 18px;
      color: var(--muted);
      font-size: 0.92rem;
    }

    canvas {
      width: 100% !important;
      height: 320px !important;
    }

    @media (max-width: 640px) {
      .wrap {
        padding: 20px 14px 28px;
      }

      .hero,
      .panel {
        border-radius: 18px;
      }

      .status-row {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }
    }
  </style>
</head>
<body>
  <main class="wrap">
    <section class="hero">
      <h1>$Title</h1>
      <p>Reporte visual generado a partir del resumen exportado por k6. El objetivo del ejercicio es validar el login de Fake Store API con una meta de 20 TPS, latencia maxima de 1500 ms y error menor a 3%.</p>
    </section>

    <section class="grid cards">
      <article class="panel card">
        <strong>$requests</strong>
        <span>Peticiones ejecutadas</span>
      </article>
      <article class="panel card">
        <strong>$tps</strong>
        <span>TPS promedio</span>
      </article>
      <article class="panel card">
        <strong>$latencyP95 ms</strong>
        <span>Latencia p95</span>
      </article>
      <article class="panel card">
        <strong>$latencyMax ms</strong>
        <span>Latencia maxima</span>
      </article>
    </section>

    <section class="grid charts">
      <article class="panel">
        <h2 class="section-title">Distribucion de latencia</h2>
        <canvas id="latencyChart"></canvas>
      </article>
      <article class="panel">
        <h2 class="section-title">Calidad de la ejecucion</h2>
        <canvas id="qualityChart"></canvas>
      </article>
    </section>

    <section class="grid">
      <article class="panel">
        <h2 class="section-title">Indicadores de cumplimiento</h2>
        <div class="status">
          <div class="status-row">
            <div>
              <b>TPS minimo</b>
              <span>Objetivo: al menos 20 TPS</span>
            </div>
            <div class="pill $(if ($tps -ge 20) { "ok" } else { "warn" })">$(if ($tps -ge 20) { "Cumple" } else { "No cumple" })</div>
          </div>
          <div class="status-row">
            <div>
              <b>Latencia maxima</b>
              <span>Objetivo: maximo 1500 ms</span>
            </div>
            <div class="pill $(if ($latencyMax -le 1500) { "ok" } else { "warn" })">$(if ($latencyMax -le 1500) { "Cumple" } else { "No cumple" })</div>
          </div>
          <div class="status-row">
            <div>
              <b>Tasa de error</b>
              <span>Objetivo: menor a 3%</span>
            </div>
            <div class="pill $(if ($failedRate -lt 3) { "ok" } else { "warn" })">$(if ($failedRate -lt 3) { "Cumple" } else { "No cumple" })</div>
          </div>
          <div class="status-row">
            <div>
              <b>Checks funcionales</b>
              <span>Pases: $checksPasses | Fallos: $checksFails</span>
            </div>
            <div class="pill $(if ($successRate -ge 97) { "ok" } else { "warn" })">$(if ($successRate -ge 97) { "Estable" } else { "Inestable" })</div>
          </div>
        </div>
        <div class="meta">Generado: $generatedAt</div>
      </article>
    </section>
  </main>

  <script>
    const durationLabels = $durationLabelsJson;
    const durationData = $durationDataJson;
    const qualityLabels = $qualityLabelsJson;
    const qualityData = $qualityDataJson;

    new Chart(document.getElementById('latencyChart'), {
      type: 'bar',
      data: {
        labels: durationLabels,
        datasets: [{
          label: 'Milisegundos',
          data: durationData,
          borderRadius: 10,
          backgroundColor: ['#94d2bd', '#0a9396', '#e9d8a6', '#ee9b00', '#ca6702', '#bb3e03']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              color: '#5d6a75'
            },
            grid: {
              color: 'rgba(93, 106, 117, 0.12)'
            }
          },
          x: {
            ticks: {
              color: '#5d6a75'
            },
            grid: {
              display: false
            }
          }
        }
      }
    });

    new Chart(document.getElementById('qualityChart'), {
      type: 'radar',
      data: {
        labels: qualityLabels,
        datasets: [{
          label: 'Indicadores',
          data: qualityData,
          fill: true,
          backgroundColor: 'rgba(10, 147, 150, 0.18)',
          borderColor: '#005f73',
          pointBackgroundColor: '#bb3e03',
          pointBorderColor: '#fff',
          pointHoverBackgroundColor: '#fff',
          pointHoverBorderColor: '#bb3e03'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          r: {
            angleLines: {
              color: 'rgba(93, 106, 117, 0.15)'
            },
            grid: {
              color: 'rgba(93, 106, 117, 0.15)'
            },
            pointLabels: {
              color: '#5d6a75'
            },
            ticks: {
              backdropColor: 'transparent',
              color: '#5d6a75'
            }
          }
        },
        plugins: {
          legend: {
            display: false
          }
        }
      }
    });
  </script>
</body>
</html>
"@

$outputDirectory = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Set-Content -Path $OutputPath -Value $html -Encoding UTF8
