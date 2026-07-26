<#
.SYNOPSIS
  Valida la entrega: /health y /ready por HTTP publico + tags en los recursos.

.EXAMPLE
  .\scripts\verify.ps1 -BaseUrl http://ethos-cand-lucio-o-dev-alb-123.us-east-1.elb.amazonaws.com
#>
[CmdletBinding()]
param(
  [string]$BaseUrl      = '',
  [string]$AwsProfile   = 'ethos-cand',
  [string]$Region       = 'us-east-1',
  [string]$CandidateId  = 'lucio-o-dev',
  [int]$Attempts        = 30,
  [int]$DelaySeconds    = 10
)

$ErrorActionPreference = 'Continue'
$env:AWS_PROFILE = $AwsProfile
$env:AWS_REGION  = $Region

$prefix  = "ethos-cand-$CandidateId"
$AlbName = "$prefix-alb"
$Cluster = "$prefix-ecs-cluster"
$Service = "$prefix-svc"
$failed  = $false

function Say([string]$m) { Write-Host "`n==> $m" -ForegroundColor Cyan }

if (-not $BaseUrl) {
  Say 'Resolviendo DNS del ALB'
  $dns = aws elbv2 describe-load-balancers --names $AlbName --query 'LoadBalancers[0].DNSName' --output text
  if (-not $dns -or $dns -eq 'None') { Write-Host '  x No se pudo resolver el ALB.' -ForegroundColor Red; exit 1 }
  $BaseUrl = "http://$dns"
}
$BaseUrl = $BaseUrl.TrimEnd('/')
Write-Host "  Base: $BaseUrl"

# --- HTTP publico ------------------------------------------------------------
foreach ($path in '/health', '/ready') {
  Say "GET $BaseUrl$path"
  $ok = $false
  for ($i = 1; $i -le $Attempts; $i++) {
    try {
      $r = Invoke-WebRequest -Uri "$BaseUrl$path" -TimeoutSec 10 -UseBasicParsing
      if ($r.StatusCode -eq 200) {
        Write-Host "  OK 200" -ForegroundColor Green
        Write-Host "     $($r.Content.Substring(0, [Math]::Min(300, $r.Content.Length)))"
        $ok = $true
        break
      }
      Write-Host "  ... intento $i/$Attempts -> $($r.StatusCode)"
    } catch {
      Write-Host "  ... intento $i/$Attempts -> sin respuesta"
    }
    Start-Sleep -Seconds $DelaySeconds
  }
  if (-not $ok) { Write-Host "  x $path no devolvio 200" -ForegroundColor Red; $failed = $true }
}

# --- Salud del servicio ------------------------------------------------------
Say 'Estado del servicio ECS'
aws ecs describe-services --cluster $Cluster --services $Service `
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount,taskDef:taskDefinition}' --output table

Say 'Salud de los targets en el ALB'
$tgArn = aws elbv2 describe-target-groups --names "$prefix-tg" --query 'TargetGroups[0].TargetGroupArn' --output text
if ($tgArn -and $tgArn -ne 'None') {
  aws elbv2 describe-target-health --target-group-arn $tgArn `
    --query 'TargetHealthDescriptions[].{target:Target.Id,port:Target.Port,estado:TargetHealth.State,razon:TargetHealth.Reason}' --output table
}

# --- Tags obligatorios -------------------------------------------------------
Say 'Verificando tags ethos:candidate / ethos:project'
$expected = @{ 'ethos:candidate' = $CandidateId; 'ethos:project' = 'devops-test' }

function Check-Tags([string]$label, [string]$arn) {
  if (-not $arn -or $arn -eq 'None') { Write-Host "  ? $label - no encontrado" -ForegroundColor Yellow; return }
  $raw = aws elbv2 describe-tags --resource-arns $arn --query 'TagDescriptions[0].Tags' --output json 2>$null
  if (-not $raw) { Write-Host "  ? $label - sin lectura de tags" -ForegroundColor Yellow; return }
  $tags = @{}
  ($raw | ConvertFrom-Json) | ForEach-Object { $tags[$_.Key] = $_.Value }
  $missing = @()
  foreach ($k in $expected.Keys) { if ($tags[$k] -ne $expected[$k]) { $missing += $k } }
  if ($missing.Count -eq 0) { Write-Host "  OK $label" -ForegroundColor Green }
  else { Write-Host "  x $label - falta/incorrecto: $($missing -join ', ')" -ForegroundColor Red; $script:failed = $true }
}

$albArn = aws elbv2 describe-load-balancers --names $AlbName --query 'LoadBalancers[0].LoadBalancerArn' --output text
Check-Tags "ALB  ($AlbName)" $albArn
Check-Tags "TG   ($prefix-tg)" $tgArn

foreach ($pair in @(
    @{ label = "Cluster ECS ($Cluster)"; arn = (aws ecs describe-clusters --clusters $Cluster --query 'clusters[0].clusterArn' --output text) },
    @{ label = "Servicio ECS ($Service)"; arn = (aws ecs describe-services --cluster $Cluster --services $Service --query 'services[0].serviceArn' --output text) }
  )) {
  $raw = aws ecs list-tags-for-resource --resource-arn $pair.arn --query 'tags' --output json 2>$null
  if ($raw) {
    $tags = @{}
    ($raw | ConvertFrom-Json) | ForEach-Object { $tags[$_.key] = $_.value }
    $missing = @()
    foreach ($k in $expected.Keys) { if ($tags[$k] -ne $expected[$k]) { $missing += $k } }
    if ($missing.Count -eq 0) { Write-Host "  OK $($pair.label)" -ForegroundColor Green }
    else { Write-Host "  x $($pair.label) - falta/incorrecto: $($missing -join ', ')" -ForegroundColor Red; $failed = $true }
  } else {
    Write-Host "  ? $($pair.label) - sin lectura de tags" -ForegroundColor Yellow
  }
}

$ecrTags = aws ecr list-tags-for-resource --resource-arn "arn:aws:ecr:${Region}:$((aws sts get-caller-identity --query Account --output text)):repository/$prefix" --query 'tags' --output json 2>$null
if ($ecrTags) {
  $tags = @{}
  ($ecrTags | ConvertFrom-Json) | ForEach-Object { $tags[$_.Key] = $_.Value }
  $missing = @()
  foreach ($k in $expected.Keys) { if ($tags[$k] -ne $expected[$k]) { $missing += $k } }
  if ($missing.Count -eq 0) { Write-Host "  OK ECR ($prefix)" -ForegroundColor Green }
  else { Write-Host "  x ECR ($prefix) - falta/incorrecto: $($missing -join ', ')" -ForegroundColor Red; $failed = $true }
}

Write-Host ''
if ($failed) { Write-Host 'VERIFICACION CON FALLOS' -ForegroundColor Red; exit 1 }
Write-Host 'VERIFICACION OK' -ForegroundColor Green
Write-Host "  URL de entrega: $BaseUrl"
