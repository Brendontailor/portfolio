#requires -Version 5.1
<#
.SYNOPSIS
    Quality gate e issues abertas do projeto no SonarQube Cloud.

.EXAMPLE
    .\scripts\sonar-check.ps1

.EXAMPLE
    .\scripts\sonar-check.ps1 -Project Brendontailor_outro-projeto
#>
param(
    [string]$Project = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command sonar -ErrorAction SilentlyContinue)) {
    Write-Error "SonarQube CLI nao encontrado no PATH."
    exit 1
}

if ($Project -eq "") {
    $remote = (git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$') {
        $Project = ($Matches.owner + "_" + ($Matches.repo -replace '[^A-Za-z0-9_]', '_'))
    }
}

if ($Project -eq "") {
    Write-Error "Nao foi possivel deduzir o projeto. Use -Project <owner>_<repo>."
    exit 1
}

Write-Host ""
Write-Host "SonarQube Cloud - $Project" -ForegroundColor Cyan
Write-Host ""

sonar auth status
if ($LASTEXITCODE -ne 0) {
    Write-Error "Sem autenticacao. Rode: sonar auth login --server https://sonarcloud.io --org brendontailor"
    exit 1
}

Write-Host ""
Write-Host "Quality gate" -ForegroundColor Cyan
sonar quality-gate status --project $Project

$raw = sonar api get "/api/issues/search?componentKeys=$Project&statuses=OPEN,CONFIRMED&ps=500"
$data = $raw | ConvertFrom-Json

Write-Host ""
Write-Host ("Issues abertas: {0}" -f $data.total) -ForegroundColor Cyan

if ($data.total -gt 0) {
    Write-Host ""
    $data.issues | Group-Object type | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  {0,-16} {1}" -f $_.Name, $_.Count)
    }
    Write-Host ""
    $data.issues | Sort-Object type, severity, rule | ForEach-Object {
        $file = $_.component -replace '^[^:]+:', ''
        Write-Host ("  [{0}/{1}] {2}  {3}:{4}" -f $_.type, $_.severity, $_.rule, $file, $_.line)
        Write-Host ("      {0}" -f $_.message)
    }
}