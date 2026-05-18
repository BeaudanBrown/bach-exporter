Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string] $Message)
  Write-Host ""
  Write-Host $Message
}

function Read-RequiredRVersion {
  param([string] $SharedRoot)

  $LockPath = Join-Path $SharedRoot "app\renv.lock"
  if (-not (Test-Path -LiteralPath $LockPath)) {
    throw "Could not find app\renv.lock next to this launcher."
  }

  $Lock = Get-Content -LiteralPath $LockPath -Raw | ConvertFrom-Json
  $Version = $Lock.R.Version
  if ([string]::IsNullOrWhiteSpace($Version)) {
    throw "app\renv.lock does not declare an R version."
  }

  return $Version
}

function Get-RigCommand {
  $Rig = Get-Command rig -ErrorAction SilentlyContinue
  if ($null -eq $Rig) {
    $Roots = @(
      [Environment]::GetEnvironmentVariable("LOCALAPPDATA", "User"),
      [Environment]::GetEnvironmentVariable("ProgramFiles", "Machine"),
      [Environment]::GetEnvironmentVariable("ProgramFiles(x86)", "Machine")
    )
    $Candidates = foreach ($Root in $Roots) {
      if (-not [string]::IsNullOrWhiteSpace($Root)) {
        Join-Path $Root "Programs\rig\rig.exe"
        Join-Path $Root "rig\rig.exe"
      }
    }
    foreach ($Candidate in $Candidates) {
      if (-not [string]::IsNullOrWhiteSpace($Candidate) -and (Test-Path -LiteralPath $Candidate)) {
        return $Candidate
      }
    }

    return $null
  }

  return $Rig.Source
}

function Update-ProcessPath {
  $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = @($MachinePath, $UserPath) -join ";"
}

function Use-LauncherCache {
  $CacheRoot = $env:BACH_EXPORTER_LOCAL_CACHE_DIR
  if ([string]::IsNullOrWhiteSpace($CacheRoot)) {
    $LocalAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA", "User")
    if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
      $LocalAppData = [Environment]::GetFolderPath("LocalApplicationData")
    }
    if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
      $UserProfile = [Environment]::GetEnvironmentVariable("USERPROFILE", "User")
      if (-not [string]::IsNullOrWhiteSpace($UserProfile)) {
        $LocalAppData = Join-Path $UserProfile "AppData\Local"
      }
    }
    if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
      throw "Could not resolve a stable local AppData cache directory."
    }
    $CacheRoot = Join-Path $LocalAppData "R\cache\R\bachExporter"
  }

  $TempRoot = Join-Path $CacheRoot "tmp"
  New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

  $env:BACH_EXPORTER_LOCAL_CACHE_DIR = $CacheRoot
  $env:TMPDIR = $TempRoot
  $env:TMP = $TempRoot
  $env:TEMP = $TempRoot

  return @{
    CacheRoot = $CacheRoot
    TempRoot = $TempRoot
  }
}

function Install-RigWithWinget {
  $Winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($null -eq $Winget) {
    return $false
  }

  Write-Step "Installing rig with winget..."
  & $Winget.Source install --id Posit.rig -e --source winget --accept-package-agreements --accept-source-agreements
  Update-ProcessPath
  return ($LASTEXITCODE -eq 0)
}

function Ensure-Rig {
  $Rig = Get-RigCommand
  if ($null -ne $Rig) {
    return $Rig
  }

  if (Install-RigWithWinget) {
    Start-Sleep -Seconds 1
    Update-ProcessPath
    $Rig = Get-RigCommand
    if ($null -ne $Rig) {
      return $Rig
    }
  }

  throw @"
rig is required to install and launch the required R version, but it is not installed.

Install rig from:
https://github.com/r-lib/rig/releases

If winget just installed rig, close this window, open a new PowerShell window,
and rerun this launcher. This launcher does not change your default R version.
"@
}

function Ensure-RVersion {
  param(
    [string] $Rig,
    [string] $RequiredR
  )

  function Get-RMinorVersion {
    param([string] $Version)

    $Parts = $Version -split "\."
    if ($Parts.Length -lt 2) {
      throw "Required R version '$Version' is not a major.minor.patch version."
    }

    return "$($Parts[0]).$($Parts[1])"
  }

  function Find-CompatibleRVersion {
    param(
      [object[]] $Output,
      [string] $RequiredMinor
    )

    $Pattern = "(^|\s)($([regex]::Escape($RequiredMinor))\.[0-9]+)($|\s)"
    foreach ($Line in $Output) {
      $Text = [string] $Line
      if ($Text -match $Pattern) {
        return $Matches[2]
      }
    }

    return $null
  }

  function Invoke-Rig {
    param([string[]] $Arguments)

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      $Output = & $Rig @Arguments 2>&1
      $Status = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $PreviousErrorActionPreference
    }

    return @{
      Output = $Output
      Status = $Status
    }
  }

  $RequiredMinor = Get-RMinorVersion -Version $RequiredR

  Write-Step "Checking for R $RequiredMinor.x..."
  $ListResult = Invoke-Rig -Arguments @("list")
  $ListResult.Output | ForEach-Object {
    if ($_ -notmatch "^\[INFO\]") {
      Write-Host $_
    }
  }
  if ($ListResult.Status -ne 0) {
    throw "rig could not list installed R versions."
  }

  $InstalledVersion = Find-CompatibleRVersion -Output $ListResult.Output -RequiredMinor $RequiredMinor
  if ($null -ne $InstalledVersion) {
    return $InstalledVersion
  }

  Write-Step "Installing R $RequiredMinor.x with rig..."
  $AddResult = Invoke-Rig -Arguments @("add", $RequiredMinor)
  $AddResult.Output | ForEach-Object {
    if ($_ -notmatch "^\[INFO\]") {
      Write-Host $_
    }
  }
  if ($AddResult.Status -ne 0) {
    throw "rig failed to install R $RequiredMinor.x."
  }

  $ListResult = Invoke-Rig -Arguments @("list")
  $InstalledVersion = Find-CompatibleRVersion -Output $ListResult.Output -RequiredMinor $RequiredMinor
  if ($null -eq $InstalledVersion) {
    throw "rig installed R, but no R $RequiredMinor.x installation was detected."
  }

  return $InstalledVersion
}

$LauncherRoot = Split-Path -Parent $PSCommandPath
$SharedRoot = Split-Path -Parent $LauncherRoot
$Launcher = Join-Path $LauncherRoot "launch_bach_exporter.R"
if (-not (Test-Path -LiteralPath $Launcher)) {
  throw "Could not find launcher\launch_bach_exporter.R next to this launcher."
}

$RequiredR = Read-RequiredRVersion -SharedRoot $SharedRoot
$Rig = Ensure-Rig
$RunR = Ensure-RVersion -Rig $Rig -RequiredR $RequiredR
$Cache = Use-LauncherCache

Write-Step "Launching BACH Exporter with R $RunR..."
Write-Host "Shared root: $SharedRoot"
Write-Host "Launcher: $Launcher"
Write-Host "Local cache: $($Cache.CacheRoot)"
$env:BACH_EXPORTER_LAUNCHER = $Launcher
try {
  & $Rig run --r-version $RunR -f $Launcher
  $RunStatus = $LASTEXITCODE
  if ($RunStatus -ne 0) {
    Write-Host ""
    Write-Host "rig/R exited with status $RunStatus."
  }
  exit $RunStatus
} finally {
  Remove-Item Env:\BACH_EXPORTER_LAUNCHER -ErrorAction SilentlyContinue
}
