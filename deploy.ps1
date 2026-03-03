param (
    [string]$PluginName,
    [string]$EnvName = "staging",
    [string]$SpecificFiles = ""
)

$envFile = Join-Path $PSScriptRoot ".env.deploy"
if (-not (Test-Path $envFile)) {
    Write-Host ".env.deploy file not found at $envFile!" -ForegroundColor Red
    exit 1
}

$config = @{}
Get-Content $envFile | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $name, $value = $_.Split('=', 2)
    $config[$name.Trim()] = $value.Trim()
}

$DEPLOY_HOST = $config['DEPLOY_HOST']
$DEPLOY_USER = $config['DEPLOY_USER']
$DEPLOY_PORT = $config['DEPLOY_PORT']
$LOCAL_PLUGINS_DIR = $config['LOCAL_PLUGINS_DIR'].Trim('"')

if ($EnvName -eq "production") {
    $REMOTE_BASE = $config['REMOTE_BASE_PRODUCTION'].Trim('"')
    $DisplayName = "PRODUCTION"
}
else {
    $REMOTE_BASE = $config['REMOTE_BASE_STAGING'].Trim('"')
    $DisplayName = "STAGING"
}

$localBase = Join-Path $PSScriptRoot $LOCAL_PLUGINS_DIR
$localPluginPath = Join-Path $localBase $PluginName
$remotePluginPath = "$REMOTE_BASE/$PluginName"

if (-not (Test-Path $localPluginPath)) {
    Write-Host "❌ Local plugin folder not found: $localPluginPath" -ForegroundColor Red
    exit 1
}

# 1. Ensure remote plugin directory exists
ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "mkdir -p $remotePluginPath"

if ($SpecificFiles) {
    # Extract file array from comma-separated string
    $files = $SpecificFiles -split ','
    foreach ($file in $files) {
        $sourcePath = Join-Path $localPluginPath $file
        if (-not (Test-Path $sourcePath)) {
            Write-Host "⚠️ Warning: File not found locally, skipping: $file" -ForegroundColor Yellow
            continue
        }
        
        # Handle subfolders format
        $unixFile = $file -replace '\\', '/'
        $remoteFilePath = "$remotePluginPath/$unixFile"
        
        # Ensure the sub-directory exists on the server before copying
        if ($unixFile -match '/') {
            $remoteDir = $remoteFilePath.Substring(0, $remoteFilePath.LastIndexOf('/'))
            ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "mkdir -p $remoteDir"
        }

        Write-Host "📤 Uploading $file..." -ForegroundColor Cyan
        scp -P $DEPLOY_PORT "$sourcePath" "$($DEPLOY_USER)@$($DEPLOY_HOST):$remoteFilePath"
    }
}
else {
    Write-Host "📤 Uploading all files for '$PluginName'..." -ForegroundColor Cyan
    scp -P $DEPLOY_PORT -r "$localPluginPath/." "$($DEPLOY_USER)@$($DEPLOY_HOST):$remotePluginPath"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Setting server permissions..." -ForegroundColor Cyan
    ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "chmod 755 $remotePluginPath && find $remotePluginPath -type d -exec chmod 755 {} \; && find $remotePluginPath -type f -exec chmod 644 {} \;"
    Write-Host "✅ Successfully deployed to $DisplayName!" -ForegroundColor Green
}
else {
    Write-Host "❌ Upload finished with errors" -ForegroundColor Red
}
