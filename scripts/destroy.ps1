<#
.SYNOPSIS
  Destruye toda la infraestructura de la prueba (evita costo residual).

.DESCRIPTION
  Pide confirmacion explicita antes de borrar. El repositorio ECR se crea con
  force_delete = true, asi que se va junto con sus imagenes.

.EXAMPLE
  .\scripts\destroy.ps1
#>
[CmdletBinding()]
param(
  [string]$AwsProfile  = 'ethos-cand',
  [string]$Region      = 'us-east-1',
  [string]$CandidateId = 'lucio-o-dev',
  [int]$ContainerPort  = 8081,
  [string]$AlbSecurityGroupId     = 'sg-07bd280c1ecb8a92a',
  [string]$ServiceSecurityGroupId = 'sg-07bd280c1ecb8a92a',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$env:AWS_PROFILE = $AwsProfile
$env:AWS_REGION  = $Region

$InfraDir = Join-Path $PSScriptRoot '..\infra\ecs' | Resolve-Path

if (-not $Force) {
  Write-Host "Se va a DESTRUIR toda la infraestructura de ethos-cand-${CandidateId}:" -ForegroundColor Yellow
  Write-Host '  ALB, listener, target group, cluster y servicio ECS, roles IAM, log group y el repo ECR con sus imagenes. El security group compartido de la VPC se reutiliza, no se crea ni se borra.'
  $answer = Read-Host "Escribe 'destruir' para confirmar"
  if ($answer -ne 'destruir') { Write-Host 'Cancelado.'; exit 0 }
}

Push-Location $InfraDir
try {
  terraform destroy -input=false -auto-approve `
    "-var=candidate_id=$CandidateId" `
    "-var=aws_region=$Region" `
    "-var=aws_profile=$AwsProfile" `
    "-var=container_port=$ContainerPort" `
    "-var=alb_security_group_id=$AlbSecurityGroupId" `
    "-var=service_security_group_id=$ServiceSecurityGroupId"
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'terraform destroy fallo. Revisa dependencias colgadas (ENIs del servicio suelen tardar).' -ForegroundColor Red
    exit 1
  }
}
finally {
  Pop-Location
}

Write-Host 'Infraestructura destruida.' -ForegroundColor Green
