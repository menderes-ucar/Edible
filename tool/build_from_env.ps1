param(
    [ValidateSet('appbundle', 'apk', 'ipa')]
    [string]$Target = 'appbundle'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot '.env'

if (-not (Test-Path $envFile)) {
    throw "'.env' bulunamadı: $envFile"
}

$allowedKeys = @(
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'REVENUECAT_ANDROID_API_KEY',
    'REVENUECAT_IOS_API_KEY',
    'REVENUECAT_ENTITLEMENT_ID',
    'ROUTING_BASE_URL',
    'ROUTING_PROFILE',
    'ROUTING_API_KEY',
    'ROUTING_API_KEY_HEADER',
    'ROUTING_API_KEY_PREFIX',
    'ROUTING_USER_AGENT'
)

$defines = @()

foreach ($line in Get-Content -LiteralPath $envFile) {
    $trimmed = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
        continue
    }

    if ($trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        continue
    }

    $name = $Matches[1]
    $value = $Matches[2].Trim()

    if ($name -notin $allowedKeys) {
        continue
    }

    if ($value.Length -ge 2) {
        $first = $value.Substring(0, 1)
        $last = $value.Substring($value.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            $value = $value.Substring(1, $value.Length - 2)
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $defines += "--dart-define=$name=$value"
    }
}

if ($defines.Count -eq 0) {
    throw '.env içinde kullanılabilir hiçbir build değişkeni bulunamadı.'
}

Push-Location $projectRoot
try {
    Write-Host ''
    Write-Host 'Edible environment build' -ForegroundColor Cyan
    Write-Host "Target: $Target"
    Write-Host "Loaded $($defines.Count) build variables from .env"
    Write-Host ''

    switch ($Target) {
        'appbundle' {
            flutter build appbundle --release @defines
        }
        'apk' {
            flutter build apk --release @defines
        }
        'ipa' {
            flutter build ipa --release @defines
        }
    }
}
finally {
    Pop-Location
}
