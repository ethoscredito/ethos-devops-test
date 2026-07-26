<#
.SYNOPSIS
  Despliegue completo del Camino A (ECS Fargate + ALB) desde cero.

.DESCRIPTION
  Resuelve el huevo-y-la-gallina del primer deploy en 3 fases:
    1. Crea SOLO el repositorio ECR (el servicio ECS no puede arrancar sin imagen).
    2. Construye app-ethos-mock y la publica en ECR con tag trazable (SHA del commit).
    3. Aplica el resto de la infraestructura apuntando a esa imagen.
  Termina con el smoke test contra el ALB.

.PARAMETER RepoRoot
  Ruta al clon de ethos-devops-test (donde vive app-ethos-mock/).

.PARAMETER AwsProfile
  Perfil del AWS CLI con las credenciales del candidato.

.PARAMETER ContainerPort
  Puerto interno de la app. Si el Dockerfile declara EXPOSE, se detecta solo.

.EXAMPLE
  .\scripts\bootstrap.ps1 -RepoRoot C:\ruta\a\ethos-devops-test
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [string]$AwsProfile   = 'ethos-cand',
  [string]$Region       = 'us-east-1',
  [string]$CandidateId  = 'lucio-o-dev',
  [int]$ContainerPort   = 0,
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

function Say([string]$msg)  { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Warn([string]$msg) { Write-Host "  ! $msg"   -ForegroundColor Yellow }
function Die([string]$msg)  { Write-Host "  x $msg"   -ForegroundColor Red; exit 1 }

$InfraDir = Join-Path $PSScriptRoot '..\infra\ecs' | Resolve-Path
$AppDir   = Join-Path $RepoRoot 'app-ethos-mock'

if (-not (Test-Path $AppDir)) { Die "No existe $AppDir. Pasa -RepoRoot apuntando al clon de ethos-devops-test." }

$env:AWS_PROFILE = $AwsProfile
$env:AWS_REGION  = $Region

# --- Sanidad -----------------------------------------------------------------
Say 'Verificando herramientas y credenciales'
foreach ($t in 'aws', 'terraform', 'docker', 'git') {
  if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { Die "Falta '$t' en el PATH." }
}
$who = aws sts get-caller-identity --output json | ConvertFrom-Json
if (-not $?) { Die 'Las credenciales de AWS no funcionan.' }
Write-Host "  Identidad: $($who.Arn)"
docker info *> $null
if (-not $?) { Die 'Docker no esta corriendo.' }

# --- Puerto del contenedor ---------------------------------------------------
$Dockerfile = Join-Path $AppDir 'Dockerfile'
$detected = 0
if (Test-Path $Dockerfile) {
  $m = Select-String -Path $Dockerfile -Pattern '^\s*EXPOSE\s+(\d+)' | Select-Object -First 1
  if ($m) { $detected = [int]$m.Matches[0].Groups[1].Value }
}
if ($ContainerPort -eq 0) {
  if ($detected -gt 0) { $ContainerPort = $detected; Write-Host "  Puerto detectado en el Dockerfile (EXPOSE): $ContainerPort" }
  else { $ContainerPort = 8080; Warn "El Dockerfile no declara EXPOSE. Usando $ContainerPort. Si /health no responde, reintenta con -ContainerPort <n>." }
} elseif ($detected -gt 0 -and $detected -ne $ContainerPort) {
  Warn "El Dockerfile declara EXPOSE $detected pero se forzo -ContainerPort $ContainerPort."
}

# --- Tag de imagen -----------------------------------------------------------
$sha = (git -C $RepoRoot rev-parse --short=12 HEAD 2>$null)
if (-not $sha) { $sha = 'local' }
$ImageTag = "sha-$sha"
Write-Host "  Tag de imagen: $ImageTag"

Push-Location $InfraDir
try {
  $tfCommon = @("-var=candidate_id=$CandidateId", "-var=aws_region=$Region", "-var=aws_profile=$AwsProfile", "-var=container_port=$ContainerPort")

  Say 'Fase 0/3 - terraform init'
  terraform init -input=false
  if ($LASTEXITCODE -ne 0) { Die 'terraform init fallo.' }

  Say 'Fase 1/3 - creando repositorio ECR'
  terraform apply -input=false -auto-approve "-target=aws_ecr_repository.app" @tfCommon
  if ($LASTEXITCODE -ne 0) { Die 'No se pudo crear el repositorio ECR. Revisa tags y permisos (ver docs/RUNBOOK.md).' }

  $EcrUrl = (terraform output -raw ecr_repository_url)
  if (-not $EcrUrl) { Die 'No se obtuvo la URL del ECR.' }
  Write-Host "  ECR: $EcrUrl"
  $Registry = $EcrUrl.Split('/')[0]

  if (-not $SkipBuild) {
    Say 'Fase 2/3 - build y push de la imagen'
    cmd /c "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry"
    if ($LASTEXITCODE -ne 0) { Die 'Login a ECR fallo.' }

    docker build `
      --label "org.opencontainers.image.revision=$sha" `
      --label "ethos.candidate=$CandidateId" `
      --label 'ethos.project=devops-test' `
      -t "${EcrUrl}:${ImageTag}" `
      -t "${EcrUrl}:candidato-${CandidateId}" `
      $AppDir
    if ($LASTEXITCODE -ne 0) { Die 'docker build fallo.' }

    docker push "${EcrUrl}:${ImageTag}"
    if ($LASTEXITCODE -ne 0) { Die 'docker push fallo.' }
    docker push "${EcrUrl}:candidato-${CandidateId}"
  } else {
    Warn 'Build omitido (-SkipBuild). Se asume que el tag ya existe en ECR.'
  }

  Say 'Fase 3/3 - aplicando infraestructura (IAM, ALB, ECS)'
  terraform apply -input=false -auto-approve @tfCommon "-var=image_tag=$ImageTag"
  if ($LASTEXITCODE -ne 0) { Die 'terraform apply fallo. Ver docs/RUNBOOK.md para los AccessDenied conocidos.' }

  $AppUrl = (terraform output -raw app_url)
  Say 'Resumen'
  terraform output resumen_entrega
}
finally {
  Pop-Location
}

Say 'Smoke test (puede tardar ~1-2 min mientras el target group pasa a healthy)'
& (Join-Path $PSScriptRoot 'verify.ps1') -BaseUrl $AppUrl

Say 'Listo'
Write-Host "  URL publica: $AppUrl" -ForegroundColor Green
Write-Host "  Health:      $AppUrl/health" -ForegroundColor Green
Write-Host "  Ready:       $AppUrl/ready" -ForegroundColor Green
